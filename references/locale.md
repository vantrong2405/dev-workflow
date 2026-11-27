# Locale

Use the user's preferred language for chat. Gate labels such as `CONFIRM G3:`,
`AUDIT CONFIRM:`, and `PASS` stay in English for the checker.

1. Use the explicit language preference in this conversation when given.
2. Otherwise use `Chat locale` in the project form or the legacy domain index.
3. For a new workspace use the language of the conversation as a default. Let
   the user correct it in the convention conversation or later. A standalone
   stage can use the same default without beginning onboarding just for locale.

Record the code in the project form at setup and mirror it in the worklog index
when creating a ticket. Keep field labels and IDs in English and write notes in
the user's language.
