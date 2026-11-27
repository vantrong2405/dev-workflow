import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { mockupSchema } from './config.mjs';
import { palettes } from './palettes.mjs';

const example = JSON.parse(await readFile(new URL('./mockup.example.json', import.meta.url)));
const renderer = fileURLToPath(new URL('./render.mjs', import.meta.url));

test('the configuration rejects duplicate IDs, invalid data and unknown layouts', () => {
  const invalid = structuredClone(example);
  invalid.screens[1].id = invalid.screens[0].id;
  invalid.screens[2].data.fields[0].error = undefined;
  assert.throws(() => mockupSchema.parse(invalid), /Duplicate screen ID[\s\S]*field error/);

  invalid.screens[0].variant = 'custom';
  invalid.screens[0].data.html = '<b>Unexpected markup</b>';
  assert.throws(() => mockupSchema.parse(invalid), /variant[\s\S]*Unrecognized key/);

  const wrongBackground = structuredClone(example);
  wrongBackground.screens[1].background = wrongBackground.screens[2].id;
  assert.throws(() => mockupSchema.parse(wrongBackground), /Reference a list screen/);
});

test('bundled palettes and valid brand overrides pass contrast checks', () => {
  for (const theme of Object.keys(palettes)) {
    assert.equal(mockupSchema.parse({ ...example, theme }).theme, theme);
  }
  assert.throws(
    () => mockupSchema.parse({ ...example, palette: { accent: '#ffffff' } }),
    /on-accent on accent has contrast 1\.00:1/,
  );
  assert.throws(
    () => mockupSchema.parse({ ...example, palette: { ink: 'red' } }),
    /Invalid string/,
  );
});

test('the installed renderer captures all templates and preserves the approved image set', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'ak-vibe-test-'));
  try {
    const input = join(directory, 'mockup.json');
    const output = join(directory, 'images');
    const config = structuredClone(example);
    config.palette = { panel: '#ffffff' };
    const [list, detail, form] = config.screens;
    config.screens.push(
      { ...list, id: 'list-empty', variant: 'compact', scene: 'empty' },
      { ...detail, id: 'detail-page', variant: 'page', background: undefined },
      { ...form, id: 'form-page', variant: 'page', scene: 'default', background: undefined },
    );
    const bytes = JSON.stringify(config);
    await writeFile(input, bytes);
    const run = spawnSync(process.execPath, [renderer, input, output], { encoding: 'utf8', timeout: 60000 });
    assert.equal(run.status, 0, run.stderr || run.error?.message);
    const manifestPath = join(output, 'manifest.json');
    const manifestBytes = await readFile(manifestPath, 'utf8');
    const manifest = JSON.parse(manifestBytes);
    const hash = content => createHash('sha256').update(content).digest('hex');
    assert.equal(manifest.inputSha256, hash(bytes));
    assert.equal(manifest.palette.panel, config.palette.panel);
    assert.equal(manifest.palette.accent, palettes[config.theme].accent);
    assert.deepEqual(manifest.screens.map(screen => screen.id), config.screens.map(screen => screen.id));
    for (const screen of manifest.screens) {
      const png = await readFile(join(output, screen.file));
      assert.equal(png.toString('ascii', 1, 4), 'PNG');
      assert.equal(png.readUInt32BE(16), config.viewport.width);
      assert.equal(screen.sha256, hash(png));
    }

    const rerun = spawnSync(process.execPath, [renderer, input, output], { encoding: 'utf8', timeout: 10000 });
    assert.equal(rerun.status, 1);
    assert.match(rerun.stderr, /EEXIST/);
    assert.equal(await readFile(manifestPath, 'utf8'), manifestBytes);

    const mobile = { ...config, viewport: { width: 390, height: 550 }, screens: [list, form] };
    const mobileInput = join(directory, 'mobile.json');
    const mobileOutput = join(directory, 'mobile-images');
    await writeFile(mobileInput, JSON.stringify(mobile));
    const mobileRun = spawnSync(process.execPath, [renderer, mobileInput, mobileOutput], { encoding: 'utf8', timeout: 60000 });
    assert.equal(mobileRun.status, 0, mobileRun.stderr || mobileRun.error?.message);
    const formImage = await readFile(join(mobileOutput, `${form.id}.png`));
    assert.equal(formImage.readUInt32BE(20), mobile.viewport.height);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
