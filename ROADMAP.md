# MotoCare — Roadmap

> **Project direction (Nov 2026):** MotoCare is evolving from a maintenance tracker
> into a **crash-detection & emergency-SOS app for motorcyclists**. The goal: when a
> rider crashes and can't act — phone in a pocket, rider unconscious or injured — the
> app detects it and alerts emergency contacts (and emergency services) with the
> rider's location and medical information.

> ⚠️ **Safety disclaimer:** MotoCare is a best-effort assistance tool, **not a
> certified medical or safety device**. Detection can fail (false negatives) or
> misfire (false positives). It must be tested extensively and never relied upon as a
> sole safeguard.

## Why

Existing fall/crash-detection systems often miss motorcycle accidents, and many riders
— especially older ones — never configure them. MotoCare aims for **reliable detection
with near-zero configuration**.

## How detection works (design)

A **sensor-fusion state machine** that scores confidence instead of a yes/no flag:

1. **Riding** — sustained GPS speed above a threshold.
2. **Possible impact** — sharp acceleration spike **and/or** physically impossible
   rapid deceleration.
3. **Discriminators** (to reject false positives like hard emergency braking):
   - **Bike orientation** (gyroscope): upright = likely braking; on its side = likely a crash.
   - **Wait window**: does the ride resume within a few seconds?
   - **Post-event stillness**: rider motionless after stopping.
4. **Conditional audio (v2)** — only *after* a probable crash, the mic activates for a
   few seconds and an **on-device** classifier adjusts confidence (engine/wind = still
   riding → cancel; speech/groaning = conscious → lower alarm; silence + no motion →
   escalate). Never continuous, never uploaded.
5. **Confidence thresholds** → low: nothing · medium: "Are you OK?" countdown · high:
   short countdown, near-immediate alert.

## Roadmap

### 🟢 MVP (v1) — the core that already protects
- **Ride mode** (iOS location background mode) with auto-start when riding is detected.
- **Sensor-fusion detection**: accelerometer + gyroscope + GPS.
- **Confidence score** with the bike-upright-vs-down discriminator and a wait window.
- **Countdown alert** with **glove-friendly cancel**: large full-screen target + voice
  ("I'm OK"); hardware-button cancel as a stretch goal.
- **Alert**: SMS to **one** emergency contact with **GPS location + map link**.
- **Local medical card** + **test/simulate mode**.
- Reuses the existing **Firebase auth/profile**.

### 🟡 v2 — reliability & health signals
- ⌚ **Apple Watch**: live heart rate feeding the confidence score.
- 🎙️ **Conditional on-device audio AI** (SoundAnalysis + Create ML).
- 📞 **Escalation to emergency services (112)** + multiple contacts.
- 📍 **what3words** + live location sharing.

### 🔵 v3 — community & extras
- 👼 **Ride buddy** / live ride sharing with a trusted contact.
- 🛣️ **"Did you arrive?"** ETA-based check for crashes sensors miss.
- 🎞️ **Black box**: last-minutes sensor/GPS log for responders or insurance.
- 🧪 **"Protection active" dashboard** + polish.

## Design principles

- **Personalized theming** from the registered motorcycle's brand/model colors
  (auto-suggested, overridable in Settings → Preferences: custom style, dark/light).
- 🚨 **Non-negotiable:** the **emergency UI is never themed** — the crash countdown,
  cancel and SOS screens always use a fixed, high-contrast, unmistakable palette.
- **Accessibility first** (older riders): large tap targets, Dynamic Type, strong
  contrast, a high-visibility option.

## Security & privacy

MotoCare now handles **health and location data** — the most sensitive categories.
The hardened, tested Firestore rules (see [`SECURITY.md`](SECURITY.md)) and careful
on-device handling are foundational, not optional. GDPR considerations apply.
