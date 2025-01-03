#!/bin/bash

clear
echo -e "\033[1;32m
██████╗ ██╗   ██  ███████╗  ███████╗  ███████╗  
██╔══██╗ ██╗ ██║  ██║   ██║ ██║   ██║ ██║   ██║
██████╔╝  ████║   ██║   ██║ ██║   ██║ ██║   ██║
██╔══██╗   ██╔╝   ██║   ██║ ██║   ██║ ██║   ██║
██║  ██║   ██║    ███████║  ███████║  ███████║
╚═╝  ╚═╝   ╚═╝    ╚══════╝  ╚══════╝  ╚══════╝
\033[0m"
echo -e "\033[1;34m==================================================\033[1;34m"
echo -e "\033[1;34m@Ryddd | Testnet, Node Runer, Developer, Retrodrop\033[1;34m"

sleep 4

# Periksa apakah skrip dijalankan sebagai pengguna root
if [ "$(id -u)" != "0" ]; then
    echo "\033[1;34mSkrip ini perlu dijalankan dengan hak akses root.\033[1;34m"
    echo "\033[1;34mSilakan coba gunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan kembali skrip ini.\033[1;34m"
    exit 1
fi

# Periksa apakah Docker sudah terinstal
if ! command -v docker &> /dev/null; then
    echo "\033[1;34mDocker belum terinstal, sedang menginstal...\033[1;34m"

    # Perbarui sistem
    sudo apt update -y && sudo apt upgrade -y
    
    # Hapus versi lama
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        sudo apt-get remove -y $pkg
    done

    # Instal paket yang diperlukan
    apt update
    apt install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Tambahkan repositori Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Perbarui kembali dan instal Docker
    apt update -y && apt upgrade -y
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Periksa versi Docker
    echo "\033[1;34mDocker berhasil diinstal, versinya adalah: $(docker --version)\033[1;34m"
else
    echo "\033[1;34mDocker sudah terinstal, versinya adalah: $(docker --version)\033[1;34m"
fi

# Dapatkan jalur relatif
relative_path=$(realpath --relative-to=/usr/share/zoneinfo /etc/localtime)
echo "\033[1;34mJalur relatif: $relative_path\033[1;34m"

# Buat direktori chromium dan masuk ke dalamnya
mkdir -p $HOME/chromium
cd $HOME/chromium
echo "\033[1;34mBerhasil masuk ke direktori chromium\033[1;34m"

# Fungsi untuk membuat file docker-compose.yaml dan memulai layanan
function deploy_browser() {
    # Minta input dari pengguna
    read -p "Masukkan CUSTOM_USER: " CUSTOM_USER
    read -sp "Masukkan PASSWORD: " PASSWORD
    read -p "Masukkan port yang akan diakses: " ACCESS_PORT
    echo

    # Buat file docker-compose.yaml
    cat <<EOF > docker-compose.yaml
---
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined #opsional
    environment:
      - CUSTOM_USER=$CUSTOM_USER
      - PASSWORD=$PASSWORD
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - CHROME_CLI=https://webbrowsertools.com #opsional
    volumes:
      - /root/chromium/config:/config
    ports:
      - $ACCESS_PORT:3000   #Ubah 3000 ke port favorit Anda jika diperlukan
      - 28882:3001   #Ubah 3001 ke port favorit Anda jika diperlukan
    shm_size: "1gb"
    restart: unless-stopped
EOF

    echo "\033[1;34mFile docker-compose.yaml berhasil dibuat dan isinya sudah diimport.\033[1;34m"
    docker compose up -d
    echo "\033[1;34mDocker Compose berhasil dijalankan.\033[1;34m"
}

# Fungsi untuk menghapus node
function uninstall_docker() {
    echo "\033[1;34mSedang menghentikan Docker...\033[1;34m"
    # Hentikan kontainer Docker
    cd /root/chromium
    docker compose down

    # Hapus file dan direktori
    rm -rf /root/chromium
    echo "\033[1;34mNode berhasil dihapus.\033[1;34m"
}

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        echo -e "\033[1;32m
        ██████╗ ██╗   ██  ███████╗  ███████╗  ███████╗  
        ██╔══██╗ ██╗ ██║  ██║   ██║ ██║   ██║ ██║   ██║
        ██████╔╝  ████║   ██║   ██║ ██║   ██║ ██║   ██║
        ██╔══██╗   ██╔╝   ██║   ██║ ██║   ██║ ██║   ██║
        ██║  ██║   ██║    ███████║  ███████║  ███████║
        ╚═╝  ╚═╝   ╚═╝    ╚══════╝  ╚══════╝  ╚══════╝
        \033[0m"
        echo -e "\033[1;34m==================================================\033[1;34m"
        echo -e "\033[1;34m@Ryddd | Testnet, Node Runer, Developer, Retrodrop\033[1;34m"
        echo "Untuk keluar dari skrip, tekan tombol Ctrl + C"
        echo "Pilih tindakan yang ingin dilakukan:"
        echo "1) Deploy browser"
        echo "2) Hapus node (docker down untuk menghapus kontainer)"
        echo "3) Keluar"
        
        read -p "Masukkan pilihan Anda: " choice
        
        case $choice in
            1)
                deploy_browser
                ;;
            2)
                uninstall_docker
                ;;
            3)
                echo "\033[1;34mKeluar dari skrip.\033[1;34m"
                exit 0
                ;;
            *)
                echo "\033[1;34mPilihan tidak valid, silakan coba lagi.\033[1;34m"
                ;;
        esac

        read -p "Tekan tombol apa saja untuk melanjutkan..."
    done
}

# Jalankan menu utama
main_menu
