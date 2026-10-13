# KMFRI Clocking

A native Flutter client for KMFRI account sign-in, secure mobile-device
enrollment, and access to the existing KMFRI clocking portal.

## Architecture

Application features are organized under `lib/features/`:

- `connectivity/` checks the KMFRI endpoint and exposes online/offline state.
- `authentication/` integrates the existing staff and intern sign-in routes,
  persists the backend session cookie in secure storage, binds a random app
  installation ID to the authenticated account, and gates returning sessions
  with local device authentication.
- The app requires location permission and enabled device location services
  before continuing. If location is disabled, it opens a blocking prompt and
  rechecks after location changes and when returning from device settings.
- `clocking/` captures location-validated clock-in/out events, persists them in
  secure storage, and retries pending synchronization when connectivity returns.

Each feature keeps its Cubit, repository, service, and model in separate
subfolders where applicable. Screens are presentation-only; Cubits manage
feature state, repositories provide the app-facing data API, and services
integrate with platform or network APIs.

## Backend integration

The mobile client uses the existing session-based routes:

- `POST /auth/signin-staff` with `userId`, `password`, and `installationId`.
- `POST /auth/signin` with `email`, `password`, and `installationId`.
- `GET /valid` to validate a saved online session.
- `POST /mobile-app/device/status`, `/verify`, and `/enroll`.
- `POST /mobile-app/attendance/context` for assigned station and attendance
  state.
- `POST /mobile-app/attendance/sync` for online or queued clocking events.

The backend stores mobile registrations in the separate `MobileApp` collection.
It enforces one active mobile installation per account and globally unique
installation IDs. An authorized administrator can revoke an active record via
`POST /mobile-app/device/:deviceId/revoke` with a reason; self-service
replacement is not exposed. Attendance synchronization checks the registered
device and session, reuses the existing attendance writer/policy, validates the
configured station geofence on the server, and stores unique mobile event IDs
on attendance records so retries cannot create duplicate clock-ins or
clock-outs. Offline events can synchronize regardless of age; invalid or
timestamps more than five minutes ahead of server time are rejected to allow
minor device/server clock skew. The server records the original event time
rather than replacing it with the synchronization time.

The mobile app stores no password. The session cookie, minimum user profile,
device ID, and installation ID are stored using secure storage. Returning
offline access requires that a session and enrolled device were previously
saved and that local authentication succeeds.

Offline events remain stored until the backend confirms them. Location,
geofence, account status, attendance action, device ownership, and configured
holidays are checked again by the server during synchronization. Rejected
events remain on-device and block subsequent clock actions until they are
reviewed.

## Run

```sh
flutter pub get
flutter run
```
