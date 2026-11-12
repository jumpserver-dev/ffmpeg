FROM debian:trixie-slim AS build
ARG APT_MIRROR=http://deb.debian.org
RUN set -ex \
    && sed -i "s@http://.*.debian.org@${APT_MIRROR}@g" /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential pkg-config nasm libx264-dev xz-utils ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Debian mirrors the byte-identical upstream archive on its CDN.
RUN set -ex \
    && for url in \
        https://deb.debian.org/debian/pool/main/f/ffmpeg/ffmpeg_7.1.5.orig.tar.xz \
        https://ffmpeg.org/releases/ffmpeg-7.1.5.tar.xz; do \
        if curl --fail --location --retry 5 --retry-all-errors \
            --connect-timeout 30 --max-time 180 --retry-max-time 600 \
            --output /tmp/ffmpeg.tar.xz "${url}" \
            && echo 'de668509caf9e35e3cd162473441fdb29538c6d96ed080292b3cf9e6fc5d558f  /tmp/ffmpeg.tar.xz' \
                | sha256sum -c -; then \
            exit 0; \
        fi; \
    done \
    && exit 1

# Web recordings only need JPEG frames, scaling, H.264 encoding and MP4 output.
# FFmpeg libraries are static; libx264, libc and libm remain dynamic.
RUN set -ex \
    && mkdir /tmp/ffmpeg \
    && tar -xf /tmp/ffmpeg.tar.xz -C /tmp/ffmpeg --strip-components=1 \
    && cd /tmp/ffmpeg \
    && ./configure --disable-everything --disable-autodetect --disable-network \
        --disable-doc --disable-debug --disable-ffplay --disable-ffprobe \
        --disable-avdevice --disable-swresample --disable-shared --enable-static \
        --enable-small --enable-ffmpeg --enable-gpl --enable-libx264 \
        --enable-protocol=file --enable-demuxer=concat,image2 \
        --enable-parser=mjpeg --enable-decoder=mjpeg --enable-encoder=libx264 \
        --enable-muxer=mp4 --enable-filter=scale,format,null --enable-swscale \
    && make -j2 ffmpeg \
    && install -m 755 ffmpeg /usr/local/bin/ffmpeg \
    && strip /usr/local/bin/ffmpeg

FROM debian:trixie-slim

LABEL org.opencontainers.image.source=https://github.com/jumpserver-dev/ffmpeg
LABEL org.opencontainers.image.description="Prebuilt FFmpeg for JumpServer web recordings"

COPY --from=build /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends libx264-164 \
    && rm -rf /var/lib/apt/lists/* \
    && ffmpeg -hide_banner -version

ENTRYPOINT ["/usr/local/bin/ffmpeg"]
CMD ["-hide_banner", "-version"]
