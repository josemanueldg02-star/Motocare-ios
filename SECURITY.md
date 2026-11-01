# Security posture & testing — MotoCare

This document describes MotoCare's security model and how to verify it. It is meant to
be honest: it lists what is protected, what is not, and how each control is tested.

## Threat model in one line

The app ships a public Firebase config (`GoogleService-Info.plist`) that anyone can
read from the bundle, so the trust boundary is **the Firebase backend, not the client**.
Security = (1) rules that refuse cross-user access, (2) App Check that refuses
non-genuine clients, (3) not leaking secrets or sensitive data from the device.

## Controls

| # | Control | Where | Status |
|---|---|---|---|
| 1 | Firestore Security Rules (per-`uid` isolation, deny-by-default) | `firebase/firestore.rules` | ✅ written + tested |
| 2 | Rules test suite (emulator) | `firebase/tests/` | ✅ 11 tests passing |
| 3 | App Check provider (App Attest / DeviceCheck) | `MotoCare/MotoCareApp.swift` | ⚙️ code done — needs Console enforcement |
| 4 | Debug-only error logging | `MotoCare/AuthService.swift` | ✅ wrapped in `#if DEBUG` |
| 5 | Secrets hygiene (`GoogleService-Info.plist` git-ignored) | `.gitignore` | ✅ |
| 6 | App Transport Security (HTTPS enforced) | `MotoCare/Info.plist` | ✅ secure default (no ATS exceptions) |

---

## 1–2. Firestore rules & tests

The rules and their automated tests live in [`firebase/`](firebase/). They run against
the local Firebase Emulator — no production access, no credentials.

```bash
cd firebase
npm install      # first time only
npm test
```

Prerequisites (Node, Java 21+, Firebase CLI) and the deploy-to-production steps are in
[`firebase/README.md`](firebase/README.md).

---

## 3. App Check (manual Console steps)

The client code in `MotoCareApp.swift` already selects a provider (App Attest on iOS 14+,
DeviceCheck otherwise; a debug provider under `#if DEBUG`). To make it effective:

1. **Xcode** → target → *Frameworks, Libraries, and Embedded Content* → add
   **`FirebaseAppCheck`** from the Firebase Swift Package.
2. **Firebase Console → App Check** → register the iOS app with **App Attest**.
3. Run on a simulator once; copy the printed *debug token* into
   **App Check → Manage debug tokens**.
4. **App Check → APIs** → set **Firestore** and **Authentication** to *monitor* first,
   then *enforce* after a few days of clean traffic.

---

## 4. Static analysis with MobSF

[MobSF](https://github.com/MobSF/Mobile-Security-Framework-MobSF) (Mobile Security
Framework) performs static analysis of an iOS app: binary protections, insecure storage,
hardcoded secrets, permissions, and ATS configuration.

### Run MobSF (Docker — easiest on macOS)

```bash
# 1. Install Docker Desktop, then:
docker pull opensecurity/mobile-security-framework-mobsf:latest
docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf:latest

# 2. Open the web UI
open http://localhost:8000
```

### Get something to analyze

- **Full analysis** needs an `.ipa`: in Xcode, **Product → Archive →
  Distribute App → Development (Ad Hoc) → Export**. Drag the resulting `.ipa` into MobSF.
- **Source-only analysis** (no signing needed): zip the `MotoCare/` source folder and
  upload the `.zip`. MobSF runs its source rules (fewer binary checks, no entitlements).

### What to expect / how to read the report

| MobSF finding | Interpretation for MotoCare |
|---|---|
| Firebase API key / URL schemes in `Info.plist` / `GoogleService-Info.plist` | **Not a vulnerability.** These are public Firebase identifiers. The real boundary is the Firestore rules (control #1). Don't "fix" by hiding them. |
| `NSUserDefaults` used for storage | **True positive, low severity.** Garage data is in `UserDefaults`; it is unencrypted at rest. Acceptable for low-sensitivity data; the roadmap moves it to Firestore. |
| ATS / `NSAllowsArbitraryLoads` | Should be **clean** — this app has no ATS exceptions. If it ever flags, do not add `NSAllowsArbitraryLoads`. |
| Binary protections (PIE, ARC, stack canary) | Expected to pass for a standard Swift/Xcode release build. |
| Missing jailbreak/anti-debugging | Informational. Out of scope for a demo; a real fintech-grade app would add runtime checks. |

> **How to act on a report:** triage every finding into *true positive to fix*,
> *true positive accepted (with reason)*, or *false positive*. A security report is only
> useful once each line has a decision written next to it.

---

## Out of scope (honest limitations)

- No runtime/dynamic analysis (would need a jailbroken device + Frida).
- No penetration test of the live Firebase project (would need explicit authorization
  and is better done with the Security Rules Playground + App Check enforcement first).
- Garage data is device-local and not encrypted beyond the OS default.
