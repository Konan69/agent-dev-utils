"""Open a background Helium tab at <origin>, run fetch(<path>) with its cookies, print JSON text, close tab.
Usage: helium-fetch.py <origin> <path> [<path> ...]"""
import sys
if len(sys.argv) < 2 or sys.argv[1] in ("--help", "-h"):
    print("Usage: helium-fetch.py <origin> <path|wait:seconds|js:expression> [...] (WAIT defaults to 4 seconds)")
    raise SystemExit(0 if len(sys.argv) > 1 else 2)

import asyncio, json, sys, urllib.request
import websockets

async def main(origin, paths):
    ver = json.load(urllib.request.urlopen("http://127.0.0.1:9222/json/version"))
    async with websockets.connect(ver["webSocketDebuggerUrl"], max_size=None) as ws:
        n = 0
        async def call(method, params=None, session=None):
            nonlocal n
            n += 1
            msg = {"id": n, "method": method, "params": params or {}}
            if session: msg["sessionId"] = session
            await ws.send(json.dumps(msg))
            while True:
                r = json.loads(await ws.recv())
                if r.get("id") == n: return r
        t = await call("Target.createTarget", {"url": origin, "background": True})
        tid = t["result"]["targetId"]
        s = (await call("Target.attachToTarget", {"targetId": tid, "flatten": True}))["result"]["sessionId"]
        await asyncio.sleep(float(__import__("os").environ.get("WAIT","4")))
        try:
            r = await call("Runtime.evaluate", {"expression": "location.href", "returnByValue": True}, s); print("at", r["result"]["result"]["value"])
            for p in paths:
                if p.startswith("wait:"):
                    await asyncio.sleep(float(p[5:])); continue
                expr = p[3:] if p.startswith("js:") else f"fetch({json.dumps(p)}, {{credentials:'include'}}).then(r=>r.status+'\\n'+r.text())".replace("r.status+'\\n'+r.text()", "r.text().then(t=>r.status+'\\n'+t)")
                r = await call("Runtime.evaluate", {"expression": expr, "awaitPromise": True, "returnByValue": True}, s)
                print(f"=== {p}")
                print(r.get("result", {}).get("result", {}).get("value", r))
        finally:
            await call("Target.closeTarget", {"targetId": tid})

asyncio.run(main(sys.argv[1], sys.argv[2:]))
