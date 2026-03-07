# Sentinel Journal

This journal records CRITICAL security learnings, vulnerability patterns, and architectural gaps found in the codebase.

## Format
`## YYYY-MM-DD - [Title]`
`**Vulnerability:** [What you found]`
`**Learning:** [Why it existed]`
`**Prevention:** [How to avoid next time]`

## 2025-02-18 - Command Injection in Gantt Chart Generation
**Vulnerability:** A critical command injection vulnerability was found in `generate_gnu_gantt_chart/2` where user input (title) was directly substituted into a Gnuplot script using `String.replace/3` without sanitization. Gnuplot scripts allow executing shell commands via the `system` command or backticks.
**Learning:** String substitution for generating scripts or code is inherently dangerous. The original code assumed internal trust or didn't account for the capabilities of the Gnuplot scripting language. Additionally, path handling was unsafe (`Path.expand` without `Path.basename` on upload), and temp files were predictable.
**Prevention:**
1.  **Sanitization:** Always sanitize user input before embedding it in scripts. For Gnuplot, this means escaping backslashes, double quotes, and backticks.
2.  **Safe File Operations:** Use `Path.basename` for user-provided filenames. Use `System.tmp_dir!()` with unique subdirectories (UUIDs) to prevent race conditions.
3.  **Pattern:** Avoid "building code" with string concatenation/replacement. If unavoidable, use strict whitelisting or robust escaping functions specific to the target language.
