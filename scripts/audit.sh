#!/usr/bin/env bash
set -uo pipefail

PASS=0; FAIL=0

check() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo " [OK]  $desc"; ((PASS++))
    else
        echo " [FAIL] $desc (ожидалось: '$expected', получено: '$actual')"; ((FAIL++))
    fi
}

echo "Аудит конфигурации: $(hostname -f), $(date '+%Y-%m-%d %H:%M')"

echo "[1] Служба SSH"
check "Вход от имени root запрещён" "no" "$(sudo sshd -T | awk '/^permitrootlogin/{print $2}')"
check "Парольная аутентификация отключена" "no" "$(sudo sshd -T | awk '/^passwordauthentication/{print $2}')"
check "Порт SSH изменен с 22" "2222" "$(sudo sshd -T | awk '/^port/{print $2}')"
check "MaxAuthTries равен 3" "3" "$(sudo sshd -T | awk '/^maxauthtries/{print $2}')"

echo "[2] Межсетевой экран"
check "Межсетевой экран активен" "active" "$(sudo ufw status | awk '/^Status:/{print $2}')"
check "Политика входящего трафика deny" "deny" "$(sudo ufw status verbose | awk '/Default:/{print $2}')"

echo "[3] Учётные записи"
awk -F: ' $3>=1000 && $3<65534 {printf " %s (uid=%s)\n",$1,$3}' /etc/passwd

echo "[4] Веб-сервер"
if sudo nginx -t >/dev/null 2>&1; then
    echo " [OK]  Конфигурация nginx корректна"; ((PASS++))
else
    echo " [FAIL] Конфигурация nginx содержит ошибки"; ((FAIL++))
fi

if openssl x509 -checkend 2592000 -noout -in /etc/ssl/certs/devops.crt >/dev/null 2>&1; then
    echo " [OK]  Сертификат действителен более 30 дней"; ((PASS++))
else
    echo " [FAIL] Сертификат истекает менее чем через 30 дней или отсутствует"; ((FAIL++))
fi

if [ -z "$(sudo find /var/www/devops-site -perm -o+w 2>/dev/null)" ]; then
    echo " [OK]  В каталоге ресурса нет файлов с правом записи для всех"; ((PASS++))
else
    echo " [FAIL] Найдены файлы, доступные для записи всем"; ((FAIL++))
fi

if [ "$(sudo stat -c '%a' /etc/ssl/private/devops.key 2>/dev/null)" == "600" ]; then
    echo " [OK]  Права на закрытый ключ 600"; ((PASS++))
else
    echo " [FAIL] Права на закрытый ключ не 600"; ((FAIL++))
fi

echo "[5] Контейнеризация"
if [ "$(systemctl is-active docker)" == "active" ]; then
    echo " [OK]  Служба Docker активна"; ((PASS++))
else
    echo " [FAIL] Служба Docker не активна"; ((FAIL++))
fi

if [ "$(sudo docker inspect -f '{{.State.Health.Status}}' app-db-1 2>/dev/null)" == "healthy" ]; then
    echo " [OK]  Контейнер СУБД в состоянии healthy"; ((PASS++))
else
    echo " [FAIL] Контейнер СУБД не healthy или отсутствует"; ((FAIL++))
fi

if ! sudo ss -tln | grep -E '0\.0\.0\.0:(5000|5432)|\[::\]:(5000|5432)' > /dev/null; then
    echo " [OK]  Порты 5000 и 5432 не доступны извне"; ((PASS++))
else
    echo " [FAIL] Порты 5000 или 5432 прослушиваются на внешних интерфейсах"; ((FAIL++))
fi

if [ "$(sudo stat -c '%a' /home/devops/app/.env 2>/dev/null)" == "600" ]; then
    echo " [OK]  Права на файл .env равны 600"; ((PASS++))
else
    echo " [FAIL] Права на файл .env не 600"; ((FAIL++))
fi

echo "Пройдено: $PASS, не пройдено: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
