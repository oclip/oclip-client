#!/usr/bin/env bash

config=$HOME/.oclip

cat > $config << EOF
token=$1
passwd=$2
domain=oclip.hanxi.info
EOF

bin=$HOME/.local/bin
mkdir -p $bin
oclip=$bin/oclip
rm -f $oclip
curl -Lo $oclip https://github.com/hanxi/oclip-client/raw/master/platform/linux/oclip 2>/dev/null
chmod +x $oclip

#insert ~/.local/bin into $PATH
old_path_len=${#PATH}
sub_path=${PATH#$bin}
new_path_len=${#sub_path}
#echo $old_path_len
#echo $new_path_len
if [ $old_path_len -eq $new_path_len ]; then
    profile=$HOME/.bashrc
    touch $profile
    bin='$HOME/.local/bin'
    sed -i "\:export PATH=\$PATH\:$bin:d" $profile
    echo "export PATH=\$PATH:$bin" >> $profile
    . $profile
fi
echo 'Hello World.' | oclip -i
oclip -h
