# 💰 Budget Buddy

A beautiful and modern **Money Management App** built with Flutter, using **GetX** for state management and **Hive** for local storage. Track your expenses, manage budgets by category, and stay on top of your finances with an intuitive and reactive interface.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![GetX](https://img.shields.io/badge/GetX-4.6.6-00D9FF?logo=dart)
![Hive](https://img.shields.io/badge/Hive-2.2.3-FD8500?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

### 💵 **Flexible Currency Support**
- Choose from **24+ currencies** on first launch
- Automatic currency symbol display throughout the app
- Supports USD, EUR, GBP, INR, JPY, and many more

### 📊 **Smart Budget Management**
- Set monthly income and track spending
- Create unlimited expense categories
- Assign budget limits to each category
- Visual progress bars with color-coded status:
  - 🟢 Green: < 75% spent
  - 🟠 Orange: 75-100% spent
  - 🔴 Red: > 100% spent (over budget)

### 📝 **Transaction Tracking**
- Add transactions with amount, note, and date
- View all transactions in a single list
- Category-wise transaction history
- Real-time spending calculations

### 📅 **Multi-Month Support**
- Navigate between months to view historical data
- Track budgets and spending over time
- Persistent storage of all data

### 🎨 **Modern UI/UX**
- Material Design 3
- Smooth animations and transitions
- Clean, minimalist interface
- Reactive updates with GetX
- Pull-to-refresh functionality

### 💾 **Offline-First**
- All data stored locally using Hive
- No internet connection required
- Fast and reliable data access
- Complete data privacy

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart 3.0 or higher
- Android Studio / VS Code with Flutter extensions
- Android Emulator / iOS Simulator / Physical Device

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/budget-buddy.git
   cd budget-buddy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── data/
│   ├── models/                        # Data models
│   │   ├── category.dart             # Category model with Hive adapter
│   │   └── transaction_item.dart     # Transaction model with Hive adapter
│   └── storage/
│       ├── hive_boxes.dart           # Hive box configuration
│       └── hive_service.dart         # Hive database operations
├── modules/                           # Feature modules
│   ├── dashboard/                     # Dashboard module
│   │   ├── dashboard_controller.dart # Dashboard logic
│   │   ├── dashboard_view.dart       # Dashboard UI
│   │   └── set_income_dialog.dart    # Income dialog
│   ├── category/                      # Category module
│   │   ├── category_controller.dart  # Category logic
│   │   ├── category_view.dart        # Category list UI
│   │   └── add_transaction_view.dart # Add transaction UI
│   ├── add_category/                  # Add category module
│   │   ├── add_category_controller.dart
│   │   └── add_category_view.dart
│   ├── transactions/                  # All transactions module
│   │   ├── transactions_controller.dart
│   │   └── transactions_view.dart
│   └── currency_selection/            # Currency selection module
│       ├── currency_selection_controller.dart
│       └── currency_selection_view.dart
├── routes/                            # Navigation routes
│   ├── app_pages.dart                 # GetX routes configuration
│   └── app_routes.dart                # Route constants
├── services/                          # Business logic services
│   ├── budget_service.dart            # Budget calculations
│   └── income_service.dart            # Income management
├── utils/                             # Utilities
│   ├── constants.dart                 # App constants & styling
│   ├── helpers.dart                   # Helper functions
│   └── currency_helper.dart           # Currency operations
└── widgets/                           # Reusable widgets
    ├── category_card.dart             # Category card widget
    ├── transaction_tile.dart          # Transaction tile widget
    └── progress_bar.dart              # Progress bar widget
```

---

## 🛠 Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: GetX 4.6.6
- **Local Storage**: Hive 2.2.3
- **Language**: Dart 3.0+
- **UI**: Material Design 3

### Key Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6                  # State management, navigation, DI
  hive: ^2.2.3                 # Local NoSQL database
  hive_flutter: ^1.1.0         # Flutter integration for Hive
  uuid: ^3.0.7                 # Unique ID generation
  intl: ^0.19.0                # Internationalization & formatting

dev_dependencies:
  hive_generator: ^2.0.1       # Generate Hive adapters
  build_runner: ^2.4.6         # Code generation
  flutter_lints: ^2.0.0        # Linting rules
```

---

## 🎯 Usage

### First Launch

1. **Select Currency**: Choose your preferred currency from the list
2. **Set Income**: Tap the settings icon and set your monthly income

### Managing Budgets

1. **Create Categories**: 
   - Tap "Manage Categories"
   - Click "Add Category"
   - Enter name, budget limit, and choose a color
   - Tap "Create Category"

2. **Add Transactions**:
   - Tap a category to view transactions
   - Click the "+" button to add a new transaction
   - Enter amount, note, and date
   - Tap "Add Transaction"

3. **View Spending**:
   - Dashboard shows total income, spent, remaining, and unallocated
   - Tap "Total Spent" to see all transactions
   - Each category shows progress and remaining balance

4. **Navigate Months**:
   - Use arrow buttons on dashboard to switch months
   - View historical budgets and spending

---

## 🎨 Screenshots

| Dashboard | Categories | Transactions |
|-----------|-----------|--------------|
| ![Dashboard](https://via.placeholder.com/300x600/6200EE/FFFFFF?text=Dashboard) | ![Categories](https://via.placeholder.com/300x600/03DAC6/000000?text=Categories) | ![Transactions](https://via.placeholder.com/300x600/FF9800/FFFFFF?text=Transactions) |

---

## 🔧 Architecture

### Design Patterns

- **Clean Architecture**: Separation of concerns (data, business logic, UI)
- **Feature-Based Modularization**: Each feature in its own module
- **Repository Pattern**: Abstracted data access through services
- **Reactive Programming**: GetX observables for state management

### State Management

- **GetX Controllers**: Manage business logic and state
- **Reactive Variables**: Automatic UI updates with `Rx` and `Obx`
- **Dependency Injection**: GetX's lazy loading and permanent services
- **Navigation**: Route-based navigation with GetX routing

### Data Storage

- **Hive**: Fast, lightweight NoSQL database
- **Local-Only**: All data stored on device
- **Type-Safe**: Generated adapters for models
- **Persistent**: Data survives app restarts

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Flutter and Dart conventions
- Maintain clean architecture principles
- Add comments for complex logic
- Ensure all code passes linting
- Test on both Android and iOS

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [GetX](https://github.com/jonataslaw/getx) - Amazing state management solution
- [Hive](https://github.com/hivedb/hive) - Fast and efficient local storage
- Flutter team for the incredible framework

---

## 📞 Contact

**Your Name** - [@syeduzaif](https://github.com/syeduzaif)

Project Link: [https://github.com/syeduzaif/Budget-buddy](https://github.com/syeduzaif/Budget-buddy)

---

## ⭐ Show Your Support

If you like this project, please give it a ⭐ on GitHub!

---

<p align="center">Made with ❤️ using Flutter</p>
