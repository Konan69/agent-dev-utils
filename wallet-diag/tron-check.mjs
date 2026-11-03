if (process.argv.includes("--help")) { console.log("Usage: node tron-check.mjs (MN environment variable required)"); process.exit(0); }
// READ-ONLY. Derive the Tron address from the mnemonic and read TRX + TRC20 balances.
const { HDNodeWallet, Mnemonic, SigningKey, keccak256, getBytes } = await import("ethers");
import { createHash } from "crypto";

const MN = (process.env.MN || "").trim();
if (!MN) { console.error("set MN"); process.exit(1); }

// Tron derivation path
const node = HDNodeWallet.fromMnemonic(Mnemonic.fromPhrase(MN), "m/44'/195'/0'/0/0");
const pub = getBytes(SigningKey.computePublicKey(node.publicKey, false)).slice(1); // drop 0x04
const addr20 = getBytes(keccak256(pub)).slice(-20);
const raw = new Uint8Array(21); raw[0] = 0x41; raw.set(addr20, 1);
const sha = (b) => createHash("sha256").update(b).digest();
const checksum = sha(sha(Buffer.from(raw))).subarray(0, 4);
const full = Buffer.concat([Buffer.from(raw), checksum]);

const ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
let x = BigInt("0x" + full.toString("hex")), b58 = "";
while (x > 0n) { b58 = ALPH[Number(x % 58n)] + b58; x /= 58n; }
for (const c of full) { if (c === 0) b58 = "1" + b58; else break; }

console.log(`\nTron address: ${b58}\n`);

const r = await fetch(`https://api.trongrid.io/v1/accounts/${b58}`);
const j = await r.json();
const d = (j.data && j.data[0]) || null;
if (!d) { console.log("No account data (address never activated → never held funds)."); process.exit(0); }

console.log(`TRX (gas/energy): ${(Number(d.balance || 0) / 1e6).toFixed(6)} TRX`);
const usdt = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t";
const trc20 = d.trc20 || [];
let any = false;
for (const m of trc20) for (const [c, v] of Object.entries(m)) {
  if (c === usdt) { console.log(`USDT (TRC20): ${(Number(v) / 1e6).toFixed(6)}`); any = true; }
  else console.log(`token ${c}: ${v}`);
}
if (!any && trc20.length === 0) console.log("No TRC20 tokens.");
console.log("");
