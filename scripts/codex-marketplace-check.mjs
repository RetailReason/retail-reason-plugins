import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, resolve, sep } from 'node:path';

const root = fileURLToPath(new URL('..', import.meta.url));
const readJson = (file) => JSON.parse(readFileSync(file, 'utf8'));
const marketplace = readJson(join(root, '.agents/plugins/marketplace.json'));
assert.match(marketplace.name, /^[A-Za-z0-9_-]+$/);
assert.ok(Array.isArray(marketplace.plugins) && marketplace.plugins.length > 0);
const names = new Set();
for (const entry of marketplace.plugins) {
  assert.match(entry.name, /^[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)*$/);
  assert.ok(!names.has(entry.name), 'duplicate marketplace plugin');
  names.add(entry.name);
  assert.ok(['AVAILABLE', 'NOT_AVAILABLE', 'INSTALLED_BY_DEFAULT'].includes(entry.policy?.installation), 'unsupported installation policy');
  assert.ok(['ON_INSTALL', 'ON_USE'].includes(entry.policy?.authentication), 'unsupported authentication policy');
  assert.ok(typeof entry.category === 'string' && entry.category.length > 0);
  assert.equal(entry.source?.source, 'local');
  assert.ok(typeof entry.source.path === 'string' && entry.source.path.startsWith('./'));
  const directory = resolve(root, entry.source.path);
  assert.ok(directory.startsWith(root.endsWith(sep) ? root : root + sep), 'plugin path must stay in repository');
  const manifest = readJson(join(directory, '.codex-plugin/plugin.json'));
  assert.equal(manifest.name, entry.name, 'marketplace name must match plugin manifest');
}
console.log('codex-marketplace-check passed');
