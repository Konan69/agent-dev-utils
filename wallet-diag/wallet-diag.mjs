#!/usr/bin/env node
if (process.argv.includes("--help")) { console.log("Usage: node wallet-diag.mjs <0x-address> [bsc|ethereum|polygon]"); process.exit(0); }
// Read-only wallet diagnostic. Zero dependencies (Node 18+ for global fetch).
// Usage:  node wallet-diag.mjs <address> <chain>
//   chain = bsc | ethereum | polygon
// Reads ONLY public state from public RPCs. Never touches keys. Never signs.

const ADDR  = (process.argv[2] || "").trim();
const CHAIN = (process.argv[3] || "bsc").trim().toLowerCase();

if (!/^0x[0-9a-fA-F]{40}$/.test(ADDR)) {
  console.error("Give me a public 0x address:  node wallet-diag.mjs 0x... bsc");
  process.exit(1);
}

const CHAINS = {
  bsc: {
    name: "BNB Smart Chain",
    rpcs: ["https://bsc-dataseed.binance.org", "https://bsc-rpc.publicnode.com", "https://1rpc.io/bnb"],
    native: "BNB",
    tokens: [
      { sym: "USDT", dec: 18, addr: "0x55d398326f99059fF775485246999027B3197955" },
      { sym: "USDC", dec: 18, addr: "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d" },
      { sym: "BUSD", dec: 18, addr: "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56" },
    ],
  },
  ethereum: {
    name: "Ethereum",
    rpcs: ["https://eth.llamarpc.com", "https://ethereum-rpc.publicnode.com", "https://1rpc.io/eth"],
    native: "ETH",
    tokens: [
      { sym: "USDT", dec: 6,  addr: "0xdAC17F958D2ee523a2206206994597C13D831ec7" },
      { sym: "USDC", dec: 6,  addr: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48" },
      { sym: "DAI",  dec: 18, addr: "0x6B175474E89094C44Da98b954EedeAC495271d0F" },
    ],
  },
  polygon: {
    name: "Polygon",
    rpcs: ["https://polygon-rpc.com", "https://polygon-bor-rpc.publicnode.com", "https://1rpc.io/matic"],
    native: "POL",
    tokens: [
      { sym: "USDT", dec: 6, addr: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F" },
      { sym: "USDC", dec: 6, addr: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174" },
    ],
  },
};

const cfg = CHAINS[CHAIN];
if (!cfg) { console.error("chain must be one of: " + Object.keys(CHAINS).join(", ")); process.exit(1); }

const APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925";
const pad = (a) => "0x" + a.replace(/^0x/, "").toLowerCase().padStart(64, "0");
const fmt = (v, d) => { const s = v.toString().padStart(d + 1, "0"); return s.slice(0, -d || s.length) + "." + s.slice(-d); };

async function rpc(method, params) {
  let lastErr;
  for (const url of cfg.rpcs) {
    try {
      const r = await fetch(url, { method: "POST", headers: { "content-type": "application/json" },
        body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }) });
      const j = await r.json();
      if (j.error) throw new Error(JSON.stringify(j.error));
      return j.result;
    } catch (e) { lastErr = e; }
  }
  throw lastErr;
}

(async () => {
  console.log(`\n=== ${cfg.name} | ${ADDR} ===\n`);

  // 1. Native gas balance — the usual culprit
  const wei = BigInt(await rpc("eth_getBalance", [ADDR, "latest"]));
  const gas = fmt(wei, 18);
  console.log(`Native ${cfg.native} (gas): ${gas}`);
  const gasIsZero = wei === 0n;

  // 2. Token balances
  console.log(`\nTokens:`);
  let foundValue = false;
  for (const t of cfg.tokens) {
    try {
      const data = "0x70a08231" + ADDR.replace(/^0x/, "").toLowerCase().padStart(64, "0");
      const res = await rpc("eth_call", [{ to: t.addr, data }, "latest"]);
      const bal = BigInt(res || "0x0");
      if (bal > 0n) { foundValue = true; console.log(`  ${t.sym.padEnd(5)} ${fmt(bal, t.dec)}`); }
      else console.log(`  ${t.sym.padEnd(5)} 0`);
    } catch (e) { console.log(`  ${t.sym.padEnd(5)} (read failed: ${e.message})`); }
  }

  // 3. Active approvals (drainer allowances) over recent history
  console.log(`\nRecent approvals you granted (possible drainers):`);
  try {
    const latest = BigInt(await rpc("eth_blockNumber", []));
    const from = "0x" + (latest > 4900n ? latest - 4900n : 0n).toString(16);
    let any = false;
    for (const t of cfg.tokens) {
      const logs = await rpc("eth_getLogs", [{ address: t.addr, topics: [APPROVAL, pad(ADDR)], fromBlock: from, toBlock: "latest" }]);
      for (const lg of logs) {
        const spender = "0x" + lg.topics[2].slice(26);
        const amt = BigInt(lg.data);
        const unlimited = amt > (2n ** 250n);
        console.log(`  ${t.sym}: spender ${spender}  allowance ${unlimited ? "UNLIMITED" : fmt(amt, t.dec)}`);
        any = true;
      }
    }
    if (!any) console.log("  (none in scanned window)");
  } catch (e) { console.log(`  (approval scan unavailable on public RPC: ${e.message})`); }

  // Verdict
  console.log(`\n--- READ ---`);
  if (gasIsZero && foundValue)
    console.log(`Gas is 0 and there ARE tokens → every Send fails on "insufficient gas".\nMoving them needs native ${cfg.native} for the fee. If the key is leaked, gas added\nto a public mempool can be swept before the token transfer lands → atomic bundle needed.`);
  else if (!gasIsZero && foundValue)
    console.log(`There is gas AND tokens → a normal Send SHOULD work. If it doesn't, the block is\nelsewhere (approval lock / wrong network selected / spoof token). Check approvals above.`);
  else if (gasIsZero && !foundValue)
    console.log(`No gas and no real token balance on this chain. Either wrong chain, or the "balance"\nis a spoof/display token with no withdrawable value.`);
  else
    console.log(`Native balance present, no tokens → just Send the ${cfg.native} to a clean address.`);
  console.log("");
})();
