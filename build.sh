#!/bin/bash

# build .whl file in dist/
python2 setup.py bdist_wheel

. ./clean.sh

# EOF
