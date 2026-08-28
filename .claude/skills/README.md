# Content Pipeline Skills

2 skill cho quy trình tìm chủ đề → viết script cho kênh short video song ngữ (VI/EN, niche mẹo vặt/gia dụng). Sản lượng: 2 chủ đề/tuần, 4 clip/tuần (VI+EN mỗi chủ đề).

```
/trend-topics
      ↓
  8 chủ đề, chọn 2
      ↓
/video-script <2 chủ đề>
      ↓
  4 row (2 chủ đề × VI/EN), mỗi row 2 bản script
      ↓
  Skill tự POST vào webhook n8n → tự ghi vào Sheet "queue", status=review
      ↓
  Bạn đọc script trong Sheet, kiểm tính đúng đắn
      ↓
  OK → render clip CapCut → điền drive_file_id → status=ready
  Chưa OK → /video-script retry row <n>, <lý do>  (retry vẫn xuất TSV, tự dán tay)
      ↓
  Workflow n8n autopost tự nhặt row status=ready, đăng lên FB/YT
```

Việc ghi vào Sheet chạy qua 1 webhook n8n riêng ([`workflow_content_append.json`](../../n8n-autopost/workflow_content_append.json)) — **đã dựng và active sẵn**, xem [n8n-autopost/SETUP_GUIDE_CONTENT_PIPELINE.md](../../n8n-autopost/SETUP_GUIDE_CONTENT_PIPELINE.md).

---

## 1. `/trend-topics` — tìm chủ đề

**Khi nào chạy**: đầu tuần, bất kỳ ngày nào, không có lịch cố định.

```
/trend-topics
```

Mỗi chủ đề là 1 cặp so sánh **A vs B** — 2 item cùng loại người xem đang phân vân chọn cái nào (ví dụ `chảo teflon vs chảo ceramic`, `đường trắng vs đường vàng`). Skill tự web search (YouTube, TikTok, Google Trends, Reddit) lấy tín hiệu trending 7 ngày gần nhất, sinh ~15-20 cặp so sánh, chấm điểm, lọc còn 8. Có đọc sheet `queue` để loại cặp trùng 20 clip gần nhất.

**Output**: bảng 8 dòng, mỗi dòng có điểm Signal/Novelty/Feasibility/Factual + link nguồn làm bằng chứng + gợi ý góc quay.

**Bạn làm**: đọc bảng, chọn 2 cặp so sánh (sẽ ra 4 clip: 2 cặp × VI/EN).

> Không thấy sheet hoặc không đọc được `title` → skill nói rõ "chưa chống trùng được" thay vì im lặng bỏ qua bước đó. Nếu thấy dòng này, kiểm lại quyền truy cập Sheet trước khi tin danh sách 100%.

---

## 2. `/video-script` — viết script + fact-check

**Khi nào chạy**: ngay sau khi chọn xong 2 cặp so sánh từ `/trend-topics`.

```
/video-script chảo teflon vs chảo ceramic, và đường trắng vs đường vàng
```

(Copy nguyên cặp A vs B từ bảng ra, không cần đúng cú pháp — skill tự hiểu.)

### Skill làm gì

1. Viết **4 row** (2 chủ đề × `lang=vi`/`lang=en`), mỗi row **2 bản script khác góc** (cột `script`, `script_2`) — **8 script tổng**.
   - 2 bản dùng **chung beat sheet**, khác nhau ở câu 1 / câu 2 / câu 9 và ở giọng: bản 1 hook hỏi ngược + kết luận trung lập, bản 2 hook khẳng định gây tranh cãi + chốt hẳn 1 bên thắng. Để bạn có cái thật sự khác nhau mà chọn, không phải chọn giữa 2 câu gần giống nhau.
   - Script tuân luật ElevenLabs v3: audio tag `[excited]`, `[curious]`, `[whispers]`... đúng vị trí; không dùng SSML `<break>` (v3 không hỗ trợ); dùng `...` để tạo khoảng nghỉ; VIẾT HOA để nhấn, tiết chế.
   - Bám beat sheet cố định **10 câu / tối đa 30 giây**: hook nghi vấn (giữ 3s) → chốt khác biệt → 3 tiêu chí → kết luận thực dụng → CTA vòng lại hook.
   - Độ dài: **VI 80-90 từ · EN 66-75 từ**, và **≥280 ký tự** mỗi bản (dưới ngưỡng này v3 ra giọng không ổn định). Skill ghi kèm số từ + ký tự thật để bạn tự canh.
   - Kèm **shot list** theo từng beat để dựng CapCut — chỉ hiện trong chat, không ghi vào sheet.

2. **Fact-check** — tách hết câu khẳng định (nhiệt độ, %, thời gian...) ra list riêng, kiểm bằng web search **không đọc lại script gốc** (tránh tự bênh). Verdict `pass`/`warn`/`fail` kèm URL nguồn. Có `fail` thì tự sửa và check lại, tối đa 2 vòng — vòng 3 vẫn fail thì giữ nguyên và **nói rõ ra**, không âm thầm bỏ claim.

3. **Tự động ghi vào Sheet** — skill POST 4 row lên webhook n8n. Webhook tự tính `row_id` (đọc sheet, lấy max+1), ép cứng `status=review`, để trống `drive_file_id`/`cover_file_id`/`posted_at`. Ghi xong skill in ra `row_ids` vừa tạo.

   Gọi webhook fail (thiếu `.env`, n8n sập, sai token) → skill **không** báo "đã ghi xong". Nó in lỗi thật ra + kèm TSV dự phòng để bạn tự dán tay.

### Retry một row

Không cần gen lại từ đầu:

```
/video-script retry row 7, hook nghe cứng quá
/video-script bản 2 của row 9 nghe hơi tin giả, thêm nguồn rõ hơn
```

Retry **không gọi webhook** — webhook chỉ append nên gọi lại sẽ tạo row rác thay vì sửa row cũ. Skill chỉ sửa đúng row/bản được nêu, giữ nguyên `row_id`/`title`/`tags` trừ khi bạn bảo đổi, chạy lại fact-check cho phần vừa sửa, xuất **TSV chỉ row đó** để bạn tự dán đè vào sheet.

---

## Setup — ĐÃ XONG, không cần làm gì

Webhook n8n đã dựng và active, token đã nằm trong `.claude/.env` (gitignored). Sheet đã có sẵn cột `script_2`. `/video-script` chạy được ngay.

Chi tiết ID / cách dựng lại: [SETUP_GUIDE_CONTENT_PIPELINE.md](../../n8n-autopost/SETUP_GUIDE_CONTENT_PIPELINE.md).

### Thứ tự cột thật của sheet `queue`

```
row_id, status, lang, social, drive_file_id, cover_file_id,
title, description, tags, publish_at, posted_at, script, script_2
```

Chú ý `lang` đứng **trước** `social` — ngược với thứ tự nhiều người hay đoán. Webhook map theo *tên cột* nên append không sợ lệch, nhưng lúc dán TSV tay (chế độ retry) thì phải theo đúng thứ tự trên.

Nếu sau này thêm cột: **luôn thêm ở cuối cùng bên phải**, không chèn giữa — chèn giữa làm lệch mapping node `Read Queue` / `Mark As Posted` trong workflow autopost (đã từng dính). Thêm xong nhớ refresh column list ở các node đó.

## Vòng đời 1 row

```
review   → bạn đọc script trong Sheet
ready    → bạn đã render clip + điền drive_file_id, workflow autopost sẽ đăng
posted   → workflow tự điền khi đăng xong (không tự tay sửa)
```

Không có state `pass` riêng — đổi thẳng `review` → `ready` khi vừa duyệt nội dung vừa xong render, vì 2 việc đó luôn xảy ra cùng lúc.

## Liên quan

- [n8n-autopost/SETUP_GUIDE.md](../../n8n-autopost/SETUP_GUIDE.md) — setup workflow autopost FB/YT, đọc row `status=ready`
- [n8n-autopost/SETUP_GUIDE_CONTENT_PIPELINE.md](../../n8n-autopost/SETUP_GUIDE_CONTENT_PIPELINE.md) — setup webhook ghi tự động, dùng bởi `/video-script`
- [n8n-autopost/workflow_content_append.json](../../n8n-autopost/workflow_content_append.json) — workflow n8n cho webhook ghi tự động
- [n8n-autopost/queue_template.csv](../../n8n-autopost/queue_template.csv) — mẫu cột, đã khớp thứ tự thật của sheet production
