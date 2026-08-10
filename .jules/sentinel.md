## 2024-05-25 - Timing Attack and User Enumeration in Admin SessionController
**Vulnerability:** The admin login endpoint (`WraftDocWeb.SessionController.create`) skipped password verification (`Bcrypt.verify_pass` or `Bcrypt.no_user_verify`) for non-existent administrative users or deactivated users, allowing attackers to enumerate admin emails via timing attacks.
**Learning:** In Elixir, `with` statements can inadvertently skip required side-effects on early failures. For authentication, missing users or deactivated users must still trigger a hashing operation.
**Prevention:** Extract the user lookup into a dedicated `case` statement, and unconditionally execute `Bcrypt.no_user_verify()` on the failure path to ensure consistent response times regardless of user existence.
