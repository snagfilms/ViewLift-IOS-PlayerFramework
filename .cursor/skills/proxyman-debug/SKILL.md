---
name: proxyman-debug
description: >-
  Integrates (or removes) Proxyman Atlantis SPM for local DEBUG network
  debugging on AppCMS iOS and tvOS: link Atlantis, merge Bonjour keys, call
  Atlantis.start() behind #if DEBUG, optionally install the Proxyman CA on
  simulators. Use when the user mentions Proxyman, Atlantis, proxyman-debug,
  network debugging, intercept HTTPS, simulator SSL errors, or capturing
  iPhone / iPad / Apple TV traffic. Prefer this project skill over any old
  proxyman-atlantis-ios-tvos name.
---

# Proxyman debug (Atlantis) — AppCMS iOS / tvOS

Wire [Atlantis](https://github.com/ProxymanApp/atlantis) so **DEBUG** builds send
URLSession HTTP/HTTPS and WebSocket traffic to Proxyman **without** an HTTP
proxy or certificate trust. Optional simulator CA install enables classic proxy
tools (Map Local, Breakpoint, Scripting).

**Canonical location:** `.cursor/skills/proxyman-debug/` in this repo (not an
external-only copy). Old name: `proxyman-atlantis-ios-tvos`.

## When to apply

Only change app code when the user **explicitly** asks to integrate or remove
Proxyman/Atlantis. Attaching or renaming this skill alone must **not** wire
Atlantis into the project.

| User intent | Mode |
|-------------|------|
| Explicitly asks to add Proxyman / Atlantis / debug network | **integrate** |
| Explicitly asks to remove Atlantis / strip Proxyman debug wiring | **remove** |
| Simulator SSL / classic proxy CA (after integrate exists) | CA script only |

Do **not** start Atlantis in App Store Release / production builds.

## Preconditions

- Proxyman for macOS. Atlantis **v1.18.0+** (prefer current upToNextMajor).
- Device and Mac on same Wi-Fi **or** USB. Simulator is local.
- Atlantis **inspects** traffic only. Map Local / Breakpoint need classic proxy + CA.

## AppCMS paths (use these; discover if missing)

| Item | Path |
|------|------|
| Workspace | `AppCMS/AppCMS.xcworkspace` |
| Project | `AppCMS/AppCMS.xcodeproj/project.pbxproj` |
| iOS AppDelegate | `AppCMS/AppCMS/AppDelegate/AppDelegate.swift` |
| tvOS AppDelegate | `AppCMS/AppCMS_tvOS/AppDelegate/AppDelegate.swift` |
| iOS Info.plist | `AppCMS/TargetSpecificResources/iOS/Info.plist` |
| tvOS Info.plist | `AppCMS/TargetSpecificResources/tvOS/Info.plist` |
| Package.resolved | `AppCMS/AppCMS.xcworkspace/xcshareddata/swiftpm/Package.resolved` |
| Schemes | `AppCMS` / `AppCMS_tvOS` |

Targets: link **AppCMS** and **AppCMS_tvOS** only (application product type). Skip
Notification extensions and tests unless the user named that process.

## Workflow checklist

```
- [ ] Clarify integrate vs remove
- [ ] SPM Atlantis on AppCMS + AppCMS_tvOS
- [ ] Merge Bonjour / local-network keys (do not wipe Cast)
- [ ] DEBUG + canImport Atlantis.start() in both AppDelegates
- [ ] Resolve packages; DEBUG build if verifying
- [ ] Optional: install-simulator-cert.sh
- [ ] Warn: re-run sanitize / remove before client-agnostic commit if needed
```

---

## Mode: integrate

### 1. Add Swift Package

- URL: `https://github.com/ProxymanApp/atlantis`
- Product: `Atlantis`
- Requirement: `upToNextMajor` from `1.18.0` (or current stable major)

In `project.pbxproj`:

1. One `XCRemoteSwiftPackageReference` for the repo (project `packageReferences`).
2. One `XCSwiftPackageProductDependency` **per** app target (`AppCMS`, `AppCMS_tvOS`).
3. Matching `PBXBuildFile` + Frameworks phase membership for each target.
4. Each target’s `packageProductDependencies` lists its product dependency ID.

Do not hardcode stale UUIDs from old diffs — generate fresh 24-hex IDs if
re-adding after a remove.

Resolve:

```bash
xcodebuild -resolvePackageDependencies \
  -workspace AppCMS/AppCMS.xcworkspace \
  -scheme AppCMS
```

### 2. Info.plist

**iOS** — merge into existing `NSBonjourServices` (keep Cast / other entries):

```xml
<string>_Proxyman._tcp</string>
```

If `NSLocalNetworkUsageDescription` already describes Cast, **append** a short
Proxyman/debug clause. Do not replace the Cast string.

**tvOS** — if keys are missing, add:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>In debug builds, Atlantis uses Bonjour to send recorded traffic to the Proxyman Mac app.</string>
<key>NSBonjourServices</key>
<array>
  <string>_Proxyman._tcp</string>
</array>
```

### 3. Start Atlantis (DEBUG only)

Top of `application(_:didFinishLaunchingWithOptions:)` in **both** AppDelegates.

File-level (or near other imports):

```swift
#if DEBUG
#if canImport(Atlantis)
import Atlantis
#endif
#endif
```

Inside launch (first lines after storing `launchOptions` is fine):

```swift
#if DEBUG
#if canImport(Atlantis)
Atlantis.start()
#endif
#endif
```

Rules:

- `#if DEBUG` on import **and** start — Release must not capture.
- `#if canImport(Atlantis)` so a missing package does not break compile.
- Never commit a teammate’s Mac hostname.
- Multiple Macs: `Atlantis.start(hostName: "your-mac.local.")` (trailing dot OK).
- Do not start from Notification extensions unless debugging that process.

### 4. Simulator + classic proxy (optional)

Atlantis does **not** need a simulator certificate. Install the CA when the user
wants Safari/system HTTPS, SSL-error fixes under the system proxy, or Map Local.

```bash
bash .cursor/skills/proxyman-debug/scripts/install-simulator-cert.sh
```

Needs unsandboxed / `all` permissions for `simctl`. Boot target sims once, or
`PROXYMAN_BOOT_SIMS=1`. **Never** erase simulators unless the user asks.

### 5. Verify

1. Proxyman running, recording on.
2. Run app **DEBUG** on Simulator or device.
3. Trigger a known network call.
4. Flow appears under the app name; HTTPS body readable via Atlantis.
5. Classic proxy: SSL Proxying for that host.

---

## Mode: remove

Strip all Atlantis / Proxyman debug wiring (idempotent):

1. Remove `#if DEBUG` / `canImport(Atlantis)` import and `Atlantis.start()` from
   both AppDelegates.
2. Remove `_Proxyman._tcp` from Bonjour arrays; remove tvOS Bonjour /
   `NSLocalNetworkUsageDescription` **only if** they were added solely for
   Atlantis (do not delete Cast wording on iOS).
3. Remove Atlantis `PBXBuildFile`, Frameworks membership,
   `packageProductDependencies` entries, `XCSwiftPackageProductDependency`, and
   the `XCRemoteSwiftPackageReference` from `project.pbxproj`.
4. Remove the `atlantis` pin from `Package.resolved` (leave unrelated pins).
5. Grep the repo for `Atlantis`, `atlantis`, `_Proxyman` — expect zero matches
   outside this skill.

---

## Guardrails

- Launch-time debug bootstrap only. No production Service/ViewModel for this.
- Respect SwiftLint; do not disable rules for Atlantis.
- Never put `Atlantis.start()` outside `#if DEBUG`.
- Do not factory-reset simulators to “fix Proxyman”.
- Certificate pinning can hide hosts on the **proxy** path; Atlantis still sees
  URLSession. Some players / gRPC may need advanced Atlantis APIs or classic proxy.
- Before a **client-agnostic** shared commit: run **remove**, or
  `/sanitize-xcproj-placeholders` for setup noise — Atlantis SPM + Bonjour are
  intentional debug diffs; do not leave half-linked package refs.
- After VLAnalytics strip via sanitize, local builds still need
  `bash setup_environment.sh <project> <env>` — unrelated to Atlantis, but
  often confused when debugging “won’t compile after sanitize”.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| No flows | Proxyman on; DEBUG; Local Network allowed; same network/USB; `_Proxyman._tcp` |
| Many Macs, wrong Mac | `Atlantis.start(hostName:)` |
| Simulator HTTPS SSL (proxy) | Re-run `install-simulator-cert.sh`; trust CA; SSL Proxying |
| `simctl` connection refused | Unsandboxed shell; `xcode-select -p`; boot sim once |
| Map Local does nothing | Expected on Atlantis-only. Use classic proxy + CA |
| Compile: no Atlantis module | Package linked on that target; resolve packages |

## See also

- [Atlantis iOS docs](https://docs.proxyman.com/atlantis/atlantis-for-ios)
- [iOS Simulator docs](https://docs.proxyman.com/debug-devices/ios-simulator)
- [tvOS device notes](https://docs.proxyman.com/debug-devices/tvos-and-watchos)
- Script: [scripts/install-simulator-cert.sh](scripts/install-simulator-cert.sh)
- Related: `.cursor/skills/sanitize-xcproj-placeholders/` (commit hygiene; does not manage Atlantis)
