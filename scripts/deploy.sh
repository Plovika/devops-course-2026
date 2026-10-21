#!/usr/bin/env bash
set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
LOCAL_DIR="$(git rev-parse --show-toplevel)/site/"

# 1. Разбор аргумента --dry-run
DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
fi

# 2. Проверка наличия index.html (Требование 4)
if [ ! -f "${LOCAL_DIR}index.html" ]; then
    echo "Ошибка: файл site/index.html отсутствует!" >&2
    exit 1
fi

# 3. Проверка незафиксированных изменений (Требование 5)
if [ -n "$(git status --porcelain)" ]; then
    echo "Ошибка: в репозитории есть незафиксированные изменения!" >&2
    exit 1
fi

# 4. Синхронизация (Требование 3 и 8)
rsync -avz --delete --chmod=D755,F644 ${DRY_RUN} -e "ssh -o BatchMode=yes" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"

# 5. При --dry-run завершаем с кодом 0 (Требование 1)
if [[ -n "$DRY_RUN" ]]; then
    echo "Пробный запуск завершен."
    exit 0
fi

# 6. Проверка доступности сайта с проверкой сертификата (Требование 6)
if ! curl -f --cacert "${CA_CERT}" -s "${SITE_URL}" > /dev/null; then
    echo "Ошибка: сайт недоступен после деплоя!" >&2
    exit 1
fi

# 7. Успешное завершение (Требование 7)
echo "Успешно доставлен коммит: $(git rev-parse --short HEAD)"
