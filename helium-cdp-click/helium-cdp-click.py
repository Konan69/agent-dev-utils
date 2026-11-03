import sys
if len(sys.argv) < 2 or sys.argv[1] in ("--help", "-h"):
    print("Usage: helium-cdp-click.py <url> [button-pattern ...]")
    raise SystemExit(0 if len(sys.argv) > 1 else 2)
import asyncio, json, sys, urllib.request, websockets
async def main(url):
    ws_url = json.load(urllib.request.urlopen("http://127.0.0.1:9222/json/version"))["webSocketDebuggerUrl"]
    async with websockets.connect(ws_url, max_size=None) as ws:
        n=0
        async def call(method, params=None, sid=None):
            nonlocal n; n+=1; msg={"id":n,"method":method,"params":params or {}}
            if sid: msg["sessionId"]=sid
            await ws.send(json.dumps(msg))
            while True:
                r=json.loads(await ws.recv())
                if r.get("id")==n: return r
        t=await call("Target.createTarget",{"url":url,"background":True})
        tid=t["result"]["targetId"]
        s=(await call("Target.attachToTarget",{"targetId":tid,"flatten":True}))["result"]["sessionId"]
        async def ev(js):
            r=await call("Runtime.evaluate",{"expression":js,"returnByValue":True},s)
            return r["result"]["result"].get("value")
        for _ in range(20):
            await asyncio.sleep(1.5)
            txt=await ev("document.body ? document.body.innerText.slice(0,600) : ''")
            if txt and ("Connect" in txt or "Log in" in txt or "connected" in txt.lower()): break
        print("PAGE:", (txt or "").replace("\n"," | ")[:500])
        for pat in sys.argv[2:]:
            js="(()=>{const re=new RegExp(%s,'i');const els=[...document.querySelectorAll('button,a,[role=button],[role=link],li,div[data-identifier]')].filter(x=>x.offsetParent!==null&&re.test(x.innerText||x.getAttribute('data-identifier')||''));const b=els[els.length-1];if(b){b.click();return (b.innerText||'').slice(0,60)}return null})()" % json.dumps(pat)
            for _ in range(10):
                c=await ev(js)
                if c is not None: break
                await asyncio.sleep(1.5)
            print("CLICK", pat, "->", c)
            await asyncio.sleep(4)
            print("  URL/PAGE:", ((await ev("location.host+' :: '+document.body.innerText.slice(0,250)")) or "").replace("\n"," | "))
        print("AFTER:", ((await ev("document.body.innerText.slice(0,300)")) or "").replace("\n"," | "))
        await call("Target.closeTarget",{"targetId":tid})
asyncio.run(main(sys.argv[1]))
