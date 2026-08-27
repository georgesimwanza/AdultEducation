# PAMODZI

An offline-first adult literacy and education platform built with Flutter, designed to bring structured learning to adult learners regardless of connectivity.

## About

PAMODZI lets institutions manage subjects, content, quizzes, students, and scheduling in one place, while giving learners a reliable app experience even with intermittent internet access. Data captured offline syncs automatically once a connection is available, so nothing is lost and nothing blocks a learner from continuing their studies.

## Features

- **Offline-first design** — local storage (SQLite/Drift, Hive) keeps the app fully usable without a connection
- **Automatic sync** — an on-device sync engine (outbox queue, change tracking, conflict resolution) reconciles local and server data once online
- **Subjects & content** — structured course material organized by subject
- **Quizzes** — assessments supporting multiple question types
- **Student & institution management** — role-based access for students, teachers, and administrators
- **Scheduling** — tools for planning and tracking learning sessions

## Tech Stack

- **Frontend:** Flutter (Riverpod/BLoC for state management)
- **Backend:** Spring Boot (Java)
- **Storage:** PostgreSQL, Redis, S3-compatible storage, with SQLite/Drift and Hive on-device
- **Auth:** JWT with role-based access control

## Getting Started

1. Ensure Flutter is installed — see the [Flutter setup guide](https://docs.flutter.dev/get-started/install)
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to launch the app

## Project Status

Actively in development. Current focus includes the quiz module and stabilizing entity serialization on the backend.

## License

TBD
