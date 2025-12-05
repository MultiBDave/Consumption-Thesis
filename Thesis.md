# Project: Consumption Meter — Thesis Documentation

## Overview
This document describes the important screens (pages), models and helper functions present in the Flutter project located in the repository. The goal is to explain what each page displays, what the user can do on that page, and how the underlying functions (especially Firestore helpers and reminder/service processing) behave. This is written for a human reader (thesis or report usage) to understand the program architecture, the user flows and the core implementation decisions.

## Table of Contents
- High-Level Architecture
- Pages / Screens
  - `LoginScreen` (lib/auth_screens/login_screen.dart)
  - `HomePage` (lib/home_page.dart)
  - `MyEntries` (lib/inner_screens/my_entries.dart)
  - `ListCars` (lib/inner_screens/list_cars.dart)
  - `CarDetailsScreen` (lib/inner_screens/car_details.dart)
  - `CarFuelEntriesScreen` (lib/inner_screens/car_fuel_entries_screen.dart)
  - `CarCostsScreen` (lib/inner_screens/car_costs_screen.dart)
  - `AddCarForm` (lib/inner_screens/forms/add_car_form.dart)
- Models
  - `CarEntry`, `FuelEntry`, `ServiceItem`, `Reminder`, `ExtraCost`
- Helpers and Services
  - `helper/firebase.dart` — Firestore CRUD and higher-level helpers
  - `helper/date_utils.dart` — month arithmetic helper (addMonths)
  - `helper/flutter_flow/flutter_flow_calendar.dart` — calendar widget wrapper and visuals
- Reminders, Snoozing and Services logic
- Detailed function descriptions (selected)
- User interactions and flows
- Notes, limitations, and suggested improvements

---

## High-Level Architecture
- The app is a Flutter mobile/web project that uses Firebase (Auth and Cloud Firestore) as the backend.
- Data models are persisted as documents in collections: `CarEntrys`, `FuelEntries`, `Services`, `Reminders`, `ExtraCosts`.
- The UI is composed of multiple screens (pages) that let the user manage cars, record fuel entries, maintain services and reminders, and view a calendar with events.
- Important cross-cutting utilities:
  - `helper/firebase.dart`: central place for Firestore operations (CRUD for cars, fuels, services, reminders etc.).
  - `helper/date_utils.dart`: provides reliable calendar-month arithmetic (useful for "add X months" semantics versus approximating months as 30 days).
  - Calendar widget enhancements live in `helper/flutter_flow/flutter_flow_calendar.dart` to show day outlines and to accept an event map.

## Pages / Screens

### `LoginScreen` (lib/auth_screens/login_screen.dart)
- Purpose: Allow the user to sign in with Firebase Auth; provides password reset.
- What you see:
  - Email and password inputs.
  - A login button and a "Forgot password?" action.
  - A top image and title for the login screen.
- What it does:
  - On successful login, the code gathers reminders for the signed-in user and identifies overdue service reminders (title begins with "Service due").
  - If overdue reminders exist, it prepares them and navigates to `HomePage`, passing the overdue reminders for display.
  - If login fails, it shows an alert (using `signUpAlert`) describing the error.

### `HomePage` (lib/home_page.dart)
- Purpose: Main app container that hosts the bottom navigation (persistent tabs) and optionally shows an overdue-reminder dialog after navigation into the app.
- What you see:
  - Bottom navigation with two tabs: `Search` (ListCars) and `My Entries` (MyEntries).
- What it does:
  - Accepts `overdueReminders` when created (coming from the login flow).
  - If `overdueReminders` is present, it immediately shows a dialog listing each reminder, its date and car, with per-item "snooze (Later)" and "Undo" actions and a bulk "Later" action.
  - Per-item snooze stores `previousDate` (the original date) and `snoozedUntil` (the snooze target) and updates Firestore.
  - Undo restores the `previousDate` and clears `snoozedUntil`, persisting changes.
  - Bulk 'Later' snoozes all listed reminders and stores previousDate for each.
- Why this is done in `HomePage`: performing the dialog display in `HomePage` after navigation avoids BuildContext-after-await problems and keeps the login flow simpler (login passes structured Reminders and HomePage handles UI display).

### `MyEntries` (lib/inner_screens/my_entries.dart)
- Purpose: List of user-owned cars and quick actions for each car (view details, add fuel, edit, delete, open calendar).
- What you see:
  - An AppBar titled "My vehicles" with a calendar icon that opens a calendar dialog, and a badge showing today's reminder count.
  - A list of cards, each representing a `CarEntry` the current user owns.
  - Each car card shows: make & model & year, color indicator, driven km, consumption, estimated range, and action buttons for "Add fuel", "Details", "Add entry", "Edit", and "Delete".
  - A floating action button to add a new vehicle.
- What it does:
  - Loads the logged-in user's cars from Firestore (`fb.loadCarEntrysFromFirestore()`) and filters them by ownerUsername == current user email.
  - On "Add fuel" it opens a dialog to add a fuel entry and uses `fb.addFuelEntryToDb`/`fb.updateFuelEntry` as needed.
  - On "Details" it navigates into `CarDetailsScreen` for that car.
  - The calendar button loads reminders for the user and shows an event-aware calendar (the app calendar shows day outlines for dates that have events).
  - The top-right lock icon toggles login state — sign out clears local car lists and returns to `HomePage` (root navigator).

### `ListCars` (lib/inner_screens/list_cars.dart)
- Purpose: Public search/browse page to see all cars (not only user-owned) with various filters.
- What you see:
  - AppBar titled "Vehicle search" with a filter button.
  - Filters for make, model, year range, km range, color, and type.
  - A list showing all cars (or filtered subset).
- What it does:
  - Loads `CarEntrys` from Firestore and exposes client-side filtering and resetting of filters.
  - The results are navigable and tapping on a car opens a detail screen via `CarDetailsScreen`.

### `CarDetailsScreen` (lib/inner_screens/car_details.dart)
- Purpose: Show detailed information for a specific car, manage service intervals, images, descriptions, and owner-only actions.
- What you see:
  - A header card with car summary (avatar, make/model, year, color, type, active toggle if owner).
  - Cost breakdown and charts (fuel vs maintenance), if data exists.
  - Image area (with caption) and description text.
  - Owners-only "Service & maintenance" section listing per-service rows (name, Next due date if computable, last km, interval km, interval months).
- What it does:
  - Loads image/description and lists of `ExtraCost`, `FuelEntry`, and `ServiceItem` records for the car.
  - Ensures default service items exist (adds defaults if missing).
  - For owners: toggles `active` status — enabling creates a monthly tyre-pressure reminder (if not existing), disabling removes tyre reminders.
  - Allows setting a last service date or odometer for each service and saving changes; saving a service with a date+months interval creates or updates a date-based `Reminder` (title `Service due: <name>`), computing next due using `addMonths()`.

### `CarFuelEntriesScreen` (lib/inner_screens/car_fuel_entries_screen.dart)
- Purpose: Show the fuel log for a single car; add, edit, and delete fuel entries.
- What you see:
  - A header showing the car make/model and a summary of consumption, total fuel, cost, range.
  - A list of fuel entries (date, liters, odometer, cost), with options to delete or edit each.
  - A floating action button to add a fuel entry.
- What it does:
  - Loads `FuelEntry` documents for the car via `fb.loadFuelEntriesForCar`.
  - On adding or saving a fuel entry the screen updates the car's consumption and driven km and persists the car via `fb.modifyCarEntryInDb`.
  - After odometer update, checks `Services` for km-based intervals: if drivenKm >= lastKm + intervalKm, it creates a `Reminder` with title `Service due: <name>` (unless one already exists).

### `CarCostsScreen` (lib/inner_screens/car_costs_screen.dart)
- Purpose: Show cost breakdown for a car (fuel costs and extra costs) with charts.
- What you see:
  - Pie charts for combined costs and by-category breakdown.
  - Lists of fuel entries and extra costs.
- What it does:
  - Loads `FuelEntry` and `ExtraCost` for the car and computes totals.
  - Provides dialogs to add/edit extra costs.

### `AddCarForm` (lib/inner_screens/forms/add_car_form.dart)
- Purpose: Screen/dialog for adding or editing a car record.
- What you see:
  - Inputs for year, make, model, color, type, initial km, tank size, and owner information.
- What it does:
  - Allows the user to create or modify a `CarEntry`. On save the form will call the relevant helper to persist the car into Firestore.

## Models (brief)
- `CarEntry`:
  - Fields: id, make, model, year, color, ownerUsername, drivenKm, lastServiceOdometer, lastServiceDate, serviceIntervalKm, serviceIntervalMonths, fuelSum, initialKm, tankSize, active, imageUrl, description.
  - Methods to refresh consumption and compute estimated range are present in the model.
- `FuelEntry`:
  - Fields: id, carId, fuelAmount, odometer, date, cost.
- `ServiceItem`:
  - Fields: id, carId, name, lastKm, lastDate, intervalKm, intervalMonths, ownerUsername.
  - Used to represent per-car services like oil change, tyre rotation, etc.
- `Reminder`:
  - Fields: id, carId (optional), title, description, date, ownerUsername, snoozedUntil (optional), previousDate (optional).
  - `snoozedUntil`: when set, marks a snooze target used by the "Later" action. `previousDate` stores the pre-snooze date to enable Undo.
- `ExtraCost`:
  - Fields: id, carId, amount, date, category, description.

## Helpers and key functions
All helper functions below are in `lib/helper/firebase.dart` unless noted otherwise.

- `addDocumentToCollection(collectionName, data)`
  - Generic helper to add a new document to a collection.
- `getDocumentID(id, collection)`
  - Query helper used to find the Firestore document id where a numeric `id` field equals the given id. Returns empty string if not found.
- Car CRUD:
  - `addCarEntryToDb(carEntry)`, `updateCarEntry(carEntry, documentID)`, `modifyCarEntryInDb(carEntry)` — add or update a CarEntrys document.
  - `loadCarEntrysFromFirestore()` — returns all car documents as `CarEntry` objects.
- Fuel entries:
  - `addFuelEntryToDb(fuelEntry)`, `updateFuelEntry(fuelEntry)`, `loadFuelEntriesForCar(carId)` — manage fuel entry documents.
- Services CRUD:
  - `addServiceToDb`, `updateServiceInDb`, `removeServiceFromDb`, `loadServicesForCar` — store per-car `ServiceItem` records.
- Reminders CRUD:
  - `addReminderToDb`, `updateReminderInDb`, `removeReminderFromDb`, `loadRemindersForUser`, `loadRemindersMapForUser`.
  - Special behavior in `updateReminderInDb`: If a reminder's `date` is moved back into the past, helper clears `snoozedUntil` and `previousDate` so it will be considered overdue again on next login.
- Tyre pressure helpers:
  - `addTyrePressureReminderForCar(carId, ownerUsername)` — schedules a monthly tyre pressure check using `addMonths(now, 1)`.
  - `removeTyrePressureRemindersForCar(carId, ownerUsername)` — finds and removes tyre-pressure reminders for the car.
- Miscellaneous:
  - `calculateConsumptionFromEntries(carId, initialKm)` — computes consumption L/100km based on fuel entries and initial km.

## Calendar & event integration (lib/helper/flutter_flow/flutter_flow_calendar.dart)
- Calendar accepts a `Map<DateTime, List<dynamic>>? events` and builds a fast integer-keyed cache (YYYYMMDD) for event lookup.
- `TableCalendar` is used with custom builders to draw an outer ring (outline) for days with events so users can see which days have events before selecting them.
- `rowHeight` can be set to avoid overflow inside dialogs. The widget's `eventLoader` uses the events cache for efficient lookups.

## Reminders, Snoozing, Services logic (behavioral summary)
- A reminder for a service has title `Service due: <service name>` and normally has a `date` computed from `lastDate + intervalMonths` or is created immediately when a km threshold is hit.
- Snooze flow:
  - The overdue dialog shows reminders on login. Each reminder row has a "snooze" (clock) icon that sets `date` and `snoozedUntil` to 7 days from today and stores `previousDate` (the pre-snooze date) so Undo is possible.
  - If the user presses "Later" for all reminders, the same operation is applied in bulk.
  - Undo: restores `date` from `previousDate` and clears `snoozedUntil` and `previousDate`.
- Login-time overdue detection: `LoginScreen` loads reminders for the user and filters those whose `title` starts with "Service due" and whose `date` is on or before today. Those are passed to `HomePage` which displays the dialog.
- When a service's date is moved back into the past (either via editing by the owner or by user action), `updateReminderInDb` clears any `snoozedUntil` and `previousDate` so the reminder will appear as overdue at the next login.

## Detailed function examples and rationale
- addMonths(date, months) — rationale:
  - Adding months must follow calendar semantics, i.e., adding 1 month to January 31 should result in February 28 (or 29), not March 2 (which would happen if months were approximated by 30-day durations).
  - The app uses a central helper `addMonths()` to compute next due dates reliably for service intervals measured in months.

- Creating a Service reminder by km threshold in `CarFuelEntriesScreen`:
  - When fuel entries update a car's `drivenKm`, the code fetches all `ServiceItem` entries for that car and checks `if (drivenKm >= lastKm + intervalKm)` — if true and no existing `Service due: <name>` reminder exists, a new Reminder with `date = now` is created and added. This ensures the app surfaces due service items based on actual odometer activity.

- UI safety (BuildContext after async):
  - The code uses patterns such as capturing `Navigator.of(context)` or `ScaffoldMessenger` into local variables prior to awaiting async calls, and checks `if (!mounted) return;` after awaits. This avoids `use_build_context_synchronously` problems in Flutter.

## User interactions and flows (example)
- Add a car:
 1. Tap `+` on `MyEntries` to open Add Vehicle dialog.
 2. Fill details and save; a `CarEntry` is added to Firestore via `addCarEntryToDb`.
- Add fuel:
 1. From a car card tap the gas icon or open the car and press the add button.
 2. Provide liters/odometer/cost and Save. The app appends a `FuelEntry`, updates car consumption via `calculateConsumptionFromEntries`, and may create km-based service reminders.
- Service maintenance update:
 1. Owner opens `CarDetails`, adjusts `lastDate`/`lastKm` for a `ServiceItem`, and taps Save.
 2. If `lastDate` + `intervalMonths` exists, the code computes next date via `addMonths()` and creates/updates a `Reminder` with title `Service due: <name>`.
- Receiving overdue reminders on login:
 1. User signs in on `LoginScreen`.
 2. The login flow queries reminders for the user and finds overdue `Service due` reminders.
 3. `HomePage` shows them in a dialog with per-item snooze and undo.

## Notes, limitations and suggestions
- Undo semantics: current implementation stores one `previousDate` (pre-snooze). If repeated snoozes are allowed and you want multi-step undo, store a history stack or always set `previousDate` to the immediate pre-snooze date rather than only the earliest one. The present implementation stores the first pre-snooze date (good for single-level Undo) but may be modified to track the immediate prior date instead.
- Time zones and times: reminders are stored as `Timestamp`s (Firestore) but the UI often displays only the date. If the app needs to handle time-of-day for reminders (e.g., morning vs evening) more precisely, consider normalizing to UTC or storing an explicit time field.
- Calendar event cache: the calendar caches events keyed by YYYYMMDD integers to avoid excessive DateTime allocations during month navigation, which improves performance.
- Calendar visuals: table_calendar markers were disabled in favor of an outer ring outline so days with events are visible without small dot markers.
- Error handling: many database helpers assume the document with a given numeric `id` exists or will be created. Consider centralizing id assignment and index usage to avoid collisions.

## Where to look for specific code
- Firestore helpers and the bulk of data model persistence: `lib/helper/firebase.dart`.
- Overdue reminders dialog & snooze/undo: `lib/home_page.dart` (initial display and per-item actions).
- Login flow and the pass-through of overdue reminders: `lib/auth_screens/login_screen.dart`.
- Calendar implementation: `lib/helper/flutter_flow/flutter_flow_calendar.dart`.
- Service and reminders logic around date arithmetic: `lib/helper/date_utils.dart` and `lib/inner_screens/car_details.dart` (where next due dates are computed) and `lib/inner_screens/car_fuel_entries_screen.dart` (where km-based reminders are created).

## Closing notes
This document is intended to be a thorough, human-readable explanation of the core screens, functions, and behaviors in this app. It focuses on user-visible behavior (what users see and do) and on the helpers and models that make those behaviors possible. If desired, I can also produce a UML-style mapping of models and relationships, an ER-like summary of Firestore collection structures, or a dedicated section describing each helper function line-by-line for deeper technical documentation.

---

## Fill-In Checklist (what you should fill in / provide)

Use this checklist to finalize the thesis documentation. The entries below list exact fields, examples and placeholders you should fill in. Put real values or paths where indicated (replace text in square brackets).

- Project summary:
  - **Project Title:** [e.g. "Consumption Meter"]
  - **Author / Student Name:** [Your full name]
  - **Supervisor:** [Supervisor name]
  - **Repository Path / Branch:** `g:\THESIS\Consumption-Thesis`, branch: `[branch name]`

- Screenshots and visuals:
  - Add a screenshot for each screen listed below. Place PNG images in `docs/screenshots/` and reference them here (e.g., `docs/screenshots/login.png`).
  - Required screenshots: `login`, `home`, `my_entries`, `list_cars`, `car_details`, `add_fuel`, `calendar_overview`, `overdue_dialog`.
  - Replace placeholder tags in this file with `![Alt text](docs/screenshots/<name>.png)` or note the file path and date taken.

- Per-screen details (for each screen, fill these exact items):
  - `Screen name` (as title)
  - Purpose: a one-sentence statement.
  - Main UI elements: (list exact widgets/buttons/inputs by name). Example: `Email input`, `Password input`, `Login button`.
  - Key routes: e.g., `'/login' -> HomePage` or navigation via `Navigator.pushNamed(context, '/carDetails')`.
  - Firestore collections read: list collection names (e.g., `CarEntrys`, `Reminders`).
  - Firestore collections written: list collection names and actions (e.g., `add FuelEntry to FuelEntries`).
  - Acceptance criteria / tests: 2–3 short bullet points stating how you will verify behavior (e.g., "Adding a fuel entry increases FuelEntries count and updates car consumption").

- Model & schema (exact field names and types). Copy/paste these into your thesis code appendix or Firestore rules.
  - CarEntry (document fields):
    - `id` : string (document id or custom id)
    - `make` : string
    - `model` : string
    - `year` : int
    - `color` : string
    - `ownerUsername` : string (owner email)
    - `drivenKm` : double / number
    - `active` : boolean
    - `tankSize` : double
    - `fuelSum` : double
    - `imageUrl` : string (URL)
    - `description` : string

  - FuelEntry (document fields):
    - `id` : string
    - `carId` : string (FK -> CarEntry.id)
    - `date` : Timestamp / datetime
    - `liters` : double
    - `odometer` : int
    - `cost` : double

  - ServiceItem (document fields):
    - `id` : string
    - `carId` : string
    - `name` : string (e.g., "Oil change")
    - `lastKm` : int
    - `lastDate` : Timestamp / datetime
    - `intervalKm` : int
    - `intervalMonths` : int

  - Reminder (document fields):
    - `id` : string
    - `carId` : string (nullable)
    - `title` : string
    - `description` : string (optional)
    - `date` : Timestamp / datetime
    - `snoozedUntil` : Timestamp / datetime (nullable)
    - `previousDate` : Timestamp / datetime (nullable) — store pre-snooze date
    - `ownerUsername` : string

  - ExtraCost (document fields):
    - `id` : string
    - `carId` : string
    - `amount` : double
    - `date` : Timestamp / datetime
    - `category` : string
    - `description` : string

- Exact config values to document and where to set them (fill with your chosen values):
  - Default snooze duration (days): `[7]` — used when the user taps "Later"
  - Tyre reminder recurrence: `[1 month]` (specify months)
  - Calendar `rowHeight` used in dialogs: `[e.g. 52]`
  - Any hardcoded strings that must be localized: list keys and text (e.g., `"Service due: %s"`).

- Reminders section (fill-in fields):
  - How overdue is defined: `date <= today` (confirm local timezone handling)
  - Reminder title prefix for services: `Service due:` (exact string used in code)
  - Undo semantics: `previousDate` stores original date (confirm whether you want multi-step undo)

- Firestore security and indexes (fill exact values):
  - Rules file path: `firestore.rules` (review owner checks and write permissions)
  - Indexes: list any composite indexes required for queries (see `firestore.indexes.json`).

- Thesis appendix checklist (what to include in appendix):
  - Full model field listing (as above) and example documents (JSON) for each collection.
  - Example reminder document before/after snooze.
  - Screenshots with captions (where user performed each action).
  - PlantUML source files and rendered SVGs found in `UML.puml`, `ER.puml`, and `docs/`.


## Suggested text snippets to customize in the app (place these in the thesis as exact copy)
- Welcome screen heading: `[Welcome to Consumption Meter]`
- Overdue reminder dialog title: `[You have overdue services]`
- Snooze button label: `[Later]` — default snooze: `[7 days]`


## Where to add the missing screenshot files and example JSONs
- Create directory: `docs/screenshots/` and add named PNGs.
- Create directory: `docs/examples/` and add example JSON files named after collections: `CarEntry_example.json`, `FuelEntry_example.json`, `Reminder_example.json`.


## Quick sample example to paste into `docs/examples/Reminder_example.json`
```
{
  "id": "r_abc123",
  "carId": "c_abc123",
  "title": "Service due: Oil change",
  "description": "Next scheduled oil change",
  "date": "2025-12-01T00:00:00Z",
  "snoozedUntil": null,
  "previousDate": null,
  "ownerUsername": "owner@example.com"
}
```

## Final instructions
- After you fill in screenshots and example JSONs, tell me and I will:
  - Embed the images into `Thesis.TXT` or create a formatted `Thesis.md` with images.
  - Generate a short appendix with code excerpts and example Firestore documents.

---

*Generated from `Thesis.TXT` — converted to Markdown.*
