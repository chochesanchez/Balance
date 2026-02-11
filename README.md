# Balance - Personal Finance for Students

<div align="center">

![Balance App Icon](Assets.xcassets/AppIcon.appiconset/Balance%20App%20Icon%20iOS.png)

### WWDC25 Swift Student Challenge Winner

**A personal finance companion designed for students and young people learning to manage their money.**

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016.0+-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

[Features](#features) • [Screenshots](#screenshots) • [Installation](#installation) • [Architecture](#architecture) • [Contributing](#contributing)

</div>

---

## About

**Balance** is a native iOS app built entirely in SwiftUI, created to solve the personal finance management challenge for students and young people who are just starting to earn and manage their own money.

This project was developed for the **WWDC25 Swift Student Challenge** and was selected as a **winner**.

> **Note:** The app is currently not deployed on the App Store. It will be published once development is complete.

---

## Features

### Core Functionality

| Feature | Description |
|---------|-------------|
| **Transaction Tracking** | Record income, expenses, and transfers with ease |
| **Multiple Accounts** | Manage Cash, Checking, Savings, Credit Card, Investment accounts |
| **Custom Categories** | Create personalized expense and income categories |
| **Recurring Transactions** | Set up automatic bills and subscriptions with reminders |
| **Savings Goals** | Track progress toward financial goals with visual indicators |

### Smart Insights

| Feature | Description |
|---------|-------------|
| **Analytics Dashboard** | Visualize spending patterns with interactive charts |
| **Smart Insights** | AI-powered tips based on spending behavior |
| **Financial Health Score** | 0-100 score based on savings rate, goals, and habits |
| **Period Comparisons** | Compare spending across days, weeks, months, and years |
| **Category Analytics** | Deep dive into spending by category with trends |

### User Experience

| Feature | Description |
|---------|-------------|
| **40+ Currencies** | Support for global currencies with proper formatting |
| **Smart Notifications** | Reminders for upcoming bills and recurring expenses |
| **Offline-First** | All data stored locally - no internet required |
| **Privacy Focused** | No data collection, no accounts, no cloud sync |
| **Daily Tips** | Rotating financial education tips for young users |
| **Beautiful UI** | Modern, native iOS design following Apple HIG |

---

## Screenshots

*Coming soon*

---

## Installation

### Requirements

- iOS 16.0 or later
- Xcode 15.0 or later
- Swift 5.9+

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

This project is also compatible with **Swift Playgrounds** on iPad:
1. Open the `.swiftpm` package directly in Swift Playgrounds
2. Tap "Run My App" to launch

---

## Architecture

Balance follows the **MVVM (Model-View-ViewModel)** architecture pattern:

```
┌─────────────────────────────────────────────────────────┐
│                        Views                            │
│  (SwiftUI Views - UI Layer)                            │
├─────────────────────────────────────────────────────────┤
│                    ViewModel                            │
│  (BalanceViewModel - Business Logic & State)           │
├─────────────────────────────────────────────────────────┤
│                      Models                             │
│  (Account, Transaction, Category, Goal, etc.)          │
├─────────────────────────────────────────────────────────┤
│                   UserDefaults                          │
│  (Local Data Persistence)                              │
└─────────────────────────────────────────────────────────┘
```

### Project Structure

```
Balance.swiftpm/
├── MyApp.swift              # App entry point
├── ContentView.swift        # Main tab navigation
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
│   ├── Wallet/              # Accounts & categories
│   ├── More/                # Settings & extras
│   └── Components/          # Reusable components
│
└── Assets.xcassets/         # App icons & colors
```

---

## Tech Stack

| Technology | Usage |
|------------|-------|
| **SwiftUI** | Entire UI layer |
| **Swift 6.0** | Language with strict concurrency |
| **Charts** | Native iOS 17+ charts for analytics |
| **UserDefaults** | Local data persistence |
| **UserNotifications** | Bill reminders |
| **PhotosUI** | Profile photo picker |

### Key Technical Features

- **@MainActor** for thread-safe state management
- **Codable** for JSON encoding/decoding
- Pure SwiftUI with **no external dependencies**
- Support for both **iPhone and iPad**
- **Dark Mode** support via system colors
- **Haptic Feedback** for enhanced UX

---

## Data Models

### Core Models

| Model | Description |
|-------|-------------|
| `Account` | Financial accounts (Cash, Checking, Credit Card, etc.) |
| `Category` | Expense and income categories |
| `Transaction` | Individual financial transactions |
| `RecurringTransaction` | Scheduled recurring payments |
| `Goal` | Savings goals with progress tracking |
| `UserProfile` | User information and preferences |
| `AppState` | Application-wide settings |

### Analytics Models

| Model | Description |
|-------|-------------|
| `TimeRange` | Daily, Weekly, Monthly, Yearly scopes |
| `Insight` | Smart financial insights |
| `CategoryStat` | Category spending statistics |
| `BudgetStatus` | Budget tracking states |
| `GoalStatus` | Goal progress states |

---

## Design System

Balance uses a centralized theme system following Apple Human Interface Guidelines:

### Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#0191FF` | Buttons, links, selected states |
| Income | `#34C759` | Income amounts (System Green) |
| Expense | `#FF3B30` | Expense amounts (System Red) |
| Transfer | `#8E8E93` | Transfer amounts (System Gray) |

### Typography

- System fonts with rounded design for amounts
- Dynamic Type support
- Consistent font weights and sizes

### Spacing

- 8-point grid system
- Consistent padding and margins
- Responsive layouts

---

## Onboarding Flow

Balance includes a comprehensive 7-step onboarding:

1. **Welcome** - App introduction
2. **Name** - Personalization
3. **Contact** - Optional email/phone
4. **Profile** - Photo and username
5. **Goals** - Financial goals selection
6. **Currency** - Multi-currency setup
7. **Ready** - Guided tour preview

---

## Future Roadmap

- [ ] App Store release
- [ ] iCloud sync (optional)
- [ ] Widgets for Home Screen
- [ ] Apple Watch companion app
- [ ] Export to CSV/PDF
- [ ] Budget templates
- [ ] AI-powered insights
- [ ] Localization (Spanish, Portuguese, etc.)

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## Author

**Choche Sanchez**

- Created for WWDC25 Swift Student Challenge
- Winner 2025

---

## Acknowledgments

- Apple for SwiftUI and the Swift Student Challenge
- The Swift community for inspiration and resources
- Financial education resources that informed the app's tips and insights

---

## License

This project is available under the MIT License. See the [LICENSE](LICENSE) file for more info.

---

<div align="center">

**Made with ❤️ using SwiftUI**

*Balance - Helping students master their finances, one transaction at a time.*

</div>
