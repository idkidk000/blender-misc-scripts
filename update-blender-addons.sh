#!/bin/bash

source_root=~/build/blender-addons
target_root=~/.config/blender
python_path=~/build/blender/deps/bin/python-3.6/bin/python3

IFS_orig=$IFS
IFS='
'
for addon_git in `find $source_root -type d -name '.git'`; do
    addon_dir=$(dirname "$addon_git")
    addon_dir_name=${addon_dir:${#source_root}+1}
    addon_name=${addon_dir_name////-}
    echo -e "$(tput setaf 3)$addon_name$(tput sgr0)"
    pushd $addon_dir > /dev/null
    git pull
    
    if [ -f "$addon_dir/CMakeLists.txt" ]; then
        cmake "$addon_dir/CMakeLists.txt"
    fi
    
    if [ -f "$addon_dir/setup.py" ]; then
        #animation nodes has different params per branch. python's exit code is always 0
        #python "$addon_dir/setup.py" build --noversioncheck
        "$python_path" ./setup.py --noversioncheck --nocopy
    fi
    
    #todo - this is pretty bad. should be in a loop increasing maxdepth until found or max
    addon_init=$(find $addon_dir -name '__init__.py' -not -path '*setup*' -not -path '*src*' -not -path '*pyfluid*' | sort | head -1)
    if [ -z "$addon_init" ]; then
        ln -s $(find $addon_dir -type f -name '*.py' | head -1) "$addon_dir/__init__.py"
        addon_link_path=$addon_dir
    else
        addon_link_path=$(dirname $addon_init)
    fi
    
    for blender_dir in `ls -d $target_root/*`; do
        if [ ! -s "$blender_dir/scripts/addons/$addon_name" ]; then
            ln -s "$addon_link_path" "$blender_dir/scripts/addons/$addon_name"
        fi
    done
    popd > /dev/null
done
IFS=$IFS_orig
