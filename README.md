# MotoCare

A native iOS app for tracking motorcycle maintenance — service history, mileage, and costs — built with SwiftUI on a Firebase backend, with a security-first posture: hardened Firestore rules, App Check, and tested access control.

DEMO: still under construction!

---

## Overview

MotoCare lets riders keep a maintenance log for their motorcycle: oil changes, tyres, brakes, chain kit, general servicing. It tracks current mileage, derives the next service interval from the actual maintenance history, and reports total spend.

The project started as a SwiftUI learning exercise and was rebuilt around two engineering concerns that are easy to get wrong and rarely done properly in sample apps:

1. **Real, multi-device authentication** backed by Firebase, not a local credential store.
2. **Access control that survives a threat model** — security rules that are *tested*, not assumed.

---

## Features

- **Multiple sign-in methods** — email/password, Google, Sign in with Apple, and phone (SMS) via Firebase Authentication.
- **Multi-user accounts** — each account gets its own isolated garage and maintenance history, scoped by Firebase `uid`.
- **Maintenance log** — record type, date, mileage, cost, and notes; swipe to delete.
- **Derived service status** — the next service milestone is computed from the last recorded service and a configurable interval, not hardcoded.
- **Spend tracking** — running total of maintenance costs, formatted per locale.
- **Biometric re-entry** — optional Face ID / Touch ID to resume the last session quickly.
- **Locale-aware input** — handles comma decimal separators (`45,5`) correctly, which naive `Double(String)` parsing silently drops.

---

## Security architecture

This is the part of the project worth reading. Authentication and the user profile store live in Firebase; the security work is in making that backend refuse anything it shouldn't.

| Concern | Implementation |
|---|---|
| Authentication | **Firebase Auth** — email/password, Google, Apple, and phone (SMS) providers |
| Profile storage | **Cloud Firestore**, collection `users/{uid}`, document id = the Auth `uid` |
| Access control | **Firestore Security Rules**: a user can read/write *only* `users/{their-own-uid}`; every other path is denied by default |
| Rules validation | A **Firebase Emulator** test suite asserts the rules under attack (cross-user access, anonymous access, uid spoofing, malformed data) — see [`firebase/`](firebase/) |
| Backend abuse | **Firebase App Check** (App Attest / DeviceCheck) so the backend only answers requests from the genuine app — blocks scripted clients and SMS-flow abuse |
| Secrets hygiene | `GoogleService-Info.plist` is git-ignored; the Firebase API key is a project identifier, not a secret — the rules are the real boundary |
| Error handling | Firebase `OSStatus`/`AuthErrorCode` is mapped to safe, localized messages; raw error detail is logged only under `#if DEBUG` |
| Local garage data | Scoped per `uid` in `UserDefaults` (`garage.<uid>.bike` / `.history`), reloaded on account switch |

### Why the rules are the point

With Firebase, the client ships with a `GoogleService-Info.plist` that anyone can read from the app bundle. That is by design — it is not a secret. An attacker who extracts it can talk to the project directly. What stops them reading or modifying other users' data is the **Firestore Security Rules**, and rules that are never tested are rules you don't actually have. This project treats them as code: they live in version control and have an automated test suite (see below).

### What this does *not* protect against

Stated plainly, because a security section that only lists wins is marketing:

- **Garage data is stored in `UserDefaults`**, not the Keychain. It is low-sensitivity (maintenance records), but it is not encrypted at rest beyond the OS default and is readable from a device backup or a jailbroken container.
- **Biometric re-entry gates the UI, not the data.** It resumes the last Firebase session faster; it is not a cryptographic lock on the stored records.
- **App Check must be enforced in the Firebase Console** to take effect — the client code configures the provider, but enforcement is a server-side toggle.

---

## Tech stack

- **Swift** / **SwiftUI**
- **Firebase** — Auth, Firestore, App Check
- **GoogleSignIn** / **AuthenticationServices** (Sign in with Apple)
- **LocalAuthentication** (Face ID / Touch ID)
- **Combine** (`ObservableObject`)

---

## Architecture

MVVM, with `GarageViewModel` as the single source of truth for garage state.

```
Motocare-ios/
├── MotoCare/
│   ├── MotoCareApp.swift          # @main; AppDelegate configures App Check + Firebase
│   ├── ContentView.swift          # AppState router: splash → login → dashboard
│   ├── Motorcycle.swift           # Motorcycle + MaintenanceRecord models (Codable, typed)
│   ├── GarageViewModel.swift      # @MainActor, per-uid namespaced persistence
│   ├── AuthService.swift          # Firebase Auth wrapper (email/Google/Apple/phone) + Firestore profile
│   ├── SocialAuthHelpers.swift    # Apple nonce/credential helpers
│   ├── SplashView.swift           # Optional Face ID re-entry
│   ├── LoginView.swift
│   ├── RegisterView.swift
│   ├── PhoneAuthView.swift
│   ├── MainTabView.swift
│   ├── DashboardView.swift
│   ├── GarageView.swift
│   ├── ProfileView.swift
│   ├── AddBikeView.swift
│   └── AddMaintenanceView.swift
│
└── firebase/                      # Firestore security rules + emulator test suite
    ├── firestore.rules
    ├── firebase.json
    ├── tests/firestore.test.js
    └── README.md
```

### Design decisions

**Single source of truth.** An earlier version held the motorcycle as `@State` inside `DashboardView` while the view model owned the maintenance history. The two never spoke: logging a service at 25,000 km left the dashboard still reporting 21,560. State was consolidated into `GarageViewModel`, and service status became derived rather than stored.

**Per-user namespacing by `uid`.** Garage data is keyed as `garage.<uid>.bike` and `garage.<uid>.history`. Switching accounts reloads scoped data instead of mutating one shared record. Keying on the immutable Firebase `uid` (not the email) means a user changing their email never loses their garage.

**Typed models.** Mileage is `Int` and cost is `Double`. Storing them as `String` — the original approach — means values that cannot be sorted, summed, or validated, and it hides locale bugs until a user with a comma keyboard hits them.

---

## Security testing

The Firestore rules have an automated test suite that runs entirely against the local Firebase Emulator (no production access, no credentials):

```bash
cd firebase
npm install      # first time only
npm test         # starts the emulator, runs the tests, shuts it down
```

The suite asserts, among others: a user cannot read or write another user's profile, anonymous access is fully denied, a client cannot spoof or mutate its `uid`, and no collection outside `users` is reachable. See [`firebase/README.md`](firebase/README.md) for prerequisites and how to deploy the rules to production.

---

## Getting started

### Requirements

- Xcode 26 or later, with the iOS SDK
- A Firebase project with Auth + Firestore enabled
- `GoogleService-Info.plist` from your Firebase project, placed in `MotoCare/` (not committed)

### Run

```bash
git clone https://github.com/josemanueldg02-star/Motocare-ios.git
cd Motocare-ios
# drop your GoogleService-Info.plist into MotoCare/
open MotoCare.xcodeproj
```

Select an iOS Simulator and press `Cmd + R`.

> **Note on the simulator:** to exercise the biometric flow, enable Face ID under **Features → Face ID → Enrolled**, then trigger a match with **Features → Face ID → Matching Face**. For phone-auth testing, add a test number in **Firebase Console → Authentication → Sign-in method → Phone**.

---

## Roadmap

- [ ] Move garage data from `UserDefaults` into Firestore (per-`uid` subcollection) so it syncs across devices, with matching tested rules
- [ ] Enforce App Check in the Firebase Console (monitor → enforce)
- [ ] Multiple motorcycles per account
- [ ] Fuel/refuelling log
- [ ] Local notifications for upcoming service intervals
- [ ] Unit tests for `AuthService` and `GarageViewModel`

---

## Known limitations

- Garage data is **device-local** (`UserDefaults`); it does not yet sync between devices.
- One motorcycle per account.
- The refuelling action on the dashboard is not implemented yet.

---

## Author

**Jose Manuel Dominguez Garcia**
Backend & full-stack developer — Java/Spring Boot, React/TypeScript
[GitHub](https://github.com/josemanueldg02-star) · [LinkedIn](https://www.linkedin.com/)
