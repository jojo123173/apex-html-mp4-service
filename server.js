const express = require("express");
const cors = require("cors");
const fsp = require("fs/promises");
const path = require("path");
const os = require("os");
const crypto = require("crypto");
const { execFile } = require("child_process");
const util = require("util");
const puppeteer = require("puppeteer");

const execFileAsync = util.promisify(execFile);

const app = express();
app.use(cors());
app.use(express.json({ limit: "80mb" })); // html + mp3 base64 can be big

// API key protection
const API_KEY = process.env.API_KEY || "CHANGE_ME";

// Health endpoint for Render/Railway checks
app.get("/health", (req, res) => res.json({ ok: true }));

app.post("/render-mp4", async (req, res) => {
  let tmpDir = null;
  let browser = null;

  try {
    const key = req.header("x-api-key");
    if (!key || key !== API_KEY) {
      return res.status(401).send("Unauthorized");
    }

    const { html, mp3_base64 } = req.body || {};
    if (!html || !mp3_base64) {
      return res.status(400).json({ error: "html and mp3_base64 required" });
    }

    tmpDir = await fsp.mkdtemp(path.join(os.tmpdir(), "apex-mp4-"));
    const id = crypto.randomBytes(8).toString("hex");

    const pngPath = path.join(tmpDir, `${id}.png`);
    const mp3Path = path.join(tmpDir, `${id}.mp3`);
    const mp4Path = path.join(tmpDir, `${id}.mp4`);

    // Write MP3 from base64
    await fsp.writeFile(mp3Path, Buffer.from(mp3_base64, "base64"));

    // Render HTML -> PNG
    browser = await puppeteer.launch({
      headless: "new",
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--disable-gpu",
        "--no-zygote",
        "--single-process"
      ]
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080, deviceScaleFactor: 1 });
    await page.setContent(html, { waitUntil: "networkidle0" });
    await page.screenshot({ path: pngPath, type: "png" });

    await browser.close();
    browser = null;

    // PNG + MP3 -> MP4 (ffmpeg must be in PATH inside Docker)
    await execFileAsync("ffmpeg", [
      "-y",
      "-loop", "1",
      "-i", pngPath,
      "-i", mp3Path,
      "-c:v", "libx264",
      "-tune", "stillimage",
      "-pix_fmt", "yuv420p",
      "-c:a", "aac",
      "-b:a", "192k",
      "-shortest",
      mp4Path
    ]);

    const mp4Buffer = await fsp.readFile(mp4Path);

    res.setHeader("Content-Type", "video/mp4");
    res.setHeader(
      "Content-Disposition",
      `inline; filename="presentation_${id}.mp4"`
    );
    return res.status(200).send(mp4Buffer);
  } catch (e) {
    console.error("Render failed:", e);
    return res.status(500).json({ error: "render failed", details: String(e) });
  } finally {
    // Ensure browser closes if error occurred mid-way
    try {
      if (browser) await browser.close();
    } catch (_) {}

    // Always cleanup temp folder
    try {
      if (tmpDir) await fsp.rm(tmpDir, { recursive: true, force: true });
    } catch (_) {}
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log(`MP4 service running on http://localhost:${PORT}`)
);
