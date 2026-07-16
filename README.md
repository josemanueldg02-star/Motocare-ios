# MotoCare

A native iOS app for tracking motorcycle maintenance — service history, mileage, and costs — built with SwiftUI and a security-first approach to local credential storage.

DEMO: still under construction!...

---

## Overview

MotoCare lets riders keep a maintenance log for their motorcycle: oil changes, tyres, brakes, chain kit, general servicing. It tracks current mileage, derives the next service interval from the actual maintenance history, and reports total spend.

The project started as a SwiftUI learning exercise and was rebuilt around two engineering concerns that are easy to get wrong and rarely done properly in sample apps:

1. **Credential storage that survives a threat model**, not just a demo.
2. **A single source of truth** for app state, with data scoped per user account.

---

## Features

- **Multi-user accounts** — each account gets its own isolated garage and maintenance history.
- **Maintenance log** — record type, date, mileage, cost, and notes; swipe to delete.
- **Derived service status** — the next service milestone is computed from the last recorded service and a configurable interval, not hardcoded.
- **Spend tracking** — running total of maintenance costs, formatted per locale.
- **Biometric unlock** — optional Face ID / Touch ID, enforced at the Keychain layer.
- **Locale-aware input** — handles comma decimal separators (`45,5`) correctly, which naive `Double(String)` parsing silently drops.

---

## Security architecture

This is the part of the project worth reading. The first iteration stored credentials in `@AppStorage` — that is, `UserDefaults`, an unencrypted `.plist` readable from a device backup or a jailbroken container. It was rewritten.

| Concern | Implementation |
|---|---|
| Credential storage | iOS **Keychain**, with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (excludes iCloud sync, requires an unlocked device) |
| Password hashing | **PBKDF2-HMAC-SHA256**, 100,000 rounds, 32-byte derived key |
| Salt generation | 16 bytes from `arc4random_buf` (system CSPRNG), unique per account |
| Hash comparison | Constant-time, byte-by-byte — no short-circuit timing leak |
| Brute force | Failed-attempt counter with lockout |
| Biometric enforcement | `kSecAttrAccessControl` — credentials are unreadable without a successful biometric check, rather than gating the UI only |
| Error handling | Keychain `OSStatus` is checked and propagated; a failed write never reports a successful registration |

### Why PBKDF2 and not SHA-256

SHA-256 is a fast hash built for integrity, not for passwords. Salting alone does not fix that: an attacker who extracts the Keychain contents can test billions of candidates per second on a GPU. A slow key derivation function makes each guess expensive by design. PBKDF2 is available natively through CommonCrypto (bridged into Swift via a bridging header), so it adds no third-party dependency.

Argon2id or scrypt would be stronger choices — both are memory-hard, which blunts GPU parallelism in a way PBKDF2 does not. They were skipped here to avoid pulling in an external dependency for a local demo. In a production system this logic belongs on a server anyway (see [Roadmap](#roadmap)).

### What this does *not* protect against

Stated plainly, because a security section that only lists wins is marketing:

- There is **no server**. Accounts exist only on the device that created them.
- **User enumeration** is possible by design — registration reveals whether an email is taken. Fixing this properly requires server-side handling.
- Registered email addresses live in `UserDefaults`, not the Keychain. They are personal data, not secrets, but they are not encrypted at rest beyond the OS default.

---

## Tech stack

- **Swift** / **SwiftUI**
- **iOS 27 SDK**, Xcode Beta
- **CryptoKit** → replaced by **CommonCrypto** (PBKDF2 via bridging header)
- **Security framework** (Keychain Services)
- **LocalAuthentication** (Face ID / Touch ID)
- **Combine** (`ObservableObject`)

No third-party dependencies.

---

## Architecture

MVVM, with `GarageViewModel` as the single source of truth for garage state.

```
MotoCare/
├── MotoCareApp.swift          # @main entry point, injects the shared view model
├── ContentView.swift          # AppState router: splash → login → dashboard
│
├── Models/
│   ├── Motorcycle.swift       # Codable, typed (mileage: Int, not String)
│   └── MaintenanceRecord.swift
│
├── ViewModels/
│   └── GarageViewModel.swift  # @MainActor, per-user namespaced persistence
│
├── Services/
│   ├── AuthService.swift      # Registration, verification, PBKDF2 derivation
│   └── KeychainHelper.swift   # Keychain wrapper with access control
│
└── Views/
    ├── SplashView.swift
    ├── LoginView.swift
    ├── RegisterView.swift
    ├── MainTabView.swift
    ├── DashboardView.swift
    ├── GarageView.swift
    ├── ProfileView.swift
    ├── AddBikeView.swift
    └── AddMaintenanceView.swift
```

### Design decisions

**Single source of truth.** An earlier version held the motorcycle as `@State` inside `DashboardView` while the view model owned the maintenance history. The two never spoke: logging a service at 25,000 km left the dashboard still reporting 21,560. State was consolidated into `GarageViewModel`, and service status became derived rather than stored.

**Per-user namespacing.** Garage data is keyed as `garage.<email>.bike` and `garage.<email>.history`. Switching accounts reloads scoped data instead of mutating one shared record.

**Typed models.** Mileage is `Int` and cost is `Double`. Storing them as `String` — the original approach — means values that cannot be sorted, summed, or validated, and it hides locale bugs until a user with a comma keyboard hits them.

---

## Getting started

### Requirements

- Xcode 26.3 or later
- iOS 27 SDK
- A Mac running macOS 26 or later

### Run

```bash
git clone https://github.com/josemanueldg02-star/motocare.git
cd motocare
open MotoCare.xcodeproj
```

Select an iOS Simulator and press `Cmd + R`.

> **Note on the simulator:** to exercise the biometric flow, enable Face ID under **Features → Face ID → Enrolled**, then trigger a match with **Features → Face ID → Matching Face**.

---

## Roadmap

- [ ] **Spring Boot backend** with JWT auth and bcrypt/Argon2 — moves account management off-device and makes the app genuinely multi-user across devices
- [ ] **Real Sign in with Apple** via `AuthenticationServices` (the current social buttons are non-functional placeholders)
- [ ] Multiple motorcycles per account
- [ ] Fuel/refuelling log
- [ ] Local notifications for upcoming service intervals
- [ ] Unit tests for `AuthService` and `GarageViewModel`

---

## Known limitations

- Accounts are **device-local**; there is no sync between devices.
- The Apple / Google / Phone sign-in buttons are **UI placeholders** and do not perform real OAuth.
- One motorcycle per account.
- The refuelling action on the dashboard is not implemented yet.

---

## Author

**Jose Manuel Dominguez Garcia**
Backend & full-stack developer — Java/Spring Boot, React/TypeScript
[GitHub](https://github.com/josemanueldg02-star) · [LinkedIn](https://www.linkedin.com/)
