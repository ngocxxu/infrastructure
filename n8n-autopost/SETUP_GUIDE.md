# Setup n8n auto-post: 2 Facebook Pages + 2 YouTube channels

You post TikTok manually. This workflow handles the other 4 channels.

---

## 0. Flow

```
Cron every 15 min
   ↓
Google Sheet "queue"  ──> filter status = ready
   ↓
Code: convert VN time → RFC3339 (YouTube) + unix (Facebook)
   ↓
Google Drive: download mp4 file (binary field "video")
   ↓
Switch by lang column
   ├─ vi → YouTube VI  +  FB Page VI
   └─ en → YouTube EN  +  FB Page EN
   ↓
Write status = posted back to Sheet
```

All you do: render clip → drop it in Drive → fill 1 Sheet row → go to sleep.

---

## 1. Google Sheet control panel

Create a sheet named exactly `queue`, header order matching `queue_template.csv`:

| Column | Meaning |
|---|---|
| `row_id` | sequence number, used to write status back — **must be unique** |
| `status` | `ready` = post it · `draft` = skip · `posted` = done |
| `lang` | `vi` or `en` — decides which channel pair it goes to |
| `drive_file_id` | mp4 file ID on Drive (the part between `/d/` and `/view` in the link) |
| `title` | title, shared by YouTube + FB |
| `description` | description |
| `tags` | YouTube tags, space-separated |
| `publish_at` | `2026-08-20 19:00` — **Vietnam time**, workflow auto-converts |
| `posted_at` | auto-filled by workflow |

Leave `publish_at` empty to post immediately.

---

## 2. YouTube credential (do it twice, 2 channels)

1. Google Cloud Console → create project → enable **YouTube Data API v3**
2. OAuth consent screen → External → add your own email to Test users
3. Credentials → OAuth client ID → **Web application**
4. Authorized redirect URI: paste the exact URL n8n shows on the credential-creation screen
5. In n8n: Credentials → **YouTube OAuth2 API** → paste Client ID + Secret → Connect
6. **Repeat from step 5 for the 2nd channel**, name it differently so you can tell them apart

Then open node `YouTube VI` and `YouTube EN`, assign each the matching channel's credential.

> ⚠️ When you click Connect, Google asks which account — pick the right channel. If both channels sit under one Google account (Brand Account style), the picker shows both — don't click the wrong one.

### YouTube quota
Free quota is 10,000 units/day, each upload costs **1,600 units** → about **6 videos/day**. Quota is per Google Cloud *project*, not per channel. Posting 1 clip/day to 2 channels is well within limits.

---

## 3. Facebook Page token (do it twice, 2 Pages)

1. developers.facebook.com → Create App → type **Business**
2. Add Product → **Facebook Login**
3. Graph API Explorer → select app → **Get Page Access Token**
4. Grant permissions: `pages_show_list`, `pages_manage_posts`, `pages_read_engagement`
5. Select Page → copy token (this token is **short-lived, expires in ~1 hour**)
6. Exchange for long-lived token:

```
GET https://graph.facebook.com/v25.0/oauth/access_token
  ?grant_type=fb_exchange_token
  &client_id=APP_ID
  &client_secret=APP_SECRET
  &fb_exchange_token=SHORT_LIVED_TOKEN
```

7. Take that long-lived token and call `/me/accounts` → the returned Page token is a **permanent token** (never expires, unless you change password or remove the app)

### Getting the Page ID
Go to Page → About → Page ID. Or call `/me/accounts` above — it's included in the response.

---

## 4. Facebook Page ID and token

n8n Community edition has no Variables, so Page ID and token get typed directly into nodes. The template
ships with placeholders — replace them with real values after import.

Token must be the **permanent Page token** — verify with `debug_token`, must return `expires_at: 0`.
Get it in this order: User token → exchange for long-lived (`fb_exchange_token`) → *then* call
`/me/accounts`. Calling `/me/accounts` with a short-lived token gives a Page token that only lasts ~2 hours.

---

## 5. Import and edit

1. n8n → Import from File → select `workflow_autopost_fb_yt.json`
2. Replace all placeholders:

   | Placeholder | Node it's in | Replace with |
   |---|---|---|
   | `DAN_GOOGLE_SHEET_ID_VAO_DAY` | Read Queue, Mark As Posted | Sheet ID |
   | `DAN_FB_PAGE_ID_VI_VAO_DAY` | FB Reels Init VI, FB Set Cover VI | Vietnamese Page ID |
   | `DAN_FB_PAGE_TOKEN_VI_VAO_DAY` | FB Reels Init / Upload / Finish / Set Cover VI | Vietnamese Page token |
   | `DAN_FB_PAGE_ID_EN_VAO_DAY` | FB Reels Init EN, FB Set Cover EN | English Page ID |
   | `DAN_FB_PAGE_TOKEN_EN_VAO_DAY` | FB Reels Init / Upload / Finish / Set Cover EN | English Page token |

   FB token appears in **4 nodes per language**. In `FB Reels Upload` it's in the
   `Authorization` header (format `OAuth <token>`), not the body — easiest one to miss.

3. Assign credentials: Google Sheets, Google Drive, YouTube VI, YouTube EN.
   Node `Set publishAt` and `YT Set Thumbnail` share the same YouTube credential as
   the upload node of the same language.
4. Test run with **Execute Workflow** using a single `status=ready` row
5. Only turn on Active once it runs clean

---

## 6. Common breakage points — read before debugging

**YouTube node reports missing `publishAt` field.**
Some n8n versions don't expose `publishAt` in the YouTube node's Options. Workaround: set upload node's `privacyStatus = private`, then chain an HTTP Request node after it:

```
PUT https://www.googleapis.com/youtube/v3/videos?part=status
Body: {
  "id": "{{ $json.id }}",
  "status": {
    "privacyStatus": "private",
    "publishAt": "{{ $('Compute Publish Time').item.json.publishAtISO }}"
  }
}
```
Use the same YouTube OAuth2 credential as the upload node.

**Facebook returns error `(#100) scheduled_publish_time`.**
Scheduled time must be **at least 10 minutes** from now, **at most 6 months**. The Code node auto-bumps it to 15 minutes if you enter something too close, but a past timestamp still errors.

**Facebook returns `(#200) Permissions error`.**
Token is a User token, not a Page token. Call `/me/accounts` to get the correct Page's token.

**FB upload times out on large files.**
Node timeout is set to 300 seconds. Short 9:16 clips are only a few MB so this rarely hits. Files over 100MB should switch to the 3-stage Resumable Upload API.

**FB video doesn't show up as Reels.**
The `/videos` endpoint posts a regular video; Facebook auto-routes vertical video into the Reels tab but doesn't guarantee it. For guaranteed Reels use `/{page-id}/video_reels` — this endpoint uploads in 3 phases (`start` → `upload` → `finish`), more complex, and schedules via `video_state=SCHEDULED`. Get the simple path stable first, upgrade later.

**Google Sheet write-back hits the wrong row.**
`row_id` must be unique and unchanging. Don't re-sort the sheet mid-run.

---

## 7. What's left for you to do daily

1. Render clip → upload to a fixed Drive folder
2. Copy file ID, fill in 1 Sheet row, set `status = ready`
3. TikTok: post manually as before

About 2 minutes instead of 10 minutes clicking through 4 channels.
