#!/bin/sh

rake compile &&  bin/pymd < test.md > test.py && cat test.py
