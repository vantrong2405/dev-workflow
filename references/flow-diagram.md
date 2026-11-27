# UI reproduction diagram

Use this format for `:flow-diagram` and for the pre-fix handoff in `:clarify`.

## Prepare the run

- Use the project's configured local or test environment. Inspect its existing launch
  commands, fixture or seed scripts, and the reported UI path. Prepare the smallest
  dataset and test role that can reproduce the issue. Run an existing safe setup when
  needed and record what actually ran. If access, setup, or data is missing, identify
  the exact prerequisite before asking the user to run the case.
- Prefer the English UI when the app supports it. Use the exact labels shown on screen
  and record the locale. Preserve the reported locale for localization-dependent bugs
  or when English is unavailable. Explanations use the project chat language.
- Start every diagram with `👤 USER` and the role/account. Include the exact values
  for fixture inputs. For login show a concrete synthetic username/password pair only
  when it belongs to the prepared disposable fixture. Label illustrative credentials as
  examples. For existing protected accounts, show the test role and how to retrieve the
  login through the approved channel. Keep real passwords, tokens and personal data out
  of chat, diagrams, screenshots and worklogs.

## Draw each distinct bug

1. Remove agent chatter, duplicates, unrelated logs, and noise. For N distinct bugs,
   output exactly N independent diagrams, each headed `### BUG #N: ...` and wrapped
   in a `text` fence. Variants that share the same defect may branch in one diagram.
2. Use Unicode box-drawing. Keep boxes and arrows on one center axis. Draw branches
   at equal offsets and reconverge at the same center. Use a numbered transition per
   concrete action. Include the screen and URL. Inside each actionable box, write
   `[Action tiếp theo]` and the exact click, input, key, or selection. To its right
   start the note with `[Action hiện tại]` and describe the current state. Split
   steps when a click changes the screen or is required for someone to follow it.
3. Put the bug block at the failing transition. Include `⚠️ BUG PHÁT SINH TẠI ĐÂY`,
   `Vị trí` with a file/line or route/controller, `URL Hiện tại (Sai)` with the observed
   URL or reported URL labeled as such, `Kỳ vọng đúng` with its source, and `Nguyên nhân`
   tied to code inspection. Label an unverified diagnosis `chưa xác nhận` and cite
   what was checked. When a bug leaves the URL unchanged, give the same URL and describe
   the difference in visible behavior.
4. Say what the user should send back at the final box: observed result, actual URL,
   and a screenshot or recording that excludes secrets. Save the diagram and show it
   in the chat before the user runs it. An authored diagram by itself is a pending
   reproduction.

## Example using a disposable fixture

The example UI has English labels and seeded fake login data. Paths and outcomes below
illustrate the format. Use the actual project and its test data on a real ticket.

### BUG #1: Popup opens and the page jumps

```text
                                        👤 USER (Role: Admin / Account: admin@example.com)
                                        │
                                        │ ① Open the test URL
                                        ▼
                  ┌───────────────────────────────────────────┐    ┈┈► [Action hiện tại]: Màn hình Sign in
                  │ URL: /login                               │
                  │ [Action tiếp theo]: Fill [Email]          │
                  │   with admin@example.com                  │
                  │ [Action tiếp theo]: Fill [Password]       │
                  │   with password123 (test fixture)         │
                  │ [Action tiếp theo]: Click [Sign in]       │
                  └─────────────────────┬─────────────────────┘
                                        │ ② Sign in
                                        ▼
                  ┌───────────────────────────────────────────┐    ┈┈► [Action hiện tại]: Dashboard, signed in
                  │ URL: /dashboard                           │
                  │ [Action tiếp theo]: Click [Learning]      │
                  └─────────────────────┬─────────────────────┘
                                        │ ③ Open the Learning page
                                        ▼
                  ┌───────────────────────────────────────────┐    ┈┈► [Action hiện tại]: Sơ đồ hiện, ghi vị trí cuộn
                  │ URL: /learning                            │
                  │ [Action tiếp theo]: Click [Project setup] │
                  └─────────────────────┬─────────────────────┘
                                        │ ④ Click [Project setup]
                                        ▼
                  ┌───────────────────────────────────────────┐    ┈┈► ⚠️ BUG PHÁT SINH TẠI ĐÂY:
                  │ URL: /learning#project-setup              │          📍 Vị trí: catalog.js:42 (ví dụ)
                  │ Popup mở, trang cuộn về cuối.             │          🌐 URL Hiện tại (Sai): /learning#project-setup
                  │ Gửi URL thực tế và ảnh vùng popup.        │          🎯 Kỳ vọng đúng: /learning giữ nguyên vị trí cuộn (AC-01)
                  │                                           │          💡 Nguyên nhân: click handler mở popup nhưng để link tự điều hướng.
                  └───────────────────────────────────────────┘
```
