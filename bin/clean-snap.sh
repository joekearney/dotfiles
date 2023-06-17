sudo rm -rf /var/log/journal/*
sudo apt clean
sudo apt-get clean
sudo apt autoclean
sudo apt-get autoremove --purge

sudo rm /var/cache/apt/pkgcache.bin /var/cache/apt/srcpkgcache.bin
sudo rm -r /usr/src/*

snap list --all | awk '/disabled/{print $1, $3}' | \
    while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done