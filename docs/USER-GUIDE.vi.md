# Dùng ak

[English](USER-GUIDE.md) · **Tiếng Việt** · [日本語](USER-GUIDE.ja.md)

## Bắt đầu một task

Cài theo host bạn dùng rồi mở repo sản phẩm. Gõ `/ak` kèm việc cần làm hoặc chọn
skill start của ak. [Hướng dẫn cài đặt](INSTALL.md)

```text
/ak Sửa export CSV để giữ lại bộ lọc đang chọn
/ak TICKET-123 https://tracker.example/TICKET-123
```

Mã ticket là tùy chọn. Khi cần lưu worklog, ak có thể tự đặt mã `adhoc-…`.
Câu hỏi chỉ đọc được trả lời trực tiếp. Nếu agent cần bạn quyết định, trả lời ngay
trong hội thoại. Với việc lớn có nhiều phần giao độc lập, agent đề xuất cách chia,
chờ bạn chốt rồi xử lý các task con theo thứ tự phụ thuộc.

## Lần đầu dùng ở một dự án

Agent đọc phần có liên quan trong hướng dẫn repo, manifest, script, CI và điểm vào.
Nó điền `~/.workspaces/<slug>/PROJECT-FORM.md` bằng những gì nhiều task sẽ dùng lại,
như module nằm ở đâu, lệnh kiểm tra là gì và cần chạy trong thư mục nào.

Sau khi đọc, agent hỏi có convention hoặc kỳ vọng nào bạn muốn nó chú ý. Nếu bạn
khó gọi tên quy ước, hãy kể cách bạn làm một task gần đây hoặc lúc nào bạn xem là
đủ để bàn giao. Agent tóm lại thành rule có điều kiện và phạm vi rõ, đưa bạn xem
rồi lưu rule bạn xác nhận. Bạn có thể bỏ qua phần hỏi và làm tiếp.

Task sau đọc lại mục liên quan và chỉ cập nhật mục thiếu hoặc lỗi thời. Ngoại lệ
cho một task nằm trong worklog của task đó. Dùng `/ak:learning` khi muốn chỉ định
một mục cần học thêm hoặc đổi quy ước lâu dài. Dùng `/ak:coaching` để sửa kiến thức
nghiệp vụ đã lưu.

## Một đường từ nhận việc đến bàn giao

| Chặng | Agent làm gì |
|---|---|
| Hiểu việc | Đọc yêu cầu và vùng code liên quan một lượt. Chốt phạm vi, Risk và tiêu chí nghiệm thu. Gom câu hỏi khi thật sự cần bạn quyết định. |
| Sửa | Thực hiện theo phạm vi. Với thay đổi hành vi, ghi test tái hiện và kết quả sau sửa khi có môi trường chạy. |
| Kiểm chứng | Review diff, xử lý lỗi tìm thấy và chạy kiểm tra phù hợp. Dùng lại kết quả nếu lệnh, đầu vào, trạng thái code và tiêu chí vẫn khớp. |
| Bàn giao | Tóm tắt đã sửa gì, đã kiểm tra gì và còn vướng ở đâu. Mặc định dừng ở G8, sẵn sàng review. |

Bug UI phải được tái hiện trên trình duyệt trước khi sửa. Mọi ticket UI cần một kiểm
tra hành vi đạt trên bản code hiện tại. Thay đổi giao diện còn cần golden test đạt khi
so với ảnh mẫu đã duyệt. Thiếu môi trường hoặc kiểm tra thất bại sẽ chặn bước tương
ứng. [Quy trình kiểm chứng UI](../references/ui-verification.md)

## Điểm cần duyệt và chuẩn bị phát hành

P0 gồm tiền, phân quyền, PII, thay đổi dữ liệu cũ hoặc migration khó đảo ngược.
Luồng cần ghi chú bảo mật, xác nhận G3 của bạn và PM trước khi sửa, cùng bằng chứng
test máy có thể kiểm tra. P1/P2 rõ yêu cầu có thể đi hết luồng mặc định mà không cần
một lượt xác nhận G3 riêng. `--strict` bật các gate nghiêm ngặt.

Dùng `--ship` để chuẩn bị phát hành trong cùng flow. Đường này cần G3 và G9 strict.
P0/P1 cũng cần AUDIT được người dùng xác nhận. P2 có thể ghi lý do bỏ qua AUDIT nếu
project hoặc người dùng không yêu cầu. Quyền push, merge và deploy cần được giao rõ.

```text
/ak TICKET-123 Chuẩn bị phát hành --ship
CONFIRM G3: TICKET-123 <tên> <YYYY-MM-DD>
CONFIRM G3-PM: TICKET-123 <tên PM> <YYYY-MM-DD>
AUDIT CONFIRM: TICKET-123 <tên> <YYYY-MM-DD>
```

Agent chỉ ghi các xác nhận đã được gửi thật và áp dụng cho task. Audit đối chiếu
bằng chứng giữa các file, ví dụ rollback có xử lý đúng migration được mô tả hay không.

## Các lệnh dùng khi cần

| Lệnh | Việc cần làm |
|---|---|
| `/ak` | Bắt đầu hoặc tiếp tục task |
| `/ak:learning`, `/ak:coaching` | Cập nhật form hoặc sửa kiến thức nghiệp vụ |
| `/ak:decompose` | Đề xuất cách chia epic |
| `/ak:spec`, `/ak:clarify`, `/ak:confirm`, `/ak:plan` | Thao tác riêng trên yêu cầu và kế hoạch |
| `/ak:build`, `/ak:review`, `/ak:fix`, `/ak:test` | Thao tác riêng trên thay đổi và kiểm chứng |
| `/ak:check`, `/ak:ship`, `/ak:audit` | Chạy checker, chuẩn bị ship hoặc audit riêng |
| `/ak:status`, `/ak:clean` | Xem tiến độ hoặc lưu trữ worklog đủ điều kiện |
| `/ak:feedback`, `/ak:flow-diagram` | Báo vấn đề của ak hoặc dựng lại luồng UI |

Mỗi task có thư mục `~/.workspaces/<slug>/worklogs/<ticket>/`. Lịch sử chạy lệnh
lưu trong `06b-test-evidence.md`. Các artifact khác dẫn đến cùng bằng chứng.
`/ak:clean` mặc định lưu trữ và cần G9 trừ khi có yêu cầu `--force` rõ ràng.

Xem [điều kiện từng stage](../references/stage-contract.md),
[quy tắc Risk](../references/risk.md) và [mẫu CI](../templates/ci/github-actions-ak.yml)
khi cần dùng checker thủ công hoặc bắt buộc qua CI.
