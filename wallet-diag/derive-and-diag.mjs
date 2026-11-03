if (process.argv.includes("--help")) { console.log("Usage: node derive-and-diag.mjs (MN environment variable required)"); process.exit(0); }
// READ-ONLY. Derives the public address from a mnemonic (no signing, no broadcast)
// and reads balances/approvals from public RPCs across EVM chains.
// Mnemonic comes from env var MN so it isn't an argv. Nothing is sent anywhere
// except read-only JSON-RPC calls to public endpoints.

const { Wallet } = await import("ethers");

const MN = (process.env.MN || "").trim();
if (!MN) { console.error("set MN env var"); process.exit(1); }

const ADDR = Wallet.fromPhrase(MN).address;   // <-- public address only
console.log(`\nDerived public address (m/44'/60'/0'/0/0): ${ADDR}\n`);

const CHAINS = {
  bsc:      { name: "BNB Smart Chain", native: "BNB",
    rpcs: ["https://bsc-dataseed.binance.org", "https://bsc-rpc.publicnode.com"],
    tokens: [
      { sym: "USDT", dec: 18, addr: "0x55d398326f99059fF775485246999027B3197955" },
      { sym: "USDC", dec: 18, addr: "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d" },
      { sym: "BUSD", dec: 18, addr: "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56" }] },
  ethereum: { name: "Ethereum", native: "ETH",
    rpcs: ["https://eth.llamarpc.com", "https://ethereum-rpc.publicnode.com"],
    tokens: [
      { sym: "USDT", dec: 6,  addr: "0xdAC17F958D2ee523a2206206994597C13D831ec7" },
      { sym: "USDC", dec: 6,  addr: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48" }] },
  polygon:  { name: "Polygon", native: "POL",
    rpcs: ["https://polygon-rpc.com", "https://polygon-bor-rpc.publicnode.com"],
    tokens: [
      { sym: "USDT", dec: 6, addr: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F" },
      { sym: "USDC", dec: 6, addr: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174" }] },
};

const fmt = (v, d) => { const s = v.toString().padStart(d + 1, "0"); return s.slice(0, -d) + "." + s.slice(-d); };

async function rpc(rpcs, method, params) {
  let err;
  for (const url of rpcs) {
    try {
      const r = await fetch(url, { method: "POST", headers: { "content-type": "application/json" },
        body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }) });
      const j = await r.json();
      if (j.error) throw new Error(JSON.stringify(j.error));
      return j.result;
    } catch (e) { err = e; }
  }
  throw err;
}

for (const [key, cfg] of Object.entries(CHAINS)) {
  try {
    const wei = BigInt(await rpc(cfg.rpcs, "eth_getBalance", [ADDR, "latest"]));
    const lines = [`[${cfg.name}]  gas ${cfg.native}: ${fmt(wei, 18)}`];
    for (const t of cfg.tokens) {
      const data = "0x70a08231" + ADDR.slice(2).toLowerCase().padStart(64, "0");
      const res = await rpc(cfg.rpcs, "eth_call", [{ to: t.addr, data }, "latest"]);
      const bal = BigInt(res || "0x0");
      if (bal > 0n) lines.push(`    ${t.sym}: ${fmt(bal, t.dec)}`);
    }
    console.log(lines.join("\n"));
  } catch (e) {
    console.log(`[${cfg.name}]  read failed: ${e.message}`);
  }
}
console.log("");
