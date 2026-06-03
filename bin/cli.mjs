#!/usr/bin/env node
// helmforge — installer CLI for the HelmForge (Claude Code)
// Usage:
//   npx helmforge init [target] [--yes] [--name X] [--fe nextjs] [--be next-api]
//                     [--mobile none] [--ai none] [--vcs github] [--profile fullstack]
// Runs the kit's setup.sh against the target repo (defaults to current directory).
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';
import { existsSync, readFileSync } from 'node:fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const pkgRoot = resolve(__dirname, '..');
const pkg = JSON.parse(readFileSync(join(pkgRoot, 'package.json'), 'utf8'));

const VALUE_FLAGS = ['--name', '--desc', '--pm', '--fe', '--be', '--mobile', '--ai', '--vcs', '--profile'];

function printHelp() {
  console.log(`
helmforge v${pkg.version} — Spec-Driven multi-agent SDLC kit for Claude Code

Usage:
  npx helmforge init [target] [flags]

Arguments:
  target                 Repo to install into (default: current directory)

Flags:
  --yes, -y              Non-interactive; accept defaults
  --name <name>          Project name
  --desc <text>          One-line description
  --fe <framework>       Frontend (nextjs|nuxt|sveltekit|remix|angular|astro|react-vite|none)
  --be <framework>       Backend (nestjs|next-api|express|fastify|hono|django|fastapi|...)
  --mobile <framework>   Mobile (flutter|react-native|none)
  --ai <framework>       Runtime AI (vercel-ai-sdk|mastra|langgraph|none)
  --vcs <provider>       VCS (github|gitlab|bitbucket|azure-devops|none)
  --profile <profile>    Agents (fullstack|frontend|backend|custom)
  -h, --help             Show this help
  -v, --version          Show version

Examples:
  npx helmforge init                       # interactive, install into current repo
  npx helmforge init ./my-app --yes        # non-interactive with defaults
  npx helmforge init . --fe nextjs --be next-api --ai vercel-ai-sdk --vcs github --yes

Requires bash (macOS/Linux, or WSL/Git Bash on Windows) and Claude Code.
`);
}

const argv = process.argv.slice(2);
if (argv.length === 0 || argv.includes('-h') || argv.includes('--help')) { printHelp(); process.exit(0); }
if (argv.includes('-v') || argv.includes('--version')) { console.log(pkg.version); process.exit(0); }

// first token may be the subcommand
let i = 0;
let cmd = 'init';
if (argv[0] && !argv[0].startsWith('-')) { cmd = argv[0]; i = 1; }
if (cmd !== 'init') {
  console.error(`Unknown command: ${cmd}\nTry: npx helmforge init`);
  process.exit(1);
}

let target = process.cwd();
let sawPositional = false;
const passthrough = [];
for (; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--here') { target = process.cwd(); continue; }
  if (a === '--target') { if (argv[i + 1]) target = resolve(process.cwd(), argv[++i]); continue; }
  if (!a.startsWith('-')) {
    if (!sawPositional) { target = resolve(process.cwd(), a); sawPositional = true; continue; }
    passthrough.push(a); continue;
  }
  passthrough.push(a);
  if (VALUE_FLAGS.includes(a) && argv[i + 1] !== undefined && !argv[i + 1].startsWith('-')) {
    passthrough.push(argv[++i]);
  }
}

const setup = join(pkgRoot, 'setup.sh');
if (!existsSync(setup)) {
  console.error('Installer error: setup.sh not found in the package payload.');
  process.exit(1);
}

// bash availability
const probe = spawnSync('bash', ['--version'], { stdio: 'ignore' });
if (probe.error) {
  console.error(`
  helmforge needs bash to run the installer.
   • macOS / Linux: bash is preinstalled.
   • Windows: run inside WSL (Windows Subsystem for Linux) or Git Bash.
`);
  process.exit(1);
}

const res = spawnSync('bash', [setup, '--target', target, ...passthrough], { stdio: 'inherit' });
process.exit(res.status ?? 0);
