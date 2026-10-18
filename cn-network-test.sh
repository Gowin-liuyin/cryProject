#!/usr/bin/env bash
# 国内网络连通性测试：只打印 HTTP 状态码与计数，不会输出你的 API key 或任何 IP
# 用法：bash cn-network-test.sh  （测绘平台可选：先 export HUNTER_KEY=... FOFA_EMAIL=... FOFA_KEY=... QUAKE_KEY=... ZOOMEYE_KEY=...）
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36"
code(){ curl -s -o /dev/null -w "%{http_code}" -m 20 -A "$UA" "$1"; }
b64(){ printf '%s' "$1" | base64 | tr -d '\n' | tr '+/' '-_'; }
echo "== 1. 国内官方源 =="
for u in https://www.cnvd.org.cn/flaw/list https://www.cnvd.org.cn/webinfo/list https://www.cnvd.org.cn/rssXml \
         https://www.cnnvd.org.cn/ https://www.tc260.org.cn/ https://hunter.qianxin.com/ ; do
  echo "$(code $u)  $u"; done
echo "== 2. 境外源（看国内是否可达）=="
for u in "https://services.nvd.nist.gov/rest/json/cves/2.0?resultsPerPage=1" https://api.osv.dev/v1/vulns/GHSA-jfh8-c2jp-5v3q \
         https://api.github.com/advisories?per_page=1 https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json \
         "https://api.first.org/data/v1/epss?cve=CVE-2021-44228" "http://export.arxiv.org/api/query?search_query=cat:cs.CR&max_results=1" \
         https://huntr.com/bounties/hacktivity https://raw.githubusercontent.com/mitre-atlas/atlas-data/main/dist/ATLAS.yaml ; do
  echo "$(code "$u")  $u"; done
echo "== 3. 测绘平台（只取 total，未设 key 则跳过）=="
Q='app.name="Ollama"'
if [ -n "$HUNTER_KEY" ]; then
  r=$(curl -s -m 20 "https://hunter.qianxin.com/openApi/search?api-key=$HUNTER_KEY&search=$(b64 "$Q")&page=1&page_size=1&is_web=3")
  echo "Hunter: $(echo "$r" | python3 -c 'import sys,json;d=json.load(sys.stdin);print("code",d.get("code"),"msg",d.get("message"),"total",(d.get("data") or {}).get("total"),"rest_quota",(d.get("data") or {}).get("rest_quota"))' 2>&1)"
  for q in 'web.title="Dify"' 'web.body="vllm"' 'web.title="ComfyUI"' 'web.body="triton"'; do
    r=$(curl -s -m 20 "https://hunter.qianxin.com/openApi/search?api-key=$HUNTER_KEY&search=$(b64 "$q")&page=1&page_size=1&is_web=3")
    echo "  $q -> $(echo "$r" | python3 -c 'import sys,json;d=json.load(sys.stdin);print((d.get("data") or {}).get("total"), d.get("message"))' 2>&1)"; sleep 2; done
else echo "Hunter: 跳过（未设 HUNTER_KEY）"; fi
if [ -n "$FOFA_KEY" ]; then
  r=$(curl -s -m 20 "https://fofa.info/api/v1/search/all?email=$FOFA_EMAIL&key=$FOFA_KEY&qbase64=$(printf 'app="Ollama"'|base64|tr -d '\n')&size=1&fields=port")
  echo "FOFA: $(echo "$r" | python3 -c 'import sys,json;d=json.load(sys.stdin);print("error",d.get("error"),"size",d.get("size"),d.get("errmsg"))' 2>&1)"
else echo "FOFA: 跳过"; fi
if [ -n "$QUAKE_KEY" ]; then
  r=$(curl -s -m 20 -X POST https://quake.360.net/api/v3/search/quake_service -H "X-QuakeToken: $QUAKE_KEY" -H 'Content-Type: application/json' -d '{"query":"app:\"Ollama\"","start":0,"size":1}')
  echo "Quake: $(echo "$r" | python3 -c 'import sys,json;d=json.load(sys.stdin);print("code",d.get("code"),"total",((d.get("meta") or {}).get("pagination") or {}).get("total"),d.get("message"))' 2>&1)"
else echo "Quake: 跳过"; fi
if [ -n "$ZOOMEYE_KEY" ]; then
  r=$(curl -s -m 20 -X POST https://api.zoomeye.ai/v2/search -H "API-KEY: $ZOOMEYE_KEY" -H 'Content-Type: application/json' -d "{\"qbase64\":\"$(printf 'app="Ollama"'|base64|tr -d '\n')\",\"page\":1,\"pagesize\":1}")
  echo "ZoomEye: $(echo "$r" | python3 -c 'import sys,json;d=json.load(sys.stdin);print("code",d.get("code"),"total",d.get("total"),d.get("message"))' 2>&1)"
else echo "ZoomEye: 跳过"; fi
echo "== 完成：把以上输出整段贴回来即可（不含 key 与 IP）=="
