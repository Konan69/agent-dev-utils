"""Open a URL in a background tab of Helium (CDP 9222), wait, print an expression's value, close.

Usage: helium-cdp-text.py <url> [wait_seconds] [js_expression]
Default expression is document.body.innerText. Used for reading signed-in pages (Gmail) without
touching the foreground window.
"""
import sys
if len(sys.argv) < 2 or sys.argv[1] in ("--help", "-h"):
    print("Usage: helium-cdp-text.py <url> [wait_seconds] [js_expression]")
    raise SystemExit(0 if len(sys.argv) > 1 else 2)

import asyncio
import json
import sys
import urllib.request

import websockets


async def main() -> None:
    url = sys.argv[1]
    wait = float(sys.argv[2]) if len(sys.argv) > 2 else 8.0
    expr = sys.argv[3] if len(sys.argv) > 3 else "document.body.innerText"
    version = json.load(urllib.request.urlopen("http://127.0.0.1:9222/json/version"))
    async with websockets.connect(version["webSocketDebuggerUrl"], max_size=2**26) as ws:
        seq = 0

        async def call(method, params=None, session=None):
            nonlocal seq
            seq += 1
            msg = {"id": seq, "method": method, "params": params or {}}
            if session:
                msg["sessionId"] = session
            await ws.send(json.dumps(msg))
            while True:
                reply = json.loads(await ws.recv())
                if reply.get("id") == seq:
                    return reply.get("result", reply)

        target = (await call("Target.createTarget", {"url": url, "background": True}))["targetId"]
        try:
            session = (await call("Target.attachToTarget", {"targetId": target, "flatten": True}))["sessionId"]
            # A background tab is throttled; Gmail never finishes rendering its list without these.
            await call("Emulation.setFocusEmulationEnabled", {"enabled": True}, session)
            await call("Page.setWebLifecycleState", {"state": "active"}, session)
            await asyncio.sleep(wait)
            result = await call("Runtime.evaluate", {"expression": expr, "returnByValue": True}, session)
            print(result.get("result", {}).get("value"))
        finally:
            await call("Target.closeTarget", {"targetId": target})


asyncio.run(main())
