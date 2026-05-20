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
