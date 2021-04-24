#!/bin/bash
# Ubuntu MATE post-install script

if lsb_release -cs | grep -qE "bionic|focal"; then
    if lsb_release -cs | grep -q "bionic"; then
        ver=bionic
    else
        echo "Ubuntu MATE 20.04 LTS is not supported yet!"
        ver=focal
        exit 2
    fi
else
    echo "Currently only Ubuntu MATE 18.04 LTS is supported!"
    exit 1
fi

if [ "$UID" -ne "0" ]
then
    echo "Please run this script as root user with 'sudo ./umpis.sh'"
    exit
fi

echo "Welcome to the Ubuntu MATE post-install script!"
set -x

# Initialize
export DEBIAN_FRONTEND=noninteractive

# Setup the system
rm -v /var/lib/dpkg/lock* /var/cache/apt/archives/lock
systemctl stop unattended-upgrades.service
apt-get purge unattended-upgrades -y
echo 'APT::Periodic::Enable "0";' > /etc/apt/apt.conf.d/99periodic-disable

systemctl disable apt-daily.service
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily-upgrade.service

sed -i "s/^enabled=1/enabled=0/" /etc/default/apport
sed -i "s/^Prompt=normal/Prompt=never/" /etc/update-manager/release-upgrades
sed -i "s/^Prompt=lts/Prompt=never/" /etc/update-manager/release-upgrades

# Install updates
apt-get update
apt-get dist-upgrade -y
apt-get install -f -y
dpkg --configure -a

# Git
apt-get install -y git

# RabbitVCS integration to Caja
apt-get install -y rabbitvcs-cli python-caja python-tk mercurial subversion
sudo -u $SUDO_USER -- mkdir -p ~/.local/share/caja-python/extensions
cd ~/.local/share/caja-python/extensions
sudo -u $SUDO_USER -- wget https://raw.githubusercontent.com/rabbitvcs/rabbitvcs/v0.16/clients/caja/RabbitVCS.py

# GIMP
apt-get install -y gimp

# Inkscape
apt-get install -y inkscape

# Double Commander
apt-get install -y doublecmd-gtk

# System tools
apt-get install -y htop mc aptitude synaptic apt-xapian-index fslint apt-file
update-apt-xapian-index
apt-file update 

# Kate text editor
apt-get install -y kate

# Meld 1.5.3 as in https://askubuntu.com/a/965151/66509
wget http://security.ubuntu.com/ubuntu/pool/universe/m/meld/meld_1.5.3-1ubuntu1_all.deb -O /var/cache/apt/archives/meld_1.5.3-1ubuntu1_all.deb 
apt-get install -y --allow-downgrades /var/cache/apt/archives/meld_1.5.3-1ubuntu1_all.deb 

cat <<EOF > /etc/apt/preferences.d/pin-meld
Package: meld
Pin: version 1.5.3-1ubuntu1
Pin-Priority: 1337
EOF

# VirtualBox
apt-get install -y virtualbox

# LibreOffice
add-apt-repository -y ppa:libreoffice/ppa
apt-get update
apt-get install libreoffice -y
apt-get dist-upgrade -y
apt-get install -f -y
apt-get dist-upgrade -y

# RStudio
cd /tmp
wget -c https://rstudio.org/download/latest/stable/desktop/bionic/rstudio-latest-amd64.deb
apt-get install -y r-base-dev ./rstudio-latest-amd64.deb

# Pandoc
cd /tmp
    #LATEST_PANDOC_DEB_PATH=$(wget https://github.com/jgm/pandoc/releases/latest -O - | grep \.deb | grep href | sed 's/.*href="//g' | sed 's/\.deb.*/\.deb/g' | grep amd64)
    #echo $LATEST_PANDOC_DEB_PATH;
    #LATEST_PANDOC_DEB_URL="https://github.com${LATEST_PANDOC_DEB_PATH}";
LATEST_PANDOC_DEB_URL="https://github.com/jgm/pandoc/releases/download/2.11.2/pandoc-2.11.2-1-amd64.deb"
wget -c $LATEST_PANDOC_DEB_URL;
apt install -y --allow-downgrades /tmp/pandoc*.deb;

# bookdown install for local user
apt-get install -y build-essential libssl-dev libcurl4-openssl-dev libxml2-dev libcairo2-dev
apt-get install -y evince

sudo -u $SUDO_USER -- mkdir -p ~/R/x86_64-pc-linux-gnu-library/3.4
sudo -u $SUDO_USER -- R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.rstudio.com/', lib='/home/$SUDO_USER/R/x86_64-pc-linux-gnu-library/3.4')"
    ## FIXME on lua-filter side
    sudo -u $SUDO_USER -- R -e "require(devtools); install_version('bookdown', version = '0.21', repos = 'http://cran.rstudio.com')"

    ## fixes for LibreOffice <-> RStudio interaction as described in https://askubuntu.com/a/1258175/66509
    grep "^export LD_LIBRARY_PATH=\"/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH\"" ~/.profile || echo "export LD_LIBRARY_PATH=\"/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH\"" >> ~/.profile
    grep "^export LD_LIBRARY_PATH=\"/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH\"" ~/.bashrc || echo "export LD_LIBRARY_PATH=\"/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH\"" >> ~/.bashrc

    sudo -u $SUDO_USER -- mkdir -p ~/.local/share/applications/
    sudo -u $SUDO_USER -- cp /usr/share/applications/rstudio.desktop ~/.local/share/applications/
    sudo -u $SUDO_USER -- sed -i "s|/usr/lib/rstudio/bin/rstudio|env LD_LIBRARY_PATH=/usr/lib/libreoffice/program /usr/lib/rstudio/bin/rstudio|"  ~/.local/share/applications/rstudio.desktop

# TexLive and fonts
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | /usr/bin/debconf-set-selections

apt-get install -y texlive-extra-utils biber texlive-lang-cyrillic fonts-cmu texlive-xetex texlive-fonts-extra texlive-science-doc texlive-science font-manager ttf-mscorefonts-installer texlive-latex-extra lmodern
apt-get install --reinstall -y ttf-mscorefonts-installer

# ReText
apt-get install -y retext

cat <<\EOF > /tmp/fenced_code.patch
--- org	2021-04-24 18:00:50.029754001 +0300
+++ new	2021-04-24 18:10:19.790492001 +0300
@@ -37,7 +37,7 @@
 class FencedBlockPreprocessor(Preprocessor):
     FENCED_BLOCK_RE = re.compile(r'''
 (?P<fence>^(?:~{3,}|`{3,}))[ ]*         # Opening ``` or ~~~
-(\{?\.?(?P<lang>[\w#.+-]*))?[ ]*        # Optional {, and lang
+(\{?\.?(?P<lang>[\w#.+-]*))?([ ]*|[ ,="\w-]+)        # Optional {, and lang        # Optional {, and lang
 # Optional highlight lines, single- or double-quote-delimited
 (hl_lines=(?P<quot>"|')(?P<hl_lines>.*?)(?P=quot))?[ ]*
 }?[ ]*\n                                # Optional closing }
EOF

patch -u /usr/lib/python3/dist-packages/markdown/extensions/fenced_code.py -s --force < /tmp/fenced_code.patch
sudo -u $SUDO_USER -- echo mathjax >> ~/.config/markdown-extensions.txt

# PlayOnLinux
apt-get install -y playonlinux

# Y PPA Manager
apt-get install -y ppa-purge
add-apt-repository -y ppa:y-ppa-manager/ubuntu
apt-get update
apt-get install -y y-ppa-manager

# Telegram
add-apt-repository -y ppa:atareao/telegram
apt-get update
apt-get install -y telegram

# NotepadQQ

add-apt-repository -y ppa:notepadqq-team/notepadqq
apt-get update
apt-get install -y notepadqq

# Install locale packages
apt-get install -y `check-language-support -l en` `check-language-support -l ru`

# Flatpak
add-apt-repository -y ppa:alexlarsson/flatpak
apt-get update
apt-get install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Ubuntu Make
add-apt-repository -y ppa:lyzardking/ubuntu-make
apt-get update
apt-get install -y ubuntu-make

## Arduino
usermod -a -G dialout $USER
sudo -u $SUDO_USER -- umake electronics arduino



# Cleaning up
apt-get autoremove -y

exit 0
