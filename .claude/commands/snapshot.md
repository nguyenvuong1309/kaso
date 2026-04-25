---
description: Quản lý snapshot test — record mới, verify, hay clean stale snapshot
argument-hint: [record|verify|clean] (default: verify)
---

Quản lý snapshot test cho Kaso.

## Mode

### `verify` (default)
Chạy snapshot test bình thường, fail nếu khác baseline.
```bash
swift test --filter Snapshot
```

### `record`
Record lại snapshot mới — **CHỈ chạy khi UI thực sự thay đổi có chủ đích**.
```bash
SNAPSHOT_TESTING_RECORD=true swift test --filter Snapshot
```
- Hỏi user xác nhận trước khi record
- Sau khi record: hiển thị diff (số file changed) cho user review
- KHÔNG commit luôn — user phải review từng file

### `clean`
Xoá snapshot không còn được reference (orphan).
```bash
# Tự script: scan __Snapshots__ folder, cross-check với test file
```

## Quy tắc

- Snapshot phải test ở: light mode, dark mode, Dynamic Type XL
- Tên snapshot file phải khớp test name
- KHÔNG record khi đang debug — chỉ khi đã verify thay đổi đúng ý
- Nếu CI fail vì snapshot: KHÔNG fix bằng cách record local — fix root cause hoặc xác nhận với user

## Output

- Số snapshot pass / fail / new
- Path tới folder `__Snapshots__/` để user mở visual diff
- Đề xuất tool view diff: Kaleidoscope hoặc `git diff` (cho text snapshot)
