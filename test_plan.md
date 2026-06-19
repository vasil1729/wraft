1. **Analyze Security Issues:** Find timing attack vulnerabilities in user authentication flows where `Bcrypt.verify_pass` is bypassed on failed user lookups, allowing user enumeration.
2. **Fix `UserController`:** Update `lib/wraft_doc_web/controllers/user_controller.ex` to extract `Account.find/1`, call `Bcrypt.no_user_verify()` if the user is not found (`{:error, :invalid_email}`), and map the error to `{:error, :invalid}`.
3. **Fix `SessionController`:** Update `lib/wraft_doc_web/controllers/session_controller.ex` to look up the internal user, call `Bcrypt.no_user_verify()` if nil, and verify the password *before* checking the `is_deactivated` status.
4. **Run Tests:** Execute `docker compose run backend mix test` to verify the application tests pass and the security fixes didn't break core functionality.
5. **Pre-commit Checks:** Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
6. **Submit PR:** Submit a PR with the Sentinel-formatted security fix.
