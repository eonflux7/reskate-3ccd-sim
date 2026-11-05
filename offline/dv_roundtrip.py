#!/usr/bin/env python3
"""Encode a clip with a real camcorder codec, using ffmpeg's dvvideo encoder."""
import argparse
import subprocess
import sys

# raster, sample aspect, frame rate, pixel format, interlaced
FORMATS = {
    "dvcprohd-720p": (960, 720, "4/3", "60000/1001", "yuv422p", False),
    "dvcprohd-1080i60": (1280, 1080, "3/2", "30000/1001", "yuv422p", True),
    "dvcprohd-1080i50": (1440, 1080, "4/3", "25", "yuv422p", True),
    "dv-ntsc": (720, 480, "8/9", "30000/1001", "yuv411p", True),
    "dv-pal": (720, 576, "16/15", "25", "yuv420p", True),
}


def command(source, target, name):
    width, height, sar, rate, pixels, interlaced = FORMATS[name]
    filters = f"fps={rate},scale={width}:{height}:flags=lanczos,setsar={sar},format={pixels}"
    args = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", source, "-vf", filters,
            "-c:v", "dvvideo"]
    if interlaced:
        args += ["-flags", "+ildct"]
    return args + ["-an", target]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source")
    parser.add_argument("target", help="output path, usually .mov")
    parser.add_argument("--format", choices=FORMATS, default="dvcprohd-720p")
    options = parser.parse_args()
    return subprocess.run(command(options.source, options.target, options.format)).returncode


if __name__ == "__main__":
    sys.exit(main())
