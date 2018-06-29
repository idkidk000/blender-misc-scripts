@echo off
setlocal enableextensions enabledelayedexpansion

set ffmpeg_path=
if defined ffmpeg_path set PATH=%ffmpeg_path%;%PATH%

::defaults
set sourcedir=c:\tmp\
set sourceext=png
set framerate=30
set filename=render
set fileext=mkv
set bitrate=50M
set preset=slow
set profile=high
set crf=4
set scale=
set passes=1
set threads=4
set overwrite=y
set select=y
set pause=y
set debug=n
set codec=libx264
set audio=

:parseargs
if not "%1"=="" (
	if "%1"=="-sourcedir" set sourcedir=%2
	if "%1"=="-sourceext" set sourceext=%2
	if "%1"=="-framerate" set framerate=%2
	if "%1"=="-filename" set filename=%2
	if "%1"=="-fileext" set fileext=%2
	if "%1"=="-filext" set fileext=%2
	if "%1"=="-bitrate" set bitrate=%2
	if "%1"=="-preset" set preset=%2
	if "%1"=="-profile" set profile=%2
	if "%1"=="-crf" set crf=%2
	if "%1"=="-scale" set scale=%2
	if "%1"=="-passes" set passes=%2
	if "%1"=="-threads" set threads=%2
	if "%1"=="-overwrite" set overwrite=%2
	if "%1"=="-select" set select=%2
	if "%1"=="-pause" set pause=%2
	if "%1"=="-debug" set debug=%2
	if "%1"=="-audio" set audio=%2
	
	if "%1"=="-28" set sourcedir=c:\tmp28\
	if "%1"=="-4c" (
		set fileext=webm
		set bitrate=4M
		set crf=10
		set passes=2
	)
	
	shift
	goto :parseargs
)

set profile_arg=-profile:v %profile%

if "%fileext%"=="mkv" set codec=libx264
if "%fileext%"=="avi" set codec=libx264
if "%fileext%"=="mp4" set codec=mpeg4
if "%fileext%"=="webm" (
	set codec=libvpx
	echo profile ignored for webm
	set profile_arg= 
)

if defined scale (
	set scale_arg=-vf scale=-1:%scale%
) else (
	set scale_arg= 
)

if "%overwrite%"=="y" (
	set overwrite_arg=-y
) else (
	set overwrite_arg= 
)

set bitrate_arg=-b:v %bitrate%

if "%passes%"=="1" (
	set crf_arg=-crf %crf%
	set passlogfile_arg= 
) else (
	if "%debug%"=="y" echo crf ignored for 2pass
	set crf_arg= 
	set passlogfile_arg=-passlogfile %filename%
)

if defined audio (
	set audio_arg=-i %audio%
) else (
	set audio_arg= 
)

pushd "%sourcedir%"

for /l %%a in (1,1,%passes%) do (
	if "%%a"=="%passes%" (
		set outfile=%filename%.%fileext%
	) else (
		set outfile=nul.%fileext%
	)
	set command=ffmpeg -framerate %framerate% -i %%04d.%sourceext% %audio_arg% -c:v %codec% -preset %preset% %profile_arg% %scale_arg% %bitrate_arg% -pix_fmt yuv420p -auto-alt-ref 0 -threads %threads% -speed 0 %crf_arg% -deadline best -pass %%a %passlogfile_arg% %overwrite_arg% !outfile!
	if "%debug%"=="y" echo !command!
	!command!
)
if "%select%"=="y" explorer.exe /select,"%sourcedir%\%filename%.%fileext%"
if "%pause%"=="y" pause