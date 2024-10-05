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
    echo "=====$(date +"%Y-%m-%d-%H:%M:%S")=====" >> $profile_file-err.log
    eval "$cmd 2>>$profile_file-err.log"
else
    echo "Failed to read the profile file: ${profile_file}" > /dev/stderr
    exit 1
fi


