set -e

if [ "$TRAVIS_OS_NAME" = "linux" ]
	then
	sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
	sudo apt-get update -qq
	sudo apt-get install -y build-essential libglib2.0-dev wget
elif [ "$TRAVIS_OS_NAME" = "osx" ]
	then
	brew update > brew_update.log
	brew install glib
else
	echo "ERROR: TRAVIS_OS_NAME: $TRAVIS_OS_NAME is not handled, not installing LCM"
	exit 1
fi

wget https://github.com/lcm-proj/lcm/releases/download/v1.3.0/lcm-1.3.0.zip
unzip lcm-1.3.0.zip > unzip_lcm.log
cd lcm-1.3.0
./configure
make

if [ "$TRAVIS_OS_NAME" = "linux" ]
	then
	sudo make install
elif [ "$TRAVIS_OS_NAME" = "osx" ]
	then
	make install
fi

cd ..
lcm-gen -p lcm-1.3.0/examples/types/multidim_array_t.lcm

