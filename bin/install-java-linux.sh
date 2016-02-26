sudo add-apt-repository ppa:openjdk-r/ppa
sudo apt-get update
sudo apt-get install openjdk-8-jdk build-essential libgmp-dev libmpfr-dev libmpc-dev g++-multilib texinfo
mkdir -p ~/tmp/hsdis
cd ~/tmp/hsdis
wget http://www.java.net/download/openjdk/jdk8/promoted/b132/openjdk-8-src-b132-03_mar_2014.zip
unzip openjdk-8-src-b132-03_mar_2014.zip
cd openjdk/hotspot/src/share/tools/hsdis
wget http://ftp.heanet.ie/mirrors/gnu/binutils/binutils-2.23.2.tar.gz
tar -xzf binutils-2.23.2.tar.gz
# may be needed on Debian if you have multiarch installed
make BINUTILS=binutils-2.23.2 ARCH=amd64
cp build/linux-amd64/hsdis-amd64.so /usr/lib/jvm/java-8-oracle/jre/lib/amd64/server
