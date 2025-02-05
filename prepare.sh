#!/usr/bin/bash

git submodule update --init --recursive 

ln -sf Detic/configs detic_configs 
ln -sf Detic/datasets datasets

cd node_script
ln -sf ../Detic/detic
ln -sf ../Detic/third_party
cd ..
