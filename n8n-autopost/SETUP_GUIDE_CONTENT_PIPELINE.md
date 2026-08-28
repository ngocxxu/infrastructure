# Setup webhook auto-append to `queue` sheet

Workflow `workflow_content_append.json` receives POST from skill `/video-script`, auto-computes `row_id`, auto-appends to sheet `queue` with `status=review`. No more copy-pasting TSV.

> **✅ ALREADY SET UP on n8n production** — steps 1-4 below are reference only / for rebuilding if needed.
>
> | | |
> |---|---|
> | Workflow ID | `0aYRMivaOXFApfKd` — "Content Pipeline - Append to Queue", currently **Active** |
> | Credential | `content-pipeline-auth` (id `3XOZzcbtTbct7UCu`, type Header Auth, header `X-Auth-Token`) |
> | Sheet ID | `1Cg7G5OJJC-p6vT6WZEdQd2-bUuoEVGznGJgGmS-5Kro` (tab `queue`) |
> | Google Sheets cred | `Google Sheets account` (id `WpTyrYx7LrmoDc8W`) — shared with autopost workflow |
> | Endpoint | `https://n8n.ngocquach.com/webhook/content-pipeline-append` |
> | Token | saved in `.claude/.env` (gitignored) |
>
> Tested: append OK (`row_ids:[5]`), wrong token → `403`, missing field → blocked before write.
> JSON file in repo still keeps placeholders so it can be rebuilt from scratch.

---

## 1. Import

1. n8n → Import from File → select `workflow_content_append.json`
2. Replace placeholders:

   | Placeholder | Node | Replace with |
   |---|---|---|
   | `DAN_GOOGLE_SHEET_ID_VAO_DAY` | Read Current Queue, Append To Queue | Sheet ID (same one used in `workflow_autopost_fb_yt.json`) |
   | `DAN_HEADER_AUTH_CRED_VAO_DAY` | Webhook Append | Name of the Header Auth credential created in step 2 |

3. Assign the existing **Google Sheets** credential (same one used by `Read Queue` in the autopost workflow) to nodes `Read Current Queue` and `Append To Queue`.

## 2. Create Header Auth credential (required — don't skip)

This webhook writes to the sheet, so it **must not be public without auth**. Anyone who guesses the URL could spam junk rows into the sheet.

1. n8n → Credentials → New → **Header Auth**
2. Name: anything, e.g. `content-pipeline-auth`
3. Header Name: `X-Auth-Token`
4. Header Value: generate a long random string (e.g. `openssl rand -hex 32`)
5. Assign this credential to node `Webhook Append`

Save the Header Value — you'll need to paste it into Claude Code's environment variable (step 4).

## 3. Activate the workflow

Toggle **Active**. Webhook URL will be:

```
https://n8n.ngocquach.com/webhook/content-pipeline-append
```

## 4. Tell the skill the endpoint + token

Add to `.env` at repo root (not committed):

```
CONTENT_PIPELINE_WEBHOOK_URL=https://n8n.ngocquach.com/webhook/content-pipeline-append
CONTENT_PIPELINE_WEBHOOK_TOKEN=<Header Value from step 2>
```

## 5. Test

```bash
curl -X POST https://n8n.ngocquach.com/webhook/content-pipeline-append \
  -H "X-Auth-Token: <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "rows": [{
      "lang": "vi",
      "title": "Test row — delete after checking",
      "description": "test description",
      "tags": "test",
      "script": "[curious] script test version 1",
      "script_2": "[excited] script test version 2"
    }]
  }'
```

Expected: `{"ok":true,"appended":1,"row_ids":[<number>]}`. Open sheet `queue`, check for a new row with `status=review`. Delete the test row.

## Common errors

**403 `Authorization data is wrong!`** — wrong header name or token. Header name must be exactly `X-Auth-Token`.

**HTTP 200 but empty body** — workflow errored before reaching the `Respond To Webhook` node (usually validation in `Build Rows` blocking it). **No row got written** — this is correct behavior, but n8n doesn't return an error status code. Don't trust HTTP status; only treat it as success when the body has `ok:true`. Check n8n execution log for the reason.

**Node `Build Rows` reports "Row missing required field"** — payload is missing `lang`, `title`, `script`, or `script_2`. Skill `/video-script` always sends all 4 fields; this error usually comes from a manual curl call missing a field.

**`row_id` collision on 2 calls very close together** — node `Read Current Queue` reads the sheet right before writing so this almost never happens at the 2-clips/week frequency. If it does happen, likely 2 requests ran in parallel — avoid calling the webhook twice at once.

**Sheet doesn't have `script_2` column** — add that column to the far right of sheet `queue` before using this webhook. See [../.claude/skills/README.md](../.claude/skills/README.md) Setup Sheet section.
