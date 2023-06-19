#!/bin/bash

# Installing the following System76 packages:
# - system76-power
# - system76-firmware
# - system76-driver
# - firmware-manager
# THe script is optimized for the Lemur Pro with the Alder Lake CPU (lemp11)

REPO_SYNC=dev

# TODO: Move to mainline Pop!_OS repos
MAINLINE_ORG=https://github.com/gaganmalvi
POP_OS_ORG=https://github.com/pop-os

DRIVER_PKG=system76-driver
POWER_PKG=system76-power
FW_PKG=system76-firmware
FW_MGR=firmware-manager

echo "[-] Cloning repositories..."
# Clone repositories
git clone $MAINLINE_ORG/$DRIVER_PKG $REPO_SYNC/$DRIVER_PKG
git clone $MAINLINE_ORG/$POWER_PKG $REPO_SYNC/$POWER_PKG
git clone $MAINLINE_ORG/$FW_MGR $REPO_SYNC/$FW_MGR

git clone $POP_OS_ORG/$FW_PKG $REPO_SYNC/$FW_PKG

echo "[-] Setting up dependencies for drivers..."
# Set up dependencies
sudo zypper in \
     rust dbus-1-devel libusb-1_0-devel systemd-devel xz-devel gtk3-devel libsodium-devel

pip install wheel build installer
sudo pip install distro

cd dev

echo "[-] Building and installing system76-power..."
cd system76-power
make prefix=/usr
sudo make install prefix=/usr
sudo systemctl enable com.system76.PowerDaemon.service
sudo systemctl start com.system76.PowerDaemon.service

cd ..

echo "[-] Building and installing system76-firmware..."
cd system76-firmware
make prefix=/usr
sudo make install prefix=/usr

cd ..

echo "[-] Building and installing system76-driver..."
cd system76-driver
sudo install -D -m 0755 system76-driver-pkexec -t /usr/local/bin
sudo install -D -m 0755 system76-daemon system76-user-daemon -t /usr/lib/system76-driver/
sudo install -d /var/lib/system76-driver/
sudo install -m755 system76-nm-restart system76-thunderbolt-reload /usr/lib/system76-driver/
sudo install -Dm644 "com.system76.pkexec.system76-driver.policy" -t /usr/share/polkit-1/actions/
sudo install -Dm644 system76-user-daemon.desktop -t /etc/xdg/autostart/
sudo python3 setup.py install --skip-build
sudo cp system76-driver.desktop /usr/local/share/applications/system76-driver.desktop
sudo cp system76-driver.svg /usr/local/share/icons/hicolor/scalable/apps/system76-driver.desktop

cd ..

echo "[-] Building and installing firmware-manager..."
cd firmware-manager
make all
sudo make install
sudo systemctl enable system76-firmware-daemon.service
sudo systemctl start system76-firmware-daemon.service
sudo cp /usr/local/lib/systemd/user/com.system76.FirmwareManager.Notify.service /etc/systemd/system/com.system76.FirmwareManager.Notify.service
sudo cp /usr/local/lib/systemd/user/com.system76.FirmwareManager.Notify.timer /etc/systemd/system/com.system76.FirmwareManager.Notify.timer
cd ../../

echo "[-] All tasks done, please reboot."
