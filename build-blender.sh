#!/bin/bash

branches=
root=$HOME/build/blender
reset=
reset_deps=
build_make_args=
deps_src=${root}/deps/src
deps_bin=${root}/deps/bin
temp_dir=/tmp/build-blender
git_stash_apply=
install_deps_path=https://raw.githubusercontent.com/johnakki/blender-misc-scripts/master/install_deps.sh
patch_array=(
    https://raw.githubusercontent.com/johnakki/blender-misc-scripts/master/GHOST_SystemX11.cpp.patch
)
out_dir=build_linux # TODO: either pass as a cmake arg to ensure it's not overriden, or find a way to get the build dir from cmake
clear_cmake_cache=y
# direct cmake to use dependencies built by install_deps.sh in some instances rather than those provided by the system
build_cmake_args_array=(
    ALEMBIC_ROOT_DIR=${deps_bin}/alembic
    BLOSC_INCLUDE_DIR=${deps_bin}/blosc
    OPENSUBDIV_ROOT_DIR=${deps_bin}/osd
    OPENVDB_ROOT_DIR=${deps_bin}/openvdb
    PYTHON_ROOT_DIR=${deps_bin}/python-3.6
    ALEMBIC_LIBRARY=${deps_bin}/alembic/lib/libAlembic.so
    BLOSC_LIBRARY=${deps_bin}/blosc/lib/libblosc.so
    OPENVDB_LIBRARY=${deps_bin}/openvdb/lib/libopenvdb.so
    WITH_CODEC_SNDFILE=ON
    PYTHON_VERSION=3.6
    WITH_OPENCOLORIO=ON
    WITH_CYCLES_OSL=ON
    WITH_LLVM=ON
    LLVM_VERSION=6.0.1
    # WITH_OPENSUBDIV=ON # not working in 2.8
    WITH_OPENVDB=ON
    WITH_OPENVDB_BLOSC=ON
    WITH_OPENCOLLADA=ON
    WITH_JACK=ON
    WITH_JACK_DYNLOAD=ON
    WITH_ALEMBIC=ON
    WITH_CODEC_FFMPEG=ON
    WITH_FFTW3=ON
    WITH_OPENCOLLADA=ON
    FFMPEG_LIBRARIES="'avformat;avcodec;avutil;avdevice;swscale;swresample;lzma;rt;theora;theoradec;theoraenc;vorbis;vorbisenc;vorbisfile;ogg;xvidcore;vpx;mp3lame;x264;openjpeg'"
    # OpenGL_GL_PREFERENCE=GLVND
    WITH_SYSTEM_GLEW=ON
    WITH_CXX11=ON
)
# build_cmake_args_array=() # TODO: quick-and-dirty way of diabling args above
build_cmake_args=
build_cmake_args1=
build_make_args=install # TODO: this copies python modules but they can be symlinked instead
# now using my fixed version of install_deps.sh. the --build packages have comments against them that they need to be compiled - bf need to determine if they are going to force compilation or not.
# the provided version of osl doesnt build with llvm601 because it is required to be at least c++11 compliant, which it isn't. the (much newer) version of osl in the arch repo works fine though.
build_deps_args="--no-confirm --with-all --build-openvdb --build-osd --build-alembic --ver-openvdb=5.1.0" #--build-osl
skip_deps=

while (( "$#" )); do
    case "$1" in
    "-full" ) # TODO: deprecate once i've figured out how to set/determine the build dir more robustly
        build_make_args+=full
        out_dir=build_linux_full
        ;;
    "-reset" )
        reset=y
        ;;
    "-resetdeps" | "-reset-deps" )
        reset_deps=y
        ;;
    "-list" | "-which" | "-builds" )
        ls -l "$root"
        exit 0
        ;;
    "-heads" | "-branches" )
        xdg-open "https://git.blender.org/gitweb/gitweb.cgi/blender.git/heads"
        exit 0
        ;;
    "-cmakearg" | "-cmake-arg")
        build_cmake_args+=$2
        shift
        ;;
    "-makearg" | "-make-arg")
        build_make_args+=$2
        shift
        ;;        
    "-skipdeps" | "-skip-deps")
        skip_deps=y
        ;;
    "-?" | "-help" )
        echo 'command line options'
        echo '-full \n\tuse the "full" make preset (defaults exclude cuda, osl etc)'
        echo '-reset | -reset-deps \n\tclear build directory and start over'
        echo '-resetdeps \n\tclear dependencies directory and start over'
        echo '-heads | -branches \n\tshow available branches'
        echo '-makearg | -make-arg \n\tmake argument, e.g. -makearg headless'
        echo '-cmakearg | -cmake-arg \n\tadditional cmake argument, e.g. -cmakearg -DPYTHON_VERSION=3.6'
        echo '[branch] \n\tname of branch to build (defaults to master)'
        exit 0
        ;;
    -* )
        echo parameter $1 was not understood. -? for help
        exit 1
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
echo reset_deps $reset_deps
echo build_make_args $build_make_args
echo out_dir $out_dir
echo branches $branches
for i in ${!build_cmake_args_array[*]}; do
    # printf "   %s\n" "${build_cmake_args_array[$i]}"
    build_cmake_args+="-D${build_cmake_args_array[$i]} "
    build_cmake_arg1s+="-D ${build_cmake_args_array[$i]} "
done
echo build_cmake_args $build_cmake_args

if [ -d $temp_dir ]; then
    sudo mkdir $temp_dir
    sudo chmod 777 $temp_dir
fi

if [ "$reset_deps" == "y" ]; then
    echo clearing dependencies
    rm -rf "$deps_src/*"
    rm -rf "$deps_bin/*"
fi

for branch in $branches; do
    echo branch $branch

    buildroot="$root/$branch"
    echo build_root $buildroot

    # TODO: prompt for confirmation before reset and cloning a branch which does not already exist locally
    
    if [ "$reset" == "y" ]; then
        echo clearing $buildroot
        rm -rf "$buildroot/*"
    fi
    # exit 1
    if [ -d "$buildroot/blender" ]; then
        cd "$buildroot/blender"
        nice git stash # stash and reapply local code changes # TODO: find out how to make a patch
        #nice make update
        nice git pull --rebase origin $branch
        nice git rebase skip
        nice git checkout $branch
        if [ "$git_stash_apply" == "y" ]; then
            nice git stash apply
        fi
        cd "${buildroot}/blender/source"
        nice git submodule foreach git stash
        nice git submodule foreach git pull --rebase origin master
        nice git submodule foreach git rebase skip
        nice git submodule foreach git checkout master
        if [ "$git_stash_apply" == "y" ]; then
            nice git submodule foreach git stash apply
        fi
    else
        mkdir -p "$buildroot"
        cd "$buildroot"
        nice git clone https://git.blender.org/blender.git -b $branch
        cd "$buildroot/blender/source"
        nice git submodule update --init --recursive
        nice git submodule foreach git checkout master
        nice git submodule foreach git pull --rebase origin master
    fi
    if [ ! -d "${root}/deps" ]; then
        mkdir "${root}/deps" 
    fi
    
    if [ ! "$skip_deps" == "y" ]; then
        # See https://developer.blender.org/T56540
        wget "$install_deps_path" -O "${buildroot}/blender/build_files/build_environment/install_deps_fixed.sh"
        chmod +x "${buildroot}/blender/build_files/build_environment/install_deps_fixed.sh"
        nice "${buildroot}/blender/build_files/build_environment/install_deps_fixed.sh" --tmp="$temp_dir" --source="$deps_src" --install="$deps_bin" --info="$buildroot" $build_deps_args
        #install_deps.sh doesn't install python module "requests" which causes cmake warning. not sure if it's actually needed
        sudo $deps_bin/python-3.6/bin/pip3 install requests
        #TODO: either scrape the cmake flags from ${buildroot}/BUILD_NOTES.txt or add code to it to emit the flags to a file
        rm "$buildroot/blender/build_files/build_environment/install_deps_fixed.sh" # TODO: this is horrible
    fi
    
    cd "${buildroot}/blender"
    for i in ${!patch_array[*]}; do
        wget ${patch_array[$i]} -O "${buildroot}/blender/patch${i}.patch"
        git apply "${buildroot}/blender/patch${i}.patch"
        rm "${buildroot}/blender/patch${i}.patch" # TODO: this is also horrible
    done
    
    if [ ! -d "${buildroot}/build_linux_full" ]; then
        mkdir -p "${buildroot}/build_linux_full"
    fi
    if [ ! -d "${buildroot}/build_linux" ]; then
        cd "${buildroot}"
        ln -s build_linux_full build_linux
    fi 
    if [ "$clear_cmake_cache" == "y" ] && [ -f "${buildroot}/build_linux_full/CMakeCache.txt" ]; then
        rm "${buildroot}/build_linux_full/CMakeCache.txt"
    fi
    
    cd "${buildroot}/build_linux_full"
    cmake $build_cmake_args ../blender
    nice make $build_make_args
    
    #cd "${buildroot}/blender"
    #BUILD_CMAKE_ARGS="$build_cmake_args" nice make $build_make_args

#    if [ -d "$buildroot/$out_dir/bin" ] && [[ `which xdg-open` ]]; then
#        xdg-open "$buildroot/$out_dir/bin/"
#    fi
    if [ -f "$buildroot/$out_dir/bin/blender" ]; then
        "$buildroot/$out_dir/bin/blender" &
    else
        echo build of $branch appears to have failed
    fi
done
