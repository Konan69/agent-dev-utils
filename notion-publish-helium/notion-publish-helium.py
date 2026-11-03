import sys
if len(sys.argv) < 2 or sys.argv[1] in ("--help", "-h"):
    print("Usage: notion-publish-helium.py <notion-page-url> (publishes the page to the web)")
    raise SystemExit(0 if len(sys.argv) > 1 else 2)
import asyncio, json, sys, urllib.request, websockets
URL = sys.argv[1]
async def main():
    ver = json.load(urllib.request.urlopen("http://127.0.0.1:9222/json/version"))
    async with websockets.connect(ver["webSocketDebuggerUrl"], max_size=None) as ws:
        n = 0
        async def call(method, params=None, sid=None):
            nonlocal n; n += 1
            msg = {"id": n, "method": method, "params": params or {}}
            if sid: msg["sessionId"] = sid
            await ws.send(json.dumps(msg))
            while True:
                r = json.loads(await ws.recv())
                if r.get("id") == n: return r
        t = await call("Target.createTarget", {"url": URL, "background": False, "newWindow": True})
        tid = t["result"]["targetId"]
        s = (await call("Target.attachToTarget", {"targetId": tid, "flatten": True}))["result"]["sessionId"]
        async def ev(js):
            r = await call("Runtime.evaluate", {"expression": js, "returnByValue": True, "awaitPromise": True}, s)
            return r["result"].get("result", {}).get("value")
        async def click_at(x, y):
            for typ in ("mouseMoved", "mousePressed", "mouseReleased"):
                await call("Input.dispatchMouseEvent", {"type": typ, "x": x, "y": y, "button": "left", "clickCount": 1}, s)
                await asyncio.sleep(0.05)
        async def find(label, extra="[role=button],button,[role=tab]"):
            return await ev(f"""(()=>{{const els=[...document.querySelectorAll('{extra}')].filter(e=>(e.innerText||'').trim()==='{label}' && e.getBoundingClientRect().width>0); if(!els.length) return null; const r=els[els.length-1].getBoundingClientRect(); return [r.left+r.width/2, r.top+r.height/2];}})()""")
        try:
            await call("Page.enable", {}, s)
            await call("Page.bringToFront", {}, s)
            await call("Emulation.setFocusEmulationEnabled", {"enabled": True}, s)
            for i in range(30):
                await asyncio.sleep(1)
                tb = await ev("(()=>{const h=document.querySelector('.notion-topbar');return h?h.innerText:'';})()") or ""
                if "Share" in tb: break
            print("hidden:", await ev("document.hidden"), "| topbar:", tb.replace("\n"," | ")[:200])
            pos = await find("Share")
            print("share pos:", pos)
            if not pos: return
            await click_at(*pos); await asyncio.sleep(1.5)
            pos = await find("Publish")
            print("publish tab pos:", pos)
            if pos: await click_at(*pos); await asyncio.sleep(1.5)
            print("dialog:", (await ev("(()=>{const d=[...document.querySelectorAll('[role=dialog],.notion-overlay-container')].map(x=>x.innerText).join(' | ');return d.slice(0,500);})()") or "").replace("\n"," | "))
            pos = await ev("""(()=>{const els=[...document.querySelectorAll('[role=button],button')].filter(e=>/^(Publish|Publish to web)$/.test((e.innerText||'').trim()) && e.getBoundingClientRect().width>0); if(!els.length) return null; const r=els[els.length-1].getBoundingClientRect(); return [r.left+r.width/2, r.top+r.height/2, els.length];})()""")
            print("publish btn:", pos)
            if pos: await click_at(pos[0], pos[1])
            link=None
            for _ in range(12):
                await asyncio.sleep(1)
                link = await ev("""(()=>{const i=[...document.querySelectorAll('input')].map(x=>x.value).find(v=>/notion\\.site/.test(v||'')); if(i) return i; const t=document.body.innerText.match(/https?:\\/\\/[a-z0-9-]+\\.notion\\.site\\/\\S+/); return t?t[0]:null;})()""")
                if link: break
            print("LINK:", link)
            if not link: print("dialog after:", (await ev("(()=>{const d=[...document.querySelectorAll('[role=dialog],.notion-overlay-container')].map(x=>x.innerText).join(' | ');return d.slice(0,600);})()") or "").replace("\n"," | "))
        finally:
            await call("Target.closeTarget", {"targetId": tid})
asyncio.run(main())
