# Daybook · Session 5 submission

| Field | Value |
| --- | --- |
| Student | Pacifique Bakundukize |
| Student ID | 26798 |
| Group | B (Tuesday) |
| Repository | https://github.com/pac-cee/daybook |
| Deadline in submission PDF | Wednesday, 28 October 2026, 11:59 PM |
| Group B form | https://forms.gle/w68h6dtKp31bemRj7 |

The submission PDF supersedes the older deadline in the HTML guide. It asks for the mini project, a public GitHub repository, a README with four precisely named screenshots, and submission of the repository link through the correct group form.

## Evidence

| File | What it demonstrates |
| --- | --- |
| `screenshots/before.png` | Three added tasks, shown with the Group B notes filter |
| `screenshots/after.png` | Those exact records after the app has stopped and started in another process |
| `screenshots/api.png` | Successful live Open-Meteo response rendered in Daybook's weather feature |
| `screenshots/no-internet.png` | Production weather error state and Retry after an injected network failure |

The files also exist in `daybook/screenshots/` for the application-specific README. These native captures replace fixture renders as the submission evidence. Older headless fixtures remain identified as such in the development documentation.

## Capture method and results

- Device: iPhone 17 Pro simulator, iOS 26.4.
- Date: 28 October 2026.
- The first native integration-test process adds three named tasks through the actual form and records every persisted field.
- The process exits. A second integration-test process starts against the same application data, checks exact task IDs/fields, reapplies the notes filter and captures the after image. It does not seed or recreate those three tasks.
- Both phases pass. `--no-uninstall` preserves the application and database between integration-test runs.
- The live API capture asserts a successful fresh request and rejects cached/offline results. The original response is retained in `submission-evidence/api-observation.json`.
- The persistence reference rows are retained in `submission-evidence/before-records.json`.
- All 10 ordinary Flutter tests pass. Static analysis passes for both projects.
- The earlier direct-engine verifier passed 44 checks; that is supplementary evidence, not a substitute for these native screenshots.

### Offline-test distinction

The PDF describes using Airplane Mode. iOS Simulator shares the Mac's network connection, so this automated capture uses a deliberate `SocketException` at the network request boundary instead. The UI, error handling and Retry action are production code. After capture, the failure is removed and Retry is checked against the real Open-Meteo endpoint. This limitation is disclosed in both READMEs; no Airplane Mode capture is claimed.

## Storage distinction

The PDF's sample README describes SharedPreferences. This implementation uses SQLite for tasks, undo and weather records, as requested, and SharedPreferences for city selection. The README names the storage actually implemented rather than copying an inaccurate claim from the template.

## Submission checklist

- [x] Student name, ID, group and mini-project name in README.
- [x] Three added task records persist through separate application processes.
- [x] Live external API data shown.
- [x] Error/Retry state captured, with offline-simulation method disclosed.
- [x] Four correctly named screenshot files and README image links.
- [x] Code organization, API, persistence, testing and run instructions documented.
- [x] Public GitHub push succeeded. The anonymous repository page and all four image URLs returned HTTP 200; the rendered README contains all four screenshot references.
- [ ] Group B form submission: not submitted by this session.

The PDF also requires students to explain their code. The README's concepts-to-files table and `ASSIGNMENT.md` provide a study map; neither claims that code assistance was not used.
