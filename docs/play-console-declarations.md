# ZYKL v1.0.0 — Play Console declarations (copy-paste)

App: **ZYKL: Pomodoro Focus Timer** · package `com.zykl.app` · privacy policy `https://zykl.app/privacy`

## 1. Exact alarms (`USE_EXACT_ALARM`)
*App content → Sensitive app permissions → Exact alarm*
- Core functionality: **Timer / alarm clock**
- Justification:
  > ZYKL is a Pomodoro focus timer. The user starts a focus or break countdown, and the app must ring the
  > session-end chime at the exact second it ends, including when the screen is off or the device is idle.
  > Exact alarms are used only for the end of a countdown the user started. They never run in the background otherwise.

## 2. Foreground service (`FOREGROUND_SERVICE_SPECIAL_USE`, plus `mediaPlayback`)
*App content → Foreground service permissions*
- **Special use**, user-visible: "User-started Pomodoro focus timer: shows the live countdown notification and
  lock-screen widgets, and rings the session-end alarm while the screen is off. Stops when the session ends or the
  user stops it."
- Impact if deferred or interrupted: the countdown notification disappears and the session-end alarm can be late.
- **Media playback**: the user starts a vinyl soundscape (ambient audio). It plays with a media notification and
  play/pause controls until the user stops it.
- Video showing the feature (if asked): screen-record start timer → notification → lock screen → alarm.

## 3. Data safety
*App content → Data safety*
- Does the app collect or share any of the required user data types? **No**
  - Focus sessions, tasks and settings are stored **only on the device** (local SQLite); no account, no analytics SDK,
    no ads SDK, no crash reporting SDK, no network calls of our own.
  - Purchases are processed by **Google Play Billing**. Google handles the payment; the app only receives whether
    the Studio PRO purchase is valid. (Purchase history handled by Google is out of scope for developer collection.)
- Is all user data encrypted in transit? **Not applicable** (no data transmitted).
- Can users request deletion? Data lives on the device; uninstalling or clearing app data deletes it.

## 4. Other App content items
- **Ads:** No ads.
- **App access:** All functionality is available without login (no account). Studio PRO is a one-time purchase.
- **Content rating (IARC questionnaire):** Utility/productivity; no violence, sexual content, gambling, user-generated
  content or location sharing → expected rating **Everyone / 3+**.
- **Target audience:** 18+ (or 13+). Not designed for children.
- **News app:** No. **Government app:** No. **Financial features:** None. **Health:** No health claims.

## 5. Monetization
- One-time product: **`studio_pro_lifetime`** · name "ZYKL Studio PRO" · launch price **Rp 69.000**
  (set country prices, e.g. US$4.99–5.99) → **Activate**.
- Description: "One payment unlocks every Studio PRO hardware edition and acoustic soundscape, including every new edition and soundscape added in future updates. No subscription."
- Setup → **License testing**: add tester Google accounts (test purchases are free).

## 6. Release
- Testing → **Internal testing** → Create release → upload `build_outputs/zykl-playstore-release.aab`
  (versionCode 1, versionName 1.0.0), release name "1.0.0", add testers' emails, roll out.
- Then **Closed testing** (personal accounts: 12+ testers for 14 days) → apply for Production.
