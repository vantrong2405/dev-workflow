import { createHash } from 'node:crypto';
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { createServer } from 'vite';
import { mockupSchema } from './config.mjs';
import { resolvePalette } from './palettes.mjs';

const root = dirname(fileURLToPath(import.meta.url));
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');

async function renderScreen(context, url, config, palette, screen, directory) {
  const page = await context.newPage();
  let pageError;
  page.on('pageerror', error => { pageError ??= error; });
  try {
    const { locale, workspace } = config;
    const background = config.screens.find(item => item.id === screen.background);
    await page.addInitScript(input => { window.vibePreview = input; }, { locale, palette, workspace, screen, background });
    await page.goto(url, { waitUntil: 'load' });
    await page.locator(`[data-vibe-ready="${screen.id}"]`).waitFor({ timeout: 10000 });
    const overlay = ['dialog', 'panel'].includes(screen.variant);
    if (overlay) {
      await page.getByRole('dialog').waitFor({ timeout: 10000 });
    }
    if (screen.template === 'dashboard') {
      await page.locator('.recharts-bar-rectangle').first().waitFor({ timeout: 10000 });
    }
    const fontReady = await page.evaluate(async () => {
      await document.fonts.ready;
      return [...document.fonts].some(font => font.family.includes('Be Vietnam Pro') && font.status === 'loaded');
    });
    if (!fontReady) throw new Error('The local Be Vietnam Pro font did not load');
    const name = `${screen.id}.png`;
    const png = await page.screenshot({ path: join(directory, name), fullPage: !overlay, animations: 'disabled', caret: 'hide' });
    if (pageError) throw pageError;
    return { id: screen.id, template: screen.template, variant: screen.variant, scene: screen.scene, acceptance: screen.acceptance, file: name, sha256: sha256(png) };
  } catch (error) {
    throw new Error(`Screen ${screen.id}: ${(pageError ?? error).message}`, { cause: error });
  } finally {
    await page.close();
  }
}

async function render(inputPath, outputPath) {
  const input = await readFile(inputPath);
  const config = mockupSchema.parse(JSON.parse(input));
  const palette = resolvePalette(config.theme, config.palette);
  const directory = resolve(outputPath);
  await mkdir(dirname(directory), { recursive: true });
  await mkdir(directory);

  let server;
  let browser;
  try {
    server = await createServer({ root, server: { host: '127.0.0.1', port: 0, hmr: false } });
    await server.listen();
    const { port } = server.httpServer.address();
    const url = `http://127.0.0.1:${port}/`;
    browser = await chromium.launch();
    const context = await browser.newContext({ viewport: config.viewport, locale: config.locale, deviceScaleFactor: 1, reducedMotion: 'reduce' });
    await context.route('**/*', route => route.request().url().startsWith(url) ? route.continue() : route.abort());
    const screens = [];
    for (const screen of config.screens) {
      screens.push(await renderScreen(context, url, config, palette, screen, directory));
    }
    const manifest = { version: 1, inputSha256: sha256(input), locale: config.locale, theme: config.theme, palette, viewport: config.viewport, screens };
    await writeFile(join(directory, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`);
    console.log(join(directory, 'manifest.json'));
  } catch (error) {
    await rm(directory, { recursive: true, force: true });
    throw error;
  } finally {
    await Promise.allSettled([browser?.close(), server?.close()]);
  }
}

if (process.argv.length !== 4) {
  console.error('Usage: node render.mjs <mockup.json> <new-output-directory>');
  process.exitCode = 2;
} else {
  try {
    await render(process.argv[2], process.argv[3]);
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
