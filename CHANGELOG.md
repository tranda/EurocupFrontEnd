# Changelog

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

