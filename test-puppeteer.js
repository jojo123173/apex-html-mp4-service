const puppeteer = require("puppeteer");

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    args: ["--no-sandbox", "--disable-setuid-sandbox"]
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });

  await page.setContent(`
    <html>
      <body style="
        margin:0;
        width:1920px;
        height:1080px;
        display:flex;
        align-items:center;
        justify-content:center;
        background:linear-gradient(135deg,#667eea,#764ba2);
        color:white;
        font-size:48px;
        font-family:Arial;
      ">
        Puppeteer is WORKING ✅
      </body>
    </html>
  `);

  await page.screenshot({ path: "test.png" });
  await browser.close();

  console.log("Screenshot created: test.png");
})();
