---
name: video-script
description: Gen script short video chuẩn ElevenLabs v3 (2 bản khác góc mỗi row), fact-check có nguồn, tự động ghi vào Google Sheet queue qua webhook n8n. Dùng khi user đã chọn chủ đề và gõ /video-script, hoặc yêu cầu retry/sửa script một row.
allowed-tools: Bash(curl:*)
---

# Video Script

Gen content cho chủ đề user đã chọn, xuất thẳng row dán vào Google Sheet `queue`.

Video 9:16, **tối đa 30 giây**. Voiceover chạy qua **ElevenLabs v3**.

Chủ đề luôn là 1 cặp so sánh **A vs B** (ví dụ `chảo teflon vs chảo ceramic`, `đường trắng vs đường vàng`) — 2 item cùng loại, người xem đang phân vân chọn cái nào. Toàn bộ script phải xoay quanh việc so sánh 2 vế đó, không lạc sang giới thiệu 1 sản phẩm đơn lẻ.

## Cần gen bao nhiêu

Mỗi chủ đề → 2 row (`lang=vi`, `lang=en`). Mỗi row → **2 bản script khác góc** (`script`, `script_2`).

→ 1 chủ đề = 4 script. 2 chủ đề = 8 script.

Bản VI và EN **viết riêng, không dịch** — dịch nghe như máy đọc.

### 2 bản phải khác GÓC, không phải khác chữ

Điểm dễ làm sai nhất. Hai bản diễn đạt lại cùng một ý = vô dụng, user không có gì để chọn.

Cả 2 bản dùng **chung beat sheet** ở Bước 1 (cùng 10 câu, cùng mốc giây). Khác nhau ở nội dung câu 1, 2, 9 và ở giọng:

| Beat | Bản 1 (`script`) | Bản 2 (`script_2`) |
|---|---|---|
| Câu 1 — hook | Hỏi ngược: "A hay B, cái nào đáng tiền?" | Khẳng định gây tranh cãi: "B đang bị đánh giá thấp" / "A không tốt như bạn nghĩ" |
| Câu 2 — chốt khác biệt | Nêu khác biệt kỹ thuật trung lập | Nêu khác biệt bằng hệ quả người dùng cảm được |
| Câu 3-8 — 3 tiêu chí | Cùng 3 tiêu chí, cùng số liệu ở cả 2 bản | |
| Câu 9 — kết luận | Tuỳ tình huống — không thiên vị | Chốt rõ 1 bên thắng cho use-case chính, kèm điều kiện |
| Giọng | Bình tĩnh, đưa thông tin | Gắt, cảnh báo/khuyên |

Cả 2 bản vẫn phải nhắc tới **cả A và B** — không được bản nào bỏ sót 1 vế.

Cùng sự thật, cùng số liệu. Khác cách vào và khác nhịp.

## Bước 1 — Viết script

**Đúng 10 câu, tối đa 30 giây.** Không thêm câu, không gộp câu — mỗi beat dưới đây là một câu hoàn chỉnh.

| Giây | Câu | Nội dung | Từ (VI) | Từ (EN) | Hình |
|---|---|---|---|---|---|
| 0-3 | 1 | Hook nghi vấn: "A hay B, cái nào mới đáng tiền?" | ~9 | ~8 | Ảnh 2 bên, chưa có nhãn |
| 3-6 | 2 | Chốt khác biệt cốt lõi, 1 dòng | ~9 | ~8 | Hiện nhãn 2 bên |
| 6-12 | 3-4 | Tiêu chí 1 — thành phần / chất liệu | ~18 | ~15 | Zoom bên trái → bên phải |
| 12-18 | 5-6 | Tiêu chí 2 — độ bền / an toàn | ~18 | ~15 | Icon tick vs X |
| 18-23 | 7-8 | Tiêu chí 3 — giá / khi nào nên dùng | ~15 | ~12 | Bảng giá / số nhảy |
| 23-27 | 9 | Kết luận thực dụng: "Nấu ăn hằng ngày thì X là đủ." | ~12 | ~10 | Highlight bên thắng |
| 27-30 | 10 | CTA + câu vòng lại hook | ~9 | ~7 | Về lại ảnh mở đầu |

**Tổng: VI 80-90 từ · EN 66-75 từ.** Ngoài khung này là sai nhịp — viết lại, đừng nộp.

Hook giữ nguyên 3 giây dù tổng đã nới — 71% người xem quyết định bỏ hay ở lại trong vài giây đầu, kéo dài hook là tự bắn vào chân. 4 giây thêm vào chia cho 3 tiêu chí và câu kết luận.

Căn cứ: short-form VO chạy ~130-150 wpm, hook 7-8 từ ≈ 3 giây; tiếng Việt nói nhanh hơn (~190 wpm) nên hạn từ cao hơn tiếng Anh ở cùng số giây.

**Cận trên là trần cứng, không phải mục tiêu.** VI 90 từ = đúng 30 giây ở tốc độ danh định 3.0 từ/giây (EN 75 từ ở 2.5 từ/giây). Vượt là clip bị hụt hoặc đọc gấp.

**Sàn ký tự — ràng buộc kỹ thuật của v3.** Mỗi bản phải **≥ 280 ký tự** (tính cả audio tag). ElevenLabs khuyến nghị prompt ≥250 ký tự; ngắn hơn thì giọng ra không ổn định giữa các lần gen. Script 30 giây bình thường rơi vào ~420-480 ký tự nên dư sức — nhưng nếu viết quá cụt mà tụt dưới 280 thì phải nới câu ra, **không được** nộp bản ngắn hơn.

**Bản nháp đầu thường vượt nhẹ.** Đo thực tế: 10 câu viết theo bản năng ra 93 từ VI (~31 giây), dư 3 từ so với trần 90 — tỉa nhẹ là vừa. Nên:
- Trần mỗi câu: **VI ≤ 10 từ · EN ≤ 9 từ**. Câu nào dài hơn là phải cắt.
- Cắt chữ đệm, không cắt số liệu ("chống ăn mòn bởi muối và clo" → "chống ăn mòn muối và clo").
- Viết xong **đếm lại**, vượt thì tỉa rồi đếm lại. Đừng nộp bản chưa đếm.

Ghi số từ **và** số ký tự thực tế ở cuối mỗi bản để user tự canh.

### Luật ElevenLabs v3 — bắt buộc

**Audio tag** dạng `[tag]`, đặt ngay trước đoạn nó chi phối. Tag có hiệu lực tới ngắt câu tự nhiên kế tiếp.

Tag được dùng (chỉ tag về *cách nói*):
`[excited] [curious] [sarcastic] [whispers] [laughs] [sighs] [exhales] [mischievously]`

**Cấm:**
- Tag không phải giọng nói: `[standing]`, `[grinning]`, `[pacing]`, `[music]`, `[cut to]` — v3 đọc lỗi hoặc bỏ qua
- SSML `<break>` — v3 **không hỗ trợ**
- Tag mâu thuẫn với giọng (giọng thì thầm + `[shout]` = không ăn)
- Sound effect (`[gunshot]`, `[applause]`) — không hợp ngữ cảnh gia dụng

**Nhịp và nhấn:**
- `...` tạo khoảng nghỉ + nhấn. Cách duy nhất tạo pause (không có break tag).
- VIẾT HOA từ cần nhấn. Tiết chế, 2-3 từ mỗi bản.
- Câu ngắn = nhịp nhanh.

Tag thử nghiệm cho kết quả không ổn định giữa các giọng. Bám 8 tag trên.

### Ví dụ đạt chuẩn — bám để canh mật độ chữ

Chủ đề `inox 304 vs inox 316`, bản VI. Đã đo: **89 từ · 435 ký tự · 10 câu · ~29.7 giây**.

```
[curious] Inox 304 hay 316... cái nào đáng tiền?
Khác nhau đúng một thứ: 316 có thêm molypden.
Cả hai đều là inox không gỉ, nhóm austenit.
Molypden trong 316 chống ăn mòn muối và clo.
Nấu ăn thường ngày, 304 KHÔNG hề bị gỉ.
316 chỉ ăn tiền khi gặp nước biển, hoá chất.
Giá 316 đắt hơn 304 khoảng ba mươi phần trăm.
Nồi chảo ngoài chợ hầu hết đều là 304.
[excited] Nấu ăn hằng ngày thì 304 là ĐỦ.
Vậy bạn đang xài loại nào? Comment nha.
```

Để ý mật độ: câu dài nhất 10 từ, không câu nào có hai mệnh đề phụ chồng nhau. Đó là nhịp cần đạt.

## Bước 2 — Fact check

Tách toàn bộ câu khẳng định có thể sai thành list riêng. Kiểm từng câu bằng web search — kiểm **trên list claim**, không đọc lại script gốc (đọc lại sẽ tự bênh).

| Claim | Bản nào | Verdict | Nguồn (URL) | Ghi chú |
|---|---|---|---|---|

Verdict `pass` / `warn` / `fail`:
- Không tìm được nguồn nào → `fail`, không phải `warn`
- Số liệu (nhiệt độ, watt, phút, % tiết kiệm) bắt buộc có URL. Không URL = `fail`

**Có `fail`:** sửa, chạy lại Bước 2. Tối đa **2 vòng**. Vẫn fail → giữ nguyên nhưng đánh dấu rõ ở output để user tự quyết. **Không im lặng bỏ claim đi.**

## Bước 3 — Chuẩn bị row

Mỗi row gồm các field sau. **Không tự tính `row_id`** — webhook n8n tự tính (đọc sheet, lấy max+1) để tránh trùng, xem [`../../n8n-autopost/workflow_content_append.json`](../../n8n-autopost/workflow_content_append.json).

| Field | Giá trị |
|---|---|
| `lang` | `vi` / `en` — bắt buộc |
| `title` | tiêu đề đăng — khác với hook của script — bắt buộc |
| `script` | bản 1 đầy đủ, có audio tag — bắt buộc |
| `script_2` | bản 2 đầy đủ, có audio tag — bắt buộc |
| `description` | mô tả + 3 hashtag |
| `tags` | 3-5 tag, cách nhau dấu phẩy |
| `publish_at` | bỏ trống trừ khi user nói giờ cụ thể. Format `YYYY-MM-DD HH:mm` giờ VN. |
| `social` | bỏ qua, webhook tự set `all` |

`status`, `row_id`, `drive_file_id`, `cover_file_id`, `posted_at` — webhook tự set, đừng gửi.

## Bước 4 — Gửi vào sheet qua webhook

Chỉ chạy bước này khi **gen mới** (chủ đề vừa chọn từ `/trend-topics`), không chạy khi retry — xem mục Retry bên dưới.

Đọc `CONTENT_PIPELINE_WEBHOOK_URL` và `CONTENT_PIPELINE_WEBHOOK_TOKEN` từ `.env` gốc repo. Thiếu 1 trong 2 biến → dừng, báo user chạy setup ở [`../../n8n-autopost/SETUP_GUIDE_CONTENT_PIPELINE.md`](../../n8n-autopost/SETUP_GUIDE_CONTENT_PIPELINE.md), không tự bịa giá trị.

Gọi:
```bash
curl -sS -X POST "$CONTENT_PIPELINE_WEBHOOK_URL" \
  -H "X-Auth-Token: $CONTENT_PIPELINE_WEBHOOK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"rows": [ ...4 row vừa gen... ]}'
```

Response kỳ vọng: `{"ok":true,"appended":4,"row_ids":[...]}`.

**Đừng tin HTTP status.** Khi validate fail, n8n trả `HTTP 200` với **body rỗng** — không phải mã lỗi. Chỉ coi là thành công khi body parse được JSON và có `ok:true`. Mọi trường hợp khác (body rỗng, `403 Authorization data is wrong!`, HTML, timeout) → coi là fail, **không báo user "đã ghi xong"**, in nguyên response ra cho user tự đọc.

### Output cuối, đúng thứ tự

1. **Script full** — nhóm theo row, mỗi row 2 bản, kèm số từ + số ký tự + ước lượng giây
2. **Bảng fact check** — kèm mọi `fail` còn sót
3. **Shot list** — bảng 7 dòng theo beat sheet, cột `Hình` điền cụ thể cho đúng cặp A/B này (quay/ghép cảnh gì, cần đạo cụ gì). Đây là ghi chú dựng CapCut, **không** gửi vào sheet — sheet không có cột cho nó.
4. **Kết quả webhook** — `row_ids` vừa ghi, hoặc lỗi nếu gọi fail (kèm TSV dự phòng để user tự dán tay)
5. **Cảnh báo** nếu có: claim chưa verify, nghi trùng clip cũ, script lệch khung từ/giây (VI 80-90 · EN 66-75 · ≤30s) hoặc dưới sàn 280 ký tự

## Chế độ retry

User bảo sửa (`retry row 7`, `bản 2 nghe cứng quá`, `hook chưa gắt`):

Webhook chỉ **append**, không update — gọi lại sẽ tạo row rác thay vì sửa row cũ. **Không gọi webhook trong chế độ này.**

1. Chỉ gen lại đúng row/bản được nêu. Không đụng row khác.
2. Giữ nguyên `row_id`, `title`, `tags` trừ khi user bảo đổi.
3. Chạy lại fact check cho phần vừa sửa.
4. Xuất **TSV chỉ row đó** (đúng thứ tự cột `row_id, status, lang, social, drive_file_id, cover_file_id, title, description, tags, publish_at, posted_at, script, script_2`, dùng `row_id` cũ) — user tự dán đè vào sheet, kèm 1 dòng nói rõ đã đổi gì.

User "đánh pass" = tự đổi `status` trong sheet. Skill không đụng vào.
