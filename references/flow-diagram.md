# Flow-diagram format (used by `skills/flow-diagram`)

Persona: Senior QA Automation / Tech Lead reconstructing a UI reproduction flow combined with deep
code debugging, as a plain-text Unicode box-drawing diagram (`┌ ─ ┐ │ └ ┘ ├ ┤ ┬ ┴ ┼ ► ▼ ◄ ▲`).

## Mandatory rules

1. **Auth/credentials.** The first `👤 USER` line states Role/Account (e.g. `Admin`, `Employer`,
   `Candidate`). Any login step includes concrete fake credentials:
   `Email/Username: admin@example.com`, `Password: password123`.
2. **Action prefixes.**
   - Right-side annotation (`┈┈►`): starts with `[Action hiện tại]: <where the user is / what
     they're doing on this screen>`.
   - Inside each box: starts with `[Action tiếp theo]: <the specific click/input that moves to the
     next URL/screen>`.
3. **When a bug surfaces**, break out a dedicated right-side block:
   ```
   ┈┈► ⚠️ BUG PHÁT SINH TẠI ĐÂY:
       📍 Vị trí: `file:line` or `config/routes.rb & ControllerName`
       🌐 URL Hiện tại (Sai): <the actual wrong URL/state shown>
       🎯 Kỳ vọng đúng: <correct URL/screen + cite where this is grounded in the codebase>
       💡 Nguyên nhân: <root cause in the real code/routing — e.g. controller missing an
          action/route handler, or not reading a query param>
   ```
4. **Multi-bug layout.** N distinct bugs in the input → exactly N independent diagrams, headed
   `### BUG #1: <title>`, `### BUG #2: <title>`, etc. Main flow is centered/symmetric; a branch
   splits evenly left/right from one center point then reconverges on the middle axis. Wrap every
   diagram in a ```` ```text ```` fenced block.

## Few-shot template

```text
                     👤 USER (Role: Admin / Recruiter)
                                     │
                                     │ ① Mở trình duyệt & Đăng nhập
                                     ▼
                        ┌──────────────────────────┐               ┈┈► [Action hiện tại]: Nhập thông tin đăng nhập tài khoản
                        │ 🌐 /admin/login          │
                        │ 📝 [Action tiếp theo]:   │
                        │    Điền Email:           │
                        │    `admin@company.com`   │
                        │    Điền Password:        │
                        │    `Secret@123`          │
                        │ 🖱️ [Action tiếp theo]:   │
                        │    Click [Đăng nhập] để  │
                        │    vào /admin/dashboard  │
                        └────────────┬─────────────┘
                                     │
                                     │ ② Chuyển hướng sau đăng nhập
                                     ▼
                        ┌──────────────────────────┐               ┈┈► [Action hiện tại]: Đang ở trang Dashboard quản trị
                        │ 🌐 /admin/dashboard      │
                        │ 🖱️ [Action tiếp theo]:   │
                        │    Click Button [Tìm     │
                        │    ứng viên] để sang     │
                        │    trang /resume_searches│
                        └────────────┬─────────────┘
                                     │
                                     │ ③ Điều hướng sang danh sách tìm kiếm
                                     ▼
                        ┌──────────────────────────┐               ┈┈► [Action hiện tại]: Đang xem form tìm kiếm thông thường
                        │ 🌐 /resume_searches      │
                        │ 🖱️ [Action tiếp theo]:   │
                        │    Click Tab [AI Search] │
                        │    để chuyển sang URL    │
                        │    /resume_searches?tab=ai
                        └────────────┬─────────────┘
                                     │
                                     │ ④ Gửi request chuyển tab
                                     ▼
                        ┌──────────────────────────┐               ┈┈► ⚠️ BUG PHÁT SINH TẠI ĐÂY:
                        │ ❌ /resume_searches      │                   📍 Vị trí: `config/routes.rb` & `ResumeSearchesController`
                        │    ?tab=ai               │                   🌐 URL Hiện tại (Sai): `/resume_searches?tab=ai`
                        │ 🖱️ Thao tác: Bị lỗi 404 /│                   🎯 Kỳ vọng đúng: `/member_recommendation_search`
                        │    Route NotFound        │                      (Căn cứ: Route map thực tế trong codebase)
                        └──────────────────────────┘                   💡 Nguyên nhân: `ResumeSearchesController` chỉ khai báo
                                                                          các action RESTful cơ bản (`index`, `show`), hoàn toàn
                                                                          không handle param `tab=ai`. Chức năng AI Recommend thực tế
                                                                          nằm riêng biệt tại `MemberRecommendationSearchController#index`.
```
