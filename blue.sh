#!/bin/bash
apt-mark hold firmware-microbit-micropython firmware-microbit-micropython-dl nvidia-kernel-support nvidia-tesla-470-kernel-support && apt install -y firmware-* && apt-mark unhold firmware-microbit-micropython firmware-microbit-micropython-dl nvidia-kernel-support nvidia-tesla-470-kernel-support
