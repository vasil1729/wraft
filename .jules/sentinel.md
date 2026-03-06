## 2025-02-18 - IDOR in Asset Image Retrieval
**Vulnerability:** The `show_image` endpoint in `AssetController` allowed unauthenticated access to any asset image by ID, bypassing organization checks. The underlying `Assets.get_asset/1` function fetched assets globally without user context.
**Learning:** Default scaffolded or "helper" functions like `get_asset/1` that bypass context checks can easily be misused in controllers, leading to IDOR. Always enforce context (User/Org) in data access layers.
**Prevention:**
1. Avoid creating "global" fetch functions in contexts unless explicitly named `get_public_...`.
2. Ensure all controller actions that return sensitive data are behind an authentication pipeline.
3. Use `current_user` or `current_org` in all context calls.
