# PuTa - Movie Discovery & News App

Welcome to **PuTa**, a comprehensive mobile application for movie enthusiasts. Beyond just watching trailers, PuTa offers a complete ecosystem including movie news, actor profiles, user authentication, and a personalized experience.

The project is structured using a **Feature-first Architecture** to ensure scalability and maintainability.

## Project Information

* **App Name:** PuTa
* **Author:** Tran Thi Kim Phung, Huynh Thanh Nhuan
* **Tech Stack:** Flutter (Dart)

## Features

Based on the project modules, the application includes the following key features:

* **Authentication (`auth`):** Secure Login and Registration system for users.
* **Movie Discovery (`home`, `movie`):** Browse trending, popular, and top-rated movies. View detailed movie information.
* **Actor Profiles (`actor`):** Detailed information about cast members and their filmography.
* **News & Exploration (`explore_news`):** Stay updated with the latest movie news and articles.
* **Search System (`search`):** Advanced search functionality to find movies and actors.
* **Media Player (`player`):** Integrated video player to watch high-quality movie trailers.
* **Personalization (`favorites`, `profile`):**
  * Manage personal profile settings.
  * Save movies to a "Favorites" list.
* **Notifications (`notifications`):** System to receive updates and alerts.
* **UI/UX:** Modern interface with custom themes and reusable widgets (`shared/widgets`).

## Tech Stack & Architecture

* **Framework:** Flutter
* **Language:** Dart
* **Architecture:** Feature-first Architecture (Separation of concerns).
* **State Management:** Provider (implied by `providers` directory).
* **Networking:** Handled via `core/api` and `core/services`.
* **Routing:** Centralized navigation management in `core/router`.

## Folder Structure

The project follows a scalable folder structure divided by features and core utilities:

```text
lib/
├── core/                # Core utilities, API configs, and global services
│   ├── api/
│   ├── data/
│   ├── models/
│   ├── router/          # App navigation & routing
│   ├── services/
│   └── theme/           # App theming (colors, fonts)
├── features/            # Feature-based modules
│   ├── actor/           # Actor details
│   ├── auth/            # Authentication logic & screens
│   ├── explore_news/    # News feed
│   ├── favorites/       # Watchlist
│   ├── home/            # Main dashboard
│   ├── movie/           # Movie details
│   ├── notifications/   # Notification handling
│   ├── player/          # Video player logic
│   ├── profile/         # User profile
│   └── search/          # Search functionality
├── providers/           # Global state providers
└── shared/              # Reusable components used across features
    ├── utils/
    └── widgets/
        ├── cards/
        ├── common/
        ├── effects/
        ├── forms/
        ├── lists/
        ├── navigation/
        └── text/

Installation
To run this project locally, please follow these steps:

Clone the repository:

Bash

git clone [https://github.com/Gabu1909/Movie-Trailer-App.git](https://github.com/Gabu1909/Movie-Trailer-App.git)
Install dependencies: Navigate to the project directory and run:

Bash

flutter pub get
API Configuration:

This app likely requires an API Key (e.g., TMDB).

Check core/api or core/services to configure your API keys.

Run the App:

Bash

flutter run

Developed by Tran Thi Kim Phung & Huynh Thanh Nhuan. Enjoy exploring movies with PuTa!