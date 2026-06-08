# Цель
Автоматизирует установку archlinux по гайду с wiki.archlinux.org

# разметка по умолчанию
boot 500M
swap = ram
root +

# bootloader
systemd-boot
директория loader содержит конфигурацию и будет скопирована в /boot/loader

# pkg
содержит файлы которые будут установлены в систему

# post install
```bash
useradd -mG wheel <username> # создание пользователя

nvim /etc/sudoers # сделать wheel группу с root правами

pacman -S <intel|amd>-ucode # микрокоды. надо добавить в loader/entries/arch.conf перед initramfs
```
