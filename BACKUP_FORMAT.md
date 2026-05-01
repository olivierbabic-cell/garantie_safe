# Garantie Safe Backup Format (.gsbackup)

## Overview
The `.gsbackup` file is a ZIP archive containing the complete application state including database and attachments. This format uses a **single file strategy** for simplicity and reliability.

## Backup Strategy
- **Single managed file**: User selects a specific file location once (not a folder)
- **Placeholder creation**: Initial selection creates a small placeholder file (required on Android/iOS)
- **Always same path**: File picker returns a full path that is persisted
- **Overwrites existing**: Each backup replaces the file at the saved location
- **Platform compatibility**: Uses `saveFile()` with bytes parameter for Android/iOS SAF compatibility
- **Cloud sync**: Works seamlessly when file is saved in synced folders (Google Drive, iCloud)
- **Share support**: Built-in share functionality to send backup file to other apps/devices

## Archive Structure
```
garantie_safe_backup.gsbackup (ZIP file)
├── manifest.json              # Metadata about the backup
├── prefs.json                 # User preferences and settings
├── db/
│   └── garantie_safe.db      # SQLite database file
└── attachments/
    ├── uuid1.jpg             # Attachment file 1
    ├── uuid2.pdf             # Attachment file 2
    └── ...                   # More attachments
```

## Manifest Format
The `manifest.json` file contains:
```json
{
  "createdAt": 1705327822000,      // Unix timestamp (milliseconds)
  "schemaVersion": 4,              // Database schema version
  "appVersion": "1.0.0",           // App version that created backup
  "attachmentsCount": 15,          // Number of attachments included
  "dbFileName": "garantie_safe.db" // Database filename
}
```

## Preferences Format (prefs.json)
The `prefs.json` file contains user settings that should persist across restores:
```json
{
  "onboarding_done": true,           // Onboarding completion status
  "security_type": "device",         // "device" or "none" (PIN removed)
  "payment_methods": ["cash", "credit"], // Selected payment methods
  "backup_enabled": true,            // Auto-backup enabled
  "backup_frequency": "weekly",      // "daily", "weekly", or "monthly"
  "backup_location": "/path/to/folder", // Backup folder path
  "language": "en",                  // App language ("en", "de", or null for system)
  "dark_mode": false                 // Dark mode preference
}
```

**Note**: Custom PIN security has been removed. Users with old backups containing `"security_type": "pin"` will be automatically migrated to `"device"` lock on restore.

## Backup Process

### 1. Creation
- Database is **NOT closed** during backup (read-only operation)
- DB file is read from app documents directory
- Attachments are read from `attachments/` subdirectory
- All files are added to ZIP archive with proper structure
- Manifest is generated with accurate metadata
- Archive is verified before marking success

### 2. Verification
Before marking a backup as successful, the system verifies:
- Archive file exists and is non-empty
- `manifest.json` is present and valid JSON
- `db/garantie_safe.db` exists and is non-empty
- Attachments count matches manifest metadata

### 3. Storage
- User selects backup file location using `FilePicker.saveFile()`
- **Initial selection**: Creates placeholder file with bytes `'GSBACKUP_PLACEHOLDER'` (required on Android/iOS)
- Forced filename: `garantie_safe_backup.gsbackup`
- Full file path is persisted in SharedPreferences
- **Overwrites existing backup** - single file strategy
- First backup attempt uses direct file write, falls back to `saveFile()` with bytes if needed
- Supports both local storage and cloud-synced locations
- Never writes to `/storage/emulated/0/...` directly
- Cloud sync handled by OS (no app-level cloud API)

### 4. Auto-Backup
- Runs on app start/resume when conditions are met
- Checks: enabled flag, dirty flag, frequency (daily/weekly/monthly)
- Writes directly to saved file path using `File.writeAsBytes()`
- Only updates timestamp on successful write
- Fails silently if no location configured or write fails

## Restore Process

### 1. File Selection
- Uses OPEN FILE picker with `.gsbackup` filter
- Supports cloud providers via `withData: true` (bytes mode)
- Handles both filesystem paths and in-memory bytes

### 2. Verification
- Validates archive structure (manifest, db/, attachments/)
- Checks manifest metadata
- Verifies database file integrity

### 3. Database Replacement
**ATOMIC OPERATION:**
1. Close existing database connection
2. Delete old database file
3. Extract and write new database from `db/garantie_safe.db`
4. Reopen database connection
5. Run sanity check (count items)

### 4. Attachments Restoration
1. Delete existing `attachments/` directory
2. Extract all files from `attachments/` in backup
3. Write to new `attachments/` directory

### 5. State Management
- All Riverpod providers are invalidated
- UI state is refreshed
- **Preferences are restored from `prefs.json`**:
  - Onboarding status (prevents re-onboarding)
  - Security settings (device lock or none)
  - Payment methods selection
  - Backup settings (location, frequency, auto-backup enabled)
  - Language and dark mode preferences
- Old custom PIN users are migrated to device lock
- Navigation resets to force full UI reload

## Cloud Storage Compatibility

### Google Drive / iCloud Drive
- File picker returns `bytes` instead of `path` for cloud files
- `BackupService.restoreBackup()` accepts either:
  - `backupFilePath: String` (local filesystem)
  - `backupBytes: List<int>` (cloud/in-memory)
- No temp files created - bytes are processed directly

### Backup Upload
- Backup creates file at user-selected location
- User can select cloud-synced folder (e.g., Google Drive local folder)
- OS handles automatic sync to cloud
- Always overwrites `garantie_safe_backup.gsbackup`
- No app-level cloud API or authentication needed

### Restore Download
- File picker with `withData: true` automatically downloads cloud file
- Bytes are available immediately without manual download
- Works seamlessly across all platforms

## Auto-Backup System

### Frequency Options
- **Daily**: Every 24 hours
- **Weekly**: Every 7 days
- **Monthly**: Every 30 days

### Trigger Conditions
1. Auto-backup is enabled in settings
2. Backup location is configured
3. Data has changed since last backup (dirty flag)
4. Sufficient time has passed based on frequency
5. Debounce: minimum 5 minutes between backups

### Execution
- Runs automatically on app start/resume
- Background operation (non-blocking)
- Overwrites `garantie_safe_backup.gsbackup` at stored location
- Errors are logged but don't block app launch
- Success updates timestamp and clears dirty flag
- **No user dialogs** - fully automatic

## Error Handling

### Backup Errors
- File creation failures show user-friendly message
- Verification failures prevent marking backup as successful
- Timestamp is only updated on verified success
- Temp files are always cleaned up

### Restore Errors
- Picker failures show error with debug details (debug mode only)
- Invalid archive structure shows clear error message
- Database operations are wrapped in try-catch
- Failed restore does not corrupt existing data
- UI state is properly reset on error

## Data Integrity

### Dirty Flag
- Set to `true` when any item/attachment is created/updated/deleted
- Cleared to `false` after successful backup
- Used to determine if backup is needed

### Timestamps
- `backupLastRun`: Unix timestamp (milliseconds) of last successful backup
- `lastRestoreAt`: Unix timestamp (milliseconds) of last successful restore
- Never updated on failure

### Atomic Operations
- Database is closed before replacement
- Files are written with `flush: true`
- Verification happens before marking success
- All-or-nothing restore (no partial states)

## Testing Checklist

### Create Backup
- [ ] Manual backup from settings screen
- [ ] Auto-backup on app start (when conditions met)
- [ ] Backup overwrites existing file
- [ ] Backup with attachments
- [ ] Backup without attachments
- [ ] Verify file named `garantie_safe_backup.gsbackup`
- [ ] Verify file size is non-zero
- [ ] Verify file can be unzipped manually
- [ ] Check manifest.json contents
- [ ] Verify attachmentsCount accuracy
- [ ] Create second backup - should overwrite first

### Restore Backup
- [ ] Restore from local filesystem
- [ ] Restore from Google Drive local folder
- [ ] Restore from iCloud Drive local folder
- [ ] Verify all items restored
- [ ] Verify all attachments restored
- [ ] Check attachment previews work
- [ ] Verify UI refreshes properly
- [ ] Test restore after uninstall/reinstall

### Error Cases
- [ ] Backup with no location selected (show error)
- [ ] Restore with corrupted archive
- [ ] Restore with missing manifest
- [ ] Restore with missing database
- [ ] File picker cancellation
- [ ] File picker error handling
- [ ] Insufficient disk space
- [ ] Permission denied on backup folder

## Design Philosophy

### Single File Strategy
**Why only one backup file?**
- **Simplicity**: No confusion about which backup to restore
- **Predictability**: Always same filename, same location
- **Reliability**: No file management complexity
- **User-friendly**: Just one file to think about
- **Versioning**: Can be added in Phase 2 if needed

### No Cloud API Integration
**Why no direct cloud sync?**
- **OS handles it**: Google Drive/iCloud already sync folders automatically
- **No auth complexity**: No OAuth, no API keys, no tokens
- **Privacy**: No app-level cloud access needed
- **Simplicity**: User just picks a synced folder
- **Reliability**: Less points of failure

### Automatic Backups
**True automatic backups:**
- Run on app start/resume when due
- No user prompts or dialogs
- Silently overwrites backup file
- User just needs to select folder once
- Cloud sync happens in background via OS

## Migration Notes

### From Previous Format
The old format used timestamped filenames:
```
OLD: garantie_safe_backup_20240115_143022.gsbackup
NEW: garantie_safe_backup.gsbackup (always same name)
```

**Migration strategy:**
1. Update app
2. Old backups remain untouched (can be manually deleted)
3. New backups overwrite `garantie_safe_backup.gsbackup`
4. Restore works with both old and new formats

### Archive Structure
Both old and new formats use the same internal structure:
- `db/garantie_safe.db` (not at root)
- `attachments/*` subfolder
- `manifest.json` at root with `attachmentsCount`

### Database Schema
- Current schema version: 4
- Includes `deleted_at` column for soft deletes
- Self-healing schema on database open
- No manual migrations needed

## Security Considerations

### Data Protection
- Backups are stored in user-selected location (user controls access)
- No built-in encryption (relies on device/cloud encryption)
- Attachments are stored as-is (original format preserved)
- No compression beyond ZIP standard

### Privacy
- No telemetry or analytics
- No cloud sync by app (user manages backup location)
- No backup to app servers
- Local-first architecture

## Performance

### Backup Size
- Typical item: ~1-2 KB
- 100 items: ~100-200 KB
- Database overhead: ~40 KB
- Each attachment: varies (photos ~500 KB - 5 MB, PDFs ~100 KB - 5 MB)
- Total typical size: 1-50 MB

### Backup Time
- Local backup: < 1 second for typical dataset
- Network backup: depends on upload speed
- Verification: < 100ms

### Restore Time
- Download: depends on file size and connection
- Database replacement: < 100ms
- Attachments copy: < 1 second for typical dataset
- UI refresh: < 500ms

## Future Enhancements

### Potential Features
- [ ] Versioned backups (keep last N versions)
- [ ] Incremental backups (only changed files)
- [ ] Optional compression (reduce file size)
- [ ] Optional encryption (password-protected)
- [ ] Backup verification tool (separate screen)
- [ ] Direct cloud provider integration (optional, advanced)
- [ ] Backup scheduling (specific times)
- [ ] Export backup to share/email
- [ ] Import backup from URL/QR code

### Current Limitations
- Single backup file (no version history)
- No encryption (relies on device/cloud encryption)
- No compression beyond ZIP default
- OS-level cloud sync only (no direct API)
- Manual restore only (no auto-restore on new device)

### Why These Limitations Are OK
- **Version history**: Can add later without breaking existing backups
- **Encryption**: Most users rely on device encryption anyway
- **Compression**: File sizes are typically small enough
- **Cloud API**: Adds complexity, auth issues, privacy concerns
- **Auto-restore**: Requires cloud API, reduces simplicity

### Breaking Changes Required
Any changes to archive structure will require:
1. Version bump in manifest
2. Migration code for old formats
3. User notification of format change
4. Testing across all platforms
