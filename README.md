# PAMODZI

PAMODZI is an offline-first adult education platform built with a Flutter mobile client and a Spring Boot backend. It supports subjects, learning content, quizzes, student management, and scheduling, with two-way sync between devices and the server.

## Features

- **Subjects & Content** — Browse and manage educational subjects and their associated learning materials
- **Quizzes** — Take and manage quizzes, with support for multiple question types via a single-table inheritance model
- **Student Management** — Track and filter students, including by institution
- **Scheduling** — Manage class/session scheduling
- **Offline-First Sync** — Full offline access on the mobile client, with automatic two-way sync to the backend when connectivity is available
- **Role-Based Access** — JWT authentication with `USER` and `ADMIN` roles
- **Institution Support** — Institution registration/login flow with student filtering by institution

## Tech Stack

### Backend
- **Spring Boot** (Java) — package root: `com.project.adult`
- **JWT** — authentication with role-based access control
- **JPA/Hibernate** — entity relationships, with `@JsonIgnoreProperties` applied across bidirectional relationship cycles to avoid infinite recursion during serialization
- **Supabase Storage** — CDN for media/content assets

### Mobile (Flutter)
- **Flutter / Dart**
- **Provider** — state management
- **sqflite (SQLite)** — local offline storage
- **SharedPreferences** — local key-value storage (e.g. institution/session context)

## Architecture: Offline Sync

PAMODZI uses a timestamp-based diffing strategy to keep the mobile client and backend in sync:

- **Backend**: exposes `/api/sync/*` endpoints, using repository queries like `findByUpdatedAtAfter` to return only records changed since the client's last sync
- **Mobile**: a `SyncService` built on `sqflite` pulls and merges these diffs into the local database, so the app remains fully usable offline

## Getting Started

### Prerequisites
- JDK 17+
- Maven (or the included wrapper)
- Flutter SDK
- A Supabase project (for storage)
- A running database (e.g. PostgreSQL) for the Spring Boot backend

### Backend Setup

```bash
cd backend
# configure application.properties / application.yml with:
#   - database connection
#   - JWT secret
#   - Supabase Storage credentials
./mvnw spring-boot:run
```

### Mobile Setup

```bash
cd mobile
flutter pub get
flutter run
```

## Project Structure

```
pamodzi/
├── backend/                  # Spring Boot API
│   └── src/main/java/com/project/adult/
│       ├── controller/        # REST endpoints, including /api/sync/*
│       ├── entity/            # JPA entities (subjects, quizzes, students, etc.)
│       ├── repository/        # Spring Data repositories
│       └── service/
└── mobile/                   # Flutter client
    └── lib/
        ├── screens/            # Subjects, content, quizzes, students, scheduling
        ├── services/           # SyncService and API clients
        └── providers/          # Provider state management
```

## Known Challenges / Notes for Contributors

- **Serialization**: Bidirectional JPA relationships (e.g. in the quiz module) can trigger Jackson infinite recursion. Apply `@JsonIgnore` / `@JsonIgnoreProperties` consistently across entity relationship cycles.
- **Quiz module**: Uses `SINGLE_TABLE` inheritance to model different question types — keep this in mind when adding new question types or querying quiz entities.
- **Sync consistency**: When adding new syncable entities, make sure they expose an `updatedAt` field and are covered by a corresponding `findByUpdatedAtAfter` query and sync endpoint.

## License

_Add license information here._
