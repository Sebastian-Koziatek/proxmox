#!/bin/bash

# Konfiguracja
PBS_STORAGE="pbs"          # Nazwa storage w Proxmox VE wskazującego na PBS
SOURCE_VM_ID="315"             # ID maszyny źródłowej
NEW_VM_ID="315"               # ID dla nowej maszyny
NEW_MAC="BC:24:11:C4:18:59"    # Losowy MAC, możesz zmienić na statyczny
TARGET_STORAGE="Samsung980"    # Storage, na którym ma być zapisana nowa maszyna

# Znalezienie najnowszego backupu maszyny
SNAPSHOT_NAME=$(pvesm list $PBS_STORAGE --vmid $SOURCE_VM_ID | awk '{print $1}' | grep -E "^pbs:backup/vm/$SOURCE_VM_ID" | sort -r | head -n 1)

if [ -z "$SNAPSHOT_NAME" ]; then
  echo "Błąd: Nie znaleziono backupu dla VM $SOURCE_VM_ID w storage $PBS_STORAGE."
  exit 1
fi

echo "Znaleziono backup: $SNAPSHOT_NAME"

# Odtwarzanie maszyny na nową VM z ID $NEW_VM_ID na storage "Samsung980"
echo "Odtwarzanie maszyny z ID $SOURCE_VM_ID na nową VM z ID $NEW_VM_ID..."
qmrestore "$SNAPSHOT_NAME" $NEW_VM_ID --storage $TARGET_STORAGE
if [ $? -ne 0 ]; then
  echo "Błąd podczas odtwarzania maszyny."
  exit 1
fi

# Ustawienie adresu MAC
echo "Przypisywanie adresu MAC $NEW_MAC do VM $NEW_VM_ID..."
qm set $NEW_VM_ID --net0 model=virtio,macaddr=$NEW_MAC,bridge=vmbr0
if [ $? -ne 0 ]; then
  echo "Błąd podczas przypisywania adresu MAC."
  exit 1
fi

echo "Maszyna $NEW_VM_ID została odtworzona i skonfigurowana z MAC $NEW_MAC na storage $TARGET_STORAGE."
