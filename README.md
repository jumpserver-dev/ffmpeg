# FFmpeg

Prebuilt FFmpeg for JumpServer web recordings, extracted from Koko's base image.

- FFmpeg 7.1.5 on Debian trixie.
- Platforms: `linux/amd64` and `linux/arm64`.
- JPEG frame input, concat demuxing, scaling, H.264 encoding with libx264, and MP4 output.
- Binary: `/usr/local/bin/ffmpeg`.

FFmpeg libraries are statically linked. The binary dynamically links against
libx264, libc, and libm. Images that copy the binary should use Debian trixie and
provide `libx264-164`, as Koko's runtime image does.

The image is published to `ghcr.io/jumpserver-dev/ffmpeg`.
Tags follow `<ffmpeg-version>-<debian-release>-build-<run-number>.<run-attempt>`,
using GitHub Actions run numbers and attempts to distinguish rebuilds.

The [build workflow](.github/workflows/build-image.yml) publishes both platforms
when the Dockerfile or workflow changes on `main`, or when run manually.
When changing the FFmpeg version, update its download URLs and SHA-256 checksum
in the Dockerfile and `FFMPEG_VERSION` in the workflow together. Update Koko's
`Dockerfile-base` to consume the new tag after it has been published.
