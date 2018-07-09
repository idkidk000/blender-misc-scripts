#!/bin/bash

# defaults
sourcedir=/tmp
sourceext=png
framerate=30
filename=render
fileext=mkv
bitrate=50M
preset=slow
profile=high
crf=4
scale=0
passes=1
threads=4
overwrite=y
debug=n
codec=libx264
audio=""
loop=1
audiofadein=0.1
audiofadeout=1.5
audiostart=0
videohold=1
videofadein=0.1
videofadeout=1
open=y

while (( "$#" )); do
    case $1 in
        -?|/?|-help)
            echo 'command line options:'
            echo '-sourcedir'
            echo '-sourceext'
            echo '-framerate'
            echo '-filename'
            echo '-fileext'
            echo '-bitrate'
            echo '-preset (TODO: list)'
            echo '-profile (TODO: list)'
            echo '-crf (1-64. use -lossless instead of 0)'
            echo '-scale (y resolution)'
            echo '-passes (1/2)'
            echo '-threads'
            echo '-overwrite (y/n)'
            echo '-debug (y/n)'
            echo '-audio (file path)'
            echo '-audiofadein / -afadein (seconds) e.g. 0.5'
            echo '-audiofadeout / -afadeout (seconds) e.g. 0.5'
            echo '-audiostart / -astart (seconds) e.g. 0.5'
            echo '-videofadein / -vfadein (seconds) e.g. 0.5'
            echo '-videofadeout / -vfadeout (seconds) e.g. 0.5'
            echo '-videohold /-vhold (seconds) e.g. 0.5'
            echo '-loop (count)'
            echo '-open (y/n)'
            echo '-28'
            echo '-doc'
            echo '-4c'
            echo '-lossless'
            exit 1
            ;;
        -sourcedir)
            sourcedir=$2
            ;;
        -sourceext)
            sourceext=$2
            ;;
        -framerate)
            framerate=$2
            ;;
        -filename)
            filename=$2
            ;;
        -fileext|filext)
            fileext=$2
            ;;
        -bitrate)
            bitrate=$2
            ;;
        -preset)
            preset=$2
            ;;
        -profile)
            profile=$2
            ;;
        -crf)
            crf=$2
            ;;
        -scale)
            scale=$2
            ;;
        -passes)
            passes=$2
            ;;
        -threads)
            threads=$2
            ;;
        -overwrite)
            overwrite=$2
            ;;
        -debug)
            debug=$2
            ;;
        -audio)
            audio=$2
            ;;
        -audiofadein|-afadein)
            audiofadein=$2
            ;;
        -audiofadeout|-afadeout)
            audiofadeout=$2
            ;;
        -audiostart|-astart)
            audiostart=$2
            ;;
        -videofadein|-vfadein)
            videofadein=$2
            ;;
        -videofadeout|-vfadeout)
            videofadeout=$2
            ;;
        -videohold|-vhold)
            videohold=$2
            ;;
        -loop)
            loop=$2
            ;;            
        "-28")
            sourcedir=/tmp/28
            ;;
        -doc)
            sourcedir=$HOME/Documents
            ;;
        "-4c")
            fileext=webm
            bitrate=4M
            crf=10
            passes=2
            ;;
        "-lossless")
            crf=0
            profile=""
            ;;
    esac
    shift
done

if [ "$videohold"!="0" ]; then
    #this is awful but i can't get the concat filter to work    
    mkdir /tmp/ffencode-tmp
    rm /tmp/ffencode-tmp/*
    cp $sourcedir/*.$sourceext /tmp/ffencode-tmp/
    videoholdframes=$(echo "$videohold * $framerate" | bc)
    framecount=$(ls -l $sourcedir/*.$sourceext | wc -l)
    totalframecount=$(echo "$framecount + $videoholdframes" | bc)
    holdframefile=$sourcedir/$(printf "%04d" $framecount).$sourceext
    
    if [ ""=%debug="y" ]; then
        echo "videoholdframes $videoholdframes"
        echo "framecount $framecount"
        echo "totalframecount $totalframecount"
        echo "holdframefile $holdframefile"
    fi
    
    for ((i=$framecount;i<=$totalframecount;i++)); do
        cp $holdframefile /tmp/ffencode-tmp/$(printf "%04d" $i).$sourceext
    done
    sourcedir=/tmp/ffencode-tmp
fi
framecount=$(ls -l $sourcedir/*.$sourceext | wc -l)
duration=$(echo "$framecount / $framerate" | bc)

if [ "$debug"=="y" ]; then
    echo "sourcedir $sourcedir"
    echo "sourceext $sourceext"
    echo "framerate $framerate"
    echo "filename $filename"
    echo "fileext $fileext"
    echo "bitrate $bitrate"
    echo "preset $preset"
    echo "profile $profile"
    echo "crf $crf"
    echo "scale $scale"
    echo "passes $passes"
    echo "threads $threads"
    echo "overwrite $overwrite"
    echo "debug $debug"
    echo "codec $codec"
    echo "audio $audio"
    echo "audiofadein $audiofadein"
    echo "audiofadeout $audiofadeout"
    echo "audiostart $audiostart"
    echo "videofadein $videofadein"
    echo "videofadeout $videofadeout"   
    echo "videohold $videohold"   
    echo "loop $loop"
    echo "framecount $framecount"
    echo "duration duration"    
fi

case "$filext" in
    mkv|avi)
        codec=libx264
        ;;
    mp4)
        codec=mpeg4
        ;;
    webm)
        codec=libvpx
        profile_arg=""
        ;;
esac

if [ $scale -gt 0 ]; then
    scale_arg="-vf scale=-1:$scale"
else
    scale_arg=""
fi

if [ "$overwrite"=="y" ]; then
    overwrite_arg="-y"
else
    overwrite_arg=""
fi

bitrate_arg="-b:v $bitrate"

if [ @$passes==1 ]; then
    crf_arg="-crf $crf"
    passlogfile_arg=""
else
    crf_arg=""
    passlogfile_arg="-passlogfile $filename"
fi

if [ -z "$audio" ]; then
    audio_arg=""
else
    audiofadetotal=$(echo "$audiofadein + $audiofadeout" | bc)
    if (( $(echo "$audiofadetotal > $duration" | bc -l) )); then
        echo 'audio fade duration is longer than source'
        audiofadein=0
        audiofadeout=0
    else
        audiofadeoutstart=$(echo "$duration - $audiofadeout" | bc)
    fi
    #convert seconds to timestamps
    #audiostarttime=$(date -u -d @${audiostart} +"%T.%3N")
    #audiofadeintime=$(date -u -d @${audiofadein} +"%T.%3N")
    #audiofadeoutstarttime=$(date -u -d @${audiofadeoutstart} +"%T.%3N")
    #audiofadeouttime=$(date -u -d @${audiofadeout} +"%T.%3N")
    #audio_arg="-ss $audiostarttime -i $audio -filter_complex afade=t=in:st=0:d=${audiofadeintime},afade=t=out:st=${audiofadeoutstarttime}:d=${audiofadeouttime}"
    audio_arg="-ss $audiostart -i $audio -filter_complex afade=t=in:st=0:d=${audiofadein},afade=t=out:st=${audiofadeoutstart}:d=${audiofadeout}"
fi

if [ @$videofadein!=0 ] || [ @$videofadeout!=0 ] || [ @$videohold!=0 ]; then
    videofadetotal=$(echo "$videofadein + $videofadeout" | bc)
    if (( $(echo "$videofadetotal > $duration" | bc -l) )); then
        echo 'video fade duration is longer than source'
        videofadein=0
        videofadeout=0
    else
        videofadeoutstart=$(echo "$duration - $videofadeout" | bc)
    fi
    #convert seconds to timestamps
    #videofadeintime=$(date -u -d @${videofadein} +"%T.%3N")
    #videofadeoutstarttime=$(date -u -d @${videofadeoutstart} +"%T.%3N")
    #videofadeouttime=$(date -u -d @${videofadeout} +"%T.%3N")
    #videofilter_arg="-filter_complex fade=t=in:st=0:d=${videofadeintime},fade=t=out:st=${videofadeoutstarttime}:d=${videofadeouttime}"
    videofilter_arg="-filter_complex fade=t=in:st=0:d=${videofadein},fade=t=out:st=${videofadeoutstart}:d=${videofadeout}"
else
    videofilter_arg=""
fi

if [ $loop -gt 1 ]; then
    loop_arg="-loop $loop"
else
    loop_arg=""
fi

if [ -z "$profile" ]; then
    profile_arg=""
else
    profile_arg="-profile:v $profile"
fi

pushd $sourcedir

for ((i=1;i<=$passes;i++)); do
    if [ $i -eq $passes ]; then
        outfile="$filename.$fileext"
    else
        outfile=/dev/null
    fi
    command="ffmpeg -loglevel error -stats -framerate $framerate -i %04d.$sourceext $videofilter_arg $audio_arg -c:v $codec -preset $preset $profile_arg $scale_arg $bitrate_arg $loop_arg -pix_fmt yuv420p -auto-alt-ref 0 -threads $threads -speed 0 $crf_arg -deadline best -pass $i $passlogfile_arg -shortest $overwrite_arg $outfile"
    if [ "$debug"=="y" ]; then
        echo $command
    fi
    $command
done

if [ "$open"=="y" ]; then
    xdg-open "$outfile"
fi
