# agent-dev-utils

Small scripts I wrote while running coding agents all day.

Each one fixes one thing that broke on a WSL machine running agents: 75 orphaned headless Chromes holding 7.2 GB (`browser-reap`), a git worktree building against another checkout's packages (`worktree-relink`), `opencode` stuck on a stale model list. They share no code; copy the one you need.

![Terminal running worktree-relink in a seeded git worktree. Before the run, node_modules/@acme/ui resolves to the main checkout. After the run, it resolves to the worktree's own packages/ui.](docs/media/hero.gif)

## Install

Linux or WSL 2. Bash scripts need nothing extra; the Python ones need two packages.

```bash
git clone <this-repo-url> agent-dev-utils && cd agent-dev-utils
python3 -m pip install -r requirements.txt   # websockets, cryptography
```

## Use

```bash
browser-reap/browser-reap 60 --dry-run              # agent-browser Chromes and recorders older than 60 min
worktree-relink/worktree-relink ../app-wt @acme     # give a worktree its own workspace packages
opencode-models-refresh/opencode-models-refresh     # re-download models.dev into opencode's cache
python3 helium-cdp-text/helium-cdp-text.py <url>    # page text from your signed-in browser over CDP
python3 t3-staging-tools/resolve.py FILE 0 both     # resolve one conflict hunk: ours, theirs, both or text
node wallet-diag/wallet-diag.mjs <0x-address> bsc   # read-only balances and approvals
```

```console
$ m=node_modules/@acme/ui; realpath $m; worktree-relink . @acme; realpath $m
/tmp/wt-demo/app/packages/ui
relinked 1 node_modules dirs under /tmp/wt-demo/app-wt to its own @acme packages
/tmp/wt-demo/app-wt/packages/ui
```

| Tool | |
| --- | --- |
| `browser-reap` | Kill stale `agent-browser` Chromes, daemons and `ffmpeg` screencast recorders |
| `worktree-relink` | Replace a symlinked `node_modules` in a pnpm worktree with one that points at the worktree's own packages |
| `opencode-models-refresh` | Fetch `models.dev/api.json` with a long timeout and swap it into opencode's cache |
| `helium-cdp-*`, `helium-fetch`, `notion-publish-helium` | Read, click, fetch and publish through a browser already running with remote debugging on port 9222 |
| `ft-helium-extract`, `ft-sync` | Pull your X session cookies from a Windows browser profile and feed them to `ft sync` |
| `t3-overlay`, `t3-staging-tools` | Overlay a local T3 Code build on the Windows install; resolve conflict hunks; Windows toasts from WSL |
| `wallet-diag` | Read-only wallet checks over public RPC for EVM chains and Tron; never signs |
| `i2m` | Run four image-to-3D and pose models on one drawing and render each with Blender |
| `railway-light-proxy` | A password-protected HTTP proxy on Railway, with deploy and region scripts |
| `ida-scripts` | Keep the `ida-pro-mcp` server alive for IDA Pro on Windows |

Arguments, requirements, configuration and how the cookie extraction works, for every tool: [docs/tools.md](docs/tools.md).

## Limits

- Most tools assume Linux under WSL 2 with Windows next to it. `ft-helium-extract`, `t3-overlay`, `notify-windows.sh` and `ida-scripts` do not work without Windows.
- `ft-helium-extract` decrypts session cookies from your own browser profile. Anyone who can read `~/.config/ft-helium/cookies` can act as your X account.
- Only these were run while this README was written: `--help` for every script, `browser-reap --dry-run`, `worktree-relink` and `resolve.py` on fixtures, `opencode-models-refresh` with a scratch `HOME`, and `wallet-diag.mjs` on a public address. The CDP scripts, cookie extraction, the T3 overlay, the i2m models, the Railway deployment and the IDA scripts were not run.
- `run-all.sh` hard-codes CUDA 12.8 under `/usr/local/cuda-12.8` and `TORCH_CUDA_ARCH_LIST="12.0"`.
- The model code and weights that `i2m` downloads have their own licenses, and some are not MIT. See [i2m/NOTICE](i2m/NOTICE).

## License

MIT. Models that `i2m` downloads keep their own terms: [i2m/NOTICE](i2m/NOTICE).
