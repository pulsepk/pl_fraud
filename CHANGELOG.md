# Changelog

## [2026-10-07] - Startup event registration

### Fixed
- `onResourceStart` is now a plain server event handler instead of a registered net event, so clients can no longer re-run the item registration / dependency check at will.
