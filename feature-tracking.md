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
- [ ] `2.3` Import sao kê ngân hàng PDF 🟡
- [ ] `2.4` Subscription tracker 🟡 - Một phần: đã có `SubscriptionDomain` phát hiện khoản lặp, kỳ hạn, ngày gia hạn kế tiếp và monthly total; thiếu UI/notification.
- [ ] `2.5` Nhập bằng giọng nói 🟡

## 3. AI & Phân tích thông minh

- [ ] `3.1` Phát hiện chi tiêu bất thường 🔴 - Một phần: đã có `InsightDomain` phát hiện giao dịch lớn và category spike; thiếu UI/cảnh báo.
- [ ] `3.2` Gợi ý cắt giảm thông minh 🟡
- [ ] `3.3` Dự báo số dư cuối tháng 🟡
- [ ] `3.4` Phân tích theo thời gian 🟡
- [ ] `3.5` AI chatbot tài chính cá nhân 🔴

## 4. Mục tiêu tài chính

- [ ] `4.1` Tạo mục tiêu tiết kiệm 🟡 - Một phần: onboarding có chọn financial goal, chưa có CRUD goal với số tiền/thời hạn/ảnh.
- [ ] `4.2` Kết nối mục tiêu với chi tiêu thực 🟡
- [ ] `4.3` Quỹ khẩn cấp 🟡
- [ ] `4.4` Mô phỏng nghỉ hưu 🟡

## 5. Báo cáo nâng cao

- [ ] `5.1` Báo cáo so sánh tháng/năm 🟡
- [ ] `5.2` Xuất báo cáo PDF 🟡
- [ ] `5.3` Benchmark ẩn danh 🟡
- [ ] `5.4` Xuất dữ liệu CSV 🟡 - Một phần: đã có `TransactionCSVExporter` domain; thiếu UI share/export file.

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

- [ ] `10.1` Theo dõi tài sản & Net worth 🟡
- [ ] `10.2` Danh mục đầu tư 🔴
- [ ] `10.3` Theo dõi nợ & khoản vay 🟡

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
- [ ] `14.2` No-spend day tracker 🟢 - Một phần: đã có `WellnessDomain` tính no-spend days/current streak/longest streak; thiếu UI.
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
- [ ] `17.3` Hours of life converter 🟢
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
- [x] Domain foundation cho subscription detection, anomaly detection, CSV export và no-spend tracking.
