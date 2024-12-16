
# Backup System

A comprehensive backup system for creating and managing automated backups with features for compression, version control, and reporting.

## Features

- Automated backup creation with compression
- Change detection (only backs up when files have changed)
- Disk space validation
- Backup integrity verification
- Configurable retention policy (keeps N most recent backups)
- Backup status notifications
- Comprehensive reporting system
- Restore capability

## Directory Structure

```bash
backup-system/
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   └── report.sh
├── configs/
│   └── backup.conf
├── backups/
├── logs/
├── reports/
└── checksums/
```

## Configuration

Edit `configs/backup.conf` to set:
- Source directory (`SOURCE_DIR`)
- Backup directory (`BACKUP_DIR`)
- Report directory (`REPORT_DIR`)
- Number of backups to retain (`MAX_BACKUPS`)

## Usage

### Backup
```bash
# Normal backup
./scripts/backup.sh

# Dry run (preview what would be backed up)
./scripts/backup.sh --dry-run
```

### Restore
```bash
./scripts/restore.sh
```
The restore script provides an interactive menu to:
- List available backups
- Preview backup contents
- Restore from a selected backup

### Reporting
```bash
./scripts/report.sh
```
The reporting utility provides:
- Latest backup summary
- Complete backup history
- Space usage trends
- Generation of full reports

## Logs

- Backup operations are logged to `./logs/backup.log`
- Restore operations are logged to `./logs/restore.log`
- Report operations are logged to `./logs/report.log`

## Installation

1. Clone the repository
2. Make scripts executable:
   ```bash
   chmod +x scripts/backup.sh
   chmod +x scripts/restore.sh
   chmod +x scripts/report.sh
   ```
3. Configure your backup settings in `configs/backup.conf`
4. Create initial directories:
   ```bash
   mkdir -p backups logs reports checksums
   touch logs/.gitkeep backups/.gitkeep reports/.gitkeep checksums/.gitkeep
   ```

## Dependencies

- Bash shell
- Standard Unix utilities (tar, gzip, awk)
