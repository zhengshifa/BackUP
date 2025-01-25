#!/usr/bin/env sh
# profile based rsync-time-backup
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value


# load config
config_dir=/etc/backup

# create backup cli command
fn_create_backup_cmd () {
    cmd="$config_dir/rsync_tmbackup.sh --strategy '${STRATEGY:-'1:1 30:7 364:30'}' -p ${REMOTE_PORT:-22} ${REMOTE_USER:-root}"

    exclude_file_check=${EXCLUDE_FILE:-}

    if [ -n "$REMOTE_HOST" ] && [ -n "$REMOTE_PATH" ] && [ -n "$BACKUP_PATH" ]; then
        if [ -n "${exclude_file_check}" ]; then
            cmd="${cmd}'@'$REMOTE_HOST:$REMOTE_PATH $BACKUP_PATH $EXCLUDE_FILE"
        else
            cmd="${cmd}'@'$REMOTE_HOST:$REMOTE_PATH $BACKUP_PATH"
        fi
    else
        cmd='echo 请检查备份REMOTE_HOST等参数'
    fi
    echo "$cmd"
}

# create restore cli command
fn_create_restore_cmd () {
    cmd="rsync -aP  --delete"

    if [ -n "$REMOTE_HOST" ] && [ -n "$REMOTE_PATH" ] && [ -n "$BACKUP_PATH" ]; then

        cmd="${cmd} $BACKUP_PATH -p ${REMOTE_PORT:-22} ${REMOTE_USER:-root}@$REMOTE_HOST:$REMOTE_PATH"
    else
        cmd='echo 请检查备份REMOTE_HOST等参数'
    fi

    echo "$cmd"
}

# show help when invoked without parameters
if [ $# -eq 0 ]; then
    exit 0
fi

action=${1?"param 1: action: backup, restore"}
profile=${2?"param 2: name of the profile"}

# load profile
profile_dir="${config_dir}/conf.d"
profile_file="${profile_dir}/${profile}.inc"
exclude_file_convention="${profile_dir}/${profile}.excludes.lst"

if [ -r "$profile_file" ]; then
    # Load configuration
    if [ -r "$exclude_file_convention" ]; then
        EXCLUDE_FILE="$exclude_file_convention"
    fi

    # shellcheck disable=SC1090,SC1091
    . "$profile_file"

    # create cli command
    if [ "$action" = "restore" ]; then
        cmd=$(fn_create_restore_cmd)
    else
        cmd=$(fn_create_backup_cmd)
    fi

    # Execute the command
    log_dir=${config_dir}/.logs
    mkdir -p $log_dir
    echo -e "\n\n\n=======$(date +"%Y-%m-%d-%H:%M:%S")=======" >> ${log_dir}/${profile}-err.log
    eval "$cmd 2>> ${log_dir}/${profile}-err.log"
    
    # Backup verification
    echo -e "\n[Backup Verification]" >> ${log_dir}/${profile}-err.log
    if [ "$action" = "backup" ]; then
        # Check backup file count
        file_count=$(find $BACKUP_PATH -type f | wc -l)
        echo "Backup file count: $file_count" >> ${log_dir}/${profile}-err.log
        
        # Check backup size
        backup_size=$(du -sh $BACKUP_PATH | awk '{print $1}')
        echo "Backup size: $backup_size" >> ${log_dir}/${profile}-err.log
        
        # Verify latest backup
        latest_backup=$(ls -t $BACKUP_PATH | head -n 1)
        if [ -n "$latest_backup" ]; then
            echo "Verifying latest backup: $latest_backup" >> ${log_dir}/${profile}-err.log
            rsync --dry-run --checksum $BACKUP_PATH/$latest_backup $BACKUP_PATH/verify/ >> ${log_dir}/${profile}-err.log 2>&1
            if [ $? -eq 0 ]; then
                echo "Backup verification successful" >> ${log_dir}/${profile}-err.log
            else
                echo "Backup verification failed" >> ${log_dir}/${profile}-err.log
            fi
        else
            echo "No backup found for verification" >> ${log_dir}/${profile}-err.log
        fi
    fi
else
    echo "Failed to read the profile file: ${profile_file}" > /dev/stderr
    exit 1
fi
