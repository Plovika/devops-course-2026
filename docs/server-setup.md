# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины
- Объём оперативной памяти: 2048 МБ
- Количество ядер процессора: 2
- Объём диска: 25 ГБ (динамически расширяемый)

## 2. Сетевые интерфейсы
- Адаптер 1: NAT (IP: 10.0.2.15, назначение: доступ в интернет)
- Адаптер 2: Виртуальный адаптер хоста (Host-only, IP: 192.168.56.101, назначение: доступ с хостовой машины)

## 3. Правило проброса портов
- Порт хостовой системы: 2222
- Порт гостевой системы: 2222

## 4. Учётные записи
- student: группы (student, sudo), способ аутентификации (пароль)
- devops: группы (devops, sudo), способ аутентификации (SSH-ключ)

## 5. Служба SSH
- Порт: 2222
- Файл конфигурации: /etc/ssh/sshd_config.d/99-hardening.conf
- Изменённые директивы: Port 2222, PermitRootLogin no, PasswordAuthentication no, PubkeyAuthentication yes, PermitEmptyPasswords no, MaxAuthTries 3, LoginGraceTime 30, AllowUsers devops, X11Forwarding no, ClientAliveInterval 300, ClientAliveCountMax 2

## 6. Правила межсетевого экрана
- Политики по умолчанию: deny (incoming), allow (outgoing)
- Перечень правил: limit 2222/tcp (SSH), allow 80/tcp (HTTP), allow 443/tcp (HTTPS)

## 7. Снимки состояния
- 01-clean-install (создан после чистой установки)
- 02-keys-configured (создан после настройки ключей)
- 03-ssh-hardened (создан после усиления SSH и настройки UFW)

## 8. Веб-сервер
- Устанавливаемый пакет: nginx
- Путь к конфигурации ресурса: /etc/nginx/sites-available/devops-site
- Каталог ресурса: /var/www/devops-site, владелец devops:devops, права 755 для каталогов, 644 для файлов
- Пути к сертификату и ключу: /etc/ssl/certs/devops.crt (644), /etc/ssl/private/devops.key (600, владелец root)
- Команда формирования сертификата: sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/devops.key -out /etc/ssl/certs/devops.crt -subj "/CN=devops.local" -addext "subjectAltName=DNS:devops.local"
- Срок действия: 365 дней
