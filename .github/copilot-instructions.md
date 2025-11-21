# Copilot Instructions for Salon Management App

## Project Overview
Flutter-based salon management application supporting web, iOS, Android, macOS, Linux, and Windows. The app handles appointment booking, POS (point-of-sale), check-in/out workflows with a REST API backend.

## Architecture & Data Flow

### State Management
- **Provider pattern** (`provider: ^6.0.5`) for global state
- `BookingProvider` (`lib/provider/booking.provider.dart`) manages booking workflow state across multiple screens
- Current user stored in `MyAppState.currentUser` (static field) and `SharedPreferences`
- Provider usage: Access via `Provider.of<BookingProvider>(context, listen: false)` for updates

### Navigation Pattern
- Named routes defined in `lib/main.dart` routes table: `/`, `/dashboard`, `/booking`, `/pos`, `/login`, etc.
- Mix of `Navigator.pushReplacementNamed(context, '/route')` and direct `MaterialPageRoute` pushes
- Auth flow: `CustomerLoginPage` → `AuthChecker` (validates token) → `Dashboard` or `Login`

### API Integration
- `lib/api/api_manager.dart` exposes `apiManager` singleton (currently `MyHttp()`)
- Pluggable architecture: swap `LocalData()`, `CustomBackend()`, or `FireStoreUtils()` by changing `apiManager` declaration
- All API endpoints in `lib/config/app_config.dart` with `api_url` base pointing to `http://83.136.248.80:8080`
- Bearer token auth: Retrieved from `SharedPreferences` and added to headers in `fetchFromServer()`
- Error handling: 401 responses throw session expiry messages

**Customer token flow (Guest bookings)**:
- After booking, backend returns `{ token, bookingkey, customerkey }` (model: `BookingResponse`)
- Token stored in `SharedPreferences` as `customer_token`
- Use token to call:
  - `/api/booking/customer/profile` via `fetchCustomerProfile()`
  - `/api/booking/customer/bookings` via `fetchCustomerBookings()`
- Both methods automatically retrieve token from SharedPreferences and use Bearer auth

### Booking Workflow
Multi-step wizard stored in `BookingProvider.onbooking`:
1. Staff selection (`ui/booking/staff.dart`) → `setStaff()`
2. Calendar/schedule (`ui/booking/calendar.dart`) → `setSchedule()` using `booking_calendar` package
3. Customer login/selection (`ui/booking/customer_login.dart`) → authenticates or creates customer
4. Service selection (`ui/booking/service.dart`) → `setService()`
5. Customer details (`ui/booking/customer.dart`) → `setCustomerDetails()`
6. Summary & save (`ui/booking/summary.dart`) → `apiManager.SaveBooking()`

**Edit mode behavior**: `editMode` flag in `BookingProvider` skips calendar step when modifying existing bookings. Set via `setEditMode(true)` when entering summary from booking list.

**Availability checking**: `fetchAvailability()` returns time slots with `slot_time`, `available` boolean, and `available_staffs` array. Response can be List or Map with 'slots' key.

### Data Models
- Models in `lib/model/`: `User`, `Booking`, `Staff`, `Service`, `Customer`
- All use `fromJson()` factories and `toJson()` methods
- `Booking.bookingstart` parsed as `DateTime`, formatted as `yyyy-MM-dd HH:mm` for display

### POS, Check-in/Check-out Features
- **Current state**: Placeholder screens only (`SaleScreen`, `CheckInScreen`, `CheckOutScreen`)
- Defined in routes but contain minimal "Screen" text placeholders
- `SaleScreen` in `lib/ui/pos/home.dart`
- Check-in/Check-out widgets in `lib/ui/dashboard.dart`
- No API endpoints or business logic implemented yet

## Development Conventions

### Localization
- `easy_localization: ^3.0.5` with JSON files in `assets/translations/` (`en.json`, `vn.json`)
- Use `.tr()` extension on strings: `const Text('signIn').tr()`
- Supported locales: `en`, `vn`

### UI Patterns
- Color scheme: `COLOR_PRIMARY = 0xFF3E66C5` in `lib/constants.dart`
- AppBar default: Blue background, white text/icons
- Image handling: `getImage(base64String)` helper in `lib/services/helper.dart` decodes base64 or returns `AssetImage('assets/default_avatar.png')`
- Drawers: `AppDrawerDashboard`, `AppDrawerBooking` in `lib/ui/common/`

### Code Style
- Print statements for debugging (not debugPrint) are common throughout
- Field validation helpers in `lib/services/helper.dart`: `validateFeild()`, `validateEmail()`, etc.
- Forms use `AutovalidateMode` and `GlobalKey<FormState>`

## Critical Commands

```bash
# Run on web
flutter run -d chrome

# Run on specific platform
flutter run -d macos
flutter run -d ios

# Build for web
flutter build web

# Get dependencies
flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze

# Check for outdated packages
flutter pub outdated
```

## Key Files Reference
- **Entry point**: `lib/main.dart` (initializes localization, provider, routes)
- **API config**: `lib/config/app_config.dart` (change API base URL here)
- **Constants**: `lib/constants.dart` (colors, API keys)
- **Booking flow**: `lib/provider/booking.provider.dart`, `lib/ui/booking/*`
- **Auth logic**: `MyAppState._getUserInfo()`, `AuthChecker._checkToken()`
- **HTTP client**: `lib/api/http/http.dart` (handles token refresh, error responses)

## Common Patterns

**Adding a new screen to booking flow:**
1. Create widget in `lib/ui/booking/`
2. Update `BookingProvider` with new setter method
3. Call setter in screen's `onTap`/`onPressed`
4. Navigate to next step with `Navigator.push(context, MaterialPageRoute(...))`

**Adding API endpoint:**
1. Add constant to `AppConfig` (e.g., `api_url_new_endpoint`)
2. Create method in `MyHttp` class calling `fetchFromServer()`
3. Map response to model with `Model.fromJson()`
4. Expose via `apiManager` in UI layer

**Using booking_calendar package:**
- `BookingService` wraps appointment slots with `bookingStart`, `bookingEnd`, `serviceDuration`
- `uploadBookingMock()` triggered on slot selection, updates `BookingProvider` and navigates
- `convertStreamResultMock()` transforms availability data into `DateTimeRange` list for blocked slots
- Availability slots with `available: false` are marked as busy/unavailable

**Testing with different backends:**
Change line in `lib/api/api_manager.dart`:
```dart
var apiManager = MyHttp(); // or LocalData(), CustomBackend()
```
