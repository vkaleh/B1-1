## 2. 체크리스트 
### SSH 포트 변경(20022) 및 Root 원격 접속 차단 설정 확인 내역
```bash
vi /etc/ssh/sshd_config
```
<p>
<img width="549" height="748" alt="Screenshot 2026-05-14 at 2 53 45 PM" src="https://github.com/user-attachments/assets/ccd5442c-989e-43bf-9f9b-a999bf5d530d" />
</p>
<br>

### 방화벽(UFW 또는 firewalld) 활성화 및 20022/tcp, 15034/tcp만 허용 내역
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

### 계정/그룹(agent-admin/dev/test, agent-common/core) 생성 확인 내역
```bash
root@ec5fb12f757e:/# id agent-admin
uid=1001(agent-admin) gid=1002(agent-core) groups=1002(agent-core),1001(agent-common)
root@ec5fb12f757e:/# id agent-dev
uid=1002(agent-dev) gid=1001(agent-common) groups=1001(agent-common),1002(agent-core)
root@ec5fb12f757e:/# id agent-test
uid=1003(agent-test) gid=1001(agent-common) groups=1001(agent-common)
```
<br>

### 디렉토리 구조 및 권한(ACL 포함) 확인 내역

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

### 앱 Boost Sequence 5단계 [OK] 및 "Agent READY" 확인 내역
<p>
<img width="570" height="535" alt="Screenshot 2026-05-14 at 5 47 24 PM" src="https://github.com/user-attachments/assets/96b925f2-cdc7-4ea3-8341-18bff0e2232b" />
</p>
<br>

### monitor.sh 실행 결과(프로세스/포트/리소스/경고) 내역

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

### /var/log/agent-app/monitor.log 누적 기록 확인(최근 라인) 내역

### crontab 매분 실행 등록 및 자동 실행 확인(1분 후 로그 증가) 내역 




### 도커 컨테이너 재시작 후 테스트 순서 
#### 1. UFW 활성화 + 포트 허용
```bash
ufw enable
ufw allow 20022/tcp
ufw allow 15034/tcp
```

#### 2. SSH 서비스 시작
```bash
service ssh start
```

#### 3. cron 서비스 시작
```bash
service cron start
```

#### 4. 앱 실행 (agent-admin으로)
```bash
su - agent-admin -c "/usr/local/bin/agent-app &"
```
