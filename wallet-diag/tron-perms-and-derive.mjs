if (process.argv.includes("--help")) { console.log("Usage: node tron-perms-and-derive.mjs <tron-address> (MN environment variable required)"); process.exit(0); }
// READ-ONLY. 1) Read on-chain owner/active permissions for the account.
// 2) Derive addresses from the mnemonic across many paths and see if ANY of them
//    matches an authorized signer. No signing, no broadcast.
const { HDNodeWallet, Mnemonic, SigningKey, keccak256, getBytes } = await import("ethers");
import { createHash } from "crypto";

const ADDR = process.argv[2];
if (!ADDR) { console.error("pass tron address"); process.exit(1); }
const MN = (process.env.MN || "").trim();
if (!MN) { console.error("set MN"); process.exit(1); }

const ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const sha = (b) => createHash("sha256").update(b).digest();
function hexToB58(hex) {
  const raw = Buffer.from(hex.replace(/^0x/, ""), "hex");
  const full = Buffer.concat([raw, sha(sha(raw)).subarray(0, 4)]);
  let x = BigInt("0x" + full.toString("hex")), o = "";
  while (x > 0n) { o = ALPH[Number(x % 58n)] + o; x /= 58n; }
  for (const c of full) { if (c === 0) o = "1" + o; else break; }
  return o;
}
const norm = (a) => (!a ? "?" : a.startsWith("T") ? a : hexToB58(a.startsWith("41") || a.startsWith("0x41") ? a : "41" + a.replace(/^0x/, "")));
function tronFromPub(pubHex) {
  const pub = getBytes(SigningKey.computePublicKey(pubHex, false)).slice(1);
  const addr20 = getBytes(keccak256(pub)).slice(-20);
  return hexToB58("41" + Buffer.from(addr20).toString("hex"));
}

// 1) On-chain permissions
const j = await (await fetch(`https://api.trongrid.io/v1/accounts/${ADDR}`)).json();
const d = (j.data && j.data[0]) || {};
console.log(`\n=== On-chain permissions for ${ADDR} ===`);
const owner = d.owner_permission;
const actives = d.active_permission || [];
const authorized = new Set();
if (owner) {
  console.log(`Owner permission (threshold ${owner.threshold}):`);
  for (const k of owner.keys) { const a = norm(k.address); authorized.add(a); console.log(`   ${a}  weight ${k.weight}`); }
}
for (const ap of actives) {
  console.log(`Active permission "${ap.permission_name || ap.type || "active"}" (threshold ${ap.threshold}):`);
  for (const k of ap.keys) { const a = norm(k.address); authorized.add(a); console.log(`   ${a}  weight ${k.weight}`); }
}
if (!owner && !actives.length) console.log("  (no custom permissions returned)");

console.log(`\nIs the account's own address (${ADDR}) an authorized signer?  ${authorized.has(ADDR) ? "YES" : "NO"}`);
console.log(`Authorized signer set: ${[...authorized].join(", ") || "(default = self)"}`);

// 2) Derive from mnemonic across paths, compare to authorized signers
const mn = Mnemonic.fromPhrase(MN);
const targets = authorized.size ? authorized : new Set([ADDR]);
console.log(`\n=== Scanning mnemonic derivations for any authorized signer ===`);
let hit = null;
for (let acct = 0; acct < 6 && !hit; acct++) {
  for (let idx = 0; idx < 20; idx++) {
    for (const path of [`m/44'/195'/${acct}'/0/${idx}`, `m/44'/195'/${acct}'/${idx}`]) {
      let node; try { node = HDNodeWallet.fromMnemonic(mn, path); } catch { continue; }
      const a = tronFromPub(node.publicKey);
      if (targets.has(a)) { hit = { path, a }; break; }
    }
    if (hit) break;
  }
}
console.log(`Standard path address (m/44'/195'/0'/0/0): ${tronFromPub(HDNodeWallet.fromMnemonic(mn, "m/44'/195'/0'/0/0").publicKey)}`);
if (hit) console.log(`\n*** MATCH: your seed derives authorized signer ${hit.a} at ${hit.path} -> RECOVERY POSSIBLE ***`);
else console.log(`\n>>> No derivation of this seed (scanned 240 paths) matches any authorized signer.\n>>> This seed CANNOT sign for the account under current permissions.`);
console.log("");
