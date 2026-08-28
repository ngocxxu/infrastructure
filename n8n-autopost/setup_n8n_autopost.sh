#!/usr/bin/env bash
# Import workflow auto-post (FB Page + YouTube) vao n8n qua Public API.
# Chay tu thu muc infrastructure:  bash setup_n8n_autopost.sh
set -euo pipefail

N8N_URL="${N8N_URL:-https://n8n.ngocquach.com}"
ENV_FILE="${ENV_FILE:-.claude/.env}"
PAYLOAD="${PAYLOAD:-payload_create.json}"
WF_NAME="AutoPost - FB Page + YouTube (VI/EN)"

[ -f "$ENV_FILE" ] || { echo "Khong thay $ENV_FILE"; exit 1; }
[ -f "$PAYLOAD" ]  || { echo "Khong thay $PAYLOAD (dat cung thu muc voi script)"; exit 1; }

set -a; . "$ENV_FILE"; set +a
: "${N8N_API_KEY:?Thieu N8N_API_KEY trong $ENV_FILE}"

H_KEY="X-N8N-API-KEY: $N8N_API_KEY"
H_JSON="Content-Type: application/json"

echo "==> Kiem tra ket noi $N8N_URL"
code=$(curl -sS -o /tmp/n8n_list.json -w '%{http_code}' -H "$H_KEY" "$N8N_URL/api/v1/workflows?limit=250")
if [ "$code" != "200" ]; then
  echo "That bai (HTTP $code). Noi dung:"; cat /tmp/n8n_list.json; echo
  echo "Kiem tra: API key con han? Public API da bat chua (N8N_PUBLIC_API_DISABLED)?"
  exit 1
fi
echo "    OK"

# Tim workflow trung ten -> update thay vi tao trung
existing=$(python3 -c "
import json,sys
d=json.load(open('/tmp/n8n_list.json')); ws=d.get('data',d)
print(next((w['id'] for w in ws if w.get('name')=='''$WF_NAME'''),''))
")

if [ -n "$existing" ]; then
  echo "==> Da ton tai (id=$existing) -> cap nhat"
  code=$(curl -sS -o /tmp/n8n_res.json -w '%{http_code}' -X PUT \
    -H "$H_KEY" -H "$H_JSON" --data-binary @"$PAYLOAD" \
    "$N8N_URL/api/v1/workflows/$existing")
else
  echo "==> Tao workflow moi"
  code=$(curl -sS -o /tmp/n8n_res.json -w '%{http_code}' -X POST \
    -H "$H_KEY" -H "$H_JSON" --data-binary @"$PAYLOAD" \
    "$N8N_URL/api/v1/workflows")
fi

if [ "$code" != "200" ] && [ "$code" != "201" ]; then
  echo "Loi HTTP $code:"; cat /tmp/n8n_res.json; echo; exit 1
fi

wid=$(python3 -c "import json;print(json.load(open('/tmp/n8n_res.json')).get('id',''))")
echo "    Xong. Workflow ID: $wid"
echo
echo "Mo: $N8N_URL/workflow/$wid"
echo
echo "CON PHAI LAM TAY (API khong lam thay duoc):"
echo "  1. Gan credential: Google Sheets, Google Drive, YouTube VI, YouTube EN"
echo "     (OAuth bat buoc bam duyet tren trinh duyet)"
echo "  2. Thay DAN_GOOGLE_SHEET_ID_VAO_DAY o 2 node Google Sheets"
echo "  3. Khai 4 bien FB_PAGE_ID_VI / FB_PAGE_TOKEN_VI / FB_PAGE_ID_EN / FB_PAGE_TOKEN_EN"
echo "     (ban Community khong co Variables -> go thang vao 2 node FB)"
echo "  4. Execute Workflow thu 1 dong roi moi bat Active"
