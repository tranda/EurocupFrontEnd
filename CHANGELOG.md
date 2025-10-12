# Changelog

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

