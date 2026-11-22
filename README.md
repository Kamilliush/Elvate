# Elvate

Elvate is a native iOS app for planning strength workouts, logging training sessions and tracking body measurements. It was built in Swift and SwiftUI as my engineering thesis project, with Firebase as the backend.

## Features

- **Accounts** – sign up and sign in with email and password or with Google; password reset by email; change of email (with verification link) and password; account deletion.
- **Exercise library** – 873 exercises bundled locally as JSON, with search by name and filtering by primary muscle group.
- **Custom routines** – build a routine from selected exercises, set reps and weight for each set, rest time and an icon; edit or delete it later.
- **Workout mode** – workout stopwatch, check off sets, automatic rest countdown after each set, and resume an interrupted workout after the app is closed.
- **Workout summary and history** – duration, sets, reps, total volume (reps × weight) and heaviest lift; finished workouts are saved and can be reviewed or deleted.
- **Body measurements** – height, weight, waist, biceps, thigh and chest, with history, line charts and date ranges (week, month, year, all, custom).
- **Profile** – editable display name, weight trend chart and list of completed workouts.

## Tech stack

| Area | Technology |
| --- | --- |
| Language and UI | Swift 5, SwiftUI, Swift Charts |
| Architecture | MVVM (`ObservableObject` view models) with a manager layer for data access |
| Concurrency | async/await, `Task` |
| Authentication | Firebase Auth, Google Sign-In |
| Database | Cloud Firestore |
| Local storage | Bundled `exercises.json`, `UserDefaults` for the workout in progress |
| Dependencies | Swift Package Manager |
| Minimum iOS | 26.0 |

## Architecture

```
SwiftUI views
   └── ViewModels / RoutineStore (shared state via @EnvironmentObject)
         ├── AuthenticationManager, SignInGoogleHelper  → Firebase Auth
         ├── UserManager, RoutineManager,
         │   CompletedWorkoutsManager, MeasurementsManager → Cloud Firestore
         └── LocalExerciseService, WorkoutInProgressStore → exercises.json, UserDefaults
```

All user data in Firestore lives under the user's own document:

```
users/{userId}
├── routines/{routineId}
├── completedWorkouts/{workoutId}
└── measurements/{metricId}/entries/{entryId}
```

## Project structure

```
Elvate/
├── ElvateApp.swift          # App entry point, Firebase configuration
├── RootView.swift           # Tab bar and sign-in gate
├── Core/
│   ├── Authentication/      # Email and Google sign-in
│   ├── Workout/             # Exercises, routines, workout mode, history
│   ├── Profile/             # Profile, measurements, charts
│   └── Settings/            # Account settings
├── Firestore/               # User profile model and manager
├── Utilities/
└── Resources/               # exercises.json, assets, Firebase config
```

## Running the project

1. Clone the repository and open `Elvate.xcodeproj` in Xcode with the iOS 26 SDK.
2. Wait for Swift Package Manager to resolve the Firebase and Google Sign-In packages.
3. The app reads its Firebase configuration from `Elvate/Resources/GoogleService-Info.plist`. To use your own backend, create a Firebase project, enable Email/Password and Google sign-in, create a Firestore database and replace that file with your own.
4. Build and run on a simulator or a device.

## Author

Kamil Jakut – engineering thesis project, 2025.
