if (process.argv.includes("--help")) { console.log("Usage: node tron-history.mjs <tron-address>"); process.exit(0); }
// READ-ONLY. Pull recent TRX and TRC20 history for the address to detect a sweeper.
const ADDR = process.argv[2];
if (!ADDR) { console.error("pass tron address"); process.exit(1); }

const fmtTime = (ms) => new Date(ms).toISOString().replace("T", " ").slice(0, 19);

async function get(path) {
  const r = await fetch(`https://api.trongrid.io${path}`);
  return r.json();
}

// TRC20 transfers (USDT in/out)
const t20 = await get(`/v1/accounts/${ADDR}/transactions/trc20?limit=40&order_by=block_timestamp,desc`);
console.log(`\n=== TRC20 transfers (most recent first) ===`);
for (const tx of (t20.data || [])) {
  const dir = tx.to === ADDR ? "IN " : (tx.from === ADDR ? "OUT" : "?  ");
  const sym = tx.token_info?.symbol || "?";
  const dec = tx.token_info?.decimals ?? 6;
  const val = Number(tx.value) / 10 ** dec;
  const other = tx.to === ADDR ? tx.from : tx.to;
  console.log(`${fmtTime(tx.block_timestamp)}  ${dir} ${val} ${sym}  ${dir === "IN " ? "from" : "to"} ${other}`);
}
if (!(t20.data || []).length) console.log("(none)");

// Native TRX / system transactions
const tx = await get(`/v1/accounts/${ADDR}/transactions?limit=40&order_by=block_timestamp,desc`);
console.log(`\n=== TRX / system transactions (most recent first) ===`);
let sweeps = 0;
for (const t of (tx.data || [])) {
  const c = t.raw_data?.contract?.[0];
  const type = c?.type || "?";
  const p = c?.parameter?.value || {};
  let line = `${fmtTime(t.block_timestamp)}  ${type}`;
  if (type === "TransferContract") {
    const from = hex2b58(p.owner_address), to = hex2b58(p.to_address);
    const amt = (Number(p.amount || 0) / 1e6);
    const dir = from === ADDR ? "OUT" : "IN ";
    if (from === ADDR) sweeps++;
    line += `  ${dir} ${amt} TRX  ${dir === "IN " ? "from " + from : "to " + to}`;
  }
  console.log(line);
}
if (!(tx.data || []).length) console.log("(none)");
console.log(`\nOutgoing TRX transfers seen: ${sweeps}  ${sweeps > 0 ? "<-- look for instant-out-after-in = sweeper" : "(no outgoing TRX = no obvious sweeper yet)"}`);
console.log("");

function hex2b58(hex) {
  return hex || "?"; // hex is enough to spot in/out patterns
}
