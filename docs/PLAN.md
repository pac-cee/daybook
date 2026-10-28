# Session 5 implementation plan

Inputs: every section of kigali-weather.html and all 12 slides plus notes in Session5-Data-From-The-Internet.pptx. Plain-text extracts are adjacent for review. Original inputs remain unchanged.

1. Establish Flutter iOS/Android application and tests.
2. Model Open-Meteo current, hourly and seven-day forecast, with timeout and validated parsing.
3. Store one weather snapshot per city in SQLite. Use SharedPreferences for selected city, preserving the guide's settings lesson. Isolate network, storage, models, state and widgets.
4. Build Weather screen: Kigali, Huye, Musanze, Rubavu chips; loading, error/retry, refresh, offline cache and exact observation timestamp.
5. Build user's chosen Daybook Tasks mini project: first-run samples, create/read/update/delete, completion, priority, notes, due date, search/filter and durable undo. Include live weather on task screen.
6. Exercise API failures, corrupt data, city races, SQLite reopen and task mutations; inspect rendered phone layouts; build and install when simulator permissions allow.
7. Record assignment answers, API research, schema, structure and verification. Commit/push requires a Git repository destination, absent from supplied folder.

## Reference lock

Primary: Apple Weather, https://support.apple.com/en-au/guide/iphone/iph1ac0b35f/26/ios/26. Preserve central location and oversized temperature, horizontal hourly strip, stacked daily forecast and grouped metrics. Adapt to user's white/black/one accent constraint.
Secondary: provided guide owns cities, offline behavior, error and retry. Refero bundled typography/craft guidance owns hierarchy, spacious grouping and accessible controls. Apple design skill owns system font, native scrolling and sheets. No Refero MCP tools are configured.

| Decision | Source | Role |
| --- | --- | --- |
| White canvas, near-black text, muted blue #3E6D8C | User palette | Blue for selected controls and weather icons; neutral surfaces are black opacity |
| 112 pt light temperature, 32 pt page headings, 16 pt body | Apple Weather + typography craft | Weather scanning hierarchy |
| 24 pt page margins; 20 pt cards; 12/16/24 spacing | Craft + user's spacing request | Consistent rhythm |
| Cupertino weather and navigation icons | Apple reference | Meaningful code-native symbols, no decorative assets |
| Visible cache date, offline message and Retry | Lesson | Never present saved observations as current |
| Native sheets with labeled fields and 48 pt controls | Apple design | Reversible, accessible task editing |

No cloud accounts or sync: slide 11 announces a future individually assigned capstone. It is not the Session 5 assignment. This local task app does not pretend to meet that future scope.
