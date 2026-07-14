# Product Requirements Document (PRD)

## Smart Grocery Shopping Assistant

**Version:** 1.0
**Date:** 12 July 2026
**Platform:** Flutter (frontend) / Firebase (backend)
**Source:** Derived from the Smart Grocery Shopping Assistant UX & UI Specification v1.0 (12 July 2026)

---

## Table of Contents

1. Introduction
2. Design System — Global UI Foundations
3. Information Architecture & Navigation
4. User Roles & Access Control
5. Global UX Behaviour & System States
6. Component & Widget Library
7. Module Specifications
8. Accessibility & Non-Functional Requirements
9. Functional Requirement Traceability Matrix
10. Appendix

---

## 1. Introduction

### 1.1 Purpose

Smart Grocery Shopping Assistant is a mobile application that helps Malaysian consumers compare grocery prices using the Malaysian Government **PriceCatcher** dataset. It lets users search products, compare prices across supermarkets, find nearby stores, build shopping lists with cost estimates, track a budget, and view historical price trends — in English, Bahasa Melayu, or Chinese.

### 1.2 Scope

Four core modules and four supporting modules, plus a shared Notification Centre:

**Core modules**
- Module 1 — Product Search & Price Comparison
- Module 2 — Nearby Supermarkets
- Module 3 — Shopping List & Cost Estimator
- Module 4 — Price Trends & Analytics

**Supporting modules**
- Module 5 — Three-Language Support
- Module 6 — Dashboard & UI Foundation
- Module 7 — Login / Logout & Guest Access
- Module 8 — Budget Shopping List

### 1.3 Intended Audience

- Frontend developers implementing the Flutter UI
- UI/UX reviewers validating design consistency
- Course examiners assessing the software engineering deliverable

### 1.4 How to Read This Document

Each module section (§7) follows the same structure: purpose, related functional requirements, screen wireframe(s), interaction flow, business rules / component notes, and developer notes. Wireframes are simplified ASCII layouts showing structure and content priority, not final visual design.

---

## 2. Design System — Global UI Foundations

"Modern Minimalist" style, shared across all modules.

### 2.1 Design Goals

- Simple and intuitive interface
- Mobile-first design
- Modern minimalist appearance
- Reduce user steps
- Fast product comparison
- Consistent UI across all modules

### 2.2 Colour Palette

| Role | Suggested Value | Usage |
|---|---|---|
| Primary (Green) | `#2E7D32` | Filled buttons, active nav state, success indicators, budget bar within limit |
| Background | `#FFFFFF` | Screen and card backgrounds |
| Text (Dark Gray) | `#333333` | Primary body and label text |
| Warning (Amber) | `#FFA000` | Price alerts, budget approaching limit |
| Error (Red) | `#D32F2F` | Error states, budget exceeded |
| Info (Blue) | `#1976D2` | Informational banners, links, secondary highlights |
| Surface / Divider | `#F5F5F5` / `#E0E0E0` | Card fill, list separators |

### 2.3 Typography

| Style | Size | Weight | Usage |
|---|---|---|---|
| Heading 1 | 22 sp | Bold | Screen titles |
| Heading 2 | 18 sp | Semi-bold | Section headers, card titles |
| Body | 14 sp | Regular | Primary content text |
| Caption | 12 sp | Regular | Metadata, timestamps, helper text |
| Button Label | 14 sp | Medium | All button text |

### 2.4 Spacing & Layout Grid

- Base unit: 8dp grid (4dp for compact list rows)
- Screen horizontal padding: 16dp
- Card internal padding: 12–16dp
- Vertical spacing between cards: 8dp

### 2.5 Buttons

| Type | Style | Example Usage |
|---|---|---|
| Filled | Primary action — green fill, white label | Apply, Login, Complete Shopping, Save Budget |
| Outlined | Secondary action — green outline, green label | Cancel, Reset, Register |
| Text | Minor / tertiary action — no border or fill | Skip, View All, Clear All |

### 2.6 Cards

- Rounded corners (suggested 12dp radius)
- Soft drop shadow for elevation
- Consistent internal spacing across all card types (product, store, alert, budget)

---

## 3. Information Architecture & Navigation

### 3.1 App Structure

```
Dashboard
├─ Search Products
├─ Shopping List
├─ Nearby Supermarkets
├─ Price Trends
├─ Saved Products
├─ Profile
├─ Settings
│  └─ Language
└─ About
```

### 3.2 Global Navigation Pattern

| Element | Behaviour |
|---|---|
| Landing screen | Dashboard |
| Primary navigation | App Bar (top) + Navigation Drawer (side) |
| Quick access | Quick Action cards on the Dashboard link directly to Search, Nearby, List and Trends |

### 3.3 Role-Based Access Flow

```
App Launch → Dashboard
                ├─ Continue as Guest → Search & Compare, View Map & Trends, Temporary Shopping List
                └─ Login / Register  → All Guest Features + Saved Products + Price Alerts + Saved Shopping List
```

---

## 4. User Roles & Access Control

| Capability | Guest | Registered User |
|---|---|---|
| Search & compare prices | Yes | Yes |
| View nearby supermarkets & maps | Yes | Yes |
| View price trends | Yes | Yes |
| Shopping list | Temporary (session only) | Saved to account |
| Save products | No — prompted to log in | Yes |
| In-app price alerts | No | Yes |

Attempting a registered-only action as a Guest (e.g. tapping "Save Product") triggers a Login/Register dialog rather than blocking the action silently — see Module 7 (§7.2).

---

## 5. Global UX Behaviour & System States

These states apply to every list-driven and network-driven screen across all modules.

| State | Behaviour |
|---|---|
| Loading | Skeleton loader in place of content |
| Empty | Friendly message with an action button (e.g. "No products found — try another search") |
| Error | Inline message with a Retry button |
| Long Process | Progress message (e.g. while calculating cost estimate) |
| Offline | Dedicated "No Internet" screen |
| Accessibility | Minimum 48×48dp touch targets, high-contrast text, scalable font sizes |

### Feedback Patterns

- **SnackBar** for transient confirmations (e.g. "Added to shopping list")
- **BottomSheet** for filters, store details, and language selection
- **Dialog** for authentication prompts and destructive-action confirmation (e.g. Clear All)

---

## 6. Component & Widget Library

| Component | UI Role | Flutter Widget |
|---|---|---|
| Drawer | Global navigation menu | `Drawer` |
| Card | Product / store / alert / budget containers | `Card` |
| SearchBar | Product search entry point | `SearchBar` |
| BottomSheet | Filters, store details, language picker | `showModalBottomSheet` |
| List | Scrollable result / list screens | `ListView.builder` |
| Progress Bar | Budget usage indicator | `LinearProgressIndicator` |
| Map | Nearby supermarkets | `GoogleMap` |
| Snackbar | Transient confirmations | `SnackBar` |

---

## 7. Module Specifications

Each module shares the global design system (§2), navigation (§3), and state handling (§5).

| § | Module | Primary FR(s) |
|---|---|---|
| 7.1 | Module 6 — Dashboard & UI Foundation | Supports all — navigation entry point |
| 7.2 | Module 7 — Login / Logout & Guest Access | FR8, FR9 |
| 7.3 | Module 1 — Product Search & Price Comparison | FR1, FR2, FR3 |
| 7.4 | Module 2 — Nearby Supermarkets | FR4 |
| 7.5 | Module 3 — Shopping List & Cost Estimator | FR5, FR6 |
| 7.6 | Module 4 — Price Trends & Analytics | FR10 |
| 7.7 | Module 8 — Budget Shopping List | FR7 |
| 7.8 | Module 5 — Three-Language Support | FR11 |
| 7.9 | Notification Centre | FR9 (support) |

---

### 7.1 Module 6 — Dashboard & UI Foundation

**Purpose:** Central landing screen and navigation hub. Surfaces the most time-sensitive information (budget status, nearby cheapest store, price alerts) without requiring the user to navigate away.

**Screen Elements**
- Search bar (shortcut into Module 1)
- Quick Action cards: Search, Nearby, List, Trends
- Budget Card — visible only after a budget has been created (Module 8)
- Nearby Cheapest Supermarket card
- Price Alerts preview
- Recent Products list

```
+-----------------------------------+
| [=] Smart Grocery      [Bell][P] |  App Bar
+-----------------------------------+
| [Search] Search products...      |
+-----------------------------------+
| Quick Actions                     |
| [Search] [Nearby] [List] [Trends] |
+-----------------------------------+
| Budget: RM120 / RM200  [====   ]  |  * shown only after budget setup
+-----------------------------------+
| Nearby Cheapest Supermarket       |
|  NSK Kolombong          1.2 km    |
+-----------------------------------+
| Price Alerts                      |
|  Cooking Oil price dropped RM2    |
+-----------------------------------+
| Recent Products                   |
|  Sunflower Oil 1L      RM8.90     |
|  Rice 5kg               RM22.50   |
+-----------------------------------+
```
*Figure 7.1.1 — Dashboard wireframe*

```
+-------------------------+
| Smart Grocery           |
| user@example.com        |
+-------------------------+
| Dashboard                |
| Search Products          |
| Shopping List             |
| Nearby Supermarkets       |
| Price Trends              |
| Saved Products             |
| Profile                   |
| Settings                  |
| About                     |
+-------------------------+
| Logout                    |
+-------------------------+
```
*Figure 7.1.2 — Navigation Drawer wireframe*

**Developer Notes**
- Reuse shared components (Card, Drawer, SearchBar) across all modules.
- Use `ListView.builder` for Recent Products and Price Alerts lists.
- Budget Card visibility is conditional on budget-created state (see §7.7).
- Follow the shared design system (§2) for spacing and colour.

---

### 7.2 Module 7 — Login / Logout & Guest Access

**Purpose:** Provide optional authentication: Guests can use most of the app immediately; registration is only required to unlock saving and alerts, minimising onboarding friction (design goal: reduce user steps).

**Related Functional Requirements**

| FR | Requirement |
|---|---|
| FR8 | Users can save products after login. |
| FR9 | Users can receive in-app price alerts. |

**Access Rules**

| Role | Allowed Without Login |
|---|---|
| Guest | Search products, compare prices, view nearby supermarkets, view price trends, temporary shopping list |
| Registered | All guest features, plus: saved products, in-app price alerts, saved (persistent) shopping list |

```
+-----------------------------------+
|          Login / Register         |
+-----------------------------------+
| Email    [_____________________]  |
| Password [_____________________]  |
|          [ Login ]                |
| Don't have an account? Register   |
+-----------------------------------+
```
*Figure 7.2.1 — Login / Register screen*

```
+-----------------------------------+
|          Login Required           |
| Please log in to save products    |
| and receive price alerts.         |
|     [Login]      [Cancel]         |
+-----------------------------------+
```
*Figure 7.2.2 — Guest gating dialog (triggered by "Save Product")*

**Authentication Gating Flow**

```
User Taps 'Save Product' or 'Save List'
        │
        ▼
    Logged In? ──yes──► Save Product + Enable Price Tracking
        │no
        ▼
Show Login/Register Dialog ──► Login ──┐
                              └► Register ─┴► Authenticated ──retry save──► Save Product + Enable Price Tracking
```
*Figure 7.2.3 — Authentication gating flow*

**Developer Notes**
- Use Firebase Authentication for email/password login and session state.
- Gate save/alert actions behind an auth-state check rather than hiding the buttons, so guests understand the value of registering.
- Persist shopping list locally for guests; migrate to Firestore on registration if feasible.

---

### 7.3 Module 1 — Product Search & Price Comparison

**Purpose:** Let users search grocery products, compare prices across supermarkets, and add items to their shopping list — the app's core value proposition.

**Related Functional Requirements**

| FR | Requirement |
|---|---|
| FR1 | Users can search grocery products. |
| FR2 | Users can compare prices across supermarkets. |
| FR3 | Users can filter and sort products. |

**Screen: Search & Results**

```
+-----------------------------------+
| < Search Products                 |
+-----------------------------------+
| [Search] cooking oil____________  |
+-----------------------------------+
| Recent Searches                   |
|  Rice   Sugar   Milk              |
+-----------------------------------+
| [Filter v]           Results: 24  |
+-----------------------------------+
| Sunflower Oil 1L                  |
| Category: Cooking Oil   Unit: 1L  |
| Cheapest: RM8.90 (NSK)            |
|  [Compare Prices]     [+ Add]     |
+-----------------------------------+
| (next product card...)            |
+-----------------------------------+
```
*Figure 7.3.1 — Search results with Product Card*

```
+-----------------------------------+
|              Filter               |
+-----------------------------------+
| Category   [ Cooking Oil     v]   |
| Price Range [ RM0 ---o---- RM50]  |
| Sort By    ( ) Price              |
|            ( ) Distance           |
|            ( ) Alphabetical       |
+-----------------------------------+
|   [Reset]        [Apply]          |
+-----------------------------------+
```
*Figure 7.3.2 — Filter bottom sheet*

```
+-----------------------------------+
| < Compare Prices — Sunflower Oil  |
+-----------------------------------+
| Lowest   Average    Highest       |
| RM8.90   RM10.20    RM12.50       |
+-----------------------------------+
| Sort: [Price v]                   |
+-----------------------------------+
| NSK Kolombong        RM8.90  1.2km|
| Giant Kepayan         RM9.50 2.4km|
| Tesco Warisan Sq.    RM10.80 3.1km|
+-----------------------------------+
|       [+ Add to List]             |
+-----------------------------------+
```
*Figure 7.3.3 — Price comparison screen*

**Product Card — Component Spec**

| Field | Description |
|---|---|
| Product Name | Display name of the item |
| Category | Product category tag |
| Unit | e.g. 1L, 5kg, 1 unit |
| Cheapest Price | Lowest current price + supermarket name |
| Compare Prices | Secondary button → Comparison screen |
| Add | Primary button → adds to Shopping List (Module 3) |

**Interaction Flow**

```
Open Search Screen
   → Type Keyword / Tap Recent Search / Select Autocomplete
   → Product Results List
        ├─(filter)→ Filter & Sort (Bottom Sheet) ─(apply)→ Product Results List
        ├─(tap card)→ Comparison Screen (Lowest/Avg/Highest) → Add to Shopping List
        └─(quick add)→ Add to Shopping List
   → Shopping List (Module 3)
```
*Figure 7.3.4 — Search-to-list interaction flow*

**Screen States**
- Loading — skeleton list while results load
- Empty — "No products found" with a Clear Filters action
- Error — retry button on failed fetch

**Developer Notes**
- Debounce search input to limit dataset queries.
- Use `ListView.builder` for results and `BottomSheet` for the filter panel.
- Comparison screen sort options: Price, Distance, Alphabetical.

---

### 7.4 Module 2 — Nearby Supermarkets

**Purpose:** Help users locate nearby supermarkets on a map and navigate to them using Google Maps.

**Related Functional Requirement**

| FR | Requirement |
|---|---|
| FR4 | Users can locate nearby supermarkets. |

**Screen: Map & Store Details**

```
+-----------------------------------+
|       [ Google Map View ]         |
|                                    |
|   (marker)   (marker)    (you)    |
|                                    |
+-----------------------------------+
```
*Figure 7.4.1 — Default map screen*

```
+-----------------------------------+
| NSK Kolombong                     |
| 123 Jalan Kolombong, Kota Kinabalu|
| Distance: 1.2 km                  |
+-----------------------------------+
|  [Navigate]     [View Prices]     |
+-----------------------------------+
```
*Figure 7.4.2 — Store bottom sheet (marker tap)*

**Interaction Flow**

```
Open Nearby Supermarkets
   → Google Map View (user location + markers)
   → Tap Marker
   → Store Bottom Sheet (Name, Address, Distance)
        ├─ Navigate    → Google Maps App (external)
        └─ View Prices → Store Price List (links to Module 1)
```
*Figure 7.4.3 — Nearby supermarkets interaction flow*

**Developer Notes**
- Use the `GoogleMap` widget with the device's current location as the initial camera position.
- "Navigate" launches the external Google Maps app with the store's coordinates.
- "View Prices" opens the store's product list, reusing the Comparison screen layout (§7.3).

---

### 7.5 Module 3 — Shopping List & Cost Estimator

**Purpose:** Let users build a shopping list, automatically estimate total cost, and identify the cheapest place (or combination of places) to buy everything.

**Related Functional Requirements**

| FR | Requirement |
|---|---|
| FR5 | Users can create and manage shopping lists. |
| FR6 | Users can estimate shopping costs. |

**Screen: Shopping List**

```
+-----------------------------------+
| < Shopping List                   |
+-----------------------------------+
| Sunflower Oil 1L    Qty [ 2 ] x   |
| Rice 5kg             Qty [ 1 ] x  |
| Sugar 1kg             Qty [ 3 ] x |
+-----------------------------------+
| Total Cost:          RM58.40      |
| Cheapest Supermarket: NSK         |
| Mixed-Store Total:   RM52.10      |
+-----------------------------------+
|       [Complete Shopping]         |
+-----------------------------------+
```
*Figure 7.5.1 — Shopping list & cost estimator*

**Business Rules**
- Adding a product already in the list increases its quantity instead of creating a duplicate row.
- Total cost recalculates automatically on any quantity change.
- "Mixed-Store Total" recommends the cheapest supermarket per item when it beats a single-store total.

**Interaction Flow**

```
Add Product to List (from Module 1)
   → Already in List?
        ├─yes→ Increase Quantity +1
        └─no → Insert New Item (Qty = 1)
   → Recalculate Total Cost
   → Compare Supermarket Totals
   → Recommend Cheapest / Mixed-Store Option
   → Complete Shopping
```
*Figure 7.5.2 — Cost estimation interaction flow*

**Developer Notes**
- Use `ListView.builder` with a quantity stepper per row.
- "Complete Shopping" clears or archives the list per product decision (not specified in PRD — default: archive).

---

### 7.6 Module 4 — Price Trends & Analytics

**Purpose:** Show historical price movement for a product so users can decide whether now is a good time to buy.

**Related Functional Requirement**

| FR | Requirement |
|---|---|
| FR10 | Users can view historical price trends. |

**Screen: Analytics**

```
+-----------------------------------+
| < Price Trends                    |
+-----------------------------------+
| [Search] Search a product...      |
+-----------------------------------+
| Sunflower Oil 1L                  |
|                                    |
| RM12 |          *                 |
| RM10 |   *  *   *   *             |
| RM8  |*        *   *              |
|      +------------------------    |
|       J  F  M  A  M  J  J         |
+-----------------------------------+
| Lowest RM8.10  Avg RM9.80  High RM11.90 |
+-----------------------------------+
| Date        Store     Price       |
| 2026-07-01  NSK       RM8.90      |
| 2026-06-15  Giant     RM9.20      |
+-----------------------------------+
```
*Figure 7.6.1 — Price trend analytics screen*

A product search is required before analytics can be viewed ("Search required before viewing analytics").

**Analytics Access Flow**

```
Open Price Trends
   → Product Selected?
        ├─no → Prompt: Search a Product First → (back to Open Price Trends)
        └─yes→ Analytics Page
                 ├─ Line Chart (historical prices)
                 ├─ Price Table (date, store, price)
                 └─ Lowest / Average / Highest
```
*Figure 7.6.2 — Analytics access flow*

**Developer Notes**
- Line chart plots historical price against date; table lists raw records below it.
- Compute Lowest / Average / Highest client-side from the fetched PriceCatcher records, or via a backend aggregation if available.

---

### 7.7 Module 8 — Budget Shopping List

**Purpose:** Help budget-conscious shoppers set a spending limit and stay within it while building a shopping list.

**Related Functional Requirement**

| FR | Requirement |
|---|---|
| FR7 | Users can set a shopping budget. |

**Screen: Budget**

```
+-----------------------------------+
| < My Budget                       |
+-----------------------------------+
| Set Budget: [ RM200.00     ]      |
|             [Save Budget]         |
+-----------------------------------+
| Budget Used                       |
| RM120 / RM200                     |
| [==============------] 60%        |
+-----------------------------------+
| Cheaper Alternatives               |
|  Try Brand X Rice — Save RM3.00   |
+-----------------------------------+
```
*Figure 7.7.1 — Budget screen (within limit)*

**Business Rules**
- Budget decreases automatically as items are added to the shopping list.
- Progress bar is green while within budget; turns red when the budget is exceeded.
- When exceeded, the system surfaces cheaper alternative products.
- The Dashboard Budget Card (§7.1) appears only once a budget has been created.

**Budget Tracking Flow**

```
Enter Budget Amount
   → Add Products to Shopping List
   → Recalculate Remaining Budget
   → Exceeded Budget?
        ├─no → Green Progress Bar (within budget)
        └─yes→ Red Progress Bar + Suggest Cheaper Alternatives
   (user adjusts list) → back to Add Products to Shopping List
```
*Figure 7.7.2 — Budget tracking flow*

**Developer Notes**
- Use `LinearProgressIndicator` with a colour swap driven by a threshold check (used / total > 1.0).
- Recalculate on every shopping list change (shared state with Module 3).

---

### 7.8 Module 5 — Three-Language Support

**Purpose:** Allow users to switch the app's display language between English, Bahasa Melayu, and Chinese.

**Related Functional Requirement**

| FR | Requirement |
|---|---|
| FR11 | Users can switch application language. |

```
+-----------------------------------+
| < Settings > Language             |
+-----------------------------------+
| ( ) English                       |
| (o) Bahasa Melayu                 |
| ( ) Chinese                       |
+-----------------------------------+
|            [Apply]                |
+-----------------------------------+
```
*Figure 7.8.1 — Language selection screen*

**Language Switch Flow**

```
Settings → Language → Select Language (EN / BM / ZH) → Apply → UI Reloads in Selected Language
```
*Figure 7.8.2 — Language switch flow*

**Developer Notes**
- Use Flutter's localization (`intl` / `.arb` files) with one bundle per supported language.
- Persist the selected language locally so it survives app restarts.
- Apply the change immediately without requiring a full app restart ("App updates immediately after selection").

---

### 7.9 Notification Centre

**Purpose:** Central location for in-app price alerts and system notifications, supporting FR9 (in-app price alerts).

```
+-----------------------------------+
| < Notifications      [Mark All]   |
+-----------------------------------+
|  Cooking Oil price dropped RM2.00 |
|  2 hours ago                      |
+-----------------------------------+
|  Rice price increased RM1.00      |
|  1 day ago                        |
+-----------------------------------+
|          [Clear All]              |
+-----------------------------------+
```
*Figure 7.9.1 — Notification Centre*

**Rules**
- In-app notifications only — no push notifications in this scope.
- Saving a product automatically enables price tracking for that product.
- "Mark All as Read" and "Clear All" are available from the app bar.

---

## 8. Accessibility & Non-Functional Requirements

| Non-Functional Requirement | UX Implementation |
|---|---|
| Mobile-first responsive interface | Single-column layouts, touch-first controls, tested at common Android/iOS breakpoints |
| Easy-to-use navigation | Consistent App Bar + Drawer pattern (§3.2) on every screen |
| Fast search performance | Debounced search input, skeleton loading state (§5) |
| Secure user authentication | Firebase Authentication; session-gated actions (§7.2) |
| High availability | Offline state screen (§5) with retry, cached last-known data where feasible |
| Accessibility support | 48×48dp minimum touch targets, high-contrast text, scalable font sizes (§5) |
| Modern minimalist UI | Design system tokens in §2 applied consistently across modules |

---

## 9. Functional Requirement Traceability Matrix

| FR | Requirement | Module | Primary Screen(s) |
|---|---|---|---|
| FR1 | Search grocery products | Module 1 | Search & Results (§7.3) |
| FR2 | Compare prices across supermarkets | Module 1 | Comparison Screen (§7.3) |
| FR3 | Filter and sort products | Module 1 | Filter Bottom Sheet (§7.3) |
| FR4 | Locate nearby supermarkets | Module 2 | Map & Store Bottom Sheet (§7.4) |
| FR5 | Create and manage shopping lists | Module 3 | Shopping List (§7.5) |
| FR6 | Estimate shopping costs | Module 3 | Shopping List (§7.5) |
| FR7 | Set a shopping budget | Module 8 | Budget Screen (§7.7) |
| FR8 | Save products after login | Module 7 | Login/Register + Gating Dialog (§7.2) |
| FR9 | Receive in-app price alerts | Module 7 / Notification Centre | Notification Centre (§7.9) |
| FR10 | View historical price trends | Module 4 | Analytics Screen (§7.6) |
| FR11 | Switch application language | Module 5 | Language Selection (§7.8) |

---

## 10. Appendix

### A. Glossary

| Term | Definition |
|---|---|
| PriceCatcher | Malaysian Government dataset of grocery transactional price records used as the app's core data source |
| Guest | An unauthenticated user with access to core browsing features |
| Mixed-Store Recommendation | A cost estimate that buys each item from whichever supermarket is cheapest for that item |

### B. Assumptions & Constraints

- Internet connection is required.
- Google Maps is used for navigation.
- Product information depends on government datasets.
- Historical data availability depends on PriceCatcher records.

### C. Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter |
| Backend | Firebase |
| Database | Firestore |
| Maps | Google Maps |
| Authentication | Firebase Authentication |
| Dataset | Malaysia PriceCatcher Government Dataset |

---

*— End of Document —*
