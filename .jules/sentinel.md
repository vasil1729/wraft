## 2024-05-22 - Gnuplot Command Injection and Path Traversal
**Vulnerability:** Found `generate_gnu_gantt_chart` in `lib/wraft_doc/documents/documents.ex` susceptible to Command Injection via unsanitized `title` injected into Gnuplot script, and Path Traversal via unsanitized `filename` used in `cp` command and output path.
**Learning:** `System.cmd` does not protect against vulnerabilities if the command arguments (like a script file) are constructed using unsanitized user input. Also, string replacement in script templates is dangerous without strict escaping.
**Prevention:** Sanitize filenames with `Path.basename`. Escape all user inputs injected into scripts (e.g., escape quotes and backslashes for Gnuplot strings). Use safe path joining.
