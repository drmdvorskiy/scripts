#!/bin/bash
# apt-mark hold firmware-microbit-micropython 
# apt-mark hold firmware-microbit-micropython-dl
# apt-mark hold nvidia-kernel-support
# apt-mark hold nvidia-tesla-470-kernel-support
# apt install -y firmware-* 
# apt-mark unhold firmware-microbit-micropython
# apt-mark unhold firmware-microbit-micropython-dl
# apt-mark unhold nvidia-kernel-support
# apt-mark unhold nvidia-tesla-470-kernel-support

apt install -y `apt-cache search 'firmware-*' | awk '{print $1}' | grep -P '^firmware-' | grep -v -e microbit -e nvidia | tr '\n' ' '`