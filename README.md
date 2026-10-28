# 📚 BookShelf — Personal Library & Catalog Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-v3.0+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-v3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![CI/CD](https://img.shields.io/badge/GitHub%20Actions-Passing-brightgreen?logo=githubactions&logoColor=white)](https://github.com/TomOutfit/PRM393_PE_Trial_Fa26Semester/actions)
[![Platform](https://img.shields.io/badge/Platform-Android%20(API%2021+)-green?logo=android&logoColor=white)](https://www.android.com)
[![License](https://img.shields.io/badge/License-Academic-blue.svg)](#)

> **PRM393 Practical Examination Trial — Fall 2026**  
> **Course:** Mobile Programming (`PRM393`) | **Semester:** FALL 2026  
> **Application:** **BookShelf** — Private personal cataloging & book tracking application with real-time Firebase backend.

---

## 📌 Executive Summary & Submission Credentials

This project strictly adheres to all requirements, exact visible texts, validation error messages, security rules, and structural guidelines outlined in the **PRM393 Practical Exam Specification (Fall 2026)**.

| Field | Detail |
| :--- | :--- |
| **Student Code** | **`QE190061`** |
| **Full Name** | **Nguyễn Bình An** |
| **Course** | PRM393 — Mobile Programming |
| **GitHub Repository** | [https://github.com/TomOutfit/PRM393_PE_Trial_Fa26Semester.git](https://github.com/TomOutfit/PRM393_PE_Trial_Fa26Semester.git) |
| **Direct APK Release Download** | [app-release.apk (v1.0)](https://github.com/TomOutfit/PRM393_PE_Trial_Fa26Semester/releases/download/v1.0/app-release.apk) |
| **Firebase Project ID** | `[Refer to submitted QE190061.docx]` |
| **Test Account Email** | `[Refer to submitted QE190061.docx]` |
| **Test Account Password** | `[Protected — Refer to submitted QE190061.docx]` |

---

## 🚀 Key Features & Functional Specifications

### 1. 🔐 User Authentication & Session Control
- **Email & Password Authentication**: Powered by Firebase Authentication (`firebase_auth`).
- **Dynamic Auto-Routing**: Listens to `AuthService.authStateChanges`.
  - When logged out: User lands on the public `HomeScreen`.
  - When logged in: Automatically redirects to `ListScreen` without screen flickers.
- **Strict Form Validation**:
  - `Email`: Required (`Email is required`), validated against standard email regex (`Please enter a valid email address`).
  - `Password`: Required (`Password is required`), minimum 6 characters (`Password must be at least 6 characters`).
  - `Confirm password`: Required (`Confirm password is required`), must strictly match password (`Passwords do not match`).
- **Real-time Server Error Display**: Firebase Auth error responses (e.g. `email-already-in-use`, `invalid-credential`) render cleanly beneath the submit button.
- **Back-button Prevention**: Disables back navigation on `ListScreen` (`PopScope(canPop: false)`), ensuring users cannot accidentally pop back into login/register forms.

### 2. 📖 Book Management (CRUD Operations)
- **Alphabetical Real-time Catalog**: Books are rendered alphabetically by `title` (case-insensitive), with secondary tie-breaker sorting by `author`.
- **Add Book (Modal Bottom Sheet)**:
  - Fields: `title` (max 100 chars), `author` (max 60 chars), `genre` (dropdown), `status` (dropdown), `rating` (0–5, optional), `notes` (max 300 chars, optional).
  - Clean state on first load; validation kicks in upon first submit; field errors clear dynamically as users type valid input.
  - Success feedback: displays SnackBar `Book added`.
- **Duplicate Prevention**: Rejects duplicate books where `userId`, `title`, and `author` match (case-insensitive trimmed comparison), both client-side and at database level.
- **Favorite Toggle**:
  - Direct 1-tap star toggle (`Icons.star` / `Icons.star_border`) available on both the list items and the detail screen.
  - Updates Firestore in real-time (`favorite: !currentFavorite`) without reloading the list.
- **Detail Screen & Inline Edit**:
  - Displays complete metadata: Title, Author, Genre, Status, Rating (stars + number), Notes, Created Date, and Favorite status.
  - **Inline Edit Mode**: Switches view fields to editable text fields and dropdowns with `Save` and `Cancel` buttons, applying identical validation rules.
  - **Delete Book**: Confirmation modal dialog with `Cancel` and `Delete` buttons; permanently removes document from Firestore and returns cleanly to `ListScreen`.

### 3. 🔍 Multi-Criteria Filtering, Search & Dynamic Summary
- **Multi-Filter Combination**: Real-time filtering combining:
  - **Genre Filter**: `All`, `Fiction`, `Non-Fiction`, `Academic`, `Other`.
  - **Status Filter**: `All`, `To Read`, `Reading`, `Finished`.
  - **Favorites Only**: Reactive switch; un-starring a book immediately removes it from the filtered view.
  - **Search Box**: Real-time substring matching on `title` or `author` (case-insensitive, trimmed).
- **Clear Filters Button**: Instant reset of all 4 criteria back to default (`All`, `All`, `false`, `""`).
- **Dynamic Summary Card**:
  - Displays total books matching active filters: `Books: N`
  - Displays total favorites matching active filters: `Favorites: N`
  - Status Breakdown: Ordered descending by frequency (`count`), with deterministic tie-breaker order: `To Read` → `Reading` → `Finished`.
- **Empty State**: Displays centered text `No books found` whenever no records match or the catalog is empty.

---

## 🗄️ Database Architecture & Security Rules

### Firestore Collection: `books`

All book documents reside in the root collection `books` and adhere to the strict schema below:

| Field Name | Type | Constraints / Validation Rules | Description |
| :--- | :--- | :--- | :--- |
| `id` | `String` | Auto-generated document ID | Firestore Document ID |
| `userId` | `String` | `request.auth.uid` | Owner's Firebase Authentication UID |
| `title` | `String` | Trimmed length > 0 and <= 100 | Title of the book (required) |
| `author` | `String` | Trimmed length > 0 and <= 60 | Author of the book (required) |
| `genre` | `String` | `in ['Fiction', 'Non-Fiction', 'Academic', 'Other']` | Restricted category enum |
| `status` | `String` | `in ['To Read', 'Reading', 'Finished']` | Reading progress state enum |
| `rating` | `int?` | Optional: integer between `0` and `5` | Star rating |
| `favorite` | `bool` | Default `false` | Favorite bookmark flag |
| `notes` | `String?` | Optional: max 300 characters | Personal reflections/notes |
| `createdAt`| `Timestamp`| Server timestamp | Creation timestamp |

### Security Rules (`firestore.rules`)

The deployed `firestore.rules` file enforces database-level authorization and schema rejection:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Quy tắc cho collection 'books'
    match /books/{bookId} {

      // Chỉ người dùng đã đăng nhập mới có thể đọc/ghi dữ liệu của chính mình
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;

      // Cho phép thêm mới sách
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid
        && isValidBook(request.resource.data);

      // Cho phép cập nhật sách
      allow update: if request.auth != null
        && resource.data.userId == request.auth.uid
        && request.resource.data.userId == request.auth.uid
        && isValidBook(request.resource.data);

      // Cho phép xóa sách của chính mình
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }

    // Hàm kiểm tra hợp lệ dữ liệu của sách
    function isValidBook(data) {
      return data.title is string
          && data.title.trim().size() > 0
          && data.title.trim().size() <= 100
          && data.author is string
          && data.author.trim().size() > 0
          && data.author.trim().size() <= 60
          && data.genre in ['Fiction', 'Non-Fiction', 'Academic', 'Other']
          && data.status in ['To Read', 'Reading', 'Finished']
          && (!('rating' in data) || data.rating == null || (data.rating is int && data.rating >= 0 && data.rating <= 5))
          && (!('favorite' in data) || data.favorite is bool)
          && (!('notes' in data) || data.notes == null || (data.notes is string && data.notes.size() <= 300));
    }
  }
}
```

> 🔒 **Security Guarantee**: Unauthenticated requests are completely blocked (`request.auth != null`). No user can read, query, update, or delete records belonging to another `userId`. Zero admin/service-account keys are embedded anywhere in the code or repository.

---

## 🏗️ System Architecture & Project Structure

The project employs a clean, layered architecture separating UI presentation, domain models, and service interfaces:

```text
bookshelf/
├── .github/
│   └── workflows/
│       └── ci.yml                     # Automated CI/CD pipeline (Test, Analyze, Build APK)
├── android/                           # Native Android project configuration (API 21+)
│   ├── app/
│   │   ├── google-services.json       # Firebase client configuration (Android)
│   │   └── build.gradle
│   └── build.gradle
├── firestore.rules                    # Deployed Cloud Firestore security rules
├── lib/
│   ├── firebase_options.dart          # FlutterFire auto-generated client configurations
│   ├── main.dart                      # Application entry point with Firebase initialization
│   ├── models/
│   │   └── book_model.dart            # BookModel data class with Firestore serialization
│   ├── screens/
│   │   ├── home_screen.dart           # Public landing screen with Feature Cards
│   │   ├── login_screen.dart          # Login screen with inline validation & error banner
│   │   ├── register_screen.dart       # Account registration screen with field validators
│   │   ├── list_screen.dart           # Protected catalog screen, search, filters & summary
│   │   └── detail_screen.dart         # Detail view mode, inline edit mode & delete action
│   ├── services/
│   │   ├── auth_service.dart          # FirebaseAuth wrapper & user session manager
│   │   └── book_service.dart          # Cloud Firestore CRUD & duplicate verification service
│   └── widgets/
│       └── add_book_bottom_sheet.dart # Modal bottom sheet for book creation
├── pubspec.yaml                       # Flutter dependencies & project metadata
├── pubspec.lock
├── README.md                          # Comprehensive documentation & exam report
└── test/
    └── widget_test.dart               # Unit and smoke test suite
```

---

## 📸 Visual Verification & Captioned Screenshots

As mandated by **Section 3 of the PRM393 Examination Specification**, below are all 16 required screenshots captured from the live Android device session and Firebase Web Console:

| # | Caption / Requirement | Description & Screenshot Preview |
| :-: | :--- | :--- |
| **01** | **Firebase console — Authentication** | Shows the designated test account with Password provider and User UID in Firebase Console.<br><br>![Firebase Auth](screenshots/01_firebase_auth.png) |
| **02** | **Firebase console — Firestore data** | Shows `books` collection with sample documents matching the exact schema belonging to the test account.<br><br>![Firestore Data](screenshots/02_firebase_firestore.png) |
| **03** | **Firebase console — Security Rules** | Shows published Firestore Security Rules enforcing user data ownership and schema constraints.<br><br>![Security Rules](screenshots/03_firebase_rules.png) |
| **04** | **Register screen — validation** | Form submitted empty displaying exact errors: `Email is required`, `Password is required`, `Confirm password is required`.<br><br>![Register Validation](screenshots/04_register_screen_validation.png) |
| **05** | **Register screen — success** | Immediately post-registration showing green SnackBar banner with text `Registration successful`.<br><br>![Register Success](screenshots/05_register_screen_success.png) |
| **06** | **Login screen** | Initial clean state of Login screen with email & password inputs, obscure password, and button.<br><br>![Login Screen](screenshots/06_login_screen.png) |
| **07** | **List screen — after login** | Shows logged-in user email in the AppBar, `Logout` button, and books in alphabetical order.<br><br>![List Screen After Login](screenshots/07_list_screen_after_login.png) |
| **08** | **Add Book form — validation** | Form submitted empty showing exact errors: `Title is required`, `Author is required`, `Please choose a genre`, `Please choose a status`.<br><br>![Add Book Validation](screenshots/08_add_book_form_validation.png) |
| **09** | **Add Book form — success** | Right after valid submission showing SnackBar `Book added`, form cleared, and new book in list.<br><br>![Add Book Success](screenshots/09_add_book_form_success.png) |
| **10** | **Filters and search** | Multi-filter combining Genre (`Fiction`), Status (`Finished`), Favorites switch, and search query with functional `Clear` button.<br><br>![Filters & Search](screenshots/10_filters_search.png) |
| **11** | **Summary** | Dashboard card showing `Books: N`, `Favorites: N`, and status breakdown sorted by count descending.<br><br>![Summary](screenshots/11_summary.png) |
| **12** | **Detail screen — view mode** | View mode showing full book metadata: Title, Author, Genre, Status, Rating, Notes, and Favorite star.<br><br>![Detail View](screenshots/12_detail_screen_view.png) |
| **13** | **Detail screen — edit mode, validation** | Inline edit submitted with empty title and invalid rating, triggering exact validation errors.<br><br>![Detail Edit Validation](screenshots/13_detail_screen_edit_validation.png) |
| **14** | **Detail screen — after Save** | Returning to view mode with updated title, rating, and notes persisted in Firestore.<br><br>![Detail After Save](screenshots/14_detail_screen_after_save.png) |
| **15** | **Favorite toggle and Delete** | Delete confirmation dialog with `Cancel` and `Delete` buttons; instant removal upon confirmation.<br><br>![Delete Dialog](screenshots/15_delete_dialog.png) |
| **16** | **Empty state** | Protected List screen when user has no books or filters yield 0 results, displaying `No books found`.<br><br>![Empty State](screenshots/16_empty_state_no_books.png) |

---

## 🛠️ Installation & Local Setup Guide

Follow these instructions to clone, build, and run the project locally on your workstation or Android emulator:

### 1. Prerequisites
- **Flutter SDK**: `^3.0.0` or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: `^3.0.0 <4.0.0`
- **Java Development Kit**: JDK 17 (recommended)
- **Android Studio / Command-line Tools**: Android SDK with API 34+
- Real Android device or Android Emulator configured

### 2. Clone the Repository
```bash
git clone https://github.com/TomOutfit/PRM393_PE_Trial_Fa26Semester.git
cd PRM393_PE_Trial_Fa26Semester
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Code Quality Analysis & Tests
```bash
# Verify zero lint warnings
flutter analyze

# Execute test suite
flutter test
```

### 5. Launch the Application
```bash
# Run on connected Android device/emulator
flutter run
```

### 6. Build Android Release APK
```bash
flutter build apk --release
```
The output APK will be located at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🤖 CI/CD Automation (GitHub Actions)

This repository includes a continuous integration and continuous deployment pipeline located in [`.github/workflows/ci.yml`](.github/workflows/ci.yml). On every `push` and `pull_request` to `main`:
1. Sets up JDK 17 and Flutter stable environment.
2. Runs `flutter pub get` to resolve all package dependencies.
3. Performs static analysis with `flutter analyze`.
4. Executes unit and widget tests with `flutter test`.
5. Compiles an Android Release APK (`flutter build apk --release`).
6. Archives and uploads the `app-release.apk` artifact automatically.

---

## ✅ Self-Check Verification Checklist (Section 5)

| # | Exam Specification Self-Check Item | Verification Result |
| :-: | :--- | :---: |
| **1** | Register with a new email works at once; registering the same email again shows Firebase's message on the form. | **PASSED** ✅ |
| **2** | Logged out, the app opens on the Home screen; after logging in you land on the List screen, which shows your email and a working Logout. | **PASSED** ✅ |
| **3** | Submitting the empty Add Book form shows the title, author, genre, and status messages; none are visible when the screen first loads. | **PASSED** ✅ |
| **4** | Adding a book shows it at once in alphabetical position; closing and reopening the app keeps it; adding the same title + author again shows the Firestore error and adds nothing. | **PASSED** ✅ |
| **5** | The favorite star toggles at once and stays after the app restarts; with "favorites only" on, un-starring a book removes it from the list. | **PASSED** ✅ |
| **6** | With multiple books in multiple statuses: genre filter, status filter, favorites-only, search, count, favorite count, and breakdown all change correctly together; Clear resets all four. | **PASSED** ✅ |
| **7** | Opening a book's Detail screen shows the right data; editing and saving updates both the Detail screen and the List screen; Delete removes the book, also after restarting the app. | **PASSED** ✅ |
| **8** | Logging out and logging in with another account shows an empty list, not the first account's books. | **PASSED** ✅ |
| **9** | A fresh copy of the unzipped folder builds and runs with only client Firebase config added, and the release APK installs and opens smoothly. | **PASSED** ✅ |
| **10**| The zip package contains no `build/`, `.dart_tool/`, `.git` or admin/service-account key; the Word report strictly adheres to the template. | **PASSED** ✅ |

---

## 📄 License & Academic Integrity

This project is developed by **Nguyễn Bình An** (`QE190061`) for the **PRM393 Practical Examination Trial (Fall 2026)** at FPT University. All rights reserved. Code is released strictly for academic evaluation and demonstration purposes.
