# 시스템 관제 자동화 스크립트 개발
## 1. 프로젝트 개요
Ubuntu 서버 환경에서 SSH 보안 설정, 계정/권한 관리, 환경 구성을 수행하고, 시스템 자원 및 애플리케이션 상태를 자동으로 모니터링하는 스크립트를 구축한다. <br>
<br>

## 2. 체크리스트 
### 2-1. SSH 포트 변경(20022) 및 Root 원격 접속 차단 설정 확인 내역
```bash
vi /etc/ssh/sshd_config
```
<p>
<img width="549" height="748" alt="Screenshot 2026-05-14 at 2 53 45 PM" src="https://github.com/user-attachments/assets/ccd5442c-989e-43bf-9f9b-a999bf5d530d" />
</p>
<br>

### 2-2. 방화벽(UFW 또는 firewalld) 활성화 및 20022/tcp, 15034/tcp만 허용 내역
```bash
root@ec5fb12f757e:/# ufw status
Status: inactive
root@ec5fb12f757e:/# ufw enable
Firewall is active and enabled on system startup
root@ec5fb12f757e:/# ufw allow 20022/tcp
Skipping adding existing rule
Skipping adding existing rule (v6)
root@ec5fb12f757e:/# ufw allow 15034/tcp
Skipping adding existing rule
Skipping adding existing rule (v6)
root@ec5fb12f757e:/# ufw status
Status: active

To                         Action      From
--                         ------      ----
20022/tcp                  ALLOW       Anywhere                  
15034/tcp                  ALLOW       Anywhere                  
20022/tcp (v6)             ALLOW       Anywhere (v6)             
15034/tcp (v6)             ALLOW       Anywhere (v6)
```
<br>

### 2-3. 계정/그룹(agent-admin/dev/test, agent-common/core) 생성 확인 내역
```bash
root@ec5fb12f757e:/# id agent-admin
uid=1001(agent-admin) gid=1002(agent-core) groups=1002(agent-core),1001(agent-common)
root@ec5fb12f757e:/# id agent-dev
uid=1002(agent-dev) gid=1001(agent-common) groups=1001(agent-common),1002(agent-core)
root@ec5fb12f757e:/# id agent-test
uid=1003(agent-test) gid=1001(agent-common) groups=1001(agent-common)
```
<br>

### 2-4. 디렉토리 구조 및 권한(ACL 포함) 확인 내역

- upload_files
```bash
root@ec5fb12f757e:/# ls -l /home/agent-admin/agent-app              
total 0
drwxr-xr-x 1 agent-admin agent-core 24 May 12 13:10 api_keys
drwxr-xr-x 1 root        root       20 May 12 13:47 bin
drwxr-xr-x 1 root        root        0 May 14 15:44 upload_files

root@ec5fb12f757e:/# chown agent-admin:agent-common /home/agent-admin/agent-app/upload_files
root@ec5fb12f757e:/# chmod 770 /home/agent-admin/agent-app/upload_files
root@ec5fb12f757e:/# setfacl -d -m g:agent-common:rwx /home/agent-admin/agent-app/upload_files  # 앞으로 생성될 모든 파일과 하위 폴더에 자동으로 권한 적용 (Default, Modify)
root@ec5fb12f757e:/# setfacl -m g:agent-common:rwx /home/agent-admin/agent-app/upload_files     # 현재 upload_files에 대해 권한 적용 

root@ec5fb12f757e:/# getfacl /home/agent-admin/agent-app/upload_files
getfacl: Removing leading '/' from absolute path names
# file: home/agent-admin/agent-app/upload_files
# owner: agent-admin
# group: agent-common
user::rwx
group::rwx
group:agent-common:rwx
mask::rwx
other::---
default:user::rwx
default:group::rwx
default:group:agent-common:rwx
default:mask::rwx
default:other::---

root@ec5fb12f757e:/# ls -l /home/agent-admin/agent-app
total 0
drwxr-xr-x  1 agent-admin agent-core   24 May 12 13:10 api_keys
drwxr-xr-x  1 root        root         20 May 12 13:47 bin
drwxrwx---+ 1 agent-admin agent-common  0 May 14 15:44 upload_files
```
<br>

- api_keys
```bash
root@ec5fb12f757e:/# ls -l /home/agent-admin/agent-app 
total 0
drwxr-xr-x  1 agent-admin agent-core   24 May 12 13:10 api_keys
drwxr-xr-x  1 root        root         20 May 12 13:47 bin
drwxrwx---+ 1 agent-admin agent-common  0 May 14 15:44 upload_files

root@ec5fb12f757e:/# chown root:agent-core /home/agent-admin/agent-app/api_keys
root@ec5fb12f757e:/# chmod 770 /home/agent-admin/agent-app/api_keys
root@ec5fb12f757e:/# setfacl -d -m g:agent-core:rwx /home/agent-admin/agent-app/api_keys
root@ec5fb12f757e:/# setfacl -m g:agent-core:rwx /home/agent-admin/agent-app/api_keys

root@ec5fb12f757e:/# getfacl /home/agent-admin/agent-app/api_keys
getfacl: Removing leading '/' from absolute path names
# file: home/agent-admin/agent-app/api_keys
# owner: root
# group: agent-core
user::rwx
group::rwx
group:agent-core:rwx
mask::rwx
other::---
default:user::rwx
default:group::rwx
default:group:agent-core:rwx
default:mask::rwx
default:other::---

root@ec5fb12f757e:/# ls -l /home/agent-admin/agent-app         
total 0
drwxrwx---+ 1 root        agent-core   24 May 12 13:10 api_keys
drwxr-xr-x  1 root        root         20 May 12 13:47 bin
drwxrwx---+ 1 agent-admin agent-common  0 May 14 15:44 upload_files
```
<br>

- /var/log/agent-app
```bash
root@ec5fb12f757e:/# ls -l /var/log/agent-app
total 552
-rw-r--r-- 1 agent-admin agent-core 557464 May 14 15:27 agent_app.log
-rw-r--r-- 1 agent-admin agent-core   2358 May 14 14:43 monitor.log

root@ec5fb12f757e:/# ls -l /var/log          
total 392
lrwxrwxrwx  1 root        root                39 May 12 12:51 README -> ../../usr/share/doc/systemd/README.logs
drwxr-xr-x  1 agent-admin agent-core          48 May 14 14:26 agent-app
-rw-r--r--  1 root        root             16486 May 12 12:54 alternatives.log
drwxr-xr-x  1 root        root                60 May 14 14:23 apt
-rw-r--r--  1 root        root             61229 Apr 10 11:20 bootstrap.log
-rw-rw----  1 root        utmp               768 May 14 14:04 btmp
-rw-r--r--  1 root        root            310226 May 14 14:23 dpkg.log
-rw-r--r--  1 root        root                 0 Apr 10 11:20 faillog
drwxr-sr-x+ 1 root        systemd-journal      0 May 12 12:51 journal
-rw-rw-r--  1 root        utmp                 0 Apr 10 11:20 lastlog
drwx------  1 root        root                 0 May 12 12:51 private
-rw-rw-r--  1 root        utmp                 0 Apr 10 11:20 wtmp

root@ec5fb12f757e:/# chmod 770 /var/log/agent-app
root@ec5fb12f757e:/# setfacl -d -m g:agent-core:rwx /var/log/agent-app
root@ec5fb12f757e:/# setfacl -m g:agent-core:rwx /var/log/agent-app

root@ec5fb12f757e:/# getfacl var/log/agent-app
# file: var/log/agent-app
# owner: agent-admin
# group: agent-core
user::rwx
group::rwx
group:agent-core:rwx
mask::rwx
other::---
default:user::rwx
default:group::rwx
default:group:agent-core:rwx
default:mask::rwx
default:other::---

root@ec5fb12f757e:/# ls -l /var/log/agent-app
total 552
-rw-r--r-- 1 agent-admin agent-core 557464 May 14 15:27 agent_app.log
-rw-r--r-- 1 agent-admin agent-core   2358 May 14 14:43 monitor.log
```
<br>

### 2-5. 앱 Boost Sequence 5단계 [OK] 및 "Agent READY" 확인 내역
<p>
<img width="570" height="535" alt="Screenshot 2026-05-14 at 5 47 24 PM" src="https://github.com/user-attachments/assets/96b925f2-cdc7-4ea3-8341-18bff0e2232b" />
</p>
<br>

### 2-6. monitor.sh 실행 결과(프로세스/포트/리소스/경고) 내역

터미널 1에서는 
```bash
agent-admin@ec5fb12f757e:~$ /usr/local/bin/agent-app &
```

터미널 2에서는
```bash
docker exec -it agent-mission2 bash

agent-admin@ec5fb12f757e:~$ $AGENT_HOME/bin/monitor.sh
===== SYSTEM MONITOR RESULT =====

[HEALTH CHECK]
Checking process 'agent-app'...[OK] (PID: 96,97,387,389)
Checking port 15034...[OK]

[FIREWALL CHECK]
ERROR: You need to be root to run this script
UFW Status: active

[RESOURCE MONITORING]
CPU Usage : 0.0%
MEM Usage : 4.3%
DISK Used : 1%


===== STATISTICS REPORT =====
[CPU]
  Average : 0.0%
  Maximum : 0.0% at 2026-05-14 18:19:48
  Minimum : 0.0% at 
[Memory]
  Average : 4.9%
  Maximum : 5.2% at 
  Minimum : 4.6% at 2026-05-14 18:19:48
[Samples]
  Data Points : 82 samples

[INFO] Log appended: /var/log/agent-app/monitor.log
```
<br>

### 2-7. /var/log/agent-app/monitor.log 누적 기록 확인(최근 라인) 내역
```
root@c80e2ad812e4:/# tail -n 5 /var/log/agent-app/monitor.log
[2026-05-19 13:04:01] PID:7388 CPU:0.0% MEM:3.8% DISK_USED:1%
[2026-05-19 13:05:01] PID:7388 CPU:7.5% MEM:4.9% DISK_USED:1%
[2026-05-19 13:06:01] PID:7388 CPU:0.0% MEM:4.8% DISK_USED:1%
[2026-05-19 13:07:01] PID:7388 CPU:2.5% MEM:3.9% DISK_USED:1%
[2026-05-19 13:08:01] PID:7388 CPU:4.2% MEM:5.5% DISK_USED:1%
```
<br>

### 2-8. crontab 매분 실행 등록 및 자동 실행 확인(1분 후 로그 증가) 내역 
```bash
root@c80e2ad812e4:/# crontab -l
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command
* * * * * /home/agent-admin/agent-app/bin/monitor.sh
```

```
root@c80e2ad812e4:/# tail -f /var/log/agent-app/monitor.log
[2026-05-19 13:03:01] PID:7388 CPU:0.0% MEM:5.0% DISK_USED:1%
[2026-05-19 13:04:01] PID:7388 CPU:0.0% MEM:3.8% DISK_USED:1%
[2026-05-19 13:05:01] PID:7388 CPU:7.5% MEM:4.9% DISK_USED:1%
[2026-05-19 13:06:01] PID:7388 CPU:0.0% MEM:4.8% DISK_USED:1%
[2026-05-19 13:07:01] PID:7388 CPU:2.5% MEM:3.9% DISK_USED:1%
```
<br>

## 3. 수행 방법 
### 우분투 24.04 로 실행 
```bash
docker run -it --privileged --name agent-mission ubuntu:24.04 /bin/bash
apt update && apt install -y openssh-server ufw acl python3 python3-pip vim bc net-tools iproute2 sudo curl
```
<br>

### 설치되었는지 확인
```bash
root@c80e2ad812e4:/# sshd -V 2>&1 | head -1
OpenSSH_9.6p1 Ubuntu-3ubuntu13.16, OpenSSL 3.0.13 30 Jan 2024
root@c80e2ad812e4:/# python3 --version
Python 3.12.3
root@c80e2ad812e4:/# ufw --version
ufw 0.36.2
Copyright 2008-2023 Canonical Ltd.
```
<br>

### 새 터미널 창 열어서 다운로드받은 agent-app을 Mac->Docker 컨테이너로 옮기기 
```bash
사용자ID@c4r2s8 ~ % docker cp ~/Downloads/agent-app c80e2ad812e4:/usr/local/bin/         
Successfully copied 7.93MB to c80e2ad812e4:/usr/local/bin/
```
<br>

### 원래 터미널 창에서 파일 수정 
```bash
root@c80e2ad812e4:/# vi /etc/ssh/sshd_config
#Port 22 -> Port 20022
#PermitRootLogin prohibit-password -> PermitRootLogin no
#PasswordAuthentication yes -> PasswordAuthentication yes 로 수정
```
<br>

### 방화벽 설정
```bash
root@c80e2ad812e4:/# ufw allow 20022/tcp
Rules updated
Rules updated (v6)
root@c80e2ad812e4:/# ufw allow 15034/tcp
Rules updated
Rules updated (v6)
root@c80e2ad812e4:/# ufw enable
Firewall is active and enabled on system startup
root@c80e2ad812e4:/# service ssh restart
 * Restarting OpenBSD Secure Shell server sshd                           [ OK ] 
root@c80e2ad812e4:/# ufw status
Status: active

To                         Action      From
--                         ------      ----
20022/tcp                  ALLOW       Anywhere                  
15034/tcp                  ALLOW       Anywhere                  
20022/tcp (v6)             ALLOW       Anywhere (v6)             
15034/tcp (v6)             ALLOW       Anywhere (v6) 
```
<br>

### 그룹, 계정 설정
```bash
root@c80e2ad812e4:/# groupadd agent-common
root@c80e2ad812e4:/# groupadd agent-core
root@c80e2ad812e4:/# useradd -m -s /bin/bash -g agent-core agent-admin
root@c80e2ad812e4:/# useradd -m -s /bin/bash -g agent-common agent-dev
root@c80e2ad812e4:/# useradd -m -s /bin/bash -g agent-common agent-test
root@c80e2ad812e4:/# usermod -aG agent-common agent-admin
root@c80e2ad812e4:/# usermod -aG agent-core agent-dev
root@c80e2ad812e4:/# id agent-admin
uid=1001(agent-admin) gid=1002(agent-core) groups=1002(agent-core),1001(agent-common)
root@c80e2ad812e4:/# id agent-dev
uid=1002(agent-dev) gid=1001(agent-common) groups=1001(agent-common),1002(agent-core)
root@c80e2ad812e4:/# id agent-test
uid=1003(agent-test) gid=1001(agent-common) groups=1001(agent-common)
```
<br>

### 계정 비밀번호 설정
```bash
root@c80e2ad812e4:/# sudo passwd agent-admin
New password: 
Retype new password: 
passwd: password updated successfully
root@c80e2ad812e4:/# sudo passwd agent-dev  
New password: 
Retype new password: 
passwd: password updated successfully
root@c80e2ad812e4:/# sudo passwd agent-test 
New password: 
Retype new password: 
passwd: password updated successfully
```
<br>

### 실행 권한 부여
```bash
root@c80e2ad812e4:/# /usr/local/bin/agent-app
bash: /usr/local/bin/agent-app: Permission denied
root@c80e2ad812e4:/# ls -la /usr/local/bin/agent-app
-rw-rw-r-- 1 1267600509 1267600509 7926296 Jan 29 10:36 /usr/local/bin/agent-app
root@c80e2ad812e4:/# chmod +x /usr/local/bin/agent-app
root@c80e2ad812e4:/# ls -la /usr/local/bin/agent-app
-rwxrwxr-x 1 1267600509 1267600509 7926296 Jan 29 10:36 /usr/local/bin/agent-app
root@c80e2ad812e4:/# /usr/local/bin/agent-app
>>> Starting Agent Boot Sequence...
[1/5] Checking User Account               [FAIL]
 >>> Error: Running as 'root' is forbidden. Use a service account.
[2/5] Verifying Environment Variables     [FAIL]
 >>> Skipped due to previous critical failure.
[3/5] Checking Required Files             [FAIL]
 >>> Skipped due to previous critical failure.
[4/5] Checking Port Availability          [FAIL]
 >>> Skipped due to previous critical failure.
[5/5] Verifying Log Permission            [FAIL]
 >>> Skipped due to previous critical failure.
--------------------------------------------------
System Boot Failed. Process Terminated.

Running as 'root' is forbidden이므로 admin 계정으로 전환 후 실행 
root@c80e2ad812e4:/# su - agent-admin
agent-admin@c80e2ad812e4:~$ /usr/local/bin/agent-app
>>> Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
 ... Running as service user 'agent-admin' (uid=1001)
[2/5] Verifying Environment Variables     [FAIL]
 >>> Critical Env 'AGENT_HOME' is missing.
[3/5] Checking Required Files             [FAIL]
 >>> Skipped due to previous critical failure.
[4/5] Checking Port Availability          [FAIL]
 >>> Skipped due to previous critical failure.
[5/5] Verifying Log Permission            [FAIL]
 >>> Skipped due to previous critical failure.
--------------------------------------------------
System Boot Failed. Process Terminated.
```
<br>

### 환경변수 적용
```bash
agent-admin@c80e2ad812e4:~$ exit
logout
root@c80e2ad812e4:/# echo 'export AGENT_HOME=/home/agent-admin/agent-app' >> /etc/bash.bashrc
root@c80e2ad812e4:/# echo 'export AGENT_PORT=15034' >> /etc/bash.bashrc
root@c80e2ad812e4:/# echo 'export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files' >> /etc/bash.bashrc
root@c80e2ad812e4:/# echo 'export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key' >> /etc/bash.bashrc
root@c80e2ad812e4:/# echo 'export AGENT_LOG_DIR=/var/log/agent-app' >> /etc/bash.bashrc
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
export AGENT_LOG_DIR=/var/log/agent-app
root@c80e2ad812e4:/# source /etc/bash.bashrc
```
<br>

계정이 달라도 환경변수가 같게 설정하기 위해서 bash.bashrc에 환경변수를 설정했음 
```bash
root@c80e2ad812e4:/# echo $AGENT_HOME
/home/agent-admin/agent-app
agent-admin@c80e2ad812e4:~$ echo $AGENT_HOME
/home/agent-admin/agent-app
```
<br>

### 환경변수 적용 후 다시 테스트 
```bash
root@c80e2ad812e4:/# su - agent-admin
agent-admin@c80e2ad812e4:~$ echo $AGENT_HOME
/home/agent-admin/agent-app
agent-admin@c80e2ad812e4:~$ /usr/local/bin/agent-app
>>> Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
 ... Running as service user 'agent-admin' (uid=1001)
[2/5] Verifying Environment Variables     [OK]
 ... All required Envs correct
[3/5] Checking Required Files             [FAIL]
 >>> Key file not found: /home/agent-admin/agent-app/api_keys/t_secret.key
[4/5] Checking Port Availability          [FAIL]
 >>> Skipped due to previous critical failure.
[5/5] Verifying Log Permission            [FAIL]
 >>> Skipped due to previous critical failure.
--------------------------------------------------
System Boot Failed. Process Terminated.
```
<br>

### 키 파일 생성
```bash
agent-admin@c80e2ad812e4:~$ mkdir -p $AGENT_HOME/api_keys
agent-admin@c80e2ad812e4:~$ echo 'agent_api_key_test' > $AGENT_HOME/api_keys/t_secret.key
agent-admin@c80e2ad812e4:~$ cat $AGENT_HOME/api_keys/t_secret.key
agent_api_key_test
agent-admin@c80e2ad812e4:~$ /usr/local/bin/agent-app
>>> Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
 ... Running as service user 'agent-admin' (uid=1001)
[2/5] Verifying Environment Variables     [OK]
 ... All required Envs correct
[3/5] Checking Required Files             [OK]
 ... Verified 'secret.key' with correct key string.
[4/5] Checking Port Availability          [OK]
 ... Port 15034 is available.
[5/5] Verifying Log Permission            [FAIL]
 >>> Log directory not found: /var/log/agent-app
--------------------------------------------------
System Boot Failed. Process Terminated.
```
<br>

### 로그 디렉토리 생성
```bash
agent-admin@c80e2ad812e4:~$ mkdir -p /var/log/agent-app
mkdir: cannot create directory ‘/var/log/agent-app’: Permission denied
agent-admin@c80e2ad812e4:~$ exit
logout
root@c80e2ad812e4:/# mkdir -p /var/log/agent-app
root@c80e2ad812e4:/# chown agent-admin:agent-core /var/log/agent-app        # agent-admin이 쓸 수 있는 권한 부여
root@c80e2ad812e4:/# su - agent-admin
agent-admin@c80e2ad812e4:~$ /usr/local/bin/agent-app
>>> Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
 ... Running as service user 'agent-admin' (uid=1001)
[2/5] Verifying Environment Variables     [OK]
 ... All required Envs correct
[3/5] Checking Required Files             [OK]
 ... Verified 'secret.key' with correct key string.
[4/5] Checking Port Availability          [OK]
 ... Port 15034 is available.
[5/5] Verifying Log Permission            [OK]
 ... Log directory is writable: /var/log/agent-app
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
2026-05-19 12:19:28,067 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-05-19 12:19:28,067 [INFO] Agent listening at port 15034
2026-05-19 12:19:28,067 [INFO] === Agent Started. Beginning resource cycle. ===
2026-05-19 12:19:28,067 [INFO] --- Step Info: Mode=UP, CPU Lv=1, Mem=0MB ---
2026-05-19 12:19:28,104 [INFO] [Memory] Increasing... (+25 MB) Total: 25 MB
2026-05-19 12:19:28,130 [INFO] [CPU] Level 1 workload completed. Duration: 0.03s
```
<br>

### 다른 터미널 창에서 monitor.sh가 생성될 폴더를 만듦
```bash
root@c80e2ad812e4:/# mkdir /home/agent-admin/agent-app/bin
root@c80e2ad812e4:/# vi /home/agent-admin/agent-app/bin/monitor.sh
```
<br>

### :set encoding=utf-8 후 복붙 
<details>
  <summary>monitor.sh 코드 </summary> 

```bash
#!/bin/bash
# ============================================
# monitor.sh - 시스템 관제 자동화 스크립트
# 소유자: agent-dev | 그룹: agent-core | 권한: 750
# ============================================

# ── 설정값 ──────────────────────────────────
APP_NAME="agent-app"
APP_PORT=15034
LOG_FILE="/var/log/agent-app/monitor.log"
LOG_MAX_SIZE=$((10 * 1024 * 1024))   # 10MB (bytes)
LOG_MAX_FILES=10

THRESHOLD_CPU=20
THRESHOLD_MEM=10
THRESHOLD_DISK=80

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# ── 로그 로테이션 함수 ───────────────────────
rotate_log() {
    if [ -f "$LOG_FILE" ]; then
        local size
        size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        if [ "$size" -ge "$LOG_MAX_SIZE" ]; then
            # 오래된 파일 삭제 (10개 초과 시)
            for i in $(seq $((LOG_MAX_FILES - 1)) -1 1); do
                [ -f "${LOG_FILE}.$i" ] && mv "${LOG_FILE}.$i" "${LOG_FILE}.$((i+1))"
            done
            mv "$LOG_FILE" "${LOG_FILE}.1"
            touch "$LOG_FILE"
        fi
    fi
}

# ── 헬스 체크 함수 ───────────────────────────
health_check() {
    echo "[HEALTH CHECK]"

    # 프로세스 확인
    echo -n "Checking process '$APP_NAME'..."
    PID=$(pgrep -f "$APP_NAME" | head -1)
    if [ -z "$PID" ]; then
        echo "[FAIL] Process not running!"
        exit 1
    fi
    echo "[OK] (PID: $PID)"

    # 포트 확인
    echo -n "Checking port $APP_PORT..."
    # ss 가 없을 때를 대비해 netstat와 bash 내장 기능 등 호환성 확보
    if command -v ss &>/dev/null; then
        PORT_CHECK=$(ss -tulnp | grep -E :${APP_PORT}'([[:space:]]|$)')
    else
        PORT_CHECK=$(netstat -tulnp 2>/dev/null | grep -E :${APP_PORT}'([[:space:]]|$)')
    fi

    if [ -n "$PORT_CHECK" ]; then
        echo "[OK]"
    else
        echo "[FAIL] Port $APP_PORT not listening!"
        exit 1
    fi
}

# ── 방화벽 상태 확인 ─────────────────────────
check_firewall() {
    echo ""
    echo "[FIREWALL CHECK]"
    if command -v ufw &>/dev/null; then
        STATUS=$(sudo ufw status 2>/dev/null | grep -i "Status:" | awk '{print $2}')
        if [ "$STATUS" != "active" ]; then
            echo "[WARNING] UFW firewall is not active!"
        else
            echo "UFW Status: active [OK]"
        fi
    elif command -v firewall-cmd &>/dev/null; then
        if ! firewall-cmd --state &>/dev/null; then
            echo "[WARNING] firewalld is not active!"
        else
            echo "firewalld Status: active [OK]"
        fi
    else
        echo "[WARNING] No firewall tool found!"
    fi
}

# ── 리소스 수집 함수 ─────────────────────────
collect_resources() {
    echo ""
    echo "[RESOURCE MONITORING]"

    # [수정] CPU 사용률: 현재 순간의 정확한 측정을 위해 '유휴(idle)' 값을 100에서 빼는 방식으로 계산 (Locale 독립적)
    # top -bn2를 사용하여 2번째 사이클의 신뢰할 수 있는 데이터를 수집합니다.
    local IDLE
    IDLE=$(top -bn2 -d 0.5 | grep -i "Cpu(s)" | tail -n 1 | awk -F',' '{
        for(i=1;i<=NF;i++){
            if($i ~ /id/){print $i}
        }
    }' | grep -oP '[0-9.]+')
    
    # 쉼표(,)를 소수점(.)으로 치환 (일부 리눅스 환경 대비)
    IDLE=${IDLE//, /.}
    
    if [ -z "$IDLE" ]; then IDLE="100.0"; fi
    CPU=$(echo "100.0 - $IDLE" | bc -l)
    CPU=$(printf "%.1f" "$CPU" 2>/dev/null || echo "$CPU")

    # 메모리 사용률
    MEM=$(free | awk '/Mem:/ {printf "%.1f", $3/$2 * 100}')

    # 디스크 사용률 (루트 파티션)
    DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

    echo "CPU Usage  : ${CPU}%"
    echo "MEM Usage  : ${MEM}%"
    echo "DISK Used  : ${DISK}%"

    # 임계값 경고
    echo ""
    if (( $(echo "$CPU > $THRESHOLD_CPU" | bc -l) )); then
        echo "[WARNING] CPU threshold exceeded (${CPU}% > ${THRESHOLD_CPU}%)"
    fi
    if (( $(echo "$MEM > $THRESHOLD_MEM" | bc -l) )); then
        echo "[WARNING] MEM threshold exceeded (${MEM}% > ${THRESHOLD_MEM}%)"
    fi
    if [ "$DISK" -gt "$THRESHOLD_DISK" ]; then
        echo "[WARNING] DISK threshold exceeded (${DISK}% > ${THRESHOLD_DISK}%)"
    fi
}

# ── 로그 기록 함수 ───────────────────────────
write_log() {
    rotate_log
    echo "[${TIMESTAMP}] PID:${PID} CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}%" >> "$LOG_FILE"
    echo ""
    echo "[INFO] Log appended: $LOG_FILE"
}

# ── 통계 리포트 함수 ─────────────────────────
statistics_report() {
    echo ""
    echo "===== STATISTICS REPORT ====="

    if [ ! -f "$LOG_FILE" ]; then
        echo "No log data available."
        return
    fi

    # 샘플 수
    SAMPLES=$(wc -l < "$LOG_FILE")
    if [ "$SAMPLES" -eq 0 ]; then
        echo "Log file is empty."
        return
    fi

    # CPU 통계
    CPU_AVG=$(grep -oP 'CPU:\K[0-9.]+' "$LOG_FILE" | awk '{s+=$1; c++} END {if(c>0) printf "%.1f", s/c; else print "0.0"}')
    CPU_MAX=$(grep -oP 'CPU:\K[0-9.]+' "$LOG_FILE" | sort -n | tail -1)
    CPU_MIN=$(grep -oP 'CPU:\K[0-9.]+' "$LOG_FILE" | sort -n | head -1)

    # MEM 통계
    MEM_AVG=$(grep -oP 'MEM:\K[0-9.]+' "$LOG_FILE" | awk '{s+=$1; c++} END {if(c>0) printf "%.1f", s/c; else print "0.0"}')

    echo "[CPU]"
    echo "  Average : ${CPU_AVG}%"
    echo "  Max     : ${CPU_MAX}%"
    echo "  Min     : ${CPU_MIN}%"
    echo "[Memory]"
    echo "  Average : ${MEM_AVG}%"
    echo "[Samples]"
    echo "  Data Points : ${SAMPLES} samples"
}

# ── 메인 실행 ────────────────────────────────
echo "===== SYSTEM MONITOR RESULT ====="
echo "Timestamp: $TIMESTAMP"
echo ""

health_check
check_firewall
collect_resources
write_log
statistics_report

echo ""
echo "================================="
```
</details>
<br>

### monitor.sh 권한 설정
```bash
root@c80e2ad812e4:/# chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh
root@c80e2ad812e4:/# chmod 750 /home/agent-admin/agent-app/bin/monitor.sh
root@c80e2ad812e4:/# ls -l /home/agent-admin/agent-app/bin/monitor.sh
-rwxr-x--- 1 agent-dev agent-core 6172 May 19 12:37 /home/agent-admin/agent-app/bin/monitor.sh
```
<br>

### cron 등록
```bash
root@c80e2ad812e4:/# apt update && apt install -y cron
root@c80e2ad812e4:/# crontab -e
맨 아랫줄에 
* * * * * /home/agent-admin/agent-app/bin/monitor.sh 추가
```
<br>
       
### cron 서비스 실행
```bash
root@c80e2ad812e4:/# service cron status        # 크론 서비스 상태 확인
 * cron is not running
root@c80e2ad812e4:/# service cron start         # 크론 서비스 시작
 * Starting periodic command scheduler cron                              [ OK ] 
root@c80e2ad812e4:/# service cron status
 * cron is running
```
<br>

### crontab 확인
```bash
root@c80e2ad812e4:/# tail -f /var/log/agent-app/monitor.log
[2026-05-19 13:03:01] PID:7388 CPU:0.0% MEM:5.0% DISK_USED:1%
[2026-05-19 13:04:01] PID:7388 CPU:0.0% MEM:3.8% DISK_USED:1%
[2026-05-19 13:05:01] PID:7388 CPU:7.5% MEM:4.9% DISK_USED:1%
```
<br>

## 4. 도커 컨테이너 재시작 후 테스트 순서 
### 4-1. UFW 활성화 + 포트 허용
```bash
ufw enable
ufw allow 20022/tcp
ufw allow 15034/tcp
```

### 4-2. SSH 서비스 시작
```bash
service ssh start
```

### 4-3. cron 서비스 시작
```bash
service cron start
```

### 4-4. 앱 실행 (agent-admin으로)
```bash
su - agent-admin -c "/usr/local/bin/agent-app &"
```

## 5. 개념 알아가기
### 5-1. SSH 포트 변경과 Root 원격 접속 차단의 필요성
#### SSH 포트 변경 (22 → 20022 등):
인터넷에 연결된 서버의 22번 포트는 전 세계 해커들과 자동화된 공격 봇(Bot)들의 최우선 타깃임<br>
포트를 기본값에서 다른 임의의 번호로 바꾸는 것만으로도 무차별 대입 공격(Brute Force Attack)의 90% 이상을 자동으로 필터링하는 '숨김을 통한 보안(Security by Obscurity)' 효과를 얻을 수 있음<br>
<br>

#### Root 원격 접속 차단 (PermitRootLogin no):
root 계정은 시스템의 모든 권한을 가진 최고 존엄 계정이며, 아이디가 root라는 것을 전 세계 모두가 알고 있음 <br>
해커에게 절반의 정답(아이디)을 주고 시작하는 것과 같으므로, 원격 접속을 막아서 1차 방어선을 구축함 <br>
대신 권한이 제한된 일반 사용자 계정으로 로그인한 뒤, sudo나 su를 통해 권한을 획득하는 것이 보안 추적(Auditing)과 안전성 측면에서 훨씬 유리함 <br>
<br>

### 5-2. 필요 포트만 허용하는 이유 (최소 권한 원칙)
해커가 노릴 수 있는 침입 경로를 원천 차단하여 시스템의 취약점을 최소화하기 위함
- 공격 표면(Attack Surface)의 최소화: 포트는 네트워크에서 내부 서비스로 들어오는 '문'으로, 해커의 침입 경로가 될 수 있음 

- 보안 사고 예방 및 탐지 용이성:
  - 정찰 행위 탐지: 닫힌 포트로 들어오는 모든 비정상적 접근 시도는 방화벽 로그(Log)에 흔적으로 남기 때문에, 해커의 사전 스캔 행위(시스템의 빈틈을 찾으려는)를 즉각 감지할 수 있음
  - 모니터링 효율화: 관리자가 허용된 포트의 트래픽만 집중 감시하면 되므로, 공격 징후를 훨씬 쉽고 빠르게 찾아낼 수 있음

- 아웃바운드(Outbound: 안에서 밖으로 나가는 것) 차단: 내부 PC가 악성코드나 랜섬웨어에 감염되더라도, 허용되지 않은 포트가 막혀 있으면 악성코드가 외부 해커의 명령 서버와 연결하거나 내부 데이터를 밖으로 유출하는 것을 원천 차단할 수 있음
<br>

### 5-3. 역할 기반 계정/그룹과 ACL을 통해 공유 디렉토리와 보안 디렉토리를 분리하는 이유
- 직무 분리(Separation of Duties)를 통한 정보 보호: 사용자의 역할에 맞춰 권한을 그룹화함으로써, 일반 업무용 공유 디렉토리와 기밀 유지가 필요한 보안 디렉토리를 물리적·논리적으로 격리함 <br>
- 세분화된 접근 제어(Fine-Grained Control): 단순한 그룹 권한의 한계를 넘어, ACL(Access Control List: 접근 제어 목록)을 통해 개별 사용자나 특정 상황에 맞는 권한(읽기/쓰기/수정 등)을 부여할 수 있음 <br>
- 피해 범위 최소화(Blast Radius 제한): 특정 계정이 해킹당하거나 악성코드에 감염되더라도, 해당 계정이 접근할 수 있는 디렉토리로만 피해가 한정됨. 즉, 공유 디렉토리는 오염되더라도 보안 디렉토리는 보호 가능 <br>

#### ACL
일반 리눅스 권한은 group::rwx 하나로 퉁치지만, ACL을 쓰면 group:agent-core:rwx 처럼 특정 그룹을 명시해서 권한을 바인딩할 수 있음 <br>
만약 여기에 agent-common이라는 다른 그룹에게도 권한을 주고 싶다면, 기존 방식으론 불가능하지만 ACL을 쓰면 group:agent-common:r-x 같은 줄을 아래에 이어붙이기만 하면 됨 <br>
<br>

### 5-4. 환경 변수(AGENT_HOME 등)로 실행 환경을 고정하는 이유와 검증 방법
소스코드 내부에 절대경로를 하드코딩해두면, 서버 환경이 바뀌거나 경로가 조금만 달라져도 프로그램이 터지므로, <br>
환경 변수를 사용해서 소스코드를 수정하지 않고도 환경 변수 값만 바꿔서 개발/테스트/운영 서버에 유연하게 배포할 수 있게 함. <br>
또, 프로그램이 참조할 표준 경로를 강제하여 엉뚱한 디렉토리에 파일이 생성되는 것을 막아줌 <br>
<br>

### 5-5. crontab으로 모니터링을 주기 실행시키고, 로그 보존 정책(압축/삭제)이 필요한 이유 
#### crontab 주기 실행의 이유 (자동화):
사람이 1분마다 서버에 들어와서 top이나 df를 치며 감시할 수는 없기 때문. <br>
crontab을 통해 모니터링 스크립트를 주기적으로 실행함으로써 관제 업무를 자동화하고 시스템 공백 없는 24/7 상시 감시 체계를 유지함 <br>
<br>

#### 로그 보존 정책(압축/삭제)이 필수적인 이유 (디스크 풀 방지):
로그를 무제한으로 쌓아두면 언젠가는 서버의 디스크 공간이 가득 차게 됨. <br>
리눅스는 디스크가 꽉 차는 순간 시스템 전체가 마비되거나 데이터가 유실될 수 있으므로, <br>
따라서 로그 파일이 일정 크기를 넘으면 새 파일로 교체하고(Rotate), 오래된 로그는 용량을 줄이기 위해 압축(.gz)하거나, <br>
보존 기한(예: 30일 또는 최대 10개 파일)이 지난 과거 로그는 자동으로 삭제하는 정책이 필수적임. <br>
스크립트 내에 구현된 rotate_log() 함수나 리눅스의 logrotate 도구가 존재하는 이유 <br>
<br>

## 6. 수행 내용에 대한 보충 설명
### 6-1. monitor.sh에서 프로세스 식별과 포트 확인에 사용한 명령과 선택 이유?

### 6-2. CPU/MEM/DISK 값을 어떤 방식으로 추출/파싱했는지, 로그 포맷을 왜 이런 형태로 고정했는지?

### 6-3. 용량 기반 로그 관리를 어떤 방식으로 구현했는지?

### 6-4. 경고는 출력하되 종료하지 않는 항목(방화벽 비활성/임계치 초과)을 분리한 운영상의 이유가 뭘까?

### 6-5. 리다이렉션 기호 >와 >>의 차이, 로그 누적에 >>가 필요한 이유?

### 6-6. 모니터링 대상이 웹 서버(Nginx 등)로 바뀐다면, monitor.sh에서 바꿔야 할 핵심 포인트?

### 6-7. 프로세스는 살아있는데 포트가 안 열리는 상황을 발견했다면, 원인 후보와 확인 순서는 뭘까?

### 6-8. 로그가 급증해 디스크가 가득 찰 위험이 있다면, 운영자가 취할 대응은?
