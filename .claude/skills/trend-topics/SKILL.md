---
name: trend-topics
description: Tìm và chấm điểm chủ đề dạng so sánh A-vs-B cho kênh short video gia dụng/mẹo vặt song ngữ VI-EN. Trả shortlist 8 cặp so sánh có số liệu thật để user chọn 2. Dùng khi user gõ /trend-topics hoặc hỏi "tìm chủ đề", "topic tuần này".
---

# Trend Topics

Tìm chủ đề short video. Niche: **mẹo vặt / review đồ gia dụng nhà bếp**. Format 9:16, dưới 60 giây. Đăng song song 2 thị trường Việt Nam và US.

**Mỗi chủ đề là 1 cặp so sánh A vs B** — 2 item cùng loại, cùng mục đích, người xem đang phân vân chọn cái nào. Ví dụ: `chảo teflon vs chảo ceramic`, `đường trắng vs đường vàng`. Không nhận chủ đề dạng liệt kê 1 món, mẹo đơn lẻ, hay dạng "5 cách...".

Output là shortlist để user chọn 2 cặp → user chạy `/video-script`.

## Bước 1 — Thu tín hiệu thật

Web search, dữ liệu 7 ngày gần nhất. **Bắt buộc có số hoặc nguồn cụ thể.** Không được tự nghĩ chủ đề rồi gán nhãn "đang hot" — lỗi đó làm hỏng cả pipeline.

Quét:
- YouTube Shorts đang lên trong niche (VN + US) — title thật + lượt view
- TikTok Creative Center / bài tổng hợp trend tuần
- Google Trends breakout queries về đồ gia dụng, bếp
- Reddit r/Cooking, r/AirFryer, r/BuyItForLife — câu hỏi lặp lại nhiều
- Group/forum VN nếu tìm được

Nguồn không truy cập được → ghi rõ "không lấy được". Đừng bịa số.

## Bước 2 — Sinh chủ đề

Từ tín hiệu trên, sinh 15-20 cặp so sánh **A vs B**. Cả A và B phải là thứ người xem thật sự đang phân vân chọn — không tự bịa cặp giả để có nội dung (ví dụ "chảo teflon vs chảo ceramic" hợp vì cả hai đều được search "cái nào tốt hơn"; "chảo teflon vs xoong áp suất" không hợp vì không ai phân vân giữa 2 thứ khác công dụng).

Chủ đề phải chạy được ở **cả** VN và US — cả A và B đều phải phổ biến ở cả hai thị trường. Loại cặp chỉ đúng một nơi (phụ thuộc thương hiệu địa phương, phụ thuộc giá điện VN).

## Bước 3 — Chấm điểm, lọc còn 8

Chấm 1-5:
- **Signal** — bằng chứng đang được quan tâm mạnh tới đâu
- **Novelty** — đã bị làm nát chưa
- **Feasibility** — quay bằng đồ có sẵn trong bếp được không
- **Factual** — kiểm chứng được bằng nguồn không, hay mẹo dân gian mơ hồ

Loại thẳng nếu Feasibility ≤ 2 hoặc Factual ≤ 2.

**Chống trùng:** đọc cột `title` trong Google Sheet `queue`, loại cặp trùng ý với 20 clip gần nhất (trùng cả khi đảo thứ tự A/B hoặc đổi nhãn tương đương). Không đọc được sheet → nói rõ "chưa chống trùng được", đừng im lặng bỏ qua.

## Bước 4 — Output

| # | So sánh (VI) | Comparison (EN) | Signal | Nov | Feas | Fact | Tổng | Bằng chứng | Góc quay gợi ý |
|---|---|---|---|---|---|---|---|---|---|

Cột "So sánh" ghi đúng dạng `A vs B`, ví dụ `Chảo teflon vs chảo ceramic`.

Sắp theo tổng điểm giảm dần, 8 dòng.
- **Bằng chứng**: số liệu + link nguồn — nếu có thể, mỗi vế A và B đều có ít nhất 1 nguồn riêng
- **Góc quay gợi ý**: 1 câu — quay cảnh gì để so A và B cạnh nhau, đạo cụ gì

Thêm mục **"Loại vì trùng"**: chủ đề nào bị bỏ, trùng clip cũ nào.

Kết bằng đúng 1 dòng:
`Chọn 2 số rồi chạy: /video-script 3 và 7`
