# 📋 Product Requirements Document (PRD)
# BudgetBuddy — Personal Finance Management Platform

**Version:** 1.0  
**Date:** March 5, 2026  
**Author:** Syed Uzaif  
**Status:** Active Development

---

## 1. Executive Summary

**BudgetBuddy** is a cross-platform personal finance management solution consisting of a **Flutter mobile application** and a companion **Next.js web application**. It empowers users to track expenses, manage budgets by category, gain AI-powered financial insights, and maintain complete control over their finances — all with a modern, intuitive interface.

> [!IMPORTANT]
> The platform operates as two interconnected products sharing a common Firebase backend: a mobile-first Flutter app and a feature-rich web dashboard.

---

## 2. Product Vision & Goals

### Vision
Deliver a beautiful, intelligent, and privacy-respecting budgeting experience that makes personal finance management effortless for everyday users.

### Key Goals
| # | Goal | Success Metric |
|---|------|---------------|
| 1 | Simplify expense tracking | < 10 seconds to log a transaction |
| 2 | Provide actionable financial insights | AI insights used by 60%+ of active users |
| 3 | Multi-platform availability | Feature parity across mobile and web |
| 4 | Offline-first experience (mobile) | Full functionality without internet connection |
| 5 | Automated CI/CD delivery | APK builds auto-published on every push |

---

## 3. Target Audience

| Segment | Description |
|---------|-------------|
| **Primary** | Young adults (18–35) managing personal budgets for the first time |
| **Secondary** | Students tracking limited income and expenses |
| **Tertiary** | Anyone seeking a simple, AI-assisted budgeting tool |

### User Personas

**Persona 1 — The College Student**  
- Limited income, needs to track every rupee/dollar  
- Wants quick entry, visual progress bars, and warnings before overspending  

**Persona 2 — The Young Professional**  
- Monthly salary, multiple spending categories  
- Values analytics dashboards, AI advice, and historical trends  

---

## 4. Feature Requirements

### 4.1 Authentication & Onboarding

| Feature | Priority | Platform |
|---------|----------|----------|
| Email/password sign-up & sign-in | P0 | Mobile + Web |
| Google Sign-In (OAuth) | P0 | Mobile + Web |
| Password reset via email | P0 | Web |
| Guided onboarding flow | P1 | Mobile + Web |
| Currency selection (24+ currencies) | P0 | Mobile + Web |
| Monthly income setup | P0 | Mobile + Web |

### 4.2 Budget Management

| Feature | Priority | Platform |
|---------|----------|----------|
| Create unlimited expense categories (name, color, budget limit) | P0 | Mobile + Web |
| Edit and delete categories | P0 | Mobile + Web |
| Predefined category templates | P1 | Mobile |
| Color-coded budget progress bars (green/orange/red) | P0 | Mobile + Web |
| Budget limit warnings (75%, 100% thresholds) | P0 | Mobile + Web |
| Monthly budget rollover/reset | P1 | Mobile + Web |

### 4.3 Transaction Tracking

| Feature | Priority | Platform |
|---------|----------|----------|
| Add transactions (amount, note, date, category) | P0 | Mobile + Web |
| View all transactions in unified list | P0 | Mobile + Web |
| Category-wise transaction history | P0 | Mobile + Web |
| Real-time spending calculations | P0 | Mobile + Web |
| Transaction date picker | P0 | Mobile + Web |

### 4.4 Dashboard & Overview

| Feature | Priority | Platform |
|---------|----------|----------|
| Total income, spent, remaining, unallocated summary | P0 | Mobile + Web |
| Category breakdown with progress bars | P0 | Mobile + Web |
| Multi-month navigation (historical data) | P0 | Mobile |
| Animated number counters | P1 | Web |
| Spend distribution pie chart | P1 | Web |
| Pull-to-refresh | P1 | Mobile + Web |

### 4.5 Analytics & Reporting

| Feature | Priority | Platform |
|---------|----------|----------|
| Monthly spending bar chart | P1 | Mobile + Web |
| Category breakdown pie chart | P1 | Mobile + Web |
| Savings rate calculation | P1 | Mobile + Web |
| Configurable time ranges (3/6/12 months) | P1 | Mobile |
| Total spent over period | P1 | Mobile + Web |

### 4.6 AI Financial Advisor (Gemini)

| Feature | Priority | Platform |
|---------|----------|----------|
| Interactive chat with AI financial advisor | P1 | Mobile + Web |
| Context-aware financial insights based on user data | P1 | Mobile |
| Spending health assessment | P1 | Mobile |
| Actionable budget recommendations | P1 | Mobile |
| Chat session management (reset) | P2 | Mobile |

### 4.7 Settings & Personalization

| Feature | Priority | Platform |
|---------|----------|----------|
| Currency preference management | P0 | Mobile + Web |
| Monthly income update | P0 | Mobile + Web |
| Theme support (light/dark/system) | P1 | Mobile + Web |
| User profile management | P1 | Web |
| Sign-out functionality | P0 | Mobile + Web |

### 4.8 App Distribution (CI/CD)

| Feature | Priority | Platform |
|---------|----------|----------|
| Download latest APK from web app | P1 | Web |
| Auto-built APK on code push (GitHub Actions) | P1 | CI/CD |
| APK upload to Google Drive | P2 | CI/CD |
| Version-based changelog | P1 | Web |

---

## 5. Data Model

### Core Entities

```
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐
│    User      │───▶│   Category   │───▶│  Transaction    │
├─────────────┤    ├──────────────┤    ├─────────────────┤
│ uid          │    │ id           │    │ id              │
│ email        │    │ name         │    │ amount          │
│ displayName  │    │ budgetLimit  │    │ note            │
│ settings     │    │ color        │    │ date            │
│ createdAt    │    │ month/year   │    │ categoryId      │
│ updatedAt    │    │ userId       │    │ userId          │
└─────────────┘    └──────────────┘    └─────────────────┘
       │
       ▼
┌─────────────┐    ┌──────────────┐
│   Income     │    │ ChatMessage  │
├─────────────┤    ├──────────────┤
│ id           │    │ id           │
│ amount       │    │ content      │
│ month/year   │    │ isUser       │
│ userId       │    │ timestamp    │
└─────────────┘    └──────────────┘
```

---

## 6. User Flows

### 6.1 First-Time User Flow
1. Open app → Auth screen (login / sign-up)
2. Sign up with email/password or Google
3. Onboarding: Select currency → Set monthly income
4. Redirect to dashboard

### 6.2 Daily Usage Flow
1. Open app → Dashboard (income, spent, remaining)
2. Tap category → View category transactions
3. Tap "+" → Add new transaction (amount, note, date)
4. Return to dashboard → See updated totals

### 6.3 AI Advisor Flow
1. Navigate to AI Chat
2. Ask budget question or request insights
3. AI responds with personalized advice based on spending data
4. Continue conversation or reset chat

---

## 7. Non-Functional Requirements

| Requirement | Specification |
|-------------|--------------|
| **Performance** | App cold start < 3s; transaction entry < 10s |
| **Offline Support** | Full mobile functionality offline via Hive |
| **Cloud Sync** | Firebase Firestore real-time data sync |
| **Security** | Firebase Auth, Firestore security rules (owner-only access) |
| **Availability** | Web app deployed on Vercel with 99.9% uptime |
| **Scalability** | Firestore auto-scaling; per-user data isolation |
| **Accessibility** | Material Design 3 defaults; system theme support |
| **CI/CD** | Automated APK builds via GitHub Actions |

---

## 8. Platform Breakdown

| Capability | Mobile (Flutter) | Web (Next.js) |
|-----------|-----------------|---------------|
| Authentication | ✅ | ✅ |
| Onboarding | ✅ | ✅ |
| Dashboard | ✅ | ✅ |
| Budget categories | ✅ | ✅ |
| Transactions | ✅ | ✅ |
| Analytics charts | ✅ | ✅ |
| AI Chat | ✅ | ✅ |
| Settings | ✅ | ✅ |
| Offline mode | ✅ (Hive) | ❌ |
| APK download | ❌ | ✅ |
| Push notifications | 🔜 Planned | ❌ |
| Data export | 🔜 Planned | 🔜 Planned |

---

## 9. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Gemini API quota limits | AI features unavailable | Graceful fallback with error message |
| Firebase cost scaling | Unexpected billing | Per-user data isolation, Firestore rules |
| Offline-to-cloud sync conflicts | Data loss | Hive as source of truth, merge on sync |
| APK signing key loss | Cannot update app | Secure key storage in GitHub Secrets |

---

## 10. Future Roadmap

| Phase | Features |
|-------|---------|
| **v1.1** | Recurring transactions, receipt scanning |
| **v1.2** | Cloud sync between mobile & web |
| **v1.3** | Push notification budget alerts |
| **v2.0** | Multi-currency support, shared family budgets |
| **v2.1** | Data export (CSV/PDF), custom reports |
| **v3.0** | Bank account integration, automatic categorization |
