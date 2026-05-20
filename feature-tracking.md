# Kaso Feature Tracking

> Checklist theo `plan.md` để theo dõi tính năng đã làm và chưa làm.
> Cập nhật: 2026-05-18.

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
- [x] `3.5` AI chatbot tài chính cá nhân: đã có trợ lý tài chính privacy-first dạng chat, phân loại câu hỏi cục bộ, trả lời dựa trên giao dịch thật, số dư dự báo, danh mục chi nhiều và gợi ý cắt giảm; không gửi PII lên cloud AI.
- [x] `4.1` Tạo mục tiêu tiết kiệm: đã có CRUD mục tiêu tiết kiệm, progress/status trên dashboard và persistence mã hoá.
- [x] `4.2` Kết nối mục tiêu với chi tiêu thực: đã hiển thị tác động ngày chậm mục tiêu khi danh mục vượt ngân sách.
- [x] `4.3` Quỹ khẩn cấp: đã gợi ý quỹ 6 tháng chi phí, coverage hiện tại và mức nên nạp hàng tháng.
- [x] `4.4` Mô phỏng nghỉ hưu: đã mô phỏng mục tiêu tài sản, số năm tới mục tiêu và giả định lợi suất/hệ số ngay trên dashboard.
- [x] `5.1` Báo cáo so sánh tháng/năm: đã so sánh chi tiêu tháng hiện tại và YTD với kỳ trước/cùng kỳ năm trước.
- [x] `5.2` Xuất báo cáo PDF: đã tạo báo cáo PDF cục bộ gồm summary tháng, phân bổ danh mục, forecast, so sánh kỳ và giao dịch gần đây.
- [x] `5.3` Benchmark ẩn danh: đã có sheet benchmark privacy-first, so sánh chi tiêu tháng hiện tại với median cohort bundled theo thành phố/tuổi/thu nhập, không upload dữ liệu cá nhân.
- [x] `5.4` Xuất dữ liệu CSV: đã có domain exporter và ShareLink export CSV từ dashboard.
- [x] `10.1` Theo dõi tài sản & Net worth: đã có tab tài sản ròng, nhập tài sản/khoản nợ, lưu mã hoá, breakdown và lịch sử tăng trưởng tháng.
- [x] `10.3` Theo dõi nợ & khoản vay: đã có CRUD khoản vay, lịch trả nợ, tổng dư nợ/lãi phải trả, mô phỏng trả thêm và tự đồng bộ liability vào net worth.
- [x] `14.2` No-spend day tracker: đã có streak, day dots, milestone chúc mừng và ước tính tiền tiết kiệm theo ngày không chi.
- [x] `17.2` Phantom expense ledger: đã có sổ khoản suýt tiêu, tổng kết tháng, breakdown danh mục, CRUD và persistence mã hoá.
- [x] `17.3` Hours of life converter: đã có tab Wellness gom HoursOfLifeFeature + PhantomExpenseFeature, cấu hình thu nhập thực nhận/giờ làm, calculator quy đổi và danh sách giao dịch gần đây quy ra giờ làm; fallback từ onboarding income khi chưa cấu hình; lưu mã hoá keychain.
- [x] `18.1` Money compatibility test cho cặp đôi: đã có domain scoring 6 chiều, quiz self/partner bằng TCA, result insight, conversation starters, share card 9:16 và ghép vào tab Wellness.
- [x] `18.2` Freelancer income smoothing: đã có domain rolling-average, quỹ đệm, tax provision, reminder, encrypted persistence, TCA dashboard và ghép vào tab Wellness.
- [x] `18.3` Sleep × spending correlation: đã có analyzer Pearson on-device, HealthKit sleep client, privacy disclaimer, scatter/breakdown UI, period filter và ghép vào tab Wellness.
- [x] `18.4` Digital financial legacy: đã có vault mã hoá cục bộ, Face ID/passcode auth client, CRUD tài khoản, hướng dẫn gia đình, export `.kasovault` mã hoá password và ghép vào tab Wellness.
- [x] `7.1` Streak & điểm thưởng: đã có `GamificationDomain`, calculator on-device tính streak/level từ giao dịch và budget, encrypted profile store, `GamificationFeature` TCA, dashboard với streak ring, điểm thưởng, milestone grid, recent rewards và alert chúc mừng khi đạt milestone; ghép vào tab Wellness.
- [x] `7.2` Huy hiệu & thành tích: đã có `Achievement`, `AchievementCalculator` on-device đánh giá 13 huy hiệu chia 4 nhóm (consistency/discipline/explorer/rewardTier), tích hợp vào `GamificationCalculator.evaluate`, persistence backward-compat trong `GamificationProfile`, card grid theo nhóm với progress bar, alert chúc mừng khi mở huy hiệu mới và queue dismiss nhiều huy hiệu cùng lúc.
- [x] `7.3` Level tài chính: đã có `FinancialLevel` 7 hạng (sprout → bronze → silver → gold → platinum → diamond → legend) theo XP từ `totalPoints`, `FinancialLevelProgress` tính tỉ lệ và XP còn lại tới hạng kế, tích hợp vào `GamificationCalculator` với `lastNotifiedFinancialLevel` để chỉ celebrate khi lên hạng thực sự (không spam cho user cũ), card mới ở đầu dashboard với badge gradient, perk text và progress bar, alert "Lên hạng tài chính" priority cao nhất so với milestone/achievement.
- [x] `12.1` Spending mood journal: đã có `MoodJournalDomain` (Mood, MoodEntry, MoodInsight, MoodJournalRepository), `MoodJournalFeature` TCA với CRUD entry, insight correlation, editor sheet; ghép vào tab Wellness section `.moodJournal`.
- [x] `12.2` Regret score: đã có `RegretScoreDomain` (RegretRating, RegretReminderBuilder, RegretSummary), `RegretScoreFeature` TCA với reminder 7 ngày sau giao dịch lớn, editor, summary card; ghép vào tab Wellness section `.regretScore`.
- [x] `13.1` What-if simulator: đã có `WhatIfDomain` (WhatIfScenario, WhatIfCalculator), `WhatIfFeature` TCA với projection scenarios và visualization cards; ghép vào tab Wellness section `.whatIf`.
- [x] `13.3` Spending calendar: đã có `SpendingCalendarDomain` (SpendingCalendar, DailySpending, SpendingCalendarBuilder), `SpendingCalendarFeature` TCA với calendar màu theo mức chi, dự báo ngày tương lai; ghép vào tab Wellness section `.spendingCalendar`.
- [x] `7.4` Weekly challenge: đã có `WeeklyChallenge` + 5 loại (dailyStreak, noSpendDays, budgetKeeper, categoryVariety, incomeLogger), `WeeklyChallengeGenerator` rotate deterministic theo ISO week (Mon-first), `WeeklyChallengeEvaluator` tính progress từ transactions/rewardEvents trong tuần, tích hợp vào `GamificationCalculator` để re-evaluate active challenge → archive khi sang tuần mới (cap 12 tuần) → generate mới; reward bonus XP `weeklyChallengeCompleted` (80–200 XP tuỳ loại); UI card đặt sau Financial Level với progress bar, days remaining, badge completed; alert celebration ưu tiên sau Financial Level.
- [x] `11.2` Mẫu giao dịch thường gặp: đã có `TransactionTemplate` + `TransactionTemplateRepository`, `EncryptedTransactionTemplateStore` AES-GCM, `TransactionTemplateSheet` UI list/delete, nút "Dùng mẫu" + "Lưu làm mẫu" trong AddTransactionSheet.
- [x] `16.1` Lì xì & đám hỉ tracker: đã có `GiftTrackerDomain` (GiftRecord, 7 dịp, given/received, GiftPersonSummary, GiftYearlySummaryBuilder), `GiftTrackerFeature` TCA với CRUD, summary yearly + per-person history; persistence mã hoá `EncryptedGiftTrackerStore`; ghép vào tab Wellness.
- [x] `16.3` BNPL exposure tracker: đã có `BNPLDomain` (BNPLObligation, 7 nhà cung cấp Fundiin/Kredivo/Atome/Shopee PayLater/MoMo Postpaid/Home Credit/generic, installments monthly, BNPLHealth 4 cấp), `BNPLFeature` TCA, summary card với health badge + exposure ratio, toggle installment paid; persistence mã hoá; ghép vào Wellness.
- [x] `12.3` Money personality: đã có `MoneyPersonalityDomain` (5 type planner/impulsive/minimalist/foodie/experienceSeeker), `MoneyPersonalityAnalyzer` on-device tính từ pattern giao dịch (Shannon entropy, large-burst share, weekend share, budget utilization, savings rate); UI hero card gradient + traits + advice + share card 9:16 Instagram Story.
- [x] `8.1` Chia sẻ Wrapped: đã có `WrappedDomain` (WrappedReport, WrappedScope month/year, WrappedBuilder no-spend streak), `WrappedFeature` TCA với scope picker, hero card, stats card, top categories card; `WrappedShareCard` 9:16 gradient Spotify Wrapped style với ImageRenderer + ShareLink.

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
- [x] `3.5` AI chatbot tài chính cá nhân 🔴 - Đã có `FinancialAssistantFeature` dạng sheet toàn app, engine phân loại intent on-device cho câu hỏi số dư, khả năng chi trả, danh mục chi nhiều và cắt giảm; dùng dữ liệu giao dịch cục bộ qua TCA dependency, không gọi cloud AI/không gửi PII.

## 4. Mục tiêu tài chính

- [x] `4.1` Tạo mục tiêu tiết kiệm 🟡 - Đã có `GoalDomain`, CRUD UI trên dashboard, progress/status và `EncryptedSavingGoalStore` lưu mã hoá.
- [x] `4.2` Kết nối mục tiêu với chi tiêu thực 🟡 - Đã tính số ngày mục tiêu bị chậm khi budget vượt hạn mức và hiển thị card tác động trên dashboard.
- [x] `4.3` Quỹ khẩn cấp 🟡 - Đã có `EmergencyFundPlanner`, card dashboard gợi ý target 6 tháng chi phí, coverage, phần còn thiếu và mức nên nạp hàng tháng.
- [x] `4.4` Mô phỏng nghỉ hưu 🟡 - Đã có `RetirementSimulator`, card dashboard tính target tài sản theo chi phí, savings rate, thời gian tới mục tiêu và input giả định lợi suất/hệ số.

## 5. Báo cáo nâng cao

- [x] `5.1` Báo cáo so sánh tháng/năm 🟡 - Đã có `SpendingComparisonReporter` và dashboard report so sánh tháng hiện tại với tháng trước, YTD với cùng kỳ năm trước.
- [x] `5.2` Xuất báo cáo PDF 🟡 - Đã có model report, SwiftUI PDF renderer bằng `ImageRenderer`, ShareLink export PDF từ dashboard và nội dung tạo cục bộ trên thiết bị.
- [x] `5.3` Benchmark ẩn danh 🟡 - Đã có `AnonymousBenchmarkReporter` và `BenchmarkFeature` so sánh chi tiêu theo danh mục với median cohort ẩn danh bundled/local; user chọn thành phố, nhóm tuổi, income band; không gửi transaction/PII ra server.
- [x] `5.4` Xuất dữ liệu CSV 🟡 - Đã có `TransactionCSVExporter` domain và ShareLink export file CSV từ dashboard.

## 6. Chia sẻ & Gia đình

- [ ] `6.1` Tài khoản gia đình / cặp đôi 🟡
- [x] `6.2` Tách tiền nhóm 🔵 - Đã có `BillSplitterDomain` (`BillParticipant`, `BillItem` với assignedTo optional, `BillTipMode` 4 mức, `BillSplit`, `BillSplitCalculator` tính shares + settlements quy về payer, `BillShare` + `BillSettlement`), `BillSplitterFeature` TCA với CRUD participants/items, payer picker, tip mode picker, per-item assignment toggle, summary card chi tiết shares + settlements và `ShareLink` text bảng chia; toàn bộ in-memory không cần backend; ghép vào tab Wellness section `.billSplitter`.
- [ ] `6.3` Phân quyền trong gia đình 🟡

## 7. Gamification

- [x] `7.1` Streak & điểm thưởng 🟢 - Đã có `GamificationDomain`, `GamificationCalculator` đánh giá streak/level dựa trên giao dịch hôm nay + budget, encrypted profile store, `GamificationFeature` TCA, view với streak ring animated, points card, milestones grid và recent rewards; cập nhật khi mở tab Wellness, idempotent trong cùng ngày, alert chúc mừng khi đạt cột mốc 3/7/30/100 ngày.
- [x] `7.2` Huy hiệu & thành tích 🟢 - Đã có `Achievement` + `AchievementCategory` (4 nhóm), `AchievementProgress`, `AchievementCalculator` on-device tính 13 huy hiệu (firstSteps, weekWarrior/monthlyMaster/centuryClub, noSpendNovice/Champion, budgetGuardian, categoryCollector, dualLogger, earlyBird, nightOwl, rewardCollector/eliteCollector); `GamificationProfile.unlockedAchievements` lưu mã hoá kèm decoder backward-compat; UI card mới với grid theo nhóm, progress bar có Reduce Motion fallback, badge unlocked, alert chúc mừng queue khi mở nhiều huy hiệu cùng lúc.
- [x] `7.3` Level tài chính 🟢 - Đã có `FinancialLevel` (sprout/bronze/silver/gold/platinum/diamond/legend) với threshold XP từ 0 → 25.000, `FinancialLevelProgress` tính ratio + XP còn lại tới hạng kế; `GamificationCalculator.evaluate` cập nhật `lastNotifiedFinancialLevel` chỉ celebrate khi lên hạng (không spam profile cũ); UI card mới đặt đầu dashboard có badge gradient theo hạng, perk text VI/EN, progress bar animated (Reduce Motion fallback) và metrics tổng XP / XP còn lại; alert "Lên hạng tài chính" độ ưu tiên cao nhất; persistence backward-compat decode profile thiếu trường mới.
- [x] `7.4` Weekly challenge 🟡 - Đã có `WeeklyChallengeKind` 5 loại + `WeeklyChallenge` struct, `WeeklyChallengeGenerator.startOfWeek/challenge` Mon-first deterministic theo ISO week-of-year, `WeeklyChallengeEvaluator` per-kind tính progress từ transactions/rewardEvents trong cửa sổ tuần; `GamificationCalculator` re-evaluate active challenge mỗi lần `task` → archive (cap 12) khi tuần thay → generate mới, fire `weeklyChallengeCompleted` RewardEvent + bonus XP khi vừa complete; UI `GamificationWeeklyChallengeCard` icon/title/description, progress bar animated (Reduce Motion), `daysLeft` chip, badge "Đã hoàn thành" và reward XP preview; alert celebration ưu tiên sau Financial Level; backward-compat decode profile thiếu activeWeeklyChallenge/completedWeeklyChallenges.

## 8. Xã hội & Viral

- [x] `8.1` Chia sẻ Wrapped cuối tháng/năm 🔵 - Đã có `WrappedDomain` (WrappedReport với totalIncome/expense/net, top 3 categories sorted, largest transaction, no-spend days, best streak; WrappedScope month/year; WrappedBuilder tính từ transactions với date interval filter và no-spend streak algorithm); `WrappedFeature` TCA với scope picker month/year, hero card gradient + period label, stats card (transaction count, largest, no-spend, streak), top categories ranked card; `WrappedShareCard` 9:16 với gradient purple→pink (Spotify Wrapped style), ImageRenderer + ShareLink Instagram Story, hero stats + mini stats grid; `WrappedContextClient` load transactions từ encrypted store; ghép vào tab Wellness section `.wrapped`.
- [x] `8.2` Thử thách tiết kiệm cộng đồng 🔵 - Đã có `CommunityChallengeDomain` (7 thử thách bundled trong `CommunityChallengeLibrary`: noSpend-week, noSpend-month, coffee-skip, cook-at-home, subscription-audit, gratitude-log, round-up-month; `CommunityChallengeCategory` 5 nhóm, `CommunityChallengeDifficulty` 3 mức, `CommunityChallengeEnrollment` với progress/daysRemaining; `CommunityChallengeRepository`), `CommunityChallengeFeature` TCA với join/check-in/leave, active enrollments card với ProgressView, browse card với difficulty badge + duration; toàn bộ on-device, không leaderboard server, không gửi PII; ghép vào tab Wellness section `.communityChallenge`.

## 9. Tích hợp & Kết nối

- [x] `9.1` iCloud Sync 🟡 - Đã có `CloudSyncDomain` (`CloudSyncAvailability` 4 trạng thái, `CloudSyncState` disabled/idle/syncing/failed, `CloudSyncStatus`, `CloudSyncRecord` payload là AES-GCM blob đã mã hoá keyed by UUID kind transaction/budget/category/savingGoal, `CloudSyncDelta` upserts+deletions, `CloudSyncClient` Sendable abstraction availability+fetchChanges+upload tách rời CloudKit, `CloudSyncPreferences` codable với syncedKinds, `CloudSyncPreferencesRepository`); `CloudSyncFeature` TCA với task load preferences + availability, toggleEnabled guard `.available`, syncNowButtonTapped → fetchChanges + upload → syncCompleted update lastSyncedAt, syncFailed state; `CloudSyncView` 4 card header + toggle + sync card với status icon + relative date + Sync now button + end-to-end encrypted disclaimer; live `LiveCloudSyncClient` trong App target dùng CKContainer private database (recordType `EncryptedRecord` chỉ chứa payload+kind+recordID+version, không bao giờ plaintext), `CKModifyRecordsOperation.savePolicy = .changedKeys`, error mapping CKError → CloudSyncError (quotaExceeded/auth/network); entitlements iCloud + CloudKit thêm vào `Kaso.entitlements` cho container `iCloud.com.vuongnguyen.kaso`; persistence mã hoá `EncryptedCloudSyncPreferencesStore` AES-GCM keychain; ghép vào tab Wellness section `.cloudSync`. Tests: 7 domain test + 4 TCA TestStore test cover task load, toggle availability check, persist, sync failure. **Lưu ý:** Sync engine chuyển encrypted blob giữa local stores và CloudKit ở mức record là follow-up — hiện tại upload `.empty` cho đến khi journal change-tracking layer hoàn chỉnh; CloudKit container cần khởi tạo trong App Store Connect/Apple Developer trước khi build production.
- [ ] `9.2` Apple Wallet & Apple Pay 🔴
- [x] `9.3` Siri Shortcuts 🟡 - Đã có `QuickEntryIntent` package với `LogExpenseIntent` + `LogIncomeIntent`, `KasoAppShortcuts` (AppShortcutsProvider) với phrase VI/EN, `TransactionCategoryEntity` + `TransactionCategoryQuery` cho disambiguation, `QuickEntryIntentEnvironment` bridge sang `EncryptedTransactionStore`; entitlements + `APPINTENTS_PACKAGE_DEPENDENCIES` đã wire trong Project.swift.
- [x] `9.4` Apple Watch 🟡 - Đã có `KasoWatchApp` target watchOS riêng (Tuist `Target.target(.app)` với `destinations: [.appleWatch]`, deployment target watchOS 10.0, `WKApplication=true`, `WKCompanionAppBundleIdentifier` trỏ về app iOS, App Group entitlement chung); `KasoWatchApp` SwiftUI `@main` với `WatchConnectivityCoordinator` `@MainActor` `ObservableObject` activate `WCSession`, delegate handler decode `WidgetSnapshot` từ `didReceiveApplicationContext`/`didReceiveMessageData` JSON, fallback đọc cache từ shared App Group UserDefaults qua `WidgetSnapshotStore.load()`; `WatchRootView` render 3 card (Hôm nay total, Còn lại budget + ProgressView + percentage chip, transactions row), `StaleIndicator` hiển thị thời điểm cập nhật relative hoặc placeholder; `KasoWidgetShared` mở rộng multiplatform iOS+watchOS (`destinations: [.iPhone, .iPad, .appleWatch]`, `.multiplatform(iOS, watchOS)`); `WatchSnapshotSender` actor `@MainActor` trên iOS dùng `WCSession.updateApplicationContext` push snapshot mỗi lần `WidgetSnapshotPublisher.publish()` (best-effort, kiểm tra `isPaired` + `isWatchAppInstalled`, fallback no-op khi WatchConnectivity không khả dụng); App embed Watch target qua dependency `.target(name: "KasoWatchApp")`. Source build sạch via `swiftc -parse`; chưa verify trên simulator do watchOS 26.5 platform chưa cài trên máy.
- [x] `9.5` Widget màn hình khoá & Home screen 🟡 - Đã có `KasoWidgets` app extension target (Tuist `Target.target(.appExtension)` với `WidgetKit` extension point, App Group entitlement `group.com.vuongnguyen.kaso`); `KasoWidgetBundle` host `KasoSpendingWidget` (StaticConfiguration kind `com.vuongnguyen.kaso.widget.spending` supportedFamilies: systemSmall, systemMedium, accessoryRectangular, accessoryInline, accessoryCircular), TimelineProvider 30 phút refresh; `KasoSpendingWidgetView` render 5 family variants (small + medium + rectangular Lock Screen + circular gauge + inline) với budget progress bar, transaction count, currency formatted; framework chung `KasoWidgetShared` (`WidgetSnapshot` codable PII-free: totalSpentToday/monthlyBudgetLimit/monthlyBudgetSpent/transactionCountToday/currencyCode/updatedAt, `WidgetSnapshotStore` AppGroup UserDefaults load/save, `WidgetSnapshotPublisher` actor publish + `WidgetCenter.reloadAllTimelines`); `KasoApp.refreshWidgetSnapshot` chạy mỗi scene appear: đọc encrypted transaction/budget store, aggregate today + monthly, publish snapshot không leak nội dung giao dịch; entitlements App Group thêm vào `Kaso.entitlements` + `KasoWidgets.entitlements`; localizations VI/EN cho widget strings.
- [x] `9.6` Live Activity 🟡 - Đã có `KasoSpendingActivityAttributes` (`ActivityAttributes`, `ContentState` codable Hashable Sendable với totalSpentToday/budgetRemaining/transactionCount, attributes sessionLabel + currencyCode), `KasoSpendingLiveActivity` `ActivityConfiguration` Lock Screen view (sessionLabel + total + budget icon row, activityBackgroundTint + activitySystemActionForegroundColor) + Dynamic Island 4 region (leading creditcard + total, trailing wallet + budget remaining, center sessionLabel, bottom transaction count) + compactLeading/compactTrailing/minimal; gated bằng `@available(iOS 16.2, *)` và `if #available(iOS 16.2, *)` trong `KasoWidgetBundle` để fallback an toàn. Activity start/end/update từ app side là follow-up khi có flow phù hợp (ví dụ shopping session) — attributes type đã sẵn để app start activity.

## 10. Đầu tư & Tài sản

- [x] `10.1` Theo dõi tài sản & Net worth 🟡 - Đã có `WealthDomain`, `WealthFeature`, encrypted stores cho asset/liability/snapshot, tab tài sản ròng, CRUD tài sản/khoản nợ, breakdown theo loại và lịch sử net worth 6 tháng.
- [x] `10.2` Danh mục đầu tư 🔴 - Đã có `InvestmentDomain`, tab đầu tư TCA, nhập holdings/giá hiện tại thủ công, tính lãi/lỗ, phân bổ, gợi ý tái cân bằng, lưu mã hoá và đồng bộ asset auto-tracked sang net worth; mới thêm `MarketPriceProvider` (interface Sendable với `fetchQuotes(symbols:)`), `MarketPriceProvider.offlineSnapshot` dùng `OfflineMarketSnapshot.priceTable` bundled in-source cho ~25 ticker (VN30 blue chips + ETF + mutual fund) với `asOf` fixed 2025-04-23, source `.network`, case-insensitive lookup; `InvestmentFeature` thêm action `refreshPricesButtonTapped` → fetch → `priceQuoteRepository.saveMany` → merge vào state.quotes → resync asset; toolbar có nút refresh (disabled khi đang refresh hoặc không có holding), `isRefreshingPrices` show ProgressView; tests cover known/unknown ticker, case normalisation và unavailable provider. Live providers cần certificate pinning là implementation follow-up — interface đã sẵn để swap in.
- [x] `10.3` Theo dõi nợ & khoản vay 🟡 - Đã có `DebtDomain`, `DebtFeature`, encrypted debt store, CRUD khoản vay, amortization schedule, tổng lãi/khoản trả hàng tháng, mô phỏng trả thêm và sync auto-tracked liability vào net worth.

## 11. UX & Tiện lợi

- [x] `11.1` Tìm kiếm thông minh 🟢 - Đã có `SmartSearchDomain` (`SmartSearchQuery` với keyword + dateRange optional, `SmartSearchParser` on-device parse cụm "hôm nay/hôm qua/tuần này/tuần trước/tháng này/tháng trước/năm nay/năm trước/this week/last week..." VI+EN và "tháng N"/"month N" theo năm hiện tại), `SmartSearchFeature` TCA standalone trong tab Wellness section `.smartSearch` với input field, ví dụ click-to-fill, result card hiển thị keyword tách ra + khoảng thời gian; parser sẵn sàng để TransactionFeature consume trong follow-up (chưa wire vào hộp tìm kiếm chính của TransactionFeature do file 1630 dòng, sẽ làm sau).
- [x] `11.2` Mẫu giao dịch thường gặp 🟢 - Đã có `TransactionTemplate` model + `TransactionTemplateRepository` trong TransactionDomain; `EncryptedTransactionTemplateStore` (AES-GCM); `TransactionTemplateSheet` UI với list/delete; nút "Dùng mẫu" và "Lưu làm mẫu" trong AddTransactionSheet; pre-fill form khi chọn mẫu; lưu mã hoá keychain.
- [x] `11.3` Nhắc nhở thông minh 🟡 - Đã có `RemindersDomain` (`ReminderKind` 5 loại: endOfDayEntry/budgetNearLimit/subscriptionRenewal/noSpendStreak/largeExpense, `ReminderPreference` với hour/minute clamp, `ReminderConfiguration.default` cho tất cả kinds, `ReminderRepository`, `ReminderScheduler` interface với authorizationStatus/requestAuthorization/apply), `RemindersFeature` TCA với toggle UI per-kind + DatePicker thời gian, permission flow `notDetermined/denied/authorized`; live `ReminderScheduler.live` dùng `UNUserNotificationCenter` schedule daily reminder cho các kind có `isDailySchedule`, notification body dùng `NSLocalizedString` từ bundle (không chứa PII/số tiền/giao dịch); ghép vào tab Wellness section `.reminders`.
- [x] `11.4` Onboarding cá nhân hoá 🟢 - Đã có flow thu nhập, danh mục, mục tiêu và gợi ý ngân sách.
- [x] `11.5` Haptic feedback & Animation 🟢 - Đã có animation dashboard/list/chart, Reduce Motion fallback và success haptic cho transaction/budget/category save.

## 12. Tâm lý & Hành vi

- [x] `12.1` Spending mood journal 🟡 - Đã có `MoodJournalDomain` (Mood, MoodEntry, MoodInsight, MoodJournalRepository), `MoodJournalFeature` TCA với CRUD entry, insight correlation after 2–3 tháng, editor sheet và card components; ghép vào tab Wellness section `.moodJournal`.
- [x] `12.2` Regret score 🟡 - Đã có `RegretScoreDomain` (RegretRating, RegretRatingDraft, RegretReminderBuilder, RegretSummary, RegretRatingRepository), `RegretScoreFeature` TCA với reminder notification 7 ngày sau giao dịch lớn, editor sheet, summary card và cảnh báo khi tạo giao dịch tương tự; ghép vào tab Wellness section `.regretScore`.
- [x] `12.3` Money personality 🔵 - Đã có `MoneyPersonalityDomain` (5 type: planner/impulsive/minimalist/foodie/experienceSeeker với emoji, color, tagline, advice; MoneyPersonalityTrait; MoneyPersonalityProfile với confidence scores), `MoneyPersonalityAnalyzer` on-device tính từ pattern giao dịch (Shannon entropy diversity, large-burst share, weekend share, budget utilization, savings rate), tối thiểu 30 giao dịch; `MoneyPersonalityFeature` TCA với hero card (gradient theo type, emoji 64pt, tagline), traits radar bar chart, advice card, share card 9:16 với ImageRenderer + ShareLink Instagram Story; `MoneyPersonalityContextClient` build context từ giao dịch 3 tháng, budgets, savings goals; ghép vào tab Wellness section `.moneyPersonality`.

## 13. Mô phỏng & Dự báo

- [x] `13.1` What-if simulator 🟡 - Đã có `WhatIfDomain` (WhatIfScenario, WhatIfCalculator, WhatIfBaselineContext), `WhatIfFeature` TCA với projection scenarios (tăng thu nhập, bỏ subscription, giảm ăn ngoài), visualization cards và impact trực quan; ghép vào tab Wellness section `.whatIf`.
- [x] `13.2` Future self letter 🟡 - Đã có `FutureSelfDomain` (FutureSelfTone optimistic/steady/cautionary, FutureSelfLetter, FutureSelfLetterBuilder ghép thư từ template localized theo savings rate 3 tháng, on-device không gọi cloud AI, FutureSelfContextClient), `FutureSelfFeature` TCA, letter card gradient + projection card (tuổi dự phóng, tiết kiệm/năm, savings rate); ghép vào tab Wellness section `.futureSelf`.
- [x] `13.3` Spending calendar 🟡 - Đã có `SpendingCalendarDomain` (SpendingCalendar, DailySpending, SpendingCalendarBuilder, SpendingCalendarContextClient), `SpendingCalendarFeature` TCA với calendar view màu theo mức chi/trung bình, dự báo ngày tương lai dựa trên subscription và pattern lặp lại; ghép vào tab Wellness section `.spendingCalendar`.

## 14. Tiết kiệm tự động

- [x] `14.1` Round-up tiết kiệm 🟡 - Đã có `RoundUpDomain` với `RoundUpStep`, `RoundUpRule`, `RoundUpCalculator` làm tròn lên step kế tiếp; `RoundUpFeature` TCA với toggle bật/tắt, picker step (1k/5k/10k/50k), simulator nhập thử số tiền và xem phần làm tròn, lịch sử entries thủ công, persistence mã hoá qua `EncryptedRoundUpStore` (rule + entries trong cùng blob AES-GCM); ghép vào tab Wellness.
- [x] `14.2` No-spend day tracker 🟢 - Đã có `WellnessDomain`, dashboard current/longest streak + day dots, milestone chúc mừng và ước tính tiết kiệm dựa trên ngày có chi tiêu trung bình.
- [x] `14.3` Guilt-free budget 🟡 - Đã có `GuiltFreeBudgetDomain` với `GuiltFreeBudgetConfiguration` (income, savings, emergency, fixed costs có kind: housing/utilities/insurance/loan/savings/emergencyFund/other), `GuiltFreeBudgetCalculator` tính `freeMoney = income − fixedCosts − savings − emergency`, health enum (healthy/tight/overspending/incomeMissing) và daily allowance theo ngày còn lại trong tháng; `GuiltFreeBudgetFeature` TCA quản lý editor income + CRUD fixed costs; UI card headline xanh khi healthy + breakdown bar phân bổ + danh sách fixed costs; persistence mã hoá `EncryptedGuiltFreeBudgetConfigurationStore`; ghép vào tab Wellness.

## 15. Xã hội & Địa lý

- [x] `15.1` Spending map 🟡 - Đã có `SpendingMapDomain` (`SpendingMapEntry`, `SpendingMapHotspot`, `SpendingMapSummary`, `SpendingMapPeriod` 30/90/all-time, `SpendingMapBuilder` cluster theo bán kính ~0.003° (~330m), tính intensity tương đối với hotspot mạnh nhất, top category theo tổng chi); `SpendingMapFeature` TCA với CRUD entry, period picker, header card tổng/đếm/cụm, MapKit `Map` annotation kích thước theo intensity, entry list với edit/delete; `SpendingMapEditorSheet` dùng `Map` cho user pan để đặt pin (không cần GPS permission), iOS-only `.keyboardType(.numberPad)` guard; persistence mã hoá `EncryptedSpendingMapStore` AES-GCM keychain; ghép vào tab Wellness section `.spendingMap`. On-device toàn bộ, không thu GPS.
- [x] `15.2` Seasonal planner 🟡 - Đã có `SeasonalPlannerDomain` (`SeasonalSpike`, `SeasonalPlan`, `SeasonalPlanBuilder` phát hiện tháng có chi cao ≥ 130% baseline trong 8 tuần tới, `SeasonalContextClient`, `SeasonalMonthName` map Tết/back-to-school/11-11/year-end), `SeasonalPlannerFeature` TCA load plan từ context client, view header + spike cards với label tháng VI/EN, gợi ý "để dành mỗi tuần"; ghép vào tab Wellness section `.seasonalPlanner` và wire context client từ `transactionRepository.fetchAll()` trong `KasoApp`.
- [x] `15.3` Spending DNA 🔵 - Đã có `SpendingDNADomain` (SpendingDNAType saver/foodie/explorer/spender/balanced, SpendingDNAReport, SpendingDNABuilder phân loại theo savings rate + dominant category on-device, SpendingDNAContextClient), `SpendingDNAFeature` TCA load report cuối năm, hero card gradient + tagline theo type, stats card, top categories, `SpendingDNAShareCard` 9:16 ImageRenderer + ShareLink Instagram Story; ghép vào tab Wellness section `.spendingDNA`.

## 16. Văn hoá & Đặc thù Việt Nam

- [x] `16.1` Lì xì & đám hỉ tracker 🟢 - Đã có `GiftTrackerDomain` (GiftRecord, GiftEventKind 7 dịp tet/wedding/newHome/babyShower/funeral/birthday/other, GiftDirection given/received, GiftPersonSummary, GiftYearlySummaryBuilder); `GiftTrackerFeature` TCA với CRUD record, summary cards (yearly given/received, person list), detail view per person với history hai chiều và suggested amount dựa trên given history; persistence mã hoá `EncryptedGiftTrackerStore`; ghép vào tab Wellness section `.giftTracker`.
- [x] `16.2` Hụi/họ tracker 🟡 - Đã có `HuiTrackerDomain` (HuiGroup, HuiCycle, HuiPeriodKind weekly/biweekly/monthly, HuiCycleScheduleBuilder auto-gen kỳ, HuiSummaryBuilder group/overall); `HuiTrackerFeature` TCA với CRUD dây hụi, toggle kỳ đã đóng/đã hốt, summary card đóng/hốt/net position, disclaimer chỉ là ledger cá nhân (không giữ tiền/không môi giới); persistence mã hoá `EncryptedHuiTrackerStore`; ghép vào tab Wellness section `.huiTracker`.
- [x] `16.3` BNPL exposure tracker 🟡 - Đã có `BNPLDomain` (BNPLObligation, BNPLProvider 7 nhà cung cấp: Fundiin/Kredivo/Atome/Shopee PayLater/MoMo Postpaid/Home Credit/Generic, BNPLInstallment, BNPLInstallmentBuilder generate monthly schedule, BNPLHealth 4 cấp safe/caution/overexposed/critical theo tỉ lệ với thu nhập, BNPLSummary với current/next-3-months/overdue/monthly exposures); `BNPLFeature` TCA với CRUD obligation, toggle paid installment; UI summary card với health badge, exposure ratio bar, breakdown obligations với progress; persistence mã hoá `EncryptedBNPLStore`; `BNPLContextClient` lấy thu nhập tháng từ onboarding hoặc giao dịch 3 tháng gần; ghép vào tab Wellness section `.bnpl`.
- [ ] `16.4` Cộng đồng giá địa phương 🔵

## 17. Tâm lý mở rộng

- [x] `17.1` Cooling-off period cho mua bốc đồng 🟡 - Đã có `CoolingOffDomain` với `PurchasePlan` (status waiting/approved/cancelled/expired), `CoolingPeriod` (1d/3d/1w/2w), `CoolingOffPolicy` (threshold mặc định 500k→1d, 2M→3d, 5M→1w, 20M→2w), `PurchasePlanSummaryBuilder` chia waiting/ready/decided và tính tổng đã tránh chi, `OpportunityCostCalculator` quy ra giờ làm/ngày trễ goal/tháng emergency; `CoolingOffFeature` TCA: editor tự đề xuất cooling period theo amount (override được), action approve/cancel/delete, ProgressView countdown, summary card tiền đã tránh + waiting; persistence mã hoá `EncryptedPurchasePlanStore` lưu plans + policy chung blob; ghép vào tab Wellness.
- [x] `17.2` Phantom expense ledger 🟢 - Đã có sổ khoản suýt tiêu, tổng tiền tránh chi trong tháng, breakdown theo nhóm, thêm/sửa/xoá và lưu mã hoá.
- [x] `17.3` Hours of life converter 🟢 - Đã có `HoursOfLifeFeature` TCA, tab Wellness mới, cấu hình thu nhập thực nhận và giờ làm trung bình/tháng (lưu mã hoá keychain), fallback từ onboarding income, calculator quy đổi nhanh và danh sách giao dịch gần đây quy ra giờ/phút làm việc.
- [x] `17.4` Money therapist mode 🟡 - Đã có `MoneyTherapistDomain` (`TherapistTopic` 5 chủ đề: recentOverspend/guilt/stressTrigger/comparisonAnxiety/generalCheckin, `TherapistPrompt` + `TherapistPromptLibrary` template on-device cho mỗi topic gồm opening message, 3 reflection questions, 2 suggested actions, closing message; `TherapistReflection` + `TherapistRepository`), `MoneyTherapistFeature` TCA với grid topic tiles, reflection sheet (questions + ô ghi chú optional + suggested actions + closing), history card; không gọi cloud AI, không gửi PII; full localization VI/EN cho mọi prompt; ghép vào tab Wellness section `.moneyTherapist`.

## 18. Ngách chuyên biệt & Wellness

- [x] `18.1` Money compatibility test cho cặp đôi 🔵 - Đã có `CompatibilityDomain`, `CompatibilityFeature`, quiz self/partner, score theo 6 chiều, conflict insights, conversation starters, share card và section trong tab Wellness.
- [x] `18.2` Freelancer income smoothing 🟡 - Đã có `FreelancerDomain`, rolling-average 3/6/12 tháng, quỹ đệm, tax provision, reminder low-buffer/slow-season, `FreelancerFeature`, encrypted store và tab Wellness.
- [x] `18.3` Sleep × spending correlation 🟡 - Đã có `SleepCorrelationDomain`, builder kết hợp sleep sample + transaction, HealthKit client, phân tích Pearson on-device, disclaimer privacy, scatter/breakdown UI và tab Wellness.
- [x] `18.4` Digital financial legacy 🔴 - Đã có `LegacyDomain`, vault model, AES-GCM export password với PBKDF2-HMAC-SHA256, encrypted local store, biometric auth client, account/instruction UI và export `.kasovault`.

---

## Kế hoạch chi tiết: Nhóm 18 — Ngách chuyên biệt & Wellness

> Cập nhật: 2026-04-27. Phân tích chi tiết từng tính năng, bao gồm domain model, TCA structure, view components, animation/transition và lộ trình triển khai.

### Tổng quan nhóm

| # | Tính năng | Tier | Phase | Độ phức tạp | Viral potential |
|---|---|---|---|---|---|
| 18.1 | Money compatibility test | 🔵 Family | Phase 5 | Trung bình | ⭐⭐⭐⭐⭐ |
| 18.2 | Freelancer income smoothing | 🟡 Pro | Phase 4 | Cao | ⭐⭐⭐ |
| 18.3 | Sleep × spending correlation | 🟡 Pro | Phase 6 | Cao | ⭐⭐⭐⭐ |
| 18.4 | Digital financial legacy | 🔴 Pro | Phase 6+ | Rất cao | ⭐⭐ |

---

### 18.1 Money Compatibility Test cho cặp đôi 🔵

#### Mục tiêu sản phẩm
Viral driver tự nhiên: một người có lý do mời partner cùng làm test trước khi bật Family account. Test phân tích 6 chiều xung đột tiền bạc phổ biến trong cặp đôi. Kết quả được thiết kế để dễ share lên Instagram Story.

#### Domain model (`Packages/Domain/CompatibilityDomain/`)

```
CompatibilityQuestion
├── id: UUID
├── dimension: CompatibilityDimension   // 6 chiều
├── text: String
├── options: [CompatibilityOption]      // 4 lựa chọn, có weight
└── weight: Double                      // trọng số trong tổng điểm

CompatibilityDimension (enum)
├── spendingStyle      // tiết kiệm vs chi tiêu tự do
├── riskTolerance      // chịu rủi ro đầu tư
├── debtAttitude       // quan điểm về nợ
├── splittingApproach  // chia tiền trong mối quan hệ
├── familySupport      // hỗ trợ gia đình hai bên
└── futureGoals        // ưu tiên dài hạn

CompatibilityAnswer
├── questionId: UUID
├── selectedOptionIndex: Int
└── respondent: Respondent              // .self | .partner

CompatibilityResult
├── overallScore: Double                // 0–100
├── dimensionScores: [CompatibilityDimension: Double]
├── compatibilityType: CompatibilityType
├── highlightedConflicts: [ConflictInsight]
├── conversationStarters: [String]
└── generatedAt: Date

CompatibilityType (enum)
├── perfectMatch       // 85–100
├── strongFoundation   // 70–84
├── workInProgress     // 50–69
├── oppositesAttract   // 30–49
└── needsAlignment     // 0–29
```

#### TCA Feature structure (`Packages/Features/CompatibilityFeature/`)

```
CompatibilityFeature
├── State
│   ├── phase: Phase         // .intro | .selfQuiz | .partnerQuiz | .result | .share
│   ├── questions: [CompatibilityQuestion]
│   ├── selfAnswers: [CompatibilityAnswer]
│   ├── partnerAnswers: [CompatibilityAnswer]
│   ├── currentQuestionIndex: Int
│   ├── result: CompatibilityResult?
│   ├── isAnimatingReveal: Bool
│   └── shareImage: CGImage?
│
├── Action
│   ├── startSelfQuiz
│   ├── answerQuestion(questionId: UUID, optionIndex: Int)
│   ├── nextQuestion
│   ├── switchToPartnerQuiz
│   ├── calculateResult
│   ├── resultCalculated(CompatibilityResult)
│   ├── triggerRevealAnimation
│   ├── generateShareImage
│   └── shareImageGenerated(CGImage)
│
└── Reducer
    ├── answerQuestion → cập nhật selfAnswers/partnerAnswers theo phase
    ├── calculateResult → CompatibilityCalculator.calculate(self:partner:)
    └── generateShareImage → ImageRenderer render CompatibilityShareCard
```

#### View components

```
CompatibilityView (root)
├── CompatibilityIntroView
│   └── illustration + "Bắt đầu" CTA
│
├── CompatibilityQuizView
│   ├── QuizProgressBar          // animated step indicator
│   ├── QuizQuestionCard         // câu hỏi với card flip transition
│   └── QuizOptionRow × 4       // tap → scale bounce + check mark
│
├── CompatibilityTransitionView  // "Giờ đến lượt partner" separator
│
├── CompatibilityResultView
│   ├── CompatibilityScoreRing   // Metal circular gauge animated
│   ├── DimensionRadarChart      // Metal radar chart 6 chiều
│   ├── ConflictInsightList      // accordion expand/collapse
│   └── ConversationStarterCards // horizontal scroll
│
└── CompatibilityShareCard       // off-screen render → CGImage
    ├── score badge
    ├── radar mini chart
    └── Kaso branding
```

#### Animation & Transition chi tiết

**A. Quiz card flip (câu hỏi mới)**
- SwiftUI `.rotation3DEffect` + `.opacity`
- Khi chuyển câu: card cũ flip 90° ra → card mới flip 90° vào
- Duration: 0.35s, easing: `.easeInOut`
- Reduce Motion fallback: `.opacity` fade 0.2s

```swift
// CardFlipModifier
struct CardFlipModifier: ViewModifier {
    let isFlipped: Bool
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(isFlipped ? 90 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(.easeInOut(duration: 0.35), value: isFlipped)
    }
}
```

**B. Option row selection (chọn đáp án)**
- Scale: 1.0 → 1.04 → 1.0 (spring, stiffness 400, damping 15)
- Background fill animate từ `surface` → `accent` trong 0.2s
- Check mark: scale 0 → 1 với `.bouncy` spring
- Haptic: `.selectionChanged` ngay khi tap

**C. Progress bar (bước tiến quiz)**
- Capsule fill animate với `.spring(response: 0.5)`
- Step dots: chấm active scale 1.0 → 1.3 với bounce

**D. Transition Self → Partner quiz**
- Full-screen overlay slide up từ bottom
- Background blur `.ultraThinMaterial` fade in
- Avatar/name của partner animate in với delay cascade
- Duration: 0.45s, `.spring(dampingFraction: 0.8)`

**E. Result reveal (Metal shader)**

File: `Packages/Features/CompatibilityFeature/Sources/Shaders/compatibility_reveal.metal`

```metal
// Ripple reveal từ tâm màn hình ra ngoài
[[ stitchable ]] half4 compatibilityReveal(
    float2 position,
    SwiftUI::Layer layer,
    float time,
    float2 center
) {
    float dist = distance(position, center);
    float wave = smoothstep(time * 1.5 - 0.3, time * 1.5, dist / 600.0);
    half4 color = layer.sample(position);
    return mix(half4(0, 0, 0, 0), color, 1.0 - wave);
}
```

- Timeline: 0s score ring, 0.3s radar chart, 0.8s conflicts list stagger in
- Score ring: stroke draw animate từ 0 → target angle (Metal circular path)
- Số score: count-up từ 0 → final (`withAnimation(.linear(duration: 1.2))`)

**F. Radar chart (Metal)**

File: `Packages/Features/CompatibilityFeature/Sources/Shaders/radar_chart.metal`

- Vẽ 2 polygon: self (xanh) vs partner (cam), blend overlay
- Animate: scale từ 0 → 1 theo từng axis với stagger 0.1s mỗi axis
- Input uniforms: 6 điểm self[], 6 điểm partner[], animationProgress (0→1)
- SwiftUI `TimelineView` feed `animationProgress` vào Metal uniform
- Reduce Motion: static polygon, bỏ animate

**G. Share card generation**
- `ImageRenderer` render `CompatibilityShareCard` off-screen
- Resolution: 1080×1920 (9:16 Story ratio), scale 3×
- Gradient nền dựa theo `CompatibilityType` (mỗi type 1 màu đặc trưng)
- `ShareLink` với `.compatibilityResult` activity type

#### Tests

```swift
// CompatibilityDomainTests
@Test("perfect match scores 85–100 khi tất cả answer giống nhau")
@Test("opposites attract khi 5/6 dimension ngược chiều hoàn toàn")
@Test("conflict highlights chỉ xuất hiện cho dimension score < 40")
@Test("conversationStarters không rỗng với mọi CompatibilityType")

// CompatibilityFeatureTests (TestStore)
@Test("answerQuestion cập nhật đúng selfAnswers khi phase == .selfQuiz")
@Test("calculateResult gửi đúng Action.resultCalculated")
@Test("phase chuyển sang .partnerQuiz sau khi tất cả câu self done")
```

#### Snapshot tests
- `CompatibilityQuizView` — light/dark/DT XL
- `CompatibilityResultView` mỗi `CompatibilityType` × light/dark
- `CompatibilityShareCard` × 5 type

---

### 18.2 Freelancer Income Smoothing 🟡

#### Mục tiêu sản phẩm
Giải quyết pain point của freelancer, tài xế công nghệ, seller online: thu nhập lên xuống bất thường khiến không biết mình "giàu" hay "nghèo" tháng này. App tính "lương ảo" ổn định, quản lý quỹ đệm và nhắc các khoản chi phí freelancer hay quên.

#### Domain model (`Packages/Domain/FreelancerDomain/`)

```
FreelancerProfile
├── id: UUID
├── monthlyIncomes: [MonthlyIncome]     // lịch sử thu nhập thực
├── smoothingWindowMonths: Int          // rolling average window (3/6/12)
├── bufferTargetMultiplier: Double      // tháng buffer muốn giữ (1.5–3.0)
├── workType: WorkType                  // .freelancer | .gigDriver | .onlineSeller | .other
└── taxRate: Double?                    // % thuế TNCN ước tính

MonthlyIncome
├── month: YearMonth
├── grossAmount: Decimal
├── deductions: [IncomeDeduction]       // thuế, chi phí kinh doanh
└── netAmount: Decimal

FreelancerSmoothedView
├── smoothedMonthlyIncome: Decimal      // rolling average sau deduction
├── bufferBalance: Decimal             // quỹ đệm hiện có
├── bufferTarget: Decimal              // mục tiêu quỹ đệm
├── bufferCoverage: Double             // tháng có thể cover
├── currentMonthSurplus: Decimal       // thu thực - smoothed = vào buffer
├── currentMonthDeficit: Decimal       // tháng thấp điểm: rút buffer
└── taxProvision: Decimal              // dự phòng thuế hàng tháng

FreelancerReminder (enum)
├── taxDeadline(amount: Decimal, dueDate: Date)
├── insuranceRenewal(provider: String, dueDate: Date)
├── lowBuffer(monthsCovered: Double)
└── slowSeasonAlert(historicalPattern: String)
```

#### TCA Feature structure (`Packages/Features/FreelancerFeature/`)

```
FreelancerFeature
├── State
│   ├── profile: FreelancerProfile?
│   ├── smoothedView: FreelancerSmoothedView?
│   ├── incomeHistory: [MonthlyIncome]
│   ├── reminders: [FreelancerReminder]
│   ├── isEditingProfile: Bool
│   ├── isAddingIncome: Bool
│   └── selectedWindow: SmoothingWindow  // .threeMonths | .sixMonths | .twelveMonths
│
├── Action
│   ├── task
│   ├── profileLoaded(FreelancerProfile?)
│   ├── addIncome(MonthlyIncome)
│   ├── incomeSaved
│   ├── changeSmootingWindow(SmoothingWindow)
│   ├── viewComputed(FreelancerSmoothedView)
│   └── remindersTapped(FreelancerReminder)
│
└── Dependency: FreelancerRepository
    ├── loadProfile: () async throws -> FreelancerProfile?
    ├── saveIncome: (MonthlyIncome) async throws -> Void
    └── computeSmoothedView: (FreelancerProfile, SmoothingWindow) -> FreelancerSmoothedView
```

#### View components

```
FreelancerDashboardView
├── SmoothedIncomeCard
│   ├── "Lương ảo tháng này" header
│   ├── số tiền lớn (animated count-up khi load)
│   └── so sánh với tháng thực + delta badge
│
├── BufferStatusCard
│   ├── BufferLiquidGauge       // Metal liquid fill animation
│   ├── "X tháng coverage" label
│   └── surplus/deficit indicator
│
├── IncomeHistoryChart           // bar chart 12 tháng + smoothed line overlay
│   └── Metal bar + line composite chart
│
├── SmoothingWindowPicker        // segment control 3M / 6M / 12M
│
├── FreelancerReminderList       // reminders theo priority
│
└── AddIncomeSheet
    ├── month picker
    ├── gross amount field
    └── deduction entries (tax, business costs)
```

#### Animation & Transition chi tiết

**A. Buffer liquid gauge (Metal shader — MTKView)**

File: `Packages/Features/FreelancerFeature/Sources/Shaders/liquid_gauge.metal`

```metal
// Sóng nước trong hình tròn, fill theo bufferCoverage
[[ stitchable ]] half4 liquidGauge(
    float2 position,
    SwiftUI::Layer layer,
    float time,
    float fillLevel,    // 0.0 → 1.0
    float2 size
) {
    float2 uv = position / size;
    float wave = sin(uv.x * 8.0 + time * 2.0) * 0.02
               + cos(uv.x * 5.0 + time * 3.1) * 0.01;
    float threshold = 1.0 - fillLevel + wave;
    float alpha = smoothstep(threshold + 0.01, threshold - 0.01, uv.y);
    // xanh lá: đủ buffer, vàng: cảnh báo, đỏ: nguy hiểm
    half4 fillColor = fillLevel > 0.5
        ? half4(0.2, 0.8, 0.4, 1.0)
        : fillLevel > 0.25
            ? half4(1.0, 0.75, 0.1, 1.0)
            : half4(0.9, 0.25, 0.2, 1.0);
    return mix(half4(0,0,0,0), fillColor, alpha);
}
```

- `MTKView` cho animation real-time 60fps
- Reduce Motion: static capsule progress bar thay thế

**B. Income history chart (Metal)**

File: `Packages/Features/FreelancerFeature/Sources/Shaders/income_chart.metal`

- 12 bar vẽ Metal, animate grow từ bottom lên khi appear
- Stagger 0.05s mỗi bar (`i * 0.05s` delay)
- Smoothed line: cubic Bézier path, stroke animate trái → phải
- Khi chuyển smoothing window: bars animate cross-fade 0.4s ease

**C. Smoothing window transition**
- Segment control change → bar chart cross-fade + line redraw 0.4s
- "Lương ảo" count-up/count-down đến giá trị mới

**D. Add income sheet**
- Amount field: tự động format VND khi nhập
- Save: sheet dismiss + bar mới animate grow vào chart
- Haptic: `.notificationOccurred(.success)`

#### Tests

```swift
// FreelancerDomainTests
@Test("smoothedIncome là average đúng khi window = 3 tháng")
@Test("bufferCoverage = bufferBalance / smoothedMonthlyIncome")
@Test("surplus = grossNet - smoothedIncome, không âm")
@Test("deficit chỉ xảy ra khi tháng thực thấp hơn smoothed")
@Test("taxProvision = netIncome * taxRate / 12")

// FreelancerFeatureTests
@Test("changeSmootingWindow recompute SmoothedView ngay lập tức")
@Test("addIncome append vào incomeHistory và trigger recompute")
```

---

### 18.3 Sleep × Spending Correlation 🟡

#### Mục tiêu sản phẩm
"Wow feature" — kết nối HealthKit sleep data với transaction history để tìm correlation cá nhân. Privacy-first: toàn bộ phân tích on-device. Hiển thị insight chỉ khi có đủ dữ liệu (≥ 21 ngày).

#### Domain model (`Packages/Domain/SleepCorrelationDomain/`)

```
SleepSpendingDataPoint
├── date: Date
├── sleepHours: Double          // từ HKCategoryValueSleepAnalysis
├── sleepQuality: SleepQuality  // .poor(<6h) | .fair(6-7h) | .good(7-9h)
├── totalSpending: Decimal
├── transactionCount: Int
└── categories: [CategorySpending]

SleepCorrelationInsight
├── correlationCoefficient: Double  // Pearson -1 → 1
├── significance: StatisticalSignificance  // .insufficient | .weak | .moderate | .strong
├── pattern: SpendingPattern?
├── dataPointCount: Int
├── insights: [String]
└── disclaimer: String              // luôn hiển thị, không thể tắt

SpendingPattern (enum)
├── moreSleepLessSpending(avgDiff: Decimal)
├── lessSleepMoreSpending(avgDiff: Decimal)
├── lessSleepMoreImpulse(categories: [TransactionCategory])
└── noSignificantPattern

SleepCorrelationPeriod
├── all
├── lastThirtyDays
└── lastNinetyDays
```

#### TCA Feature structure (`Packages/Features/SleepCorrelationFeature/`)

```
SleepCorrelationFeature
├── State
│   ├── healthKitAuthStatus: HKAuthorizationStatus
│   ├── dataPoints: [SleepSpendingDataPoint]
│   ├── insight: SleepCorrelationInsight?
│   ├── selectedPeriod: SleepCorrelationPeriod
│   ├── isLoading: Bool
│   └── isInsightExpanded: Bool
│
├── Action
│   ├── task
│   ├── requestHealthKitPermission
│   ├── healthKitPermissionResponse(Bool)
│   ├── dataLoaded([SleepSpendingDataPoint])
│   ├── insightComputed(SleepCorrelationInsight)
│   ├── changePeriod(SleepCorrelationPeriod)
│   └── expandInsight
│
└── Dependency
    ├── HealthKitClient: requestSleepData, requestAuthorization
    └── SleepCorrelationAnalyzer: compute(dataPoints:) -> SleepCorrelationInsight
```

#### View components

```
SleepCorrelationView
├── HealthKitPermissionBanner    // nếu chưa cấp quyền
│
├── SleepScatterPlotView         // Metal scatter plot chính
│   ├── trục X: giờ ngủ (4–10h)
│   ├── trục Y: tổng chi tiêu ngày hôm sau
│   ├── mỗi dot = 1 ngày (size theo transactionCount)
│   └── regression line overlay (nếu có significant correlation)
│
├── CorrelationInsightCard
│   ├── CorrelationStrengthBadge  // chip màu theo strength
│   ├── insight text
│   └── disclaimer footer (always visible)
│
├── SleepQualityBreakdown         // 3 cột: poor/fair/good × avg spending
│
├── PeriodPicker                  // 30 ngày / 90 ngày
│
└── InsufficientDataView          // khi < 21 data points
    └── "Cần thêm X ngày dữ liệu" progress indicator
```

#### Animation & Transition chi tiết

**A. Scatter plot (Metal shader + MTKView)**

File: `Packages/Features/SleepCorrelationFeature/Sources/Shaders/scatter_plot.metal`

```metal
// Render N dots, mỗi dot glow theo spending amount
// Dots spawn từ origin với stagger, float vào vị trí đúng
[[ stitchable ]] half4 scatterDot(
    float2 position,
    float2 dotCenter,
    float radius,
    float glowRadius,
    half4 color,
    float animationProgress
) {
    float dist = distance(position, dotCenter);
    float scale = animationProgress;
    float filled = smoothstep(radius * scale, radius * scale - 1.0, dist);
    float glow = smoothstep(glowRadius * scale, radius * scale, dist) * 0.3;
    return color * (filled + glow);
}
```

- Dots stagger animate in: `i * 0.03s` delay, spring bounce khi arrive
- Tap dot: scale 1.0 → 1.6, tooltip popup với ngày + số liệu
- Regression line: stroke draw animate 1.5s sau khi tất cả dots đã in

**B. Correlation strength badge**
- Gradient animate khi insight compute xong
- `.weak` → vàng, `.moderate` → cam, `.strong` → xanh lá / đỏ (dương/âm)
- Số correlation coefficient count-up từ 0.00 → final

**C. Sleep quality breakdown bars**
- 3 bars animate grow từ bottom với stagger 0.15s
- Chuyển period: animate từ giá trị cũ → mới (không flash)

**D. Permission flow**
- Banner slide down từ top, sau khi cho phép: fade out + scatter plot animate in
- Loading skeleton shimmer khi fetch data

**E. Insufficient data state**
- Circular progress: X/21 ngày, animate 0 → X/21 khi appear

#### Privacy implementation
- `SleepCorrelationAnalyzer` chạy hoàn toàn on-device
- Không log health data qua `Logger`
- Health data không persist vào encrypted store — đọc real-time từ HealthKit
- Disclaimer hardcoded, không thể bị xoá bởi user preferences

#### Tests

```swift
// SleepCorrelationDomainTests
@Test("correlationCoefficient > 0.5 khi spending tăng theo sleep giảm")
@Test("significance = .insufficient khi < 21 data points")
@Test("noSignificantPattern khi |correlation| < 0.2")
@Test("insights array không rỗng khi significance != .insufficient")

// SleepCorrelationFeatureTests
@Test("requestHealthKitPermission chỉ gọi 1 lần nếu đã có permission")
@Test("changePeriod recompute insight từ filtered dataPoints")
@Test("isLoading = true trong khi fetch, false sau dataLoaded")
```

---

### 18.4 Digital Financial Legacy 🔴

#### Mục tiêu sản phẩm
Kho lưu trữ cá nhân mã hoá cho toàn bộ tài sản số — để gia đình tiếp quản nếu xảy ra sự cố. **Phase 6+ vì độ nhạy cảm bảo mật và pháp lý cực cao.** Không có server, không sync cloud, chỉ export file mã hoá.

#### Domain model (`Packages/Domain/LegacyDomain/`)

```
LegacyVault
├── id: UUID
├── owner: String
├── createdAt: Date
├── lastUpdatedAt: Date
├── financialAccounts: [LegacyAccount]
├── insurancePolicies: [LegacyInsurance]
├── investments: [LegacyInvestment]
├── debts: [LegacyDebt]
├── digitalAssets: [LegacyDigitalAsset]
├── instructions: String              // hướng dẫn cho gia đình
└── emergencyContacts: [EmergencyContact]

LegacyAccount
├── id: UUID
├── institutionName: String
├── accountType: AccountType          // .bank | .wallet | .crypto | .brokerage
├── lastFourDigits: String?
├── approximateBalance: Decimal?
├── contactInfo: String
└── notes: String?

LegacyExportPackage
├── vaultData: Data                   // AES-256-GCM encrypted
├── encryptionHint: String            // gợi ý nhớ password (không lưu password)
├── exportedAt: Date
└── version: Int
```

#### TCA Feature structure (`Packages/Features/LegacyFeature/`)

```
LegacyFeature
├── State
│   ├── vault: LegacyVault?
│   ├── isLocked: Bool               // require re-auth để xem
│   ├── authenticationState: AuthState
│   ├── editingAccount: LegacyAccount?
│   ├── isExporting: Bool
│   ├── exportPassword: String       // không persist
│   └── confirmPassword: String      // không persist
│
├── Action
│   ├── task
│   ├── authenticate
│   ├── authenticationResult(Bool)
│   ├── addAccount(LegacyAccount)
│   ├── deleteAccount(id: UUID)
│   ├── exportVault(password: String)
│   ├── vaultExported(Data)
│   └── lock
│
└── Dependency
    ├── LegacyVaultStore: encrypted Keychain-backed storage
    ├── BiometricAuthClient: Face ID / Touch ID
    └── LegacyExporter: encrypt(vault:password:) -> Data
```

#### View components

```
LegacyView
├── LegacyLockedView             // Khi chưa auth
│   ├── lock icon (animated pulse)
│   └── "Mở bằng Face ID" / passcode fallback
│
├── LegacyDashboardView          // Sau khi auth
│   ├── VaultSummaryCard         // tổng số account, insurance, investment
│   ├── LegacyAccountSection     // danh sách account theo type
│   ├── LegacyInsuranceSection
│   ├── LegacyInvestmentSection
│   ├── InstructionsCard         // free text cho gia đình
│   └── ExportButton             // export file mã hoá
│
├── LegacyAccountEditorSheet
│   └── form thêm/sửa account
│
└── LegacyExportSheet
    ├── password input (double confirm)
    ├── strength indicator
    └── export/share file .kasovault
```

#### Security implementation
- **Encryption**: AES-256-GCM qua CryptoKit, key từ user password + PBKDF2 (100,000 iterations)
- **Storage**: chỉ in-memory khi đang dùng, encrypted blob trong Keychain
- **Auth**: Face ID / Touch ID bắt buộc, auto-lock sau 3 phút background
- **Export**: `.kasovault` file — encrypted, không thể đọc không có password
- **No cloud**: tuyệt đối không sync iCloud hay bất kỳ server
- **Audit log**: mỗi lần mở vault ghi local timestamp (không ghi nội dung)

#### Animation & Transition chi tiết

**A. Lock/unlock transition**
- `LegacyLockedView` → `LegacyDashboardView`: blur dissolve (`.blur(radius:)` animate 0→0)
- Lock icon: gentle pulse (`scaleEffect` 1.0 → 1.05 → 1.0, repeat) khi waiting auth
- Sau auth thành công: lock icon scale down → 0, content fade in

**B. Account list**
- Section expand/collapse: custom chevron rotate animation
- Add account: item animate in từ top với spring bounce
- Delete: swipe action + `.transition(.asymmetric(insertion: .push(from: .trailing), removal: .push(from: .trailing)))`

**C. Export sheet**
- Password strength bar fill animate khi gõ
- Strength màu: `weak` đỏ → `fair` vàng → `strong` xanh
- Export success: checkmark animate in + Metal confetti particle
- Haptic: `.notificationOccurred(.success)`

**D. Auto-lock countdown**
- Progress ring góc trên khi sắp lock (hiện 30s trước)
- Tap ring để extend thêm 3 phút
- Lock transition: blur animate nhanh 0.2s + haptic `.impactOccurred(intensity: 0.3)`

#### Tests

```swift
// LegacyDomainTests
@Test("encrypt → decrypt với đúng password trả về vault gốc")
@Test("decrypt với sai password throw LegacyError.invalidPassword")
@Test("export package version tăng đơn điệu theo mỗi lần export")

// LegacyFeatureTests
@Test("vault chỉ accessible sau khi authenticationResult(true)")
@Test("lock action set isLocked = true ngay lập tức")
@Test("exportVault không persist password vào state sau khi done")
```

---

### Lộ trình triển khai nhóm 18

```
Phase 4 (tuần 15–18)
└── 18.2 Freelancer income smoothing
    ├── Tuần 15: FreelancerDomain + tests
    ├── Tuần 16: FreelancerFeature + liquid gauge Metal shader
    ├── Tuần 17: Income chart Metal shader + UI
    └── Tuần 18: Reminders + snapshot tests + lint

Phase 5 (tuần 19–22)
└── 18.1 Money compatibility test
    ├── Tuần 19: CompatibilityDomain + algorithm + tests
    ├── Tuần 20: Quiz flow UI + card flip animation
    ├── Tuần 21: Result view + Metal radar chart + reveal shader
    └── Tuần 22: Share card + snapshot + accessibility audit

Phase 6 (tháng 6+)
├── 18.3 Sleep × spending correlation
│   ├── Tuần 1–2: HealthKit + SleepCorrelationDomain + tests
│   ├── Tuần 3–4: Scatter plot Metal shader + MTKView
│   └── Tuần 5: Privacy audit + insight cards + snapshot
└── 18.4 Digital financial legacy
    ├── Tuần 1–2: LegacyDomain + CryptoKit encryption + tests
    ├── Tuần 3–4: LegacyFeature + biometric auth + UI
    └── Tuần 5–6: Export flow + security review
```

### Dependency graph nhóm 18

```
CompatibilityFeature
└── CompatibilityDomain (mới, standalone)

FreelancerFeature
├── FreelancerDomain (mới)
└── TransactionDomain (đọc giao dịch để tính toán)

SleepCorrelationFeature
├── SleepCorrelationDomain (mới)
├── HealthKitClient (mới dependency trong Core)
└── TransactionDomain (đọc lịch sử chi tiêu)

LegacyFeature
├── LegacyDomain (mới, standalone)
└── CryptoKit (Apple native, không thêm dependency)
```

### Checklist trước khi ship mỗi tính năng

- [ ] Domain tests coverage ≥ 90%
- [ ] TCA `TestStore` cho mọi Action
- [ ] Snapshot tests light + dark + Dynamic Type XL
- [ ] Reduce Motion fallback cho mọi animation
- [ ] Accessibility: VoiceOver label cho mọi interactive element
- [ ] Privacy manifest nếu dùng HealthKit
- [ ] Không có `print()` hoặc PII trong `Logger`
- [ ] `tuist build` không warning
- [ ] `swiftlint` + `swiftformat` pass

---

## 19. Pricing

- [x] Free tier - Đã định nghĩa qua `SubscriptionTier.free` trong `PaywallDomain`; unlock `csvExport` + `widgets` mặc định; là tier khởi tạo `SubscriptionEntitlement.free`.
- [x] Pro tier - Đã định nghĩa qua `SubscriptionTier.pro`; unlock unlimitedHistory, ocrReceipt, bankStatementImport, voiceEntry, subscriptionTracker, aiInsights, spendingForecast, savingsGoals, advancedReports, iCloudSync, appleWatch; productID `com.vuongnguyen.kaso.pro.monthly` 49.000 ₫/tháng và `com.vuongnguyen.kaso.pro.yearly` 399.000 ₫/năm (recommended badge).
- [x] Family tier - Đã định nghĩa qua `SubscriptionTier.family`; unlock toàn bộ tier Pro + familySharing + familyCompatibility; productID `com.vuongnguyen.kaso.family.monthly` 79.000 ₫/tháng và `com.vuongnguyen.kaso.family.yearly` 599.000 ₫/năm.
- [x] Paywall thông minh - Đã có `PaywallDomain` (SubscriptionTier Comparable rank free<pro<family, SubscriptionFeatureFlag 15 toggle với `minimumTier`, PricingPlan + bundledCatalogue, SubscriptionEntitlement + Repository, PaywallStoreClient abstraction với `ResolvedProduct`/`PaywallPurchaseOutcome` decouple khỏi StoreKit, `PaywallStoreClient.empty`/`.preview`); `PaywallFeature` TCA với task load entitlement + products, selectTier picker, purchaseButtonTapped → outcome routing (purchased/cancelled/pending/failed) → save entitlement, restoreButtonTapped flow, success/error banners; UI `PaywallView` + `PaywallCards` hero + tier segmented picker + feature checklist theo tier + plan rows với recommended badge + restore button + legal footer; live `LivePaywallStoreClient` trong App target dùng StoreKit 2 (`Product.products(for:)`, `product.purchase()`, `Transaction.currentEntitlements`, `AppStore.sync()` cho restore, verify check + finish transaction), tier derived từ productID; persistence mã hoá `EncryptedSubscriptionEntitlementStore` AES-GCM keychain; ghép vào `KasoRootFeature` qua `isPaywallPresented` + floating "Nâng cấp" button; full localization VI/EN cho 15 feature flag + 3 tier + cycle + status. Tests: 6 domain test + 5 TCA TestStore test cover load, tier select, purchase outcomes, restore.

## 20. Lộ trình phát triển

- [x] Giai đoạn 1 - MVP: đã có onboarding cá nhân hoá, dashboard tháng, nhập giao dịch thủ công đầy đủ, phân danh mục tuỳ chỉnh, ngân sách theo danh mục, lịch sử giao dịch, chủ đề/dark mode, no-spend day tracker, hours of life converter và phantom expense ledger cơ bản — đủ scope free tier theo `plan.md` Giai đoạn 1.
- [x] Giai đoạn 2 - Killer feature: đã hoàn thành toàn bộ Gamification — 7.1 streak & điểm thưởng, 7.2 huy hiệu & thành tích, 7.3 level tài chính và 7.4 weekly challenge.
- [x] Giai đoạn 3 - Retention: đã hoàn thành 14.1 Round-up tiết kiệm, 14.3 Guilt-free budget và 17.1 Cooling-off period trong tab Wellness. AI insight, dự báo, mục tiêu tài chính, gamification đầy đủ đã có sẵn từ các phase trước.
- [x] Giai đoạn 4 - Differentiation: đã có money compatibility test và freelancer income smoothing MVP trong Wellness.
- [ ] Giai đoạn 5 - Growth
- [ ] Giai đoạn 6 - Expansion

## Nền tảng đã có ngoài checklist feature

- [x] Auth flow với `AuthFeature` và `KeychainAuthSessionStore`.
- [x] Root composition `Auth -> Onboarding -> Transaction`.
- [x] Design tokens cơ bản trong `KasoDesignSystem`.
- [x] Test reducer/domain cho các module hiện có.
- [x] Persistence giao dịch thật sự: app dùng `EncryptedTransactionStore` với file mã hoá và key trong Keychain.
- [x] Domain foundation cho subscription detection, anomaly detection, CSV export, no-spend tracking, saving goals, investment portfolio, phantom expense ledger và hours-of-life conversion.
- [x] Tab `Wellness` trong root composition gom `GamificationFeature`, `HoursOfLifeFeature`, `PhantomExpenseFeature`, `CompatibilityFeature`, `FreelancerFeature`, `SleepCorrelationFeature` và `LegacyFeature` qua segmented picker scrollable để tránh thêm tab thứ 6.
- [x] Persistence mã hoá mới cho `FreelancerProfile`, `LegacyVault` và `GamificationProfile`.
