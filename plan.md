# Tính năng App Quản Lý Chi Tiêu

> Tài liệu tổng hợp toàn bộ tính năng cho app quản lý chi tiêu hàng tháng — phân loại theo nhóm, mức độ ưu tiên và độ khó triển khai.

---

## Mục lục

1. [Tính năng cốt lõi (Free tier)](#1-tính-năng-cốt-lõi-free-tier)
2. [Tự động hoá](#2-tự-động-hoá)
3. [AI & Phân tích thông minh](#3-ai--phân-tích-thông-minh)
4. [Mục tiêu tài chính](#4-mục-tiêu-tài-chính)
5. [Báo cáo nâng cao](#5-báo-cáo-nâng-cao)
6. [Chia sẻ & Gia đình](#6-chia-sẻ--gia-đình)
7. [Gamification](#7-gamification)
8. [Xã hội & Viral](#8-xã-hội--viral)
9. [Tích hợp & Kết nối](#9-tích-hợp--kết-nối)
10. [Đầu tư & Tài sản](#10-đầu-tư--tài-sản)
11. [UX & Tiện lợi](#11-ux--tiện-lợi)
12. [Tâm lý & Hành vi ⭐ Mới](#12-tâm-lý--hành-vi)
13. [Mô phỏng & Dự báo ⭐ Mới](#13-mô-phỏng--dự-báo)
14. [Tiết kiệm tự động ⭐ Mới](#14-tiết-kiệm-tự-động)
15. [Xã hội & Địa lý ⭐ Mới](#15-xã-hội--địa-lý)
16. [Đề xuất Pricing](#16-đề-xuất-pricing)
17. [Lộ trình phát triển](#17-lộ-trình-phát-triển)

---

## Chú thích mức độ ưu tiên

| Ký hiệu | Ý nghĩa |
|---|---|
| 🟢 | Nên có ở free tier |
| 🟡 | Tính năng trả phí (Pro) |
| 🔴 | Khó làm, cần nhiều thời gian |
| 🔵 | Tính năng viral / tăng trưởng |

---

## 1. Tính năng cốt lõi (Free tier)

Đây là những tính năng **bắt buộc phải có** để user không xoá app trong tuần đầu tiên.

### 1.1 Nhập giao dịch thủ công 🟢
Cho phép user nhập thu nhập và chi tiêu với các thông tin: số tiền, danh mục, ngày giờ, ghi chú, ảnh hoá đơn. Hỗ trợ nhập nhanh từ màn hình chính không cần mở nhiều bước.

### 1.2 Phân danh mục 🟢
Các danh mục mặc định: Ăn uống, Đi lại, Nhà ở, Giải trí, Sức khoẻ, Giáo dục, Mua sắm, Khác. Cho phép tạo danh mục tuỳ chỉnh với icon và màu sắc riêng.

### 1.3 Tổng quan tháng 🟢
Dashboard hiển thị: tổng thu nhập, tổng chi tiêu, số dư còn lại, biểu đồ tròn phân bổ chi tiêu theo danh mục, danh sách giao dịch gần nhất.

### 1.4 Ngân sách theo danh mục 🟢
Đặt giới hạn chi tiêu cho từng danh mục mỗi tháng. Hiển thị thanh tiến độ trực quan. Cảnh báo khi đạt 80% và khi vượt ngân sách.

### 1.5 Lịch sử giao dịch 🟢
Xem lại giao dịch theo ngày, tuần, tháng. Tìm kiếm theo từ khoá, lọc theo danh mục và khoảng thời gian. Lưu trữ tối thiểu 3 tháng gần nhất ở bản free.

### 1.6 Chủ đề & Dark mode 🟢
Hỗ trợ giao diện sáng và tối theo cài đặt hệ thống. Cho phép đổi màu accent và icon app. Tính năng nhỏ nhưng user rất thích cá nhân hoá.

---

## 2. Tự động hoá

Đây là nhóm tính năng quan trọng nhất để giữ user dài hạn — vì lý do số 1 khiến user bỏ app chi tiêu là lười nhập tay.

### 2.1 Đọc SMS ngân hàng 🔴
Tự động đọc và parse tin nhắn SMS từ các ngân hàng Việt Nam (Vietcombank, Techcombank, MB Bank, BIDV, VPBank...). Tự động tạo giao dịch với số tiền, tên người nhận/gửi và phân loại danh mục sơ bộ. Đây là **tính năng killer** cho thị trường Việt Nam nơi chuyển khoản qua SMS rất phổ biến.

### 2.2 OCR chụp hoá đơn 🟡
Chụp ảnh hoá đơn giấy hoặc hoá đơn điện tử → app tự nhận diện số tiền, tên cửa hàng, ngày giờ bằng AI OCR. Giảm thời gian nhập tay đáng kể khi mua sắm.

### 2.3 Import sao kê ngân hàng PDF 🟡
Upload file PDF sao kê từ ngân hàng → app tự parse và nhập toàn bộ giao dịch trong tháng. Phù hợp để nhập dữ liệu lịch sử hoặc đồng bộ hàng tháng.

### 2.4 Subscription tracker 🟡
Tự động nhận diện các khoản phí định kỳ (Netflix, Spotify, iCloud, gym, phần mềm...) dựa trên pattern giao dịch lặp lại. Nhắc nhở trước ngày gia hạn 3–5 ngày. Hiển thị tổng chi phí subscription mỗi tháng.

### 2.5 Nhập bằng giọng nói 🟡
Nói "Ăn sáng 40 nghìn" hoặc "Grab đi làm 65 nghìn" → app tự parse số tiền và danh mục bằng AI. Không cần mở app đầy đủ, có thể nhập nhanh từ widget hoặc Siri.

---

## 3. AI & Phân tích thông minh

### 3.1 Phát hiện chi tiêu bất thường 🔴
So sánh chi tiêu hiện tại với trung bình lịch sử → cảnh báo khi có giao dịch bất thường về giá trị hoặc tần suất. Ví dụ: "Tháng này bạn chi Grab nhiều hơn 40% so với tháng trước." Cũng giúp phát hiện gian lận thẻ sớm.

### 3.2 Gợi ý cắt giảm thông minh 🟡
Phân tích pattern chi tiêu và đưa ra gợi ý cụ thể: "Nếu giảm cà phê từ 5 lần xuống 3 lần mỗi tuần, bạn tiết kiệm thêm 600.000 ₫/tháng." Gợi ý phải dựa trên dữ liệu thực, không chung chung.

### 3.3 Dự báo số dư cuối tháng 🟡
Dựa trên thói quen chi tiêu 3 tháng gần nhất và số ngày còn lại trong tháng → dự đoán số dư cuối tháng. Cảnh báo sớm nếu dự báo âm. Giúp user điều chỉnh hành vi trước khi quá muộn.

### 3.4 Phân tích theo thời gian 🟡
Nhận diện pattern theo ngày: "Bạn chi nhiều nhất vào thứ 6 và thứ 7." Theo giờ: "Chi tiêu đột biến sau 20h." Theo địa điểm nếu user cho phép dùng GPS. Giúp user hiểu sâu hơn về hành vi tiêu dùng.

### 3.5 AI chatbot tài chính cá nhân 🔴
Chat với AI để hỏi về tình hình tài chính của mình: "Tháng này tôi còn đủ tiền đi Đà Lạt không?", "Tôi nên cắt khoản nào để tiết kiệm thêm 2 triệu?" AI trả lời dựa trên dữ liệu thực của user.

---

## 4. Mục tiêu tài chính

### 4.1 Tạo mục tiêu tiết kiệm 🟡
Đặt mục tiêu có tên, số tiền cần đạt, thời hạn và ảnh minh hoạ (mua xe, du lịch, quỹ khẩn cấp, mua nhà...). App tự tính cần tiết kiệm bao nhiêu mỗi tháng để đạt mục tiêu đúng hạn.

### 4.2 Kết nối mục tiêu với chi tiêu thực 🟡
Khi user vượt ngân sách một danh mục, app hiển thị tác động cụ thể: "Bạn vừa chi vượt 500.000 ₫, mục tiêu mua xe sẽ bị lùi thêm 3 ngày." Tạo cảm giác trách nhiệm rõ ràng.

### 4.3 Quỹ khẩn cấp 🟡
Tính toán mức quỹ khẩn cấp phù hợp (thường là 3–6 tháng chi phí cố định). Theo dõi tiến độ và nhắc user nạp thêm hàng tháng. Đây là tính năng giáo dục tài chính giúp user trưởng thành hơn.

### 4.4 Mô phỏng nghỉ hưu 🟡
Dựa trên thu nhập, chi tiêu hiện tại, tỉ lệ tiết kiệm và lãi suất đầu tư trung bình → tính xem bao giờ user có đủ tiền nghỉ hưu. Điều chỉnh các biến số để thấy tác động trực quan.

---

## 5. Báo cáo nâng cao

### 5.1 Báo cáo so sánh tháng/năm 🟡
So sánh chi tiêu giữa các tháng, quý, năm với biểu đồ trực quan. Highlight những tháng chi nhiều bất thường và lý do (lễ, tết, du lịch...). Lịch sử không giới hạn cho bản Pro.

### 5.2 Xuất báo cáo PDF 🟡
Tạo báo cáo PDF đẹp tổng kết tháng/quý/năm với biểu đồ, bảng chi tiết theo danh mục. Hữu ích khi cần review tài chính cùng vợ/chồng hoặc kế toán cá nhân.

### 5.3 Benchmark ẩn danh 🟡
So sánh chi tiêu của mình với trung bình người dùng cùng thành phố, cùng độ tuổi, cùng mức thu nhập (dữ liệu ẩn danh tổng hợp). "Bạn chi cho ăn uống ít hơn 68% người dùng ở TP.HCM." Tạo cảm giác tham khảo thực tế.

### 5.4 Xuất dữ liệu CSV 🟡
Cho phép export toàn bộ dữ liệu giao dịch ra file CSV để user tự phân tích bằng Excel hoặc Google Sheets. Thể hiện sự minh bạch và tôn trọng dữ liệu người dùng.

---

## 6. Chia sẻ & Gia đình

### 6.1 Tài khoản gia đình / cặp đôi 🟡
Nhiều thành viên cùng nhập giao dịch vào một tài khoản chung. Dashboard chung hiển thị ai chi cái gì. Phù hợp cho vợ chồng muốn quản lý tài chính gia đình minh bạch.

### 6.2 Tách tiền nhóm 🔵
Đi du lịch hoặc ăn uống cùng bạn bè → nhập hoá đơn → app tự tính mỗi người phải trả bao nhiêu, ai đang nợ ai. Gửi link chia sẻ để người khác xem kết quả mà không cần tải app.

### 6.3 Phân quyền trong gia đình 🟡
Tài khoản chính (cha/mẹ) có thể đặt ngân sách cho từng thành viên. Thành viên phụ (con cái) chỉ xem được chi tiêu của mình. Phù hợp để quản lý tiền tiêu vặt cho con.

---

## 7. Gamification

### 7.1 Streak & điểm thưởng 🟢
Nhập giao dịch đủ mỗi ngày → duy trì streak. Điểm thưởng khi hoàn thành mục tiêu, không vượt ngân sách, dùng app đủ X ngày liên tiếp. Cơ chế giống Duolingo, tạo thói quen cực mạnh.

### 7.2 Huy hiệu & thành tích 🟢
Hệ thống huy hiệu: "Tiết kiệm được 10 triệu đầu tiên", "Dùng app 100 ngày", "Không vượt ngân sách 3 tháng liên tiếp"... Unlock huy hiệu mới thành lý do để tiếp tục dùng app.

### 7.3 Level tài chính 🟢
User bắt đầu ở cấp "Người mới — Ví rỗng", tích luỹ điểm qua hành vi tốt (tiết kiệm, không vượt ngân sách, nhập đủ giao dịch) để lên cấp cao hơn. Tạo cảm giác tiến bộ rõ ràng.

### 7.4 Weekly challenge 🟡
App đề xuất thử thách hàng tuần phù hợp với thói quen của user: "Tuần này không đặt đồ ăn online", "Đi làm bằng xe buýt 3 ngày". Hoàn thành → xem tiết kiệm được bao nhiêu tiền.

---

## 8. Xã hội & Viral

### 8.1 Chia sẻ Wrapped cuối tháng/năm 🔵
Cuối mỗi tháng và năm, tạo card đẹp tóm tắt tài chính cá nhân: danh mục chi nhiều nhất, số tiền tiết kiệm được, streak dài nhất... Thiết kế đẹp để dễ chia sẻ lên Instagram Story, Facebook. Đây là kênh marketing viral hiệu quả nhất với chi phí gần như bằng 0.

### 8.2 Thử thách tiết kiệm cộng đồng 🔵
Tham gia thử thách cùng người dùng khác: "Tháng 4 không mua đồ không cần thiết". Hiển thị leaderboard ẩn danh. Tạo cảm giác cộng đồng và accountability.

---

## 9. Tích hợp & Kết nối

### 9.1 iCloud Sync 🟡
Đồng bộ dữ liệu tự động giữa iPhone, iPad và Mac qua iCloud. Không mất dữ liệu khi đổi máy. Bảo mật end-to-end bằng mã hoá của Apple.

### 9.2 Apple Wallet & Apple Pay 🔴
Đồng bộ giao dịch Apple Pay và thẻ tín dụng đã liên kết với Apple Wallet. Không cần nhập tay bất kỳ giao dịch nào thực hiện qua Apple Pay.

### 9.3 Siri Shortcuts 🟡
Tạo shortcut Siri để nhập nhanh: "Này Siri, tôi vừa mua cà phê 45 nghìn" → app tự thêm vào danh mục Ăn uống. Cũng tích hợp với Siri để hỏi nhanh: "Tháng này tôi còn bao nhiêu tiền?"

### 9.4 Apple Watch 🟡
App companion trên Apple Watch: xem số dư ngân sách còn lại, nhập nhanh giao dịch phổ biến bằng vài tap từ cổ tay. Không cần lấy điện thoại ra.

### 9.5 Widget màn hình khoá & Home screen 🟡
Widget hiển thị số tiền đã chi hôm nay, ngân sách còn lại trong tháng ngay trên màn hình khoá và Home screen. Nhìn vào điện thoại là thấy ngay tình hình tài chính.

### 9.6 Live Activity 🟡
Khi đang trong ngày có nhiều giao dịch, hiển thị Live Activity ở Dynamic Island: tổng chi tiêu hôm nay cập nhật real-time.

---

## 10. Đầu tư & Tài sản

### 10.1 Theo dõi tài sản & Net worth 🟡
Nhập các tài sản: tiền tiết kiệm, cổ phiếu, bất động sản, tiền mặt, tiền vay... → tính net worth tổng. Theo dõi net worth tăng trưởng qua từng tháng. Đây là tính năng giúp user thấy "bức tranh toàn cảnh" tài chính.

### 10.2 Danh mục đầu tư 🔴
Nhập danh mục cổ phiếu, chứng chỉ quỹ → tự động lấy giá thị trường và tính lãi/lỗ theo thời gian thực. Phân tích phân bổ tài sản và đề xuất tái cân bằng.

### 10.3 Theo dõi nợ & khoản vay 🟡
Nhập các khoản vay (mua nhà, mua xe, vay tiêu dùng...) với lãi suất và kỳ hạn. App tính lịch trả nợ, tổng lãi phải trả và đề xuất trả thêm để tiết kiệm lãi.

---

## 11. UX & Tiện lợi

### 11.1 Tìm kiếm thông minh 🟢
Tìm kiếm giao dịch bằng từ khoá tự nhiên: "cà phê tuần trước", "Grab tháng 3". AI hiểu ngữ nghĩa, không cần nhớ đúng tên danh mục hay ngày chính xác.

### 11.2 Mẫu giao dịch thường gặp 🟢
Lưu các giao dịch thường xuyên làm mẫu (tiền nhà, tiền điện, cà phê sáng...). Một tap để nhập lại mà không cần điền lại thông tin. Tiết kiệm đáng kể thời gian nhập liệu hàng ngày.

### 11.3 Nhắc nhở thông minh 🟡
Nhắc nhở nhập giao dịch vào cuối ngày nếu hôm nay chưa nhập gì. Nhắc khi sắp hết ngân sách. Nhắc khi gần đến ngày trả các khoản định kỳ. Tất cả có thể tuỳ chỉnh hoặc tắt.

### 11.4 Onboarding cá nhân hoá 🟢
Khi mới dùng app, hỏi vài câu đơn giản: thu nhập hàng tháng, các danh mục chi tiêu chính, mục tiêu tài chính → tự động đặt ngân sách gợi ý phù hợp. Giảm ma sát ban đầu đáng kể.

### 11.5 Haptic feedback & Animation 🟢
Phản hồi xúc giác và animation mượt mà khi thêm giao dịch, hoàn thành mục tiêu, nhận huy hiệu. Tạo trải nghiệm "thỏa mãn" khi dùng app hàng ngày.

---

## 12. Tâm lý & Hành vi

> Đây là nhóm tính năng **chưa app nào khai thác tốt** — kết hợp tâm lý học hành vi với tài chính cá nhân. Khác biệt lớn nhất so với các đối thủ.

### 12.1 Spending mood journal 🟡
Sau mỗi giao dịch lớn (trên ngưỡng nhất định), app hỏi nhẹ nhàng: "Bạn đang cảm thấy thế nào?" với 4–5 lựa chọn cảm xúc đơn giản (vui, bình thường, stress, buồn). Sau 2–3 tháng, app phân tích correlation và hiển thị insight: "Bạn chi nhiều hơn 60% vào những ngày stress." Đây là giao điểm giữa mental health và finance — không app nào đang làm tốt điều này. Tính cá nhân hoá cực cao, khó bỏ app vì insight ngày càng chính xác hơn theo thời gian.

### 12.2 Regret score 🟡
7 ngày sau một giao dịch lớn, app gửi notification nhẹ nhàng: "Bạn mua cái áo 800.000 ₫ tuần trước — bây giờ cảm thấy thế nào?" User chấm điểm từ 1–5 sao. App học pattern theo thời gian: loại giao dịch nào user hay hối tiếc (thời trang, đồ ăn tối muộn, mua sắm online...) → lần sau cảnh báo trước khi bấm lưu: "Lần trước mua tương tự bạn đã hối tiếc." Tính năng "self-awareness" độc đáo — không app chi tiêu nào trên thế giới đang có.

### 12.3 Money personality 🔵
Sau 1 tháng dùng app, phân tích toàn bộ pattern giao dịch và xếp user vào một trong các "kiểu tài chính": The Planner (chi có kế hoạch, ít bốc đồng), The Impulsive (mua sắm bốc đồng, hay vượt ngân sách), The Minimalist (chi rất ít, tiết kiệm cao), The Foodie (ăn uống chiếm 40%+), The Experience Seeker (ưu tiên giải trí và du lịch hơn đồ vật)... Mỗi type có lời khuyên riêng, huy hiệu riêng và câu tagline hài hước. Cực kỳ shareable — user sẽ chia sẻ lên story để so sánh với bạn bè. Đây là kênh marketing viral tự nhiên với chi phí gần bằng 0.

---

## 13. Mô phỏng & Dự báo

> Nhóm tính năng tạo "khoảnh khắc wow" — user thấy ngay tác động của quyết định tài chính trong tương lai.

### 13.1 What-if simulator 🟡
Màn hình tương tác cho phép thay đổi các biến số và xem kết quả ngay lập tức: "Nếu tôi tăng lương thêm 5 triệu → tiết kiệm thêm được bao nhiêu?", "Nếu bỏ Netflix + Spotify → dư ra X triệu/năm", "Nếu giảm ăn ngoài xuống 3 lần/tuần → đạt mục tiêu mua xe sớm hơn bao nhiêu tháng?" Dùng Metal để animation số thay đổi mượt mà real-time theo từng điều chỉnh slider. Đây là tính năng "aha moment" — user thấy ngay tác động của từng quyết định nhỏ trong cuộc sống hàng ngày.

### 13.2 Future self letter 🟡
Mỗi quý, app dùng AI để viết một "bức thư từ tương lai" dựa trên thói quen chi tiêu hiện tại: nếu tiếp tục như vậy thì cuộc sống năm 60 tuổi sẽ như thế nào. Nếu tài chính lành mạnh: thư lạc quan và chi tiết về sự tự do tài chính. Nếu chi tiêu mất kiểm soát: thư cảnh báo nhưng không phán xét — chỉ phác hoạ viễn cảnh thực tế. Tính năng này tạo cảm xúc mạnh và ghi nhớ lâu. Kết hợp với goal-setting để tạo lộ trình thay đổi cụ thể ngay sau khi đọc thư.

### 13.3 Spending calendar 🟡
Calendar view hiển thị trên mỗi ngày: số tiền đã chi thực tế với màu sắc cho biết hôm đó chi nhiều hay ít so với trung bình cá nhân. Các ngày tương lai hiển thị chi tiêu dự báo dựa trên subscription đã phát hiện và pattern lặp lại (tiền điện ngày 15, tiền nhà ngày 1, sinh nhật bạn...). User nhìn vào calendar thấy ngay "tuần tới sẽ tốn nhiều vì có tiền nhà và sinh nhật". Giúp chuẩn bị tài chính chủ động thay vì bị động xử lý sau.

---

## 14. Tiết kiệm tự động

> Nhóm tính năng giúp user tiết kiệm mà không cảm thấy đau — đây là lý do mạnh nhất để trả tiền cho app.

### 14.1 Round-up tiết kiệm 🟡
Mỗi khi nhập giao dịch (ví dụ 85.000 ₫ tiền phở), app tự động làm tròn lên 100.000 ₫ và bỏ 15.000 ₫ vào một "heo đất" ảo gắn với mục tiêu tiết kiệm đang chọn. User không cảm thấy mất tiền vì số tiền mỗi lần rất nhỏ, nhưng cuối tháng tích luỹ được 300.000–500.000 ₫ một cách hoàn toàn tự động. Acorns (app Mỹ) xây dựng cả công ty tỉ đô từ cơ chế tương tự này.

### 14.2 No-spend day tracker 🟢
Mỗi ngày không chi tiêu ngoài các khoản thiết yếu cố định (nhà, điện, nước...) được tính là một "no-spend day" và hiển thị màu xanh trên calendar. App duy trì streak, gửi congratulation khi đạt milestone, và tổng kết cuối tháng: "Bạn có 12 ngày no-spend, tiết kiệm được ước tính 1.200.000 ₫." Cực kỳ gamified — user sẽ cố không xài tiền chỉ để giữ streak xanh trên calendar. Hành vi tốt được tạo ra tự nhiên từ game mechanics đơn giản.

### 14.3 Guilt-free budget 🟡
Sau khi nhập thu nhập và trừ đi tất cả khoản cố định (nhà, điện, tiết kiệm mục tiêu, quỹ khẩn cấp...), app tự động tính ra "Tiền tự do tháng này: 2.300.000 ₫ — xài thoải mái, không cần lo gì thêm." Hiển thị màu xanh tươi, không có cảnh báo nào trong khoản này. Tâm lý học cho thấy người ta chi tiêu có kiểm soát hơn khi biết rõ giới hạn an toàn. Đây là triết lý hoàn toàn ngược với các app chi tiêu truyền thống — thay vì chỉ cảnh báo và phán xét, app nói "bạn đã lo đủ rồi, cứ tận hưởng đi."

---

## 15. Xã hội & Địa lý

> Nhóm tính năng tạo context địa lý và xã hội cho chi tiêu — hiển thị dữ liệu theo cách chưa ai nghĩ đến.

### 15.1 Spending map 🟡
Nếu user cho phép dùng GPS (hoặc nhập địa điểm thủ công), app vẽ heatmap trực quan trên bản đồ thành phố: khu vực nào user hay chi tiêu và tốn bao nhiêu tiền. "40% tổng chi tiêu của bạn ở Quận 1." Có thể lọc theo danh mục: chỉ hiện ăn uống, chỉ hiện mua sắm, chỉ hiện giải trí. Dùng MapKit của Apple để render mượt mà. Rất thú vị để khám phá bản thân và là tính năng không app chi tiêu nào đang có ở thị trường Việt Nam.

### 15.2 Seasonal planner 🟡
App phân tích lịch sử nhiều năm và tự động phát hiện các "mùa chi nhiều" của từng user cụ thể: Tết Nguyên Đán (quà, phong bì, về quê), tháng 8–9 (học phí năm học mới), tháng 11 (Black Friday, 11/11), sinh nhật người thân... Trước 4–6 tuần, app chủ động nhắc nhở và gợi ý để dành thêm bao nhiêu mỗi tuần: "Tết năm ngoái bạn chi 8 triệu — bạn có muốn bắt đầu để dành từ bây giờ không?" Tính năng chủ động thực sự hữu ích, không phải chỉ phản ứng sau khi đã xài.

### 15.3 Spending DNA 🔵
Cuối mỗi năm, app tạo ra một "báo cáo DNA tài chính" — một infographic độc nhất thể hiện toàn bộ cá tính tài chính của user trong năm qua: tỉ lệ các danh mục chi tiêu, con số ấn tượng nhất (giao dịch lớn nhất, tháng tiết kiệm nhất, streak dài nhất, tổng số cà phê uống...), money personality type, và một câu tagline được AI tạo riêng: "2025: Năm của kẻ mê cà phê nhưng biết tiết kiệm." Thiết kế đẹp như Spotify Wrapped — user muốn chia sẻ ngay. Đây là cỗ máy marketing viral tự nhiên mỗi năm một lần với chi phí gần bằng 0.

---

## 16. Đề xuất Pricing

| Gói | Giá | Tính năng chính |
|---|---|---|
| **Free** | 0 ₫ | Nhập tay, ngân sách cơ bản, biểu đồ đơn giản, lịch sử 3 tháng, dark mode, gamification cơ bản |
| **Pro** | 49.000 ₫/tháng hoặc 399.000 ₫/năm | Tất cả tính năng tự động hoá, AI insight, báo cáo nâng cao, iCloud sync, widget, Apple Watch, lịch sử không giới hạn |
| **Family** | 79.000 ₫/tháng hoặc 599.000 ₫/năm | Tất cả tính năng Pro + chia sẻ tối đa 5 người, tài khoản gia đình, phân quyền thành viên |

> Gợi ý: Dùng mô hình **freemium với paywall thông minh** — cho user trải nghiệm đủ giá trị ở free tier, sau đó upsell khi user đã có thói quen dùng app (thường sau 2–4 tuần).

---

## 17. Lộ trình phát triển

### Giai đoạn 1 — MVP (tuần 1–5)
Hoàn thiện free tier: nhập tay, ngân sách, dashboard, dark mode, no-spend day tracker. Mục tiêu: user dùng đều đặn 2–4 tuần.

### Giai đoạn 2 — Killer feature (tuần 6–10)
Tích hợp đọc SMS ngân hàng và OCR hoá đơn. Đây là lý do chính để user nâng cấp lên Pro.

### Giai đoạn 3 — Retention (tuần 11–14)
AI insight, dự báo chi tiêu, mục tiêu tài chính, gamification đầy đủ, guilt-free budget, round-up tiết kiệm. Tạo habit dài hạn, user khó bỏ.

### Giai đoạn 4 — Differentiation (tuần 15–18)
Spending mood journal, regret score, what-if simulator, spending calendar. Đây là các tính năng tạo sự khác biệt thực sự so với mọi đối thủ trên thị trường.

### Giai đoạn 5 — Growth (tuần 19–22)
Money personality, spending DNA, chia sẻ Wrapped, thử thách cộng đồng, tách tiền nhóm. Tạo kênh viral tự nhiên không tốn chi phí marketing.

### Giai đoạn 6 — Expansion (tháng 6+)
Family plan, theo dõi tài sản, tích hợp Apple Watch, spending map, seasonal planner, danh mục đầu tư, future self letter. Mở rộng thị trường và tăng revenue per user.

---

## Những sai lầm cần tránh

- Làm quá nhiều tính năng ngay từ đầu → phức tạp, user bỏ sớm
- Không có free tier hấp dẫn → user không bao giờ thử
- Paywall quá sớm trước khi user thấy giá trị → uninstall ngay
- Thiếu tính năng tự động hoá → user lười nhập, bỏ app sau 2 tuần
- Bỏ qua onboarding → user không biết dùng tính năng hay, không thấy giá trị
- Chỉ làm tính năng giống đối thủ → không có lý do để user chuyển sang dùng app mình
- Bỏ qua nhóm tính năng tâm lý & hành vi → đây là điểm khác biệt lớn nhất so với thị trường hiện tại

---

*Tài liệu được tổng hợp cho dự án app quản lý chi tiêu SwiftUI + Metal — iOS.*
*Cập nhật lần cuối: tháng 4/2026 — thêm 4 nhóm tính năng mới: Tâm lý & Hành vi, Mô phỏng & Dự báo, Tiết kiệm tự động, Xã hội & Địa lý.*