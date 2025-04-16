
#install prerequisites
sudo apt install cmake libgl1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev libdrm-dev libgbm-dev ttf-mscorefonts-installer fontconfig libsystemd-dev libinput-dev libudev-dev  libxkbcommon-dev

#update fonts
sudo fc-cache

#clone repo and enter directory
git clone --recursive https://github.com/ardera/flutter-pi
cd flutter-pi

#build flutter-pi
mkdir build && cd build
cmake ..
make -j`nproc`

#install flutter-pi
sudo make install
