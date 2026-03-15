# Archive2day — iOS App

An iOS Share Extension that lets you share any webpage link directly to [archive.today](https://archive.today) to view an existing snapshot or submit the page for archiving.

---

## Features

- **Share Extension** — appears in the iOS Share Sheet from Safari or any app that shares URLs
- **Two actions** — choose to view the newest existing archive, or submit the page for a fresh snapshot
- **URL cleaning** — strips UTM and tracking parameters (`utm_source`, `fbclid`, `gclid`, etc.) before lookup so you get clean canonical archive results
- **Broad URL support** — works with any webpage, not just specific sites
- **Opens in Safari** — hands off to Safari cleanly without freezing the source app

---

## How It Works

```
Share → Archive2day
  → Extension card appears showing the page hostname
  → "View newest archive" → opens archive.today/newest/{url} in Safari
  → "Submit for archiving" → opens archive.today/?run=1&url={url} in Safari
  → Tap outside card to cancel
```

---

## Project Structure

```
Archive2day/
├── Archive2day/                  # Main app target
│   ├── Archive2dayApp.swift      # App entry point (@main)
│   ├── ContentView.swift         # SwiftUI main interface
│   ├── URLCleaner.swift          # URL cleaning + archive.today URL builder (shared)
│   └── Info.plist
│
├── ShareExtension/               # Share Extension target
│   ├── ShareViewController.swift # Extension UI + logic
│   └── Info.plist
│
└── Archive2day.xcodeproj/
```

---

## Setup in Xcode

1. **Open** `Archive2day.xcodeproj`
2. **Replace** `com.yourname.archive2day` with your bundle ID in both targets (extension must be `<appid>.ShareExtension`)
3. **Set your Team** under Signing & Capabilities for each target
4. Select `URLCleaner.swift` → **File Inspector → Target Membership** → check both targets
5. **CamelChecker target → Build Phases** → add **"Embed Foundation Extensions"** phase → add `ShareExtension.appex`
6. Build the **Archive2day** scheme to your device, launch the app once, then test the share sheet

---

## Requirements

- iOS 16.0+
- Xcode 15+
- Swift 5.9+
- Apple Developer account (for device testing)

---

## Notes

- archive.today occasionally uses alternate domains (`archive.ph`, `archive.li`) — all resolve to the same service
- This app is not affiliated with archive.today

---

## About

This app was built entirely with AI assistance using **Claude Sonnet 4.6** by [Anthropic](https://www.anthropic.com). The full app — including Swift source code, Share Extension, URL cleaning logic, app icon, and Xcode project structure — was generated through a conversational session with Claude via [claude.ai](https://claude.ai).
