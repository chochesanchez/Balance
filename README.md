# Balance - Personal Finance for Students

<div align="center">

**Made to Change, by Choche Sanchez.**

![Balance App Icon](Assets.xcassets/AppIcon.appiconset/Balance%20App%20Icon%20iOS.png)

### Version 3.0 · WWDC25 Swift Student Challenge Winner

**A personal finance companion designed for students and young people learning to manage their money.**

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017.0+-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-green.svg)](https://developer.apple.com/xcode/swiftui/)

</div>

---

## About

**Balance** is a native iOS app built entirely in SwiftUI, created to solve the personal finance management challenge for students and young people who are just starting to earn and manage their own money.

This project was developed for the **WWDC25 Swift Student Challenge** and was selected as a **winner**. Version 3.0 delivers a polished, offline-first experience ready for the App Store—no internet required, no accounts, no cloud sync. Your data stays on your device.

---

## Demo

<video src="Images/Simulator%20Screen%20Recording%20-%20iPhone%2017%20Pro%20-%202026-03-01%20at%2021.43.34.mov" controls width="100%" style="max-width: 400px; border-radius: 12px; margin: 0 auto;"></video>

*Balance in action — Oboarding*

---

## Features

### Core Functionality

| Feature | Description |
|---------|-------------|
| **Transaction Tracking** | Record income, expenses, and transfers with ease |
| **Multiple Accounts** | Manage Cash, Bank Account, Debit Card, Digital Wallet, Savings, Credit Card, Investment |
| **Savings Pots** | Envelope-style budgeting—set aside money for goals with add/withdraw support |
| **Custom Categories** | Create personalized expense, income, or both categories with 90+ icons |
| **Recurring Transactions** | Set up automatic bills and subscriptions with optional reminders |
| **Goals** | Track progress toward financial goals with visual indicators and deadlines |

### Home Dashboard

| Feature | Description |
|---------|-------------|
| **Spending Gauge** | Semicircular gauge showing day/week/month spending vs limit |
| **Quick Actions** | One-tap access to record Income, Expense, Transfer, Recurring, or Goals |
| **My Accounts** | At-a-glance account balances with navigation to full Wallet |
| **Money Distribution** | Proportional breakdown of accounts, pots, and categories |
| **Balance Trend** | Weekly balance history chart |
| **Calendar** | Transaction dots, recurring due dates, and goal deadlines |
| **Daily Tips** | Rotating financial education tips (15 tips, 3 random per day) |

### History & Record

| Feature | Description |
|---------|-------------|
| **Transaction History** | Newest-first list with search, date filter, and account/category filters |
| **Full Edit** | Edit any transaction—amount, type, title, note, date, account, category |
| **Record Screen** | Centered amount input, currency picker, recurring toggle, category selection |
| **Keyboard Done** | Dismiss keyboard with Done button |

### Wallet & More

| Feature | Description |
|---------|-------------|
| **Accounts & Categories** | Add, edit, delete with contextual icons and rainbow colors |
| **Savings Pots in Wallet** | Manage pots alongside accounts—edit, contribute, withdraw, delete |
| **Analytics** | Spending by category, savings rate, period comparisons |
| **Financial Health** | 0–100 score based on savings, goals, and habits |
| **Settings** | Weekly spending limit, notifications (recurring, goals, weekly summary), default tab (open on Record), export CSV/JSON |
| **Profile** | Photo, name, stats—editable with PHPicker for robust image selection |

### Integrations

| Feature | Description |
|---------|-------------|
| **Siri Shortcuts** | "Record expense in Balance", "Show my balance", "Record income" |
| **App Shortcuts** | Back Tap / triple-tap to open Record—configurable in Shortcuts app |
| **40+ Currencies** | Support for global currencies with proper formatting |
| **Dark Mode** | Full support via system colors |

---

## Screenshots

![Balance Screenshot](Images/Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-03-01%20at%2021.43.11.png)

*Home screen with spending gauge, quick actions, and savings pots*

---

## Installation

### Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 6.0

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/Balance.git
   ```

2. **Open in Xcode**
   ```bash
   cd Balance/Balance.swiftpm
   open Package.swift
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### Swift Playgrounds

This project is compatible with **Swift Playgrounds** on iPad:
1. Open the `.swiftpm` package directly in Swift Playgrounds
2. Tap "Run My App" to launch

---

## Architecture

Balance follows the **MVVM (Model-View-ViewModel)** architecture pattern:

```
┌─────────────────────────────────────────────────────────┐
│                        Views                            │
│  (SwiftUI Views - UI Layer)                              │
├─────────────────────────────────────────────────────────┤
│                    ViewModel                            │
│  (BalanceViewModel - Business Logic & State)             │
├─────────────────────────────────────────────────────────┤
│                      Models                             │
│  (Account, Transaction, Category, Goal, etc.)           │
├─────────────────────────────────────────────────────────┤
│                   UserDefaults                          │
│  (Local Data Persistence)                               │
└─────────────────────────────────────────────────────────┘
```

### Project Structure

```
Balance.swiftpm/
├── MyApp.swift              # App entry point
├── ContentView.swift        # Main tab navigation
├── AppIntents.swift         # Siri Shortcuts & App Shortcuts
├── Theme.swift              # Design system
│
├── Models/
│   └── BalanceModels.swift  # Data models
│
├── ViewModels/
│   └── BalanceViewModel.swift  # Main ViewModel
│
├── Views/
│   ├── Onboarding/          # 7-step onboarding flow
│   ├── Home/                # Dashboard & insights
│   ├── History/             # Transaction history
│   ├── Record/              # Add transactions
│   ├── Wallet/              # Accounts, categories, savings pots
│   ├── More/                # Profile, settings, analytics, goals
│   └── Components/          # Reusable components
│
├── Images/                  # Screenshots & demo video
└── Assets.xcassets/        # App icons & colors
```

---

## Tech Stack

| Technology | Usage |
|------------|-------|
| **SwiftUI** | Entire UI layer |
| **Swift 6.0** | Language with strict concurrency |
| **Charts** | Native iOS 17+ charts for analytics |
| **UserDefaults** | Local data persistence |
| **UserNotifications** | Bill and goal reminders |
| **PhotosUI / PHPicker** | Profile photo picker |
| **App Intents** | Siri Shortcuts and App Shortcuts |

### Key Technical Features

- **@MainActor** for thread-safe state management
- **Codable** for JSON encoding/decoding with backward compatibility
- Pure SwiftUI with **no external dependencies**
- Support for both **iPhone and iPad**
- **Dark Mode** support via system colors
- **Haptic Feedback** for enhanced UX

---

## Data Models

### Core Models

| Model | Description |
|-------|-------------|
| `Account` | Financial accounts (Cash, Bank, Debit Card, Digital Wallet, etc.) |
| `Category` | Expense, income, or both categories with optional budget |
| `Transaction` | Individual financial transactions |
| `RecurringTransaction` | Scheduled recurring payments |
| `Goal` | Savings goals and envelope-style pots (`goalType`) |
| `UserProfile` | User information and preferences |
| `AppState` | App-wide settings (currency, limits, notifications, default tab) |

---

## Design System

Balance uses a centralized theme system following Apple Human Interface Guidelines:

### Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#0191FF` | Buttons, links, selected states |
| Income | `#34C759` | Income amounts (System Green) |
| Expense | `#FF3B30` | Expense amounts (System Red) |
| Transfer | `#0191FF` | Transfer amounts (App Blue) |
| Recurring | `#FF9500` | Recurring badge (Orange) |
| Goals | `#FFCC00` | Goals icon (Yellow) |

### App Icon

The Balance app icon features a minimalist electric blue circle on white—symbolizing trust, stability, and clarity in personal finance.

---

## Onboarding Flow

Balance includes a comprehensive 7-step onboarding:

1. **Welcome** — App introduction
2. **Name** — Personalization
3. **Contact** — Optional email/phone
4. **Profile** — Photo and username
5. **Goals** — Financial goals selection
6. **Currency** — Multi-currency setup
7. **Ready** — Guided tour preview

---

## Future Roadmap

- [ ] App Store release
- [ ] iCloud sync (optional)
- [ ] Widgets for Home Screen
- [ ] Apple Watch companion app
- [ ] Budget templates
- [ ] AI-powered insights
- [ ] Localization (Spanish, Portuguese, etc.)

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## Author

**Choche Sanchez**

- Made to Change
- Created for WWDC25 Swift Student Challenge
- Winner 2025

---

## Acknowledgments

- Apple for SwiftUI and the Swift Student Challenge
- The Swift community for inspiration and resources
- Financial education resources that informed the app's tips and insights
