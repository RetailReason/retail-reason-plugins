import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const root = new URL('../', import.meta.url);
const read = (path) => readFileSync(new URL(path, root), 'utf8');
const pluginPath = 'plugins/retail-reason/';
const manifest = JSON.parse(read(`${pluginPath}.claude-plugin/plugin.json`));
const mcp = JSON.parse(read(`${pluginPath}.mcp.json`));

// Cowork displays user-config placeholders literally in its connector URL field.
assert.equal(mcp.mcpServers['retail-reason'].url, 'https://mcp.retailreason.com/mcp');
assert.equal(mcp.mcpServers['retail-reason'].type, 'http');
assert.equal(manifest.userConfig.server_url, undefined, 'Do not expose an unused server URL setting');

// Claude Code still uses its protected, user-bound key configuration.
assert.equal(mcp.mcpServers['retail-reason'].headers.Authorization, 'Bearer ${user_config.license_key}');
assert.equal(manifest.userConfig.license_key.sensitive, true);
assert.equal(manifest.userConfig.license_key.required, true);

for (const name of ['setup', 'walmart-advisor']) {
  const source = read(`${pluginPath}skills/${name}/SKILL.md`);
  const frontmatter = source.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/)?.[1];
  assert.ok(frontmatter, `${name}: YAML frontmatter is required`);
  assert.equal(frontmatter.match(/^name:\s*(.+)$/m)?.[1], name);
  // These two source files use single-line, JSON-quoted YAML descriptions.
  const rawDescription = frontmatter.match(/^description:\s*(.+)$/m)?.[1];
  assert.ok(rawDescription, `${name}: description is required`);
  const description = JSON.parse(rawDescription);
  assert.equal(typeof description, 'string', `${name}: description must be text`);
  assert.ok(description.length > 0 && description.length <= 1024,
    `${name}: description must contain 1 to 1024 characters`);
  assert.ok(!/[<>]/.test(description), `${name}: description must not contain XML tags`);
}

console.log('Claude plugin endpoint, protected key configuration, and both skill descriptions passed');
