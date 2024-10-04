#!/usr/bin/env bash

#  0 */1 * * * if grep -qs /mnt/backup /proc/mounts; then rsync_tmbackup.sh /home /mnt/backup; fi


base_dir="/etc/backup"

#删除已经有的定时任务
rm -rf /etc/cron.d/rtb

for file in "$base_dir"/conf.d/*.inc; do
    [ -e "$file" ] || continue  # 检查文件是否存在

    #重新生成定时任务
    (
        filename=$(basename "$file" .inc)
        . $base_dir/conf.d/$filename.inc
        shopt -s nocasematch  #开启不区分大小写
        if [ "$START_BACKUP" == 'yes' ];then
            echo "# rtb_${filename}_bak"  >>/etc/cron.d/rtb
            echo "${SCHEDULE:-0 */1 * * *} ${base_dir}/rtb-wrapper.sh backup ${filename}" >> /etc/cron.d/rtb
            mkdir -p -- "$BACKUP_PATH"
            touch "$BACKUP_PATH/backup.marker"
        fi
    )
done
chmod +644  /etc/cron.d/rtb
chmod +x  $base_dir/*.sh