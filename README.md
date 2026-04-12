# MFL ELmanana - Coaching Management Ecosystem

MFL ELmanana is a robust, role-based coaching management solution designed to streamline educational operations. The platform bridges the gap between administrators, tutors, students, and staff through a unified digital interface.

## 🚀 Key Features
*   **Role-Based Access Control**: Tailored experiences for Admin, Tutor, Student, and Staff roles.
*   **Smart Attendance System**: Geofenced attendance marking for precision and accountability.
*   **Digital Resource Library**: Centralized repository for PDFs, notes, and educational content.
*   **Batch & Schedule Management**: Effortless organization of student groups and academic sessions.
*   **Profile Personalization**: Real-time synchronization of profile photos and personal data.

## 🛠️ Tech Stack
*   **Frontend**: Flutter (Cross-platform optimized)
*   **Backend**: Supabase (Auth, PostgreSQL, Storage)
*   **State Management**: Riverpod
*   **Navigation**: GoRouter (Role-based secure routing)

## Setup

### 1. Supabase
1. Create project at https://supabase.com
2. Go to **SQL Editor** → paste & run `supabase_schema.sql`
3. Go to **Storage** → create a bucket named `content` (Private)
4. Copy your **Project URL** and **anon key**

### 2. Flutter
1. Open `lib/core/constants/app_constants.dart`
2. Replace:
   ```dart
   static const supabaseUrl     = 'https://YOUR_PROJECT_ID.supabase.co';
   static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

### 3. Install dependencies
```bash
flutter pub get
```

### 4. Run
```bash
# Android
flutter run

# Web (Chrome)
flutter run -d chrome

# Web (release)
flutter build web
```

### 5. Create first admin user
1. Go to Supabase → **Authentication → Users → Add user**
2. Run this SQL (replace values):
```sql
INSERT INTO institutes (name, slug)
  VALUES ('My Institute', 'my-institute')
  RETURNING id;

-- Use the returned id:
INSERT INTO users (id, name, email, role, institute_id)
  VALUES ('<auth-uid>', 'Admin Name', 'admin@email.com', 'admin', '<institute-id>');
```

## Project Structure
```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── constants/app_constants.dart   # Supabase keys + table names
│   ├── services/supabase_service.dart # Supabase client accessor
│   └── theme/app_theme.dart           # Light + dark theme
├── features/
│   ├── auth/
│   │   ├── providers/auth_provider.dart  # Login / logout / session
│   │   └── screens/
│   │       ├── splash_screen.dart
│   │       └── login_screen.dart
│   ├── admin/screens/admin_dashboard.dart
│   ├── tutor/screens/tutor_dashboard.dart
│   └── student/screens/student_dashboard.dart
├── models/
│   ├── user_model.dart
│   ├── batch_model.dart
│   ├── student_model.dart
│   └── attendance_model.dart
├── router/app_router.dart             # GoRouter + role-based redirects
└── widgets/common_widgets.dart        # Reusable UI components
```

## Current Progress
- [x] **Phase 1** — Auth, schema, role-based navigation
- [x] **Phase 2** — Batch & student management
- [x] **Phase 3** — Attendance & Geofencing system
- [x] **Phase 4** — Digital Content library & Announcements
- [ ] **Phase 5** — Final UI Polish & Submission
