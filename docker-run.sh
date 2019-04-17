#!/bin/sh

sudo docker run -it \
    -e DISPLAY=unix$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    g4bl:3.06
