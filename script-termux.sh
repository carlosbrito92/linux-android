#!/data/data/com.termux/files/usr/bin/bash

# Script Linux simplificado para Termux
# Versão editada: Wine removido + logging nos passos criticos (4 e 5)

# ============== CONFIGURAÇÃO BÁSICA ==============
DE_CHOICE="1"
DE_NAME="XFCE4"
GPU_DRIVER=""

# ============== FUNÇÕES SIMPLIFICADAS ==============
print_step() {
    echo "[$1/$2] $3"
}

install_pkg() {
    echo "  -> Instalando $1..."
    apt-get install -y -q $1 > /dev/null 2>&1
}

# install_pkg_verbose: mostra a saida real (usado nos passos que mais falham)
install_pkg_verbose() {
    echo "  -> Instalando $1 (modo verbose)..."
    apt-get install -y $1
    if [ $? -ne 0 ]; then
        echo "  [!] ATENCAO: falha ao instalar '$1'. Veja o erro acima."
    fi
}

# ============== DETECÇÃO DO DISPOSITIVO ==============
echo "=== Configurando Termux Linux ==="
echo ""

DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")

echo "Dispositivo: $DEVICE_BRAND"

# ============== SELEÇÃO DO DESKTOP ==============
echo ""
echo "Escolha o Desktop:"
echo "1) XFCE4 (recomendado)"
echo "2) LXQt (leve)"
echo "3) MATE (médio)"
echo "4) KDE (pesado)"
read -p "Opção [1-4, padrão=1]: " DE_INPUT
DE_INPUT=${DE_INPUT:-1}

case $DE_INPUT in
    1) DE_NAME="XFCE4";;
    2) DE_NAME="LXQt";;
    3) DE_NAME="MATE";;
    4) DE_NAME="KDE Plasma";;
esac
echo "Selecionado: $DE_NAME"

# ============== INSTALAÇÃO (10 PASSOS) ==============
# Wine removido: total caiu de 11 para 10 passos
TOTAL=10
CURRENT=0

# Passo 1
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Atualizando sistema"
apt-get update -y -q > /dev/null 2>&1
apt-get upgrade -y -q > /dev/null 2>&1

# Passo 2
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Adicionando repositórios"
apt-get install -y -q x11-repo tur-repo > /dev/null 2>&1

# Passo 3
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando servidor gráfico"
apt-get install -y -q termux-x11-nightly xorg-xrandr > /dev/null 2>&1

# Passo 4 (VERBOSE - falha aqui é comum)
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando $DE_NAME"
case $DE_INPUT in
    1) install_pkg_verbose "xfce4 xfce4-terminal xfce4-whiskermenu-plugin plank-reloaded thunar mousepad";;
    2) install_pkg_verbose "lxqt qterminal pcmanfm-qt featherpad";;
    3) install_pkg_verbose "mate mate-tweak plank-reloaded mate-terminal";;
    4) install_pkg_verbose "plasma-desktop konsole dolphin";;
esac

# Passo 5 (VERBOSE - driver grafico, ponto critico no Mali)
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando drivers GPU"
echo "  -> Instalando mesa-zink e vulkan-loader-android..."
apt-get install -y mesa-zink vulkan-loader-android
if [ $? -ne 0 ]; then
    echo "  [!] ATENCAO: falha ao instalar drivers GPU. Veja o erro acima."
fi
[ "$GPU_DRIVER" == "freedreno" ] && apt-get install -y -q mesa-vulkan-icd-freedreno > /dev/null 2>&1

# Passo 6
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando áudio"
apt-get install -y -q pulseaudio > /dev/null 2>&1

# Passo 7
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando apps"
apt-get install -y -q firefox vlc git wget curl > /dev/null 2>&1

# Passo 8
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Instalando Python"
apt-get install -y -q python > /dev/null 2>&1
pip install flask > /dev/null 2>&1

# Passo 9 (antes era 10) - Criando scripts
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Criando scripts"
cat > ~/start-linux.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -9 -f "termux.x11" 2>/dev/null
pulseaudio --kill 2>/dev/null
sleep 1
pulseaudio --start --exit-idle-time=-1
export PULSE_SERVER=127.0.0.1
# Forca renderizacao via Zink (OpenGL sobre Vulkan) - ideal para GPU Mali
export MESA_LOADER_DRIVER_OVERRIDE=zink
export GALLIUM_DRIVER=zink
termux-x11 :0 -ac &
sleep 2
export DISPLAY=:0
EOF

if [ "$DE_INPUT" == "1" ]; then
    echo "exec startxfce4" >> ~/start-linux.sh
elif [ "$DE_INPUT" == "2" ]; then
    echo "exec startlxqt" >> ~/start-linux.sh
elif [ "$DE_INPUT" == "3" ]; then
    echo "exec mate-session" >> ~/start-linux.sh
else
    echo "exec startplasma-x11" >> ~/start-linux.sh
fi

chmod +x ~/start-linux.sh

cat > ~/stop-linux.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 pulseaudio 2>/dev/null
echo "Desktop finalizado"
EOF
chmod +x ~/stop-linux.sh

# Passo 10 (antes era 11) - Criando atalhos
CURRENT=$((CURRENT+1)); print_step $CURRENT $TOTAL "Criando atalhos"
mkdir -p ~/Desktop
cat > ~/Desktop/Firefox.desktop << 'EOF'
[Desktop Entry]
Name=Firefox
Exec=firefox
Type=Application
EOF
chmod +x ~/Desktop/*.desktop 2>/dev/null

# ============== FINALIZAÇÃO ==============
echo ""
echo "=== INSTALAÇÃO CONCLUÍDA ==="
echo ""
echo "Para iniciar o desktop: ./start-linux.sh"
echo "Para parar: ./stop-linux.sh"
echo "Abra o app Termux-X11 para ver a interface"
echo ""
