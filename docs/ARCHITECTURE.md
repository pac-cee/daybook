# Codebase and storage

## Projects

```
session5-pack/
├── Session5-Data-From-The-Internet.pptx   original lesson slides
├── kigali-weather.html                 original detailed guide
├── kigali_weather/                     runnable weather app + reusable feature library
│   ├── lib/
│   │   ├── main.dart                   WeatherApp entry point
│   │   ├── task_app.dart               Daybook composition root
│   │   ├── core/
│   │   │   ├── app_database.dart       SQLite schema/open/close
│   │   │   ├── services.dart           dependency construction/lifecycle
│   │   │   └── theme.dart              shared tokens, icons and surfaces
│   │   └── features/
│   │       ├── weather/
│   │       │   ├── domain/             City, Weather, forecast models, WMO descriptions
│   │       │   ├── data/               HTTP client and per-city SQLite cache
│   │       │   └── presentation/       controller, screen, forecast widgets
│   │       └── tasks/
│   │           ├── domain/             Task and JSON serialization
│   │           ├── data/               task repository, seeding, transactions, undo
│   │           └── presentation/       controller, notebook screen, editing sheet
│   ├── test/                          model, HTTP, SQLite and state tests
│   ├── tool/                          direct engine verification + icon generator
│   ├── warmup.dart                    async lesson exercise
│   ├── check_weather.dart              standalone live API exercise
│   ├── ios/                           rw.sessionfive.kigaliWeather
│   └── android/                       Android app host
├── daybook/                            independently installable task app
│   ├── lib/main.dart                  launches shared TaskApp
│   ├── pubspec.yaml                   local path dependency on kigali_weather
│   ├── ios/                           rw.sessionfive.daybook
│   └── android/                       independent Android app host
├── docs/                              requirements, research, assignment, verification
│   └── screenshots/                   real Flutter renders using test fixtures
└── scripts/                           check and install both apps
```

Daybook imports the reusable feature library through a local Dart package dependency. This keeps one tested weather implementation and one set of visual tokens rather than copying weather logic between apps. The native projects and app identities are separate. Both directories must remain adjacent. At larger scale, the shared library could become a third package; it is deliberately kept small for this assignment.

## Data flow

```
Widget → ChangeNotifier controller → HTTP API / SQLite repository → typed model
                                     ↓
                            awaited write / transaction
                                     ↓
                        controller notifies the widget
```

Domain models contain no widgets. HTTP code knows no UI. Controllers handle loading, failure, cache selection and mutation outcomes. Screens render state and forward user actions. No global mutable singleton, backend or service locator is needed.

Weather: read selected-city preference, fetch asynchronously, validate, save snapshot, show data. On failure read only that city's cache. Without cache show error/Retry. Requests have a 12-second timeout. A generation counter prevents slow stale responses from changing the newly selected city's screen; the completed response may still be saved under its original city. Settings writes are queued to preserve selection order.

Tasks: seed samples only on the first successful database initialization; read ordered tasks; await each mutation before reporting success. Busy state prevents double-save. Search is local, across title and notes. All tasks shows open tasks; Today includes overdue tasks; Upcoming includes future due dates; Done includes completed tasks. The editor validates the title and preserves notes, priority, completion and dates.

## SQLite schema, version 1

`session5.db` lives in the app's platform database directory. Each installed app receives its own sandbox.

| Table | Columns / purpose |
| --- | --- |
| weather_cache | city TEXT primary key; payload TEXT containing forecast JSON |
| tasks | id TEXT primary key; title TEXT; notes TEXT; priority INTEGER 0–2; done INTEGER 0/1; due nullable ISO date; created ISO datetime |
| metadata | key TEXT primary key; value TEXT; `tasks_seeded` marks successful one-time sample creation |
| task_undo | id INTEGER fixed at 1; payload TEXT with the latest deleted task JSON |

A deletion transaction stores the exact task and deletes its active row together. Undo inserts it back and removes the undo entry in one transaction. Only the most recent deletion is retained; this is explicit in the UI. Emptying the task list never reruns sample initialization. SQLite parameters are bound, not interpolated from task text.

SharedPreferences stores one key, `city`, for the selected city. Weather times are Kigali wall-clock strings supplied by the provider. Task due dates are local calendar dates. Those concepts are kept distinct.

## Privacy and limitations

No login, location tracking, advertising or analytics. Only fixed city coordinates and forecast parameters are sent to Open-Meteo. Tasks never leave the app. Device-local persistence is not cross-device sync; uninstalling can remove the data. The free weather endpoint has no uptime guarantee. Native plugin and simulator checks must run with actual device/service access; headless engine tests do not replace that final integration check.
