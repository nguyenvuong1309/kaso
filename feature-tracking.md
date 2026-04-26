# Kaso Feature Tracking

> Checklist theo `plan.md` để theo dõi tính năng đã làm và chưa làm.
> Cập nhật: 2026-04-26.

## Quy ước

- `[x]` Đã làm: feature đã có implementation end-to-end theo đúng phạm vi trong `plan.md`.
- `[ ]` Chưa xong: chưa có, hoặc mới có một phần nên chưa đủ để tick.
- Ghi chú "Một phần" nghĩa là repo đã có nền tảng code nhưng chưa đủ scope của feature.

## Tổng quan hiện tại

- [x] `1.3` Tổng quan tháng: đã có summary thu/chi/số dư, pie chart theo danh mục và danh sách giao dịch gần đây.
- [x] `11.4` Onboarding cá nhân hoá: đã hỏi thu nhập, danh mục chính, mục tiêu và gợi ý ngân sách.
- [x] `1.1` Nhập giao dịch thủ công: đã có form thu/chi với số tiền, danh mục, ngày giờ, ghi chú, ảnh hoá đơn và nút nhập nhanh từ màn hình chính.
- [x] `1.2` Phân danh mục: đã có danh mục mặc định và tạo danh mục tuỳ chỉnh với icon/màu riêng, lưu mã hoá.
- [x] `1.4` Ngân sách theo danh mục: đã có đặt giới hạn thủ công, lưu mã hoá, progress bar và cảnh báo trực quan khi gần/vượt ngân sách.
- [x] `1.5` Lịch sử giao dịch: đã có danh sách lưu bền vững, tìm kiếm, lọc danh mục, lọc ngày/tuần/tháng và nhóm theo ngày.
- [x] `1.6` Chủ đề & Dark mode: đã có chọn system/light/dark, đổi accent và cập nhật icon chính.
- [x] `2.2` OCR chụp hoá đơn: đã đọc ảnh hoá đơn bằng Apple Vision, parse số tiền/ngày/tên cửa hàng và tự điền form giao dịch.
- [x] `2.3` Import sao kê ngân hàng PDF: đã đọc PDF bằng PDFKit, parse giao dịch sao kê và import vào lịch sử.
- [x] `2.4` Subscription tracker: đã phát hiện khoản định kỳ, hiển thị dashboard và đặt local notification trước ngày gia hạn.
- [x] `2.5` Nhập bằng giọng nói: đã dùng Apple Speech/microphone để nhận transcript, parse câu tiếng Việt và tự điền form giao dịch.
- [x] `3.1` Phát hiện chi tiêu bất thường: đã có dashboard cảnh báo giao dịch lớn và category spike dựa trên lịch sử.
- [x] `3.2` Gợi ý cắt giảm thông minh: đã phân tích baseline chi tiêu cục bộ và đưa ra mục tiêu tiết kiệm cụ thể trên dashboard.
- [x] `3.3` Dự báo số dư cuối tháng: đã dự báo chi tiêu/số dư dựa trên nhịp chi hiện tại và lịch sử 3 tháng.
- [x] `3.4` Phân tích theo thời gian: đã nhận diện ngày/giờ chi tiêu cao và đột biến sau 20h trên dashboard, xử lý cục bộ không thu GPS.
- [x] `4.1` Tạo mục tiêu tiết kiệm: đã có CRUD mục tiêu tiết kiệm, progress/status trên dashboard và persistence mã hoá.
- [x] `4.2` Kết nối mục tiêu với chi tiêu thực: đã hiển thị tác động ngày chậm mục tiêu khi danh mục vượt ngân sách.
- [x] `4.3` Quỹ khẩn cấp: đã gợi ý quỹ 6 tháng chi phí, coverage hiện tại và mức nên nạp hàng tháng.
- [x] `4.4` Mô phỏng nghỉ hưu: đã mô phỏng mục tiêu tài sản, số năm tới mục tiêu và giả định lợi suất/hệ số ngay trên dashboard.
- [x] `5.1` Báo cáo so sánh tháng/năm: đã so sánh chi tiêu tháng hiện tại và YTD với kỳ trước/cùng kỳ năm trước.
- [x] `5.2` Xuất báo cáo PDF: đã tạo báo cáo PDF cục bộ gồm summary tháng, phân bổ danh mục, forecast, so sánh kỳ và giao dịch gần đây.
- [x] `5.4` Xuất dữ liệu CSV: đã có domain exporter và ShareLink export CSV từ dashboard.
- [x] `10.1` Theo dõi tài sản & Net worth: đã có tab tài sản ròng, nhập tài sản/khoản nợ, lưu mã hoá, breakdown và lịch sử tăng trưởng tháng.
- [x] `10.3` Theo dõi nợ & khoản vay: đã có CRUD khoản vay, lịch trả nợ, tổng dư nợ/lãi phải trả, mô phỏng trả thêm và tự đồng bộ liability vào net worth.
- [x] `14.2` No-spend day tracker: đã có streak, day dots, milestone chúc mừng và ước tính tiền tiết kiệm theo ngày không chi.

## 1. Tính năng cốt lõi (Free tier)

- [x] `1.1` Nhập giao dịch thủ công 🟢 - Đã có form thêm giao dịch, ngày giờ, ghi chú, ảnh hoá đơn và nút nhập nhanh từ màn hình chính.
- [x] `1.2` Phân danh mục 🟢 - Đã có danh mục mặc định và tạo danh mục tuỳ chỉnh với icon/màu riêng, lưu mã hoá.
- [x] `1.3` Tổng quan tháng 🟢 - Đã có dashboard tháng với thu/chi/số dư, pie chart và giao dịch gần đây.
- [x] `1.4` Ngân sách theo danh mục 🟢 - Đã có flow đặt giới hạn thủ công, persistence mã hoá, progress/status gần giới hạn và vượt ngân sách.
- [x] `1.5` Lịch sử giao dịch 🟢 - Đã có list, persistence mã hoá, search, filter danh mục/thời gian và grouping theo ngày.
- [x] `1.6` Chủ đề & Dark mode 🟢 - Đã có chọn system/light/dark, đổi accent, lưu tuỳ chọn và cập nhật icon chính theo scope một icon.

## 2. Tự động hoá

- [ ] `2.1` Đọc SMS ngân hàng 🔴 - Bị chặn trên iOS public API vì app không được đọc SMS của user.
- [x] `2.2` OCR chụp hoá đơn 🟡 - Đã đọc ảnh bằng Vision, parse số tiền/ngày/tên cửa hàng, lưu ảnh mã hoá và tự điền form giao dịch.
- [x] `2.3` Import sao kê ngân hàng PDF 🟡 - Đã đọc text từ PDF bằng PDFKit, parse ngày/số tiền/thu-chi/danh mục sơ bộ và lưu giao dịch cục bộ.
- [x] `2.4` Subscription tracker 🟡 - Đã có `SubscriptionDomain`, dashboard hiển thị khoản lặp/monthly total/due-soon và local notification trước gia hạn không chứa PII.
- [x] `2.5` Nhập bằng giọng nói 🟡 - Đã có `VoiceTransactionParser`, Apple Speech client, quyền microphone/speech và nút điền form bằng giọng nói trong màn thêm giao dịch.

## 3. AI & Phân tích thông minh

- [x] `3.1` Phát hiện chi tiêu bất thường 🔴 - Đã có `InsightDomain` phát hiện giao dịch lớn/category spike và dashboard cảnh báo trực quan.
- [x] `3.2` Gợi ý cắt giảm thông minh 🟡 - Đã có `SpendingReductionSuggestionEngine` so sánh chi tiêu hiện tại với baseline 3 tháng và dashboard hiển thị mức có thể tiết kiệm.
- [x] `3.3` Dự báo số dư cuối tháng 🟡 - Đã có `MonthlyBalanceForecaster` dùng nhịp chi hiện tại + lịch sử 3 tháng để dự báo chi tiêu và số dư cuối tháng.
- [x] `3.4` Phân tích theo thời gian 🟡 - Đã có `TimeSpendingAnalyzer` nhận diện ngày/giờ chi tiêu cao và đột biến sau 20h; không thu GPS để giữ privacy mặc định.
- [ ] `3.5` AI chatbot tài chính cá nhân 🔴

## 4. Mục tiêu tài chính

- [x] `4.1` Tạo mục tiêu tiết kiệm 🟡 - Đã có `GoalDomain`, CRUD UI trên dashboard, progress/status và `EncryptedSavingGoalStore` lưu mã hoá.
- [x] `4.2` Kết nối mục tiêu với chi tiêu thực 🟡 - Đã tính số ngày mục tiêu bị chậm khi budget vượt hạn mức và hiển thị card tác động trên dashboard.
- [x] `4.3` Quỹ khẩn cấp 🟡 - Đã có `EmergencyFundPlanner`, card dashboard gợi ý target 6 tháng chi phí, coverage, phần còn thiếu và mức nên nạp hàng tháng.
- [x] `4.4` Mô phỏng nghỉ hưu 🟡 - Đã có `RetirementSimulator`, card dashboard tính target tài sản theo chi phí, savings rate, thời gian tới mục tiêu và input giả định lợi suất/hệ số.

## 5. Báo cáo nâng cao

- [x] `5.1` Báo cáo so sánh tháng/năm 🟡 - Đã có `SpendingComparisonReporter` và dashboard report so sánh tháng hiện tại với tháng trước, YTD với cùng kỳ năm trước.
- [x] `5.2` Xuất báo cáo PDF 🟡 - Đã có model report, SwiftUI PDF renderer bằng `ImageRenderer`, ShareLink export PDF từ dashboard và nội dung tạo cục bộ trên thiết bị.
- [ ] `5.3` Benchmark ẩn danh 🟡
- [x] `5.4` Xuất dữ liệu CSV 🟡 - Đã có `TransactionCSVExporter` domain và ShareLink export file CSV từ dashboard.

## 6. Chia sẻ & Gia đình

- [ ] `6.1` Tài khoản gia đình / cặp đôi 🟡
- [ ] `6.2` Tách tiền nhóm 🔵
- [ ] `6.3` Phân quyền trong gia đình 🟡

## 7. Gamification

- [ ] `7.1` Streak & điểm thưởng 🟢
- [ ] `7.2` Huy hiệu & thành tích 🟢
- [ ] `7.3` Level tài chính 🟢
- [ ] `7.4` Weekly challenge 🟡

## 8. Xã hội & Viral

- [ ] `8.1` Chia sẻ Wrapped cuối tháng/năm 🔵
- [ ] `8.2` Thử thách tiết kiệm cộng đồng 🔵

## 9. Tích hợp & Kết nối

- [ ] `9.1` iCloud Sync 🟡
- [ ] `9.2` Apple Wallet & Apple Pay 🔴
- [ ] `9.3` Siri Shortcuts 🟡
- [ ] `9.4` Apple Watch 🟡
- [ ] `9.5` Widget màn hình khoá & Home screen 🟡
- [ ] `9.6` Live Activity 🟡

## 10. Đầu tư & Tài sản

- [x] `10.1` Theo dõi tài sản & Net worth 🟡 - Đã có `WealthDomain`, `WealthFeature`, encrypted stores cho asset/liability/snapshot, tab tài sản ròng, CRUD tài sản/khoản nợ, breakdown theo loại và lịch sử net worth 6 tháng.
- [ ] `10.2` Danh mục đầu tư 🔴
- [x] `10.3` Theo dõi nợ & khoản vay 🟡 - Đã có `DebtDomain`, `DebtFeature`, encrypted debt store, CRUD khoản vay, amortization schedule, tổng lãi/khoản trả hàng tháng, mô phỏng trả thêm và sync auto-tracked liability vào net worth.

## 11. UX & Tiện lợi

- [ ] `11.1` Tìm kiếm thông minh 🟢
- [ ] `11.2` Mẫu giao dịch thường gặp 🟢
- [ ] `11.3` Nhắc nhở thông minh 🟡
- [x] `11.4` Onboarding cá nhân hoá 🟢 - Đã có flow thu nhập, danh mục, mục tiêu và gợi ý ngân sách.
- [x] `11.5` Haptic feedback & Animation 🟢 - Đã có animation dashboard/list/chart, Reduce Motion fallback và success haptic cho transaction/budget/category save.

## 12. Tâm lý & Hành vi

- [ ] `12.1` Spending mood journal 🟡
- [ ] `12.2` Regret score 🟡
- [ ] `12.3` Money personality 🔵

## 13. Mô phỏng & Dự báo

- [ ] `13.1` What-if simulator 🟡
- [ ] `13.2` Future self letter 🟡
- [ ] `13.3` Spending calendar 🟡

## 14. Tiết kiệm tự động

- [ ] `14.1` Round-up tiết kiệm 🟡
- [x] `14.2` No-spend day tracker 🟢 - Đã có `WellnessDomain`, dashboard current/longest streak + day dots, milestone chúc mừng và ước tính tiết kiệm dựa trên ngày có chi tiêu trung bình.
- [ ] `14.3` Guilt-free budget 🟡

## 15. Xã hội & Địa lý

- [ ] `15.1` Spending map 🟡
- [ ] `15.2` Seasonal planner 🟡
- [ ] `15.3` Spending DNA 🔵

## 16. Văn hoá & Đặc thù Việt Nam

- [ ] `16.1` Lì xì & đám hỉ tracker 🟢
- [ ] `16.2` Hụi/họ tracker 🟡
- [ ] `16.3` BNPL exposure tracker 🟡
- [ ] `16.4` Cộng đồng giá địa phương 🔵

## 17. Tâm lý mở rộng

- [ ] `17.1` Cooling-off period cho mua bốc đồng 🟡
- [ ] `17.2` Phantom expense ledger 🟢
- [ ] `17.3` Hours of life converter 🟢 - Một phần: đã có `WellnessDomain` quy đổi số tiền sang giờ/phút làm việc; thiếu UI và cấu hình thu nhập/giờ làm.
- [ ] `17.4` Money therapist mode 🟡

## 18. Ngách chuyên biệt & Wellness

- [ ] `18.1` Money compatibility test cho cặp đôi 🔵
- [ ] `18.2` Freelancer income smoothing 🟡
- [ ] `18.3` Sleep × spending correlation 🟡
- [ ] `18.4` Digital financial legacy 🔴

## 19. Pricing

- [ ] Free tier
- [ ] Pro tier
- [ ] Family tier
- [ ] Paywall thông minh

## 20. Lộ trình phát triển

- [ ] Giai đoạn 1 - MVP: Một phần, đã có onboarding, dashboard, nhập giao dịch thủ công đầy đủ, phân danh mục tuỳ chỉnh, ngân sách theo danh mục, lịch sử giao dịch, chủ đề/dark mode và persistence mã hoá.
- [ ] Giai đoạn 2 - Killer feature
- [ ] Giai đoạn 3 - Retention
- [ ] Giai đoạn 4 - Differentiation
- [ ] Giai đoạn 5 - Growth
- [ ] Giai đoạn 6 - Expansion

## Nền tảng đã có ngoài checklist feature

- [x] Auth flow với `AuthFeature` và `KeychainAuthSessionStore`.
- [x] Root composition `Auth -> Onboarding -> Transaction`.
- [x] Design tokens cơ bản trong `KasoDesignSystem`.
- [x] Test reducer/domain cho các module hiện có.
- [x] Persistence giao dịch thật sự: app dùng `EncryptedTransactionStore` với file mã hoá và key trong Keychain.
- [x] Domain foundation cho subscription detection, anomaly detection, CSV export, no-spend tracking, saving goals và hours-of-life conversion.
