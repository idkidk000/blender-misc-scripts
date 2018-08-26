#!/bin/bash

branches=
root=$HOME/build/blender
reset=
make_opts=
out_dir=build_linux


while (( "$#" )); do
    case "$1" in
    "-full" )
        make_opts=full
        out_dir=build_linux_full
        ;;
    "-reset" )
        reset=y
        ;;
    "-list" | "-which" | "-builds" )
        ls -l "$root"
        exit 0
        ;;
    "-heads" | "-branches" )
        xdg-open "https://git.blender.org/gitweb/gitweb.cgi/blender.git/heads"
        exit 0
        ;;
    "-?" | "-help" )
        echo 'command line options'
        echo '-full also build cycles cuda support'
        echo '-reset clear build directory and start over'
        echo '-heads | -branches show available branches'
        echo '[branch name to build] (defaults to master)'
        exit 0
        ;;
    *)
        branches="$branches $1"
        ;;
    esac
    shift
done

if [ -z "$branches" ]; then
    branches=master
fi

echo reset $reset
echo make_opts $make_opts
echo out_dir $out_dir
echo branches $branches


for branch in $branches; do
    echo branch $branch

    buildroot="$root/$branch"
    echo build_root $buildroot

    if [ ! -z $reset ]; then
        echo clearing $buildroot
        rm -rf "$buildroot/*"
    fi
    # exit 1
    if [ -d "$buildroot/blender" ]; then
        cd "$buildroot/blender"
        nice git stash
        nice make update
        # stash and reapply local changes - https://developer.blender.org/T50961
        # changed files will need to be added manually - git add path/to/file
        nice git stash apply
    else
        mkdir -p "$buildroot"
        cd "$buildroot"
        nice git clone https://git.blender.org/blender.git -b $branch
        cd "$buildroot/blender"
        nice git submodule update --init --recursive
        nice git submodule foreach git checkout master
        nice git submodule foreach git pull --rebase origin master
        #tries to compile a really old version of llvm instead of just using the current version from the arch repo
        if [[ ! `pacman -Q clang` ]]; then
            sudo pacman -S clang
        fi
        #doesn't like the openvdb in the arch repo
        sudo nice "$buildroot/blender/build_files/build_environment/install_deps.sh" --skip-llvm --build-openvdb
    fi

    cd "$buildroot/blender"
    nice make $make_opts
    xdg-open "$buildroot/$out_dir/bin/"
    if [ -f "$buildroot/$out_dir/bin/blender" ]; then
        "$buildroot/$out_dir/bin/blender" &
    else
        echo build of $branch appears to have failed
    fi
done
