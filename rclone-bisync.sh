#!/bin/bash

# Default values for paths and files
LOCKFILE="/tmp/rclone_bisync.lock"
LOGFILE="/tmp/rclone_bisync.log"
DRYRUN_OUTPUT="/tmp/rclone_bisync_dryrun.log"
ERROR_FILE="/tmp/rclone_bisync_error.log"

# Use environment variables for paths
RCLONE_CONF=${RCLONE_CONF:-""}
LOCAL_PATH=${LOCAL_PATH:-""}
REMOTE_PATH=${REMOTE_PATH:-""}

# Function to delete logs
delete_logs() {
    rm -f "$LOGFILE" "$ERROR_FILE" "$DRYRUN_OUTPUT"
}

# Function to run rclone bisync
run_bisync() {
    local resync_flag=$1
    local dry_run_flag=$2
    local output_file=$3

    if [ "$resync_flag" == "true" ]; then
        rclone --config "$RCLONE_CONF" bisync "$LOCAL_PATH" "$REMOTE_PATH" \
            --create-empty-src-dirs --compare size,modtime,checksum \
            --slow-hash-sync-only -MvP --drive-skip-gdocs --fix-case --force \
            --resync --max-lock 10 $dry_run_flag 2>&1 | tee "$output_file"
    else
        rclone --config "$RCLONE_CONF" bisync "$LOCAL_PATH" "$REMOTE_PATH" \
            --create-empty-src-dirs --compare size,modtime,checksum \
            --slow-hash-sync-only -MvP --drive-skip-gdocs --fix-case --force \
            --max-lock 10 $dry_run_flag 2>&1 | tee "$output_file"
    fi
}

# Check for rclone command
if ! command -v rclone &> /dev/null; then
    echo "Error: rclone is not installed or not in PATH."
    exit 1
fi

# Check if RCLONE_CONF is empty
if [ -z "$RCLONE_CONF" ]; then
    echo "Error: RCLONE_CONF environment variable is required."
    exit 1
fi

# Check if LOCAL_PATH is empty
if [ -z "$LOCAL_PATH" ]; then
    echo "Error: LOCAL_PATH environment variable is required."
    exit 1
fi

# Check if REMOTE_PATH is empty
if [ -z "$REMOTE_PATH" ]; then
    echo "Error: REMOTE_PATH environment variable is required."
    exit 1
fi

# Check if the lock file exists and exit if it does
if [ -e "$LOCKFILE" ]; then
    echo "Error: Another instance of the script is already running."
    exit 1
else
    # Delete the logs from the previous sync
    delete_logs
    # Create the lock file
    touch "$LOCKFILE"
    # Boolean for resync
    resync=false

    # Run the rclone bisync command with --config flag and dry-run to capture output
    run_bisync false "--dry-run" "$DRYRUN_OUTPUT"

    if grep -q "Bisync aborted. Must run --resync to recover" "$DRYRUN_OUTPUT"; then
        echo "Recovering with --resync flag"
        rm -f "$DRYRUN_OUTPUT"
        resync=true
        run_bisync true "--dry-run" "$DRYRUN_OUTPUT"
    fi

    if ! grep -q "Bisync successful" "$DRYRUN_OUTPUT"; then
        rm -f "$LOCKFILE"
        cat "$DRYRUN_OUTPUT" > "$ERROR_FILE"
        exit 1
    fi

    if $resync; then
        run_bisync true "" "$LOGFILE"
    else
        run_bisync false "" "$LOGFILE"
        if grep -q "Must run --resync to recover" "$LOGFILE"; then
            rm -f "$LOGFILE"
            echo "Recovering with --resync flag"
            run_bisync true "" "$LOGFILE"
        fi
    fi

    if ! grep -q "Bisync successful" "$LOGFILE"; then
        rm -f "$LOCKFILE"
        cat "$LOGFILE" > "$ERROR_FILE"
        exit 1
    fi

    rm -f "$LOCKFILE"
fi
