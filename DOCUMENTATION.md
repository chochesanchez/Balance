# Balance App Documentation

> **Version:** 1.0  
> **Platform:** iOS (SwiftUI)  
> **Target:** Swift Student Challenge 2025

---

## Table of Contents

1. [Overview](#overview)
2. [App Architecture](#app-architecture)
3. [Project Structure](#project-structure)
4. [Data Models](#data-models)
5. [Views & Screens](#views--screens)
6. [Design System (Theme)](#design-system-theme)
7. [Features](#features)
8. [Data Persistence](#data-persistence)
9. [User Flow](#user-flow)

---

## Overview

**Balance** is a personal finance companion app designed for students and young people. It helps users track their income, expenses, and transfers while providing insights into their spending habits and financial health.

### Key Features
- 💰 Track income, expenses, and transfers
- 📊 Analytics & spending insights
- 🔁 Recurring transactions management
- 🎯 Savings goals tracking
- 📱 Multi-currency support (40+ currencies)
- 🔔 Smart notifications for upcoming bills
- 📈 Financial health score
- 🎨 Customizable accounts & categories

---

## App Architecture

The app follows the **MVVM (Model-View-ViewModel)** architecture pattern:

```
┌─────────────────────────────────────────────────────────┐
│                        Views                            │
│  (SwiftUI Views - UI Layer)                            │
├─────────────────────────────────────────────────────────┤
│                    ViewModel                            │
│  (BalanceViewModel - Business Logic & State)           │
├─────────────────────────────────────────────────────────┤
│                      Models                             │
│  (Data Structures - Account, Transaction, etc.)        │
├─────────────────────────────────────────────────────────┤
│                   UserDefaults                          │
│  (Local Data Persistence)                              │
└─────────────────────────────────────────────────────────┘
```

### Key Components

- **`BalanceViewModel`** - Single source of truth for app state, marked with `@MainActor`
- **`@StateObject`** / **`@ObservedObject`** - SwiftUI state management
- **`Codable`** models - JSON encoding/decoding for persistence

---

## Project Structure

```
Money.swiftpm/
├── MyApp.swift              # App entry point & RootView
├── ContentView.swift        # MainTabView (5 tabs)
├── Theme.swift              # Design system (colors, typography, spacing)
│
├── Models/
│   └── BalanceModels.swift  # All data models
│
├── ViewModels/
│   └── BalanceViewModel.swift  # Main ViewModel
│
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingView.swift    # 6-step onboarding flow
│   │
│   ├── Home/
│   │   └── NewHomeView.swift       # Dashboard & insights
│   │
│   ├── History/
│   │   └── NewHistoryView.swift    # Transaction history
│   │
│   ├── Record/
│   │   └── RecordView.swift        # Add new transactions
│   │
│   ├── Wallet/
│   │   └── WalletView.swift        # Accounts & categories
│   │
│   └── More/
│       ├── MoreView.swift          # Settings & extras
│       └── RecurringView.swift     # Recurring transactions
│
└── Assets.xcassets/
    ├── AccentColor.colorset/       # Primary brand color (#008CFF)
    └── AppIcon.appiconset/         # App icon
```

---

## Data Models

### Account
Represents a financial account (wallet, bank, credit card, etc.)

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `name` | `String` | Account name |
| `type` | `AccountType` | Cash, Checking, Savings, Credit Card, Investment, Other |
| `icon` | `String` | SF Symbol name |
| `color` | `String` | Hex color code |
| `initialBalance` | `Double` | Starting balance |
| `isDefault` | `Bool` | Default account flag |
| `note` | `String?` | Optional description |
| `createdAt` | `Date` | Creation timestamp |

### Category
Represents spending/income categories

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `name` | `String` | Category name |
| `icon` | `String` | SF Symbol name |
| `color` | `String` | Hex color code |
| `type` | `CategoryType` | Expense or Income |
| `isSystem` | `Bool` | System categories can't be deleted |
| `budget` | `Double?` | Optional monthly budget |
| `sortOrder` | `Int` | Display order |
| `note` | `String?` | Optional description |

### Transaction
Represents a financial transaction

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `amount` | `Double` | Transaction amount (always positive) |
| `type` | `TransactionType` | Income, Expense, or Transfer |
| `accountId` | `UUID` | Source account |
| `categoryId` | `UUID?` | Category (optional for transfers) |
| `toAccountId` | `UUID?` | Destination account (for transfers) |
| `title` | `String` | Transaction title |
| `note` | `String` | Additional notes |
| `date` | `Date` | Transaction date |
| `createdAt` | `Date` | Creation timestamp |
| `recurringId` | `UUID?` | Link to recurring transaction |

### RecurringTransaction
Represents scheduled recurring transactions

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `title` | `String` | Transaction title |
| `amount` | `Double` | Transaction amount |
| `type` | `TransactionType` | Income or Expense |
| `accountId` | `UUID` | Associated account |
| `categoryId` | `UUID?` | Associated category |
| `frequency` | `RecurringFrequency` | Daily, Weekly, Biweekly, Monthly, Quarterly, Yearly |
| `startDate` | `Date` | Start date |
| `endDate` | `Date?` | Optional end date |
| `nextDueDate` | `Date` | Next scheduled date |
| `lastProcessedDate` | `Date?` | Last execution date |
| `note` | `String` | Additional notes |
| `isActive` | `Bool` | Active status |
| `notifyDaysBefore` | `Int` | Reminder days before due |

### Goal
Represents savings goals

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `title` | `String` | Goal name |
| `description` | `String` | Goal description |
| `targetAmount` | `Double` | Target amount |
| `currentAmount` | `Double` | Current saved amount |
| `deadline` | `Date?` | Optional deadline |
| `icon` | `String` | SF Symbol name |
| `color` | `String` | Hex color code |
| `imageData` | `Data?` | Optional image |
| `isCompleted` | `Bool` | Completion status |

### UserProfile
User information

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `name` | `String` | User's name |
| `email` | `String` | User's email |
| `profileImageData` | `Data?` | Profile photo |
| `monthlyIncomeRange` | `IncomeRange?` | Income bracket |
| `primaryGoal` | `FinancialGoal?` | Main financial goal |

### AppState
Application-wide settings

| Property | Type | Description |
|----------|------|-------------|
| `hasCompletedOnboarding` | `Bool` | Onboarding completion flag |
| `selectedCurrency` | `String` | Currency code (e.g., "USD") |
| `notificationsEnabled` | `Bool` | Notifications permission |

---

## Views & Screens

### Tab Bar Navigation
The app uses a 5-tab navigation structure:

| Tab | Icon | View | Description |
|-----|------|------|-------------|
| **Home** | `house.fill` | `NewHomeView` | Dashboard with balance, insights, tips |
| **History** | `clock.fill` | `NewHistoryView` | Transaction history with filters |
| **Record** | `plus.circle.fill` | `RecordView` | Add new transactions |
| **Wallet** | `wallet.pass.fill` | `WalletView` | Manage accounts & categories |
| **More** | `ellipsis` | `MoreView` | Settings, profile, extras |

### Onboarding Flow (6 Steps)

1. **Welcome Screen** - App introduction
2. **Profile Setup** - Name, email, profile photo
3. **Goal Selection** - Financial goals (multi-select)
4. **Income Range** - Monthly income bracket
5. **Currency Selection** - Choose from 40+ currencies
6. **First Account** - Create initial account

### Home View Components

| Component | Description |
|-----------|-------------|
| `GreetingHeader` | Time-based greeting with profile avatar |
| `BalanceOverviewCard` | Total balance, income/expenses for month |
| `QuickActionsRow` | Quick add Income/Expense/Transfer |
| `SpendingChartCard` | Pie chart by category (iOS 17+) |
| `FinancialInsightsSection` | Savings rate insights & daily average |
| `RecentTransactionsSection` | Last 5 transactions |
| `UpcomingRecurringSection` | Bills due within 7 days |
| `GoalsPreviewSection` | Active goals progress |
| `DailyTipCard` | Rotating financial tips |
| `MonthlySummaryCard` | Net savings & savings rate |

### History View Features

- **Search** - Search by title, note, category, or account
- **Type Filters** - Multi-select: All, Income, Expense, Transfer
- **Date Filters** - Single day or date range selection
- **Grouped List** - Transactions grouped by date
- **Swipe to Delete** - Quick transaction removal
- **Edit Sheet** - Full transaction editing

### Record View Features

- **Amount Input** - Large, centered currency input
- **Type Selector** - Income / Expense / Transfer buttons
- **Account Selection** - Horizontal scroll with add option
- **Category Grid** - 4-column grid with add option
- **Details Section** - Title, note, date/time picker
- **Success Overlay** - Animated confirmation

### Wallet View Features

- **Segmented Control** - Accounts / Categories tabs
- **Search** - Filter by name or type
- **Account Details** - Balance, recent transactions, edit
- **Category Metrics** - Monthly spending, transaction count
- **Add/Edit Sheets** - Icon picker, color picker

### More View Features

| Section | Items |
|---------|-------|
| **Profile** | User info with photo |
| **Features** | Recurring, Analytics, Goals, Financial Health, Tips |
| **Settings** | Currency, Export/Import |
| **About** | Help, App info |
| **Developer** | Reset onboarding, Reset data (DEBUG only) |

---

## Design System (Theme)

### Colors

| Name | Value | Usage |
|------|-------|-------|
| `primary` | `#008CFF` | Buttons, links, selected states |
| `income` | `#34C759` | Income amounts (System Green) |
| `expense` | `#FF3B30` | Expense amounts (System Red) |
| `transfer` | `#8E8E93` | Transfer amounts (System Gray) |
| `background` | System Grouped | Main background |
| `cardBackground` | System Background | Card surfaces |
| `primaryText` | Label | Main text |
| `secondaryText` | Secondary Label | Subtitles |
| `tertiaryText` | Tertiary Label | Captions |

### Category Colors (User Selection)
```
Blue, Green, Orange, Red, Purple, Pink, Yellow, Teal, Indigo, Gray
```

### Typography

| Style | Font | Usage |
|-------|------|-------|
| `largeTitle` | Bold Large Title | Screen titles |
| `title1` | Bold Title | Section headers |
| `title2` | Bold Title 2 | Card titles |
| `headline` | Headline | Row titles |
| `body` | Body | Content text |
| `subheadline` | Subheadline | Subtitles |
| `caption` | Caption | Small labels |
| `balanceAmount` | 34pt Bold Rounded | Balance displays |
| `amountInput` | 48pt Semibold Rounded | Amount entry |
| `transactionAmount` | 17pt Semibold Rounded | Transaction amounts |

### Spacing Scale

| Name | Value |
|------|-------|
| `xxs` | 4pt |
| `xs` | 8pt |
| `sm` | 12pt |
| `md` | 16pt |
| `lg` | 20pt |
| `xl` | 24pt |
| `xxl` | 32pt |
| `xxxl` | 48pt |

### Corner Radius

| Name | Value |
|------|-------|
| `small` | 8pt |
| `medium` | 12pt |
| `large` | 16pt |
| `extraLarge` | 20pt |
| `card` | 16pt |

### Haptic Feedback

| Function | Type |
|----------|------|
| `Haptics.light()` | Light impact |
| `Haptics.medium()` | Medium impact |
| `Haptics.success()` | Success notification |
| `Haptics.error()` | Error notification |
| `Haptics.selection()` | Selection changed |

---

## Features

### 1. Transaction Tracking
- Record income, expenses, and transfers
- Assign to accounts and categories
- Add titles, notes, and custom dates
- Edit and delete transactions
- View transaction history with filters

### 2. Account Management
- Multiple account types (Cash, Checking, Savings, Credit Card, Investment)
- Custom icons (22 options)
- Custom colors (10 options)
- Initial balance setting
- Real-time balance calculation
- Account-specific transaction history

### 3. Category Management
- Separate expense and income categories
- Custom icons (52 options)
- Custom colors (10 options)
- Category spending metrics
- Monthly averages

### 4. Recurring Transactions
- Multiple frequencies: Daily, Weekly, Biweekly, Monthly, Quarterly, Yearly
- Start and end dates
- Notification reminders (same day to 1 week before)
- Auto-process overdue transactions
- Pause/Resume functionality

### 5. Goals
- Set savings targets
- Optional deadlines
- Progress tracking
- Custom colors

### 6. Analytics
- Monthly income vs expenses
- Spending by category with percentages
- Net savings calculation
- Savings rate percentage
- Month-over-month comparison

### 7. Financial Health Score
- 0-100 score based on:
  - Savings rate
  - Goal setting
  - Transaction tracking
- Personalized improvement tips

### 8. Daily Tips
7 rotating financial tips:
- 50/30/20 Rule
- Track Everything
- Pay Yourself First
- Weekly Reviews
- Avoid Impulse Buys
- Emergency Fund
- Automate Savings

### 9. Multi-Currency Support
40+ currencies with:
- Currency code
- Full name
- Symbol
- Country flag

---

## Data Persistence

All data is persisted locally using `UserDefaults` with the following keys:

| Key | Data |
|-----|------|
| `balance_accounts` | Array of Account |
| `balance_categories` | Array of Category |
| `balance_transactions` | Array of Transaction |
| `balance_goals` | Array of Goal |
| `balance_recurring` | Array of RecurringTransaction |
| `balance_userProfile` | UserProfile |
| `balance_appState` | AppState |

### Encoding/Decoding
- Uses `JSONEncoder` / `JSONDecoder`
- All models conform to `Codable`
- Data is automatically saved after each mutation

---

## User Flow

```
┌──────────────────┐
│   App Launch     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     No      ┌──────────────────┐
│  Has Completed   │ ─────────▶  │   Onboarding     │
│   Onboarding?    │             │   (6 screens)    │
└────────┬─────────┘             └────────┬─────────┘
         │ Yes                            │
         │                                │
         ▼                                ▼
┌──────────────────────────────────────────────────┐
│                  Main Tab View                   │
├──────────────────────────────────────────────────┤
│                                                  │
│   [Home]  [History]  [Record]  [Wallet]  [More] │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Typical User Actions

1. **Add Transaction**
   - Tap Record tab (or Home quick action)
   - Enter amount
   - Select type (Income/Expense/Transfer)
   - Choose account
   - Select category (optional)
   - Add title/note (optional)
   - Tap "Record"

2. **View History**
   - Tap History tab
   - Use filters (type, date, search)
   - Tap transaction to edit
   - Swipe left to delete

3. **Manage Accounts**
   - Tap Wallet tab
   - View account balances
   - Tap account for details
   - Add new accounts with +

4. **Track Recurring**
   - Go to More → Recurring
   - Add subscriptions/bills
   - Get reminders before due dates
   - Process when due

---

## Technical Notes

### Requirements
- iOS 16.0+
- Swift 5.9+
- SwiftUI
- Charts framework (iOS 17+ for pie charts)

### Dependencies
- None (pure SwiftUI)

### Permissions
- Photo Library (profile photos)
- Notifications (recurring reminders)

---

## Credits

**Balance** - Made with ❤️ for Swift Student Challenge 2025

---
