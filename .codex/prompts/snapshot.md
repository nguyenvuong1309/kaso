---
description: Quản lý snapshot test — record, verify, hoặc clean.
---

Quản lý snapshot test. Argument: `record` | `verify` | `clean` (default `verify`).

## Mode

### `verify` (default)
```bash
swift test --filter Snapshot
```
Fail nếu khác baseline.

### `record`
**CHỈ chạy khi UI thực sự thay đổi có chủ đích.**

```bash
SNAPSHOT_TESTING_RECORD=true swift test --filter Snapshot
```

- Hỏi user xác nhận trước khi record
- Sau record: hiển thị diff (số file changed)
- KHÔNG commit luôn — user review từng file

### `clean`
Scan `__Snapshots__/` folder, cross-check với test file, list orphan.

```bash
find . -path '*/__Snapshots__/*' -type f | while read f; do
    test_name=$(basename "$(dirname "$f")")
    test_file="$(dirname "$(dirname "$f")")/${test_name%.*}.swift"
    [[ ! -f "$test_file" ]] && echo "Orphan: $f"
done
```

## Quy tắc

- Snapshot test ở: light, dark, Dynamic Type XL
- Tên file khớp test name
- KHÔNG record khi đang debug — chỉ khi đã verify thay đổi đúng ý
- CI fail snapshot: KHÔNG fix bằng record local — fix root cause hoặc xác nhận với user

## Output

- Số snapshot pass/fail/new
- Path tới `__Snapshots__/` để user mở visual diff
- Đề xuất tool: Kaleidoscope (image) hoặc `git diff` (text)
