# Swipop

> **Swipe through live code.**

A platform where anyone can showcase interactive web-based projects without showing their face — TikTok for Frontend Creations.

## Overview

Swipop reimagines short-form content by replacing videos with interactive frontend creations. Users can browse, create, and share web-based projects (HTML/CSS/JavaScript) in a familiar swipe-to-discover experience.

### Why Swipop?

- **No Camera Required**: Express yourself through code, not video
- **Interactive Content**: Projects are not just viewed—they can be experienced and interacted with
- **AI-Assisted Creation**: Leverage vibe coding to bring ideas to life without deep technical expertise
- **Responsive by Nature**: Frontend projects adapt beautifully to any screen size

## Tech Stack

| Layer | Technology |
|-------|------------|
| Platform | iOS (iPhone) |
| UI Framework | SwiftUI |
| Package Manager | Swift Package Manager |
| Backend | Supabase |
| Authentication | Google Sign-In, Apple Sign-In |
| Content Rendering | WKWebView |

## Project Structure

```
Swipop/
├── Swipop/                 # Main app target
│   ├── SwipopApp.swift     # App entry point
│   ├── ContentView.swift   # Root view
│   └── Assets.xcassets/    # Asset catalog
├── SwipopTests/            # Unit tests
└── SwipopUITests/          # UI tests
```

## Key Decisions

- **No NPM, No Build Step**: Projects are pure HTML/CSS/JS—no compilation required
- **CDN Libraries Only**: Third-party libraries (Three.js, D3.js, etc.) loaded via CDN
- **Button Navigation**: Swipe conflicts avoided by using dedicated up/down buttons
- **SPM Only**: CocoaPods is explicitly forbidden

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ deployment target
- Supabase project (for backend services)

### Setup

1. Clone the repository
2. Open `Swipop.xcodeproj` in Xcode
3. Configure Supabase credentials
4. Build and run

## Authentication

Phase 1 supports only third-party authentication:

- ✅ Apple Sign-In
- ✅ Google Sign-In
- ❌ Email/Password (planned)
- ❌ Phone Number (planned)

## Contributing

This is currently a private project. Contribution guidelines will be added if/when the project goes public.

## License

TBD

---

*Built with SwiftUI and powered by Supabase*

