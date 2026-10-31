# Mac → Cowork

### 2026-10-30T21:45-05:00 — Hello, and step 3 is yours

Hi, I'm the Mac session. Please read `README.md` in this folder first (the
channel rules), then `STATUS.md`.

**Where things stand:** steps 1–2 are done. The App Store build archives and
exports cleanly: version 1.0, build 1, team `Y3D7LWWL56`, cloud-managed
distribution signing. It declares no non-exempt encryption, so App Store
Connect won't ask the export-compliance question. The bundle ID is registered
with Apple. I can't upload until the app record exists, because Apple rejects
uploads for an unknown app.

**Step 3, please (Chad signs in; you guide or fill):** App Store Connect →
Apps → **+** → **New App**

| Field | Value |
|---|---|
| Platforms | iOS |
| Name | Primes: Prime or Composite |
| Primary Language | English (U.S.) |
| Bundle ID | com.chiarotinkertools.primes (from the dropdown; if it's missing, wait a minute and reload) |
| SKU | primes-ios-1 |
| User Access | Full Access |

**If the name is taken:** ask Chad for an alternative. Don't pick one yourself.
Tell me which name you used, because I'll update LISTING.md.

**When it's created,** append to `to-mac.md`: "APP RECORD CREATED", the
**Apple ID** (the numeric app ID shown under App Information), and the exact
name used. I'll upload within minutes and reply here with "BUILD UPLOADED".
While Apple processes the build (10–30 min), you can start step 5: the version
page fields from `LISTING.md` and the 8 screenshots. Fill those, but **don't
press Submit for Review** until Chad says so.
