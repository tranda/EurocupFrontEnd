# Changelog

## [0.6.6] - 2025-10-13

### Added
- Event availability filtering system
  - Added 'available' flag to events (boolean, default TRUE)
  - Events can be marked as Available/Unavailable in admin event detail form
  - Public views now only show available events by default
  - Admin event list shows all events with visual indicators (teal for available, red for unavailable)
  - Backend /events endpoint accepts 'all' parameter for admin views

### Changed
- Event list view now uses 'allEvents' parameter to fetch all events for admin management
- Event detail form includes Available toggle with descriptive status text

## [0.6.5] - 2025-10-12

### Fixed
- Club detail page initialization error
  - Fixed LateInitializationError causing red error screen on page load
  - Changed from late initialization to nullable with proper null checks
  - Added loading indicator while fetching club data

## [0.6.4] - 2025-10-12

### Changed
- Event sorting improvements across all views
  - Events now sorted by year in descending order (newest first)
  - Applied to event dropdowns in discipline race list and admin discipline list
  - Applied to event list in admin event management
  - Default event selection now consistently selects newest event (not oldest)

## [0.6.3] - 2025-10-12

### Added
- Club management features (Admin only)
  - Create, edit, and delete clubs with active status toggle
  - Club detail page with edit/delete functionality
  - Visual indicators: inactive clubs appear dimmed (50% opacity)
  - Clubs sorted by active status (active first)
  - Admins can view all clubs; regular users see only active clubs

- Team management features (Admin only)
  - Delete teams with validation (prevents deletion if crews exist)
  - Visual indicators: teams from inactive clubs appear dimmed (50% opacity)
  - Teams sorted by club active status (active club teams first)
  - Admins can view all teams; regular users see only teams from active clubs
  - Delete confirmation dialog with darker, more readable text

### Changed
- Enhanced club list view with add button in AppBar (upper right corner)
- Team list view now includes delete button for admins
- Both clubs and teams automatically clean up related records on deletion

### Fixed
- Team deletion now properly handles team_clubs records (auto-deleted with team)

## [0.6.2] - 2025-10-12

### Added
- Country flag emoji and 3-letter code display across all team and club views
  - Added comprehensive country mapping (40+ countries) with flag emojis
  - Supports Cyprus (CYP), UAE (UAE), and Neutral athletes (AIN with white flag)
  - Country badges now show flag emoji + 3-letter ISO code (e.g., 🇷🇸 SRB)

### Changed
- Replaced full country names with compact flag + code format
- Moved country badges before team/club names for better readability
- Applied consistent styling across all views:
  - Race results list and detail views
  - Team list and discipline race lists
  - Club list and ADEL club list
- Enhanced visual hierarchy with country identifier appearing first

## [0.6.1] - 2025-10-11

### Changed
- Left-aligned active filter chips for better visual layout in race results

## [0.6.0] - 2025-10-11

### Added
- Multiselect chip-based filtering system for race results
  - Age group, gender, boat size, distance, and stage filters now support multiple selections
  - OR logic within same filter category, AND logic between different categories
  - Visual filter chips with color coding (blue=age, purple=gender, orange=boat, green=distance, teal=stage)
  - Individual chip removal with automatic filter reapplication
  - Team name and country remain as text search fields

### Changed
- Converted single-select dropdown filters to multi-select FilterChips for better UX
- Active filters now display as removable chips outside the filter dialog

## [0.5.7] - 2025-10-09

### Improved
- Enhanced full-screen race photo viewer zoom capabilities
  - Added configurable min/max zoom scale (0.5x to 4.0x)
  - Improved zoom experience with mouse wheel on desktop
  - Better zoom control for both mobile and desktop platforms

## [0.5.6] - 2025-10-09

### Fixed
- Fixed race photos clickability on web platform
  - Added transparent InkWell overlay to catch taps on WebImage elements
  - Resolved CORS issues by using WebImage (HTML img tags) for thumbnails
  - Race photos are now fully clickable and open full-screen viewer
  - Full-screen viewer supports pinch-to-zoom and pan gestures

### Changed
- Improved race photo display architecture for better web compatibility

## [0.5.5] - 2025-10-09

### Added
- Race photo display functionality in race results
  - Added `images` field to RaceResult model to store array of image filenames
  - Images are fetched from server's racephotos folder
  - Race photos display vertically below race results in both list and detail views
  - Web-compatible image rendering using HTML img tags to avoid CORS issues
  - Full-screen image viewer with pinch-to-zoom capability
  - Loading indicators and error handling for mobile platforms
  - PDF export includes note about number of photos available online

### Changed
- Race results list view now shows race photos when races are expanded
- Race result detail view shows race photos at the bottom after crew results
- Added `racePhotoPrefix` constant in common.dart for photo URL construction

## [0.5.4] - Previous version

