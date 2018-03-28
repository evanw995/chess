#!/bin/bash

export PORT=5105

cd ~/www/chess
./bin/chess stop || true
./bin/chess start