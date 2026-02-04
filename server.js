// server.js
"use strict";

const express = require("express");
const cors = require("cors");
const fs = require("fs");
const fsp = require("fs/promises");
const path = require("path");
const os = require("os");
const crypto = require("crypto");
const util = require("util");
const { execFile } = require("child_process");
const puppeteer = require("puppeteer");

const execFileAsync = util.promisify(execFile);

const app = express();
app.use(cors());
app.use(express.json({ limit: "80mb" })); // html + mp3 base64 can be big

// API key protection (set API_KEY in Render env vars)
const API_KEY = process.env.API_KEY || "CHANGE_ME";

// Health check
app.get("/health", (req, res) => res.json({ ok: true }));

// Simple root page (optional)
app.get("/", (req, res) => {
  res.type("text").send("MP4 service is running. Use POST /render-mp4");
});

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

    // Write MP3
    await fsp.writeFile(mp3Path, Buffer.from(mp3_base64, "base64"));

    // Render HTML -> PNG via Puppeteer
  browser = await puppeteer.launch({
  headless: true, // IMPORTANT for Render/Docker
  executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || undefined,
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

    // Add a timeout so Render doesn’t hang forever
    await page.setContent(html, { waitUntil: "networkidle0", timeout: 60000 });
    await page.screenshot({ path: pngPath });

    await browser.close().catch(() => {});
    browser = null;

    // PNG + MP3 -> MP4 (ffmpeg must be in PATH inside Docker image)
await execFileAsync("ffmpeg", [
  "-y",
  "-loop", "1",
  "-i", pngPath,
  "-i", mp3Path,
  "-c:v", "libx264",
  "-preset", "ultrafast",
  "-pix_fmt", "yuv420p",
  "-c:a", "aac",
  "-b:a", "96k",
  "-shortest",
  mp4Path
]);
await execFileAsync("ffmpeg", [
  "-y",
  "-loop", "1",
  "-i", pngPath,
  "-i", mp3Path,
  "-c:v", "libx264",
  "-preset", "ultrafast",
  "-pix_fmt", "yuv420p",
  "-c:a", "aac",
  "-b:a", "96k",
  "-shortest",
  mp4Path
]);


    const mp4 = await fsp.readFile(mp4Path);

    res.setHeader("Content-Type", "video/mp4");
    res.setHeader(
      "Content-Disposition",
      `inline; filename="presentation_${id}.mp4"`
    );
    res.status(200).send(mp4);
  } catch (e) {
    console.error("render-mp4 failed:", e);
    res.status(500).json({ error: "render failed", details: String(e) });
  } finally {
    // Always cleanup
    if (browser) {
      await browser.close().catch(() => {});
    }
    if (tmpDir) {
      fsp.rm(tmpDir, { recursive: true, force: true }).catch(() => {});
    }
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`MP4 service running on http://localhost:${PORT}`));
