# 备份系统使用指南

## 概述
本系统是一个基于 rsync 的增量备份解决方案，支持多种服务的定时备份和恢复。

## 功能特性
- 支持增量备份和全量备份
- 支持本地和远程备份
- 可配置备份保留策略
- 详细的备份日志记录
- 支持排除特定文件/目录
- 自动备份验证

## 快速开始

### 1. 安装依赖
确保系统已安装 rsync 和 cron：
```bash
sudo apt-get install rsync cron
```

### 2. 配置备份服务
1. 进入 conf.d 目录：
```bash
cd /etc/backup/conf.d
```

2. 复制示例配置文件：
```bash
cp fastdfs.inc my-service.inc
```

3. 编辑配置文件：
```bash
vim my-service.inc
```

主要配置项说明：
- START_BACKUP: 是否启用备份 (yes/no)
- REMOTE_HOST: 远程主机地址
- REMOTE_USER: 远程用户
- REMOTE_PORT: SSH 端口
- BACKUP_PATH: 本地备份路径
- REMOTE_PATH: 远程备份路径
- STRATEGY: 备份保留策略 (格式：天数:保留数量)
- SCHEDULE: 备份调度时间 (cron 表达式)

### 3. 创建备份任务
```bash
/etc/backup/create-job.sh
```

### 4. 查看备份日志
日志文件存储在：
```bash
/etc/backup/.logs/
```

## 备份验证
每次备份完成后，系统会自动执行以下验证：
1. 检查备份文件数量
2. 检查备份文件大小
3. 验证最新备份的完整性

验证结果会记录在日志文件中，格式如下：
```
[Backup Verification]
Backup file count: 123
Backup size: 1.2G
Verifying latest backup: backup-2024-01-01
Backup verification successful
```

## 恢复备份
使用 rtb-wrapper.sh 脚本进行恢复：
```bash
/etc/backup/rtb-wrapper.sh restore my-service
```

## 常见问题

### Q: 如何修改备份频率？
A: 编辑对应服务的 .inc 文件，修改 SCHEDULE 参数

### Q: 如何查看备份是否成功？
A: 检查 /etc/backup/.logs/ 目录下的日志文件

### Q: 如何添加新的备份服务？
A: 复制现有配置文件并修改相关参数

## 维护指南
- 定期检查备份日志
- 监控备份存储空间使用情况
- 定期测试备份恢复流程
- 检查备份验证结果
