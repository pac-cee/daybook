# Verification record · 28 October 2026

- **10 ordinary Flutter tests passed:** model parsing, malformed responses, HTTP failures, city switching races, offline recovery and SQLite persistence.
- **Native before phase passed:** three tasks entered through the actual form, live API response captured, production error state captured with an injected SocketException, Retry checked against the real API.
- **Native after phase passed in a separate process:** exact task IDs and every saved field match the before records; screenshot captured after restoring from SQLite.
- **44 supplementary direct-engine checks passed:** database reopen, request failures, form interactions and layout states. These older fixture renders are not the submitted live API evidence.
- **Daybook native iOS debug build succeeded:** iPhone 17 Pro simulator, iOS 26.4.
- Screenshot dimensions, all four exact filenames and both README image paths checked.

The normal Daybook entry point is rebuilt and restored after the integration tests. The native evidence and reproduction instructions are in [SUBMISSION.md](SUBMISSION.md). The offline screenshot is a controlled request-failure simulation rather than an Airplane Mode capture; both READMEs disclose that distinction.

All task data is local. SQLite stores structured records and SharedPreferences stores selected city. No cross-device synchronization or future-capstone backend is claimed.
