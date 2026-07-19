1. **Analyze `generate_gnu_gantt_chart` for security vulnerabilities**
   - The function `generate_gnu_gantt_chart` in `lib/wraft_doc/documents/documents.ex` is vulnerable to path traversal, OS command injection via Gnuplot scripts, and does not properly clean up temporary files.
2. **Update `generate_gnu_gantt_chart/2` in `lib/wraft_doc/documents/documents.ex`**
   - Sanitize user inputs (`filename`, `title`) to restricted character sets.
   - Strictly escape Gnuplot variables (backslashes, quotes, backticks) and strip newlines to prevent multi-line command injection.
   - Use a temporary UUID-based directory for the input CSV and generated script.
   - Save the generated SVG to the persistent output directory.
   - Clean up the temporary directory after Gnuplot execution.
   - Ensure the function returns the `{output_string, exit_status}` tuple from `System.cmd/2`.
   - Use `File.cp!` instead of `System.cmd("cp", ...)` for copying files.
3. **Run Tests**
   - Run the backend tests using `docker compose run backend mix test` to verify no regressions occur and tests pass.
4. **Log Sentinel Learnings**
   - Create or update `.jules/sentinel.md` with the critical learnings of this vulnerability, matching the required Sentinel format.
5. Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
