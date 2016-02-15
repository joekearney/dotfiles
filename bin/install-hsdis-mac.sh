DEFAULT_JDK_VERSION="jdk1.8.0_60"
DEFAULT_DOWNLOAD="http://www.java.net/download/openjdk/jdk8/promoted/b132/openjdk-8-src-b132-03_mar_2014.zip"

function doInstall() {
  local jdkVersion
  read -p "What's the JDK version? Installed are: [$(ls /Library/Java/JavaVirtualMachines/)] " jdkVersion
  jdkVersion=${jdkVersion:-"${DEFAULT_JDK_VERSION}"}

  local openjdk8url
  read -p "What's the openjdk8 url for the download? Default: [http://www.java.net/download/openjdk/jdk8/promoted/b132/openjdk-8-src-b132-03_mar_2014.zip] " openjdk8url
  openjdk8url=${openjdk8url:-"${DEFAULT_DOWNLOAD}"}
  local file=$(basename $openjdk8url)

  echo
  echo "Using target jdk ${jdkVersion}"
  echo "Downloading Java sources from ${openjdk8url}"
exit
  mkdir -p ~/tmp/$file
  cd ~/tmp/$file

  [[ ! -f "$openjdk8url" ]] && wget $openjdk8url
  [[ ! -d "openjdk" ]] && unzip $file
  cd openjdk/hotspot/src/share/tools/hsdis
  [[ ! -f "binutils-2.24.tar.gz" ]] && wget http://ftp.heanet.ie/mirrors/gnu/binutils/binutils-2.24.tar.gz && tar -xzf binutils-2.24.tar.gz
  make BINUTILS=binutils-2.24 ARCH=amd64
  sudo cp build/macosx-amd64/hsdis-amd64.dylib /Library/Java/JavaVirtualMachines/${jdkVersion}.jdk/Contents/Home/jre/lib/server/
}

doInstall
