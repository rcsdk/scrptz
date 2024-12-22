#!/bin/bash

# Conditional script
if ./script1.sh; then
  ./script2.sh
  if ./script2.sh; then
    ./script3.sh
  fi
fi
