if (process.argv.includes("--help")) { console.log("Usage: node tron-sweep-check.mjs <tron-address>"); process.exit(0); }
// READ-ONLY. Correctly detect OUTGOING TRX (sweeps) by decoding our base58 -> hex.
const ADDR = process.argv[2];
if (!ADDR) { console.error("pass tron address"); process.exit(1); }

const ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
function b58dec(s) {
  let x = 0n;
  for (const c of s) { const i = ALPH.indexOf(c); if (i < 0) throw new Error("bad b58"); x = x * 58n + BigInt(i); }
  let hex = x.toString(16); if (hex.length % 2) hex = "0" + hex;
  let bytes = Buffer.from(hex, "hex");
  let zeros = 0; for (const c of s) { if (c === "1") zeros++; else break; }
  if (zeros) bytes = Buffer.concat([Buffer.alloc(zeros, 0), bytes]);
  return bytes;
}
import { createHash } from "crypto";
function hex2b58(hexAddr) {
  if (!hexAddr) return "?";
  const raw = Buffer.from(hexAddr, "hex");           // 21 bytes, 0x41 + 20
  const sha = (b) => createHash("sha256").update(b).digest();
  const full = Buffer.concat([raw, sha(sha(raw)).subarray(0, 4)]);
  let x = BigInt("0x" + full.toString("hex")), o = "";
  while (x > 0n) { o = ALPH[Number(x % 58n)] + o; x /= 58n; }
  for (const c of full) { if (c === 0) o = "1" + o; else break; }
  return o;
}

const HEX = b58dec(ADDR).subarray(0, 21).toString("hex").toLowerCase();  // "41...."
console.log(`\nAddress ${ADDR}  (hex ${HEX})\n`);

async function get(p) { return (await fetch(`https://api.trongrid.io${p}`)).json(); }
const t = (ms) => new Date(ms).toISOString().replace("T", " ").slice(0, 19);

// Pull a deep window of native/system txs
const sys = await get(`/v1/accounts/${ADDR}/transactions?limit=200&order_by=block_timestamp,desc`);
const rows = sys.data || [];

const trxIn = [], trxOut = [];
for (const tx of rows) {
  const c = tx.raw_data?.contract?.[0]; if (!c) continue;
  if (c.type !== "TransferContract") continue;
  const p = c.parameter.value;
  const owner = (p.owner_address || "").toLowerCase();
  const to = (p.to_address || "").toLowerCase();
  const amt = Number(p.amount || 0) / 1e6;
  if (owner === HEX) trxOut.push({ ts: tx.block_timestamp, amt, to });
  else if (to === HEX) trxIn.push({ ts: tx.block_timestamp, amt, from: owner });
}

console.log(`Real TRX deposits IN (>=1 TRX), most recent first:`);
trxIn.filter(x => x.amt >= 1).forEach(x => console.log(`  ${t(x.ts)}  +${x.amt} TRX  from ${hex2b58(x.from)}`));

console.log(`\nOUTGOING TRX transfers (this is what a sweep looks like):`);
if (!trxOut.length) console.log(`  NONE. Not a single TRX ever left this wallet by transfer.`);
trxOut.forEach(x => console.log(`  ${t(x.ts)}  -${x.amt} TRX  to ${hex2b58(x.to)}`));

// Sweep pairing: any deposit followed by an outgoing within 5 min?
console.log(`\nDeposit-then-swept check (IN then OUT within 5 min):`);
let flagged = 0;
for (const i of trxIn) for (const o of trxOut) {
  const dt = o.ts - i.ts;
  if (dt >= 0 && dt < 5 * 60 * 1000) { console.log(`  SWEPT: +${i.amt} in at ${t(i.ts)} -> -${o.amt} out ${Math.round(dt/1000)}s later to ${hex2b58(o.to)}`); flagged++; }
}
if (!flagged) console.log(`  None. No deposit was swept out.`);

const totalIn = trxIn.reduce((a, b) => a + b.amt, 0);
const totalOut = trxOut.reduce((a, b) => a + b.amt, 0);
console.log(`\nTotals in window: TRX in ${totalIn.toFixed(3)} | TRX transferred out ${totalOut.toFixed(3)}`);
