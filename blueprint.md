
# Nostr Key Management App Blueprint

## Overview

This document outlines the plan and structure for a Flutter-based Nostr key management application. The app will provide secure key storage, NIP-05 login, and management of connected applications.

## Core Features

*   **Secure Key Management:**
    *   Generate new npub/nsec key pairs.
    *   Import existing nsec keys.
    *   Securely store keys using `flutter_secure_storage`.
    *   Display a list of saved keys.
    *   Delete keys.
*   **NIP-05 Login:**
    *   Implement user login via NIP-05 identifiers.
*   **Connect to Nostr Apps:**
    *   Handle `nostrconnect://` and `bunker://` deep links.
    *   Manage permissions for connected applications.
    *   List connected applications and allow disconnection.
*   **User Interface:**
    *   A clean and intuitive interface for managing keys and apps.
    *   A bottom navigation bar for easy switching between major sections.
    *   A dedicated login screen.

## Project Structure

The project will follow a feature-first architecture to ensure scalability and maintainability.

```
.
├── lib
│   ├── core
│   │   └── storage
│   │       └── secure_storage.dart
│   ├── features
│   │   ├── auth
│   │   │   ├── pages
│   │   │   │   └── login_page.dart
│   │   │   └── widgets
│   │   ├── keys
│   │   │   ├── pages
│   │   │   │   └── keys_page.dart
│   │   │   ├── widgets
│   │   │   │   └── key_pair.dart
│   │   │   └── models
│   │   │       └── npub_nsec.dart
│   │   └── apps
│   │       ├── pages
│   │       │   └── connected_apps_page.dart
│   │       └── widgets
│   ├── services
│   │   └── nostr_service.dart
│   └── main.dart
└── pubspec.yaml
```

## Implementation Plan

1.  **Create `blueprint.md`:** Outline the project features and structure.
2.  **Add Dependencies:** Add `nostr_sdk` and `flutter_secure_storage` to `pubspec.yaml`.
3.  **Create Project Structure:**
    *   Create `core`, `features`, and `services` directories.
    *   Create `storage/secure_storage.dart` in `core`.
    *   Create `auth`, `keys`, and `apps` directories in `features`.
    *   Create `pages`, `widgets`, and `models` subdirectories for each feature.
4.  **Develop Key Management:**
    *   Implement `NpubNsec` model in `keys/models`.
    *   Create `KeysPage` to display and manage keys.
    *   Add functionality to generate, import, and delete keys.
5.  **Implement Authentication:**
    *   Create `LoginPage` for NIP-05 login.
6.  **Develop Connected Apps Management:**
    *   Create `ConnectedAppsPage` to list and manage connected apps.
7.  **Set Up Navigation:**
    *   Update `main.dart` with a `BottomNavigationBar` to switch between `KeysPage` and `ConnectedAppsPage`.
    *   Set `LoginPage` as the initial route.
