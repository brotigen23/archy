#!/usr/bin/bash

pacman -S kmscon

# from https://wiki.archlinux.org/title/KMSCON (26 May 2026)
systemctl enable kmsconvt@tty1
systemctl disable getty@tty1
