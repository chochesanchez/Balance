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

## Onboarding

The onboarding flow runs on first launch. `RootView` (in `MyApp.swift`) checks `viewModel.hasCompletedOnboarding` and shows either `AuthGateView` (onboarding) or `MainTabView` (main app), with a smooth `.easeInOut` transition.

**Source file:** `Views/Onboarding/OnboardingView.swift`

---

### Entry Points

| View | Purpose |
|------|---------|
| `AuthGateView` | Welcome landing screen. Offers "Get Started" (→ `OnboardingView`) and "Already have an account?" (→ `LoginView`) |
| `LoginView` | Email + password sign-in. Calls `viewModel.completeOnboarding()` on success |
| `OnboardingView` | 9-page `TabView` holding all setup screens |

---

### Step-by-Step Flow

#### Step 1 — Name  `(Page 0)`  `NameStepScreen`
- **Icon:** `person.fill` (primary blue)
- **Asks:** "What's your name?"
- **Collects:** `userName: String`
- **Validation:** Required — non-empty. Continue button disabled until filled.
- **Auto-focus:** Keyboard opens automatically after 0.4 s

---

#### Step 2 — Profile Photo  `(Page 1)`  `ProfilePhotoScreen`
- **Icon:** `camera.fill` (orange)
- **Asks:** "Set your profile photo"
- **Collects:** `profileImage: UIImage?` (optional)
- **Storage:** JPEG at 0.8 quality → `UserProfile.profileImageData`
- **Skippable:** Yes — "Skip for now" appears when no image is selected
- **Picker:** Native `PHPickerViewController`

---

#### Step 3 — Financial Goals  `(Page 2)`  `GoalSelectionScreen`
- **Icon:** `target` (orange)
- **Asks:** "What are your financial goals?"
- **Collects:** `selectedGoals: Set<FinancialGoal>` (multi-select)
- **Persisted as:** `userProfile.primaryGoal` (first selected goal)
- **Skippable:** Yes — button becomes "Skip" when nothing selected

| Option | Icon | Color |
|--------|------|-------|
| Save more money | `dollarsign.circle.fill` | Green `#34C759` |
| Track my spending | `chart.bar.fill` | Blue `#007AFF` |
| Reach a savings goal | `target` | Orange `#FF9500` |
| Build better habits | `arrow.up.right.circle.fill` | Purple `#AF52DE` |

---

#### Step 4 — Spending Habits  `(Page 3)`  `SpendingHabitsScreen`
- **Icon:** `cart.fill` (red `#FF2D55`)
- **Asks:** "How do you usually spend?"
- **Collects:** `selectedHabits: Set<SpendingHabit>` (multi-select, not persisted)
- **Skippable:** Yes

| Option | Icon | Color |
|--------|------|-------|
| Mostly cash | `banknote.fill` | Green |
| Card payments | `creditcard.fill` | Blue |
| Mobile payments | `iphone.gen3` | Purple |
| A mix of everything | `arrow.triangle.branch` | Orange |
| Lots of subscriptions | `repeat.circle.fill` | Pink |
| Impulse buyer | `bolt.fill` | Yellow |

---

#### Step 5 — Currency  `(Page 4)`  `CurrencySelectionScreen`
- **Icon:** `dollarsign.circle.fill` (income green)
- **Asks:** "Choose your currencies"
- **Collects:** `selectedCurrencies: [Currency]`, `defaultCurrency: Currency`
- **Persisted as:** `appState.selectedCurrency` (ISO code, e.g. `"USD"`)
- **Validation:** Required — at least 1 currency must be selected
- **Search:** Real-time filter by code or name
- **Supports 40+ currencies:** USD, EUR, GBP, CAD, AUD, JPY, CNY, INR, BRL, MXN, and more
- **Default badge:** Tap star on any chip to set as default. First selected becomes default automatically.

---

#### Step 6 — Account Details  `(Page 5)`  `AccountDetailsScreen`
- **Icon:** `envelope.fill` (purple)
- **Asks:** "Account details — for account recovery"
- **Collects:**
  - Email → `userProfile.email`
  - Phone → `userProfile.phone`
- **Validation:** Required — both fields must be non-empty

---

#### Step 7 — Password  `(Page 6)`  `CreatePasswordScreen`
- **Icon:** `lock.fill` (green)
- **Asks:** "Create a password"
- **Collects:** `password`, `confirmPassword` (held in local state only — not persisted to profile)
- **Validation:**
  - Minimum 6 characters
  - Both fields must match
  - Inline error "Passwords don't match" shown with fade/slide animation

---

#### Step 8 — Username  `(Page 7)`  `UsernameStepScreen`
- **Icon:** `at` (purple)
- **Asks:** "Pick a username — your unique identity on Balance"
- **Collects:** `username: String` → `userProfile.username`
- **Validation:** None — field can be left empty

---

#### Step 9 — Ready to Start  `(Page 8)`  `ReadyToStartScreen`
- **Icon:** Animated green checkmark with concentric circles
- **Title:** "You're all set!"
- **Shows:** 3-item preview of first steps (add account → create categories → record transaction)
- **Button:** "Start" — triggers `completeOnboarding()`

---

### Data Flow: Collection → Persistence

All data is held in `OnboardingView` local state throughout the flow. On the final "Start" tap:

```
viewModel.userProfile.name            ← userName
viewModel.userProfile.username        ← username
viewModel.userProfile.email           ← userEmail
viewModel.userProfile.phone           ← userPhone
viewModel.userProfile.primaryGoal     ← selectedGoals.first
viewModel.userProfile.profileImageData← profileImage?.jpegData(compressionQuality: 0.8)

viewModel.appState.selectedCurrency   ← defaultCurrency.code

viewModel.completeOnboarding()  →  appState.hasCompletedOnboarding = true  →  saveAppState()
viewModel.updateUserProfile(_)  →  saveUserProfile()
```

---

### Persistence Keys

| UserDefaults Key | Stores |
|-----------------|--------|
| `balance_userProfile` | Name, username, email, phone, photo, primary goal |
| `balance_appState` | `hasCompletedOnboarding`, selected currency |

Data is also synced to iCloud via `iCloudSyncManager` (`userProfile.json`, `appState.json`).

---

### Step Summary Table

| # | Page | Struct | Collects | Required | Skippable |
|---|------|--------|----------|----------|-----------|
| 1 | 0 | `NameStepScreen` | Full name | Yes | No |
| 2 | 1 | `ProfilePhotoScreen` | Profile photo | No | Yes |
| 3 | 2 | `GoalSelectionScreen` | Financial goals | No | Yes |
| 4 | 3 | `SpendingHabitsScreen` | Spending habits | No | Yes |
| 5 | 4 | `CurrencySelectionScreen` | Default currency | Yes | No |
| 6 | 5 | `AccountDetailsScreen` | Email + phone | Yes | No |
| 7 | 6 | `CreatePasswordScreen` | Password | Yes | No |
| 8 | 7 | `UsernameStepScreen` | Username | No | No |
| 9 | 8 | `ReadyToStartScreen` | — | — | No |

---

### Reset / Re-trigger

```swift
viewModel.resetOnboarding()  // Sets hasCompletedOnboarding = false, saves
```

Used for testing only — not exposed in the production UI.

---

### Navigation & Animations

| Element | Behavior |
|---------|---------|
| Back button | Returns to previous page; dismisses `OnboardingView` on page 0 |
| Page transition | Spring `response: 0.4, dampingFraction: 0.85`; keyboard dismissed between steps |
| Selection buttons | Spring `response: 0.3, dampingFraction: 0.7` + SF Symbol bounce |
| Welcome screen entry | Scale + opacity fade, 0.1 s delay |
| Completion checkmark | Bounce effect with 0.2 s delay |
| Root transition | `.easeInOut` switch from `AuthGateView` → `MainTabView` |
| Haptics | Selection on page advance/back; success on completion |

---

### Custom UI Components (Onboarding)

| Component | Purpose |
|-----------|---------|
| `OnboardingButton` | 52 pt tall primary button; disabled state at 35 % opacity |
| `OnboardingTextField` | Tertiary-fill field with optional icon and focus animation |
| `StepIconBadge` | Circular icon with translucent colored background |
| `ColoredGoalButton` | Tappable goal/habit card with spring animation |
| `SelectedCurrencyChip` | Pill chip with remove (✕) and set-default (★) actions |

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

### Onboarding Flow (9 Steps)

See the [Onboarding](#onboarding) section for the complete step-by-step breakdown, data collected, validation rules, and persistence details.

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
│   Onboarding?    │             │   (9 screens)    │
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
