#!/usr/bin/env bash
# Создаёт пустую ВМ PXE или запускает её с диска после установки.
set -euo pipefail

mode=${1:-}
action=${2:-}
case "$mode" in
  bios) firmware=bios ;;
  uefi) firmware=efi64 ;;
  *) echo 'Использование: bash pxe-client.sh bios|uefi create|disk' >&2; exit 2 ;;
esac

vm="pxeclient-$mode"
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

case "$action" in
  create)
    # Сначала проверяем, что HTTP-раздача PXE-сервера готова.
    curl -fsSI 'http://127.0.0.1:8080/pxe/seed/meta-data' >/dev/null
    if VBoxManage showvminfo "$vm" >/dev/null 2>&1 || [[ -e ".pxe/$vm" ]]; then
      echo "ВМ $vm или её рабочий каталог уже существует." >&2
      exit 1
    fi
    mkdir -p ".pxe/$vm"
    disk="$PWD/.pxe/$vm/disk.vdi"
    VBoxManage createvm --name "$vm" --ostype Ubuntu_64 --register
    VBoxManage modifyvm "$vm" --firmware "$firmware" --memory 8192 --cpus 2 \
      --nic1 intnet --intnet1 pxenet --nictype1 82540EM --cableconnected1 on \
      --boot1 net --boot2 none --boot3 none --boot4 none
    VBoxManage createmedium disk --filename "$disk" --size 24576 --format VDI
    VBoxManage storagectl "$vm" --name SATA --add sata --controller IntelAhci
    VBoxManage storageattach "$vm" --storagectl SATA --port 0 --device 0 \
      --type hdd --medium "$disk"
    VBoxManage startvm "$vm" --type gui
    ;;
  disk)
    if ! VBoxManage showvminfo "$vm" --machinereadable | grep -Fx 'VMState="poweroff"' >/dev/null; then
      echo "Дождитесь, пока ВМ $vm выключится после установки." >&2
      exit 1
    fi
    VBoxManage modifyvm "$vm" --boot1 disk --boot2 none --boot3 none --boot4 none
    VBoxManage startvm "$vm" --type gui
    ;;
  *)
    echo 'Использование: bash pxe-client.sh bios|uefi create|disk' >&2
    exit 2
    ;;
esac

# v1 — 2026-11-07
# Создание тестовой ВМ BIOS/UEFI и загрузка установленной системы.
