# Session 5 assignment submission notes

## Deliverables

1. **Kigali Weather**: the lesson's weather application, including assignment steps 6–8.
2. **Daybook**: the user's chosen personal task / notes mini project, implementing Part 2 persistence and live API data.
3. `kigali_weather/warmup.dart`: brochette/drink async exercise.
4. `kigali_weather/check_weather.dart`: UI-independent live API check for all four cities.

## Requirement mapping

| Guide requirement | Implementation / evidence |
| --- | --- |
| Future, async and await warm-up | warmup.dart starts both orders before awaiting Future.wait |
| Model separate from widgets | features/weather/domain/weather.dart |
| HTTP GET, status checking, JSON parsing | features/weather/data/weather_api.dart |
| Loading, error, Retry, data | WeatherController + WeatherScreen; same states in Daybook weather card |
| Rounded temperature, sky words/icon, humidity, wind, update time | WeatherHero and WeatherMetrics |
| Pull to refresh | RefreshIndicator in both main screens |
| Four selectable city chips | Exact guide cities/coordinates; selected chip and app title update |
| Remember chosen city | SharedPreferences city key, read before initial fetch |
| Save each city's weather separately | SQLite weather_cache primary key city |
| Offline saved snapshot and banner | Selected cache only, full observation date/time, explicit offline label and Retry |
| Never-loaded city offline | Error and Retry, no fabricated readings |
| Mini-project sample data first time | Three sample tasks seeded transactionally once |
| Save all mini-project changes | Create/edit/complete/date/priority/notes/delete/undo await SQLite writes |
| Three changes survive stop/restart | Direct SQLite close/reopen checks passed for edit, complete, delete; undo checked separately |
| Delete and undo are saved | Single transaction stores deleted task, persistent undo survives reopen |
| API in mini project | Daybook's live weather summary opens the detailed forecast |
| Code organization and API record | ARCHITECTURE.md, RESEARCH.md and README.md |
| Commit and push | Submission repository: https://github.com/pac-cee/daybook; prepared from a separate writable Git checkout |
| Simulator installation | Native Daybook build and both screenshot phases passed on 28 October; see VERIFICATION.md |

## Exercise answers

**Why does the brochette/drink exercise take about three seconds, not four?**
Both Futures start before either is awaited. The one-second drink finishes while the three-second brochette is still cooking. Total elapsed time is approximately the slower operation, three seconds. Awaiting the brochette before starting the drink would make them sequential and take about four seconds.

**What does `Instance of 'Future<String>'` mean?**
The program printed a Future object rather than its resolved String. Await the Future inside an async function before using the result.

**Where is humidity in the JSON?**
`current.relative_humidity_2m`, expressed as a percentage. Read it as `num`, then convert to int. Any number shown in lesson screenshots or test fixtures is illustrative; the current value must come from a live response.

**Which town is latitude -2.5967, longitude 29.7394? Is it warmer than Kigali?**
Huye. Whether it is warmer changes with the observation time. `check_weather.dart` fetches both observations and prints the measured difference. A live comparison could not be obtained inside this network-restricted session, so no current temperature claim is invented.

**What would blocking a network request do to the screen?**
A synchronous blocking operation on the UI isolate would prevent frames and input processing until it finished. A slow connection would leave animations, spinners and interactions frozen longer. Dart's asynchronous HTTP operation returns a Future; awaiting it suspends the function while the event loop remains available. Merely removing `await` from an asynchronous `http.get` does not make it synchronous; it leaves a Future that must be handled correctly.

**What happens when the phone changes or the app opens on a second phone?**
SQLite and SharedPreferences live inside the app's local sandbox. A second installation starts with its own data; deleting the app can remove local data. Durable cross-device use requires an authenticated backend/cloud database and a synchronization design. This assignment deliberately implements local persistence, not unrequested fake cloud synchronization.

**Why use SQLite when the guide demonstrates SharedPreferences?**
The user explicitly requested SQLite as the database. The implementation keeps SharedPreferences for the selected-city lesson and applies the guide's serialization/persistence concepts to SQLite weather snapshots and task records. Delete plus undo is atomic; sample initialization uses a metadata flag rather than checking whether the list is empty, so deleting everything does not resurrect samples.

## Scope and submission

Slides 1–10 and 12 cover this session. Slide 11 announces a later individualized capstone with accounts, backend CRUD, Figma, APK/poster/demo requirements. Its specific project brief is not in the folder, so it is not misrepresented as completed here. No fake accounts, YouTube publication, Figma file or cloud backend were created.

The newer submission PDF identifies the Group B deadline as Wednesday, 28 October 2026, 11:59 PM. Pacifique Bakundukize (26798) is in Group B. This deadline supersedes the earlier 5 PM time in the HTML guide. The user supplied https://github.com/pac-cee/daybook as the submission repository. A separate writable Git checkout is used for publication.
