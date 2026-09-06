# Tracker fetch (Redmine link → real content, not a guess)

Used by `:spec`/`:start` whenever the ticket URL/path argument is a tracker link, not a local file.
Don't ask the user to paste the description if the tracker is actually reachable — read it.

## Detect a Redmine link

`https?://<host>/issues/(\d+)` (strip a trailing `.json`/`.xml` or `#note-N` fragment first) — the
captured group is the numeric issue id. Redmine issue URLs are host-agnostic in shape; the host
itself comes from the URL, never hardcode one project's Redmine domain.

## How to read it — check which path this session actually has

1. **MCP Redmine tools present** (tool names start `mcp__redmine__*`, e.g. `getIssue`) — preferred,
   no key to manage:
   ```
   mcp__redmine__getIssue({ pathParams: { format: "json", issueId: <id> },
                             queryParams: { include: ["journals", "attachments", "relations"] } })
   ```
   `journals` = the comment thread — often has the actual decision/clarification, not just the
   original description; read it, don't stop at `description`.
2. **No MCP Redmine tool available** — fall back to the REST API with an API key:
   ```bash
   curl -s "https://<host>/issues/<id>.json?key=$REDMINE_API_KEY&include=journals,attachments"
   ```
   `REDMINE_API_KEY` must already be set in the environment — never invent, hardcode, or ask the
   user to paste a key inline in chat. If it isn't set, tell the user which env var name is missing
   and stop; don't silently skip the fetch and treat the link as opaque text.
3. Neither available → report that plainly (`"Link Redmine #<id> nhưng ko có MCP redmine hay
   REDMINE_API_KEY trong session này — dán nội dung ticket vào giúp mình"`) instead of fabricating
   a plausible-sounding ticket body.

## Using the result

Pull `subject`, `description`, `status`, `tracker`, any custom fields, and the `journals` thread
into the spec as **`DOCUMENTED`** provenance (reporter wording, not independently verified) — cite
`Redmine #<id>` as the source, same as any other requirement source in `references/ba-integrity.md`.
A journal entry that changes the original ask (scope narrowed, a field renamed) overrides the
original `description` — note both, and which one is current.
