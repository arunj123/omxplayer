CFLAGS=-pipe -mfloat-abi=hard -mcpu=arm1176jzf-s -fomit-frame-pointer -mabi=aapcs-linux -mtune=arm1176jzf-s -mfpu=vfp -Wno-psabi -g
CFLAGS+=-std=c++2a -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS -DTARGET_POSIX -DTARGET_LINUX -fPIC -DPIC -D_REENTRANT -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -DHAVE_CMAKE_CONFIG -D__VIDEOCORE4__ -U_FORTIFY_SOURCE -Wall -DHAVE_OMXLIB -DUSE_EXTERNAL_FFMPEG  -DHAVE_LIBAVCODEC_AVCODEC_H -DHAVE_LIBAVUTIL_OPT_H -DHAVE_LIBAVUTIL_MEM_H -DHAVE_LIBAVUTIL_AVUTIL_H -DHAVE_LIBAVFORMAT_AVFORMAT_H -DHAVE_LIBAVFILTER_AVFILTER_H -DHAVE_LIBSWRESAMPLE_SWRESAMPLE_H -DOMX -DOMX_SKIP64BIT -ftree-vectorize -DUSE_EXTERNAL_OMX -DTARGET_RASPBERRY_PI -DUSE_EXTERNAL_LIBBCM_HOST

LDFLAGS=-L$(SDKSTAGE)/opt/vc/lib/
LDFLAGS+=-L./ -Lffmpeg_compiled/usr/local/lib/ -lc -lbrcmGLESv2 -lbrcmEGL -lbcm_host -lopenmaxil -lfreetype -lz -lasound

INCLUDES+=-I./ -Ilinux -Iffmpeg_compiled/usr/local/include/ -I /usr/include/dbus-1.0 -I /usr/lib/arm-linux-gnueabihf/dbus-1.0/include -I/usr/include/freetype2 -isystem$(SDKSTAGE)/opt/vc/include -isystem$(SDKSTAGE)/opt/vc/include/interface/vcos/pthreads

DIST ?= omxplayer-dist
STRIP ?= strip

SRC=	linux/XMemUtils.cpp \
		linux/OMXAlsa.cpp \
		utils/log.cpp \
		DynamicDll.cpp \
		utils/PCMRemap.cpp \
		utils/RegExp.cpp \
		OMXSubtitleTagSami.cpp \
		OMXOverlayCodecText.cpp \
		BitstreamConverter.cpp \
		linux/RBP.cpp \
		OMXThread.cpp \
		OMXReader.cpp \
		OMXStreamInfo.cpp \
		OMXAudioCodecOMX.cpp \
		OMXCore.cpp \
		OMXVideo.cpp \
		OMXAudio.cpp \
		OMXClock.cpp \
		File.cpp \
		OMXPlayerVideo.cpp \
		OMXPlayerAudio.cpp \
		OMXPlayerSubtitles.cpp \
		SubtitleRenderer.cpp \
		Unicode.cpp \
		Srt.cpp \
		KeyConfig.cpp \
		OMXControl.cpp \
		Keyboard.cpp \
		revision.cpp \

SRC_TEST = $(SRC) testmain.cpp

OBJS+=$(filter %.o,$(SRC:.cpp=.o))
OBJS_TEST+=$(filter %.o,$(SRC_TEST:.cpp=.o))

all: omxplayer.bin

%.o: %.cpp
	@rm -f $@ 
	$(CXX) $(CFLAGS) $(INCLUDES) -c $< -o $@ -Wno-deprecated-declarations

omxplayer.o: help.h keys.h

version:
	bash gen_version.sh > version.h 

omxplayer.bin: version omxplayer.a $(OBJS_TEST)
	$(CXX) $(LDFLAGS) -o omxplayer.bin testmain.o -lvchiq_arm -lvchostif -lvcos -ldbus-1 -lrt -lpthread -lavutil -lavcodec -lavformat -lswscale -lswresample -lpcre omxplayer.a
#$(STRIP) omxplayer.bin

help.h: README.md Makefile
	awk '/SYNOPSIS/{p=1;print;next} p&&/KEY BINDINGS/{p=0};p' $< \
	| sed -e '1,3 d' -e 's/^/"/' -e 's/$$/\\n"/' \
	> $@
keys.h: README.md Makefile
	awk '/KEY BINDINGS/{p=1;print;next} p&&/KEY CONFIG/{p=0};p' $< \
	| sed -e '1,3 d' -e 's/^/"/' -e 's/$$/\\n"/' \
	> $@

omxplayer.a: version $(OBJS)
	ar rvs omxplayer.a $(OBJS)

omxplayer.1: README.md
	sed -e '/DOWNLOADING/,/omxplayer-dist/ d; /DBUS/,$$ d' $< >MAN
	curl -F page=@MAN http://mantastic.herokuapp.com 2>/dev/null >$@

clean:
	for i in $(OBJS_TEST); do (if test -e "$$i"; then ( rm $$i ); fi ); done
	@rm -f omxplayer.old.log omxplayer.log
	@rm -f omxplayer.bin
	@rm -f omxplayer.a
	@rm -rf $(DIST)
	@rm -f omxplayer-dist.tar.gz

ffmpeg:
	@rm -rf ffmpeg
	make -f Makefile.ffmpeg
	make -f Makefile.ffmpeg install


