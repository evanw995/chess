#!/bin/bash

export PORT=5105
export MIX_ENV=prod
export GIT_PATH=/home/chess/src/chess

PWD=`pwd`
if [ $PWD != $GIT_PATH ]; then
	echo "Error: Must check out git repo to $GIT_PATH"
	echo " Current directory is $PWD"
	exit 1
fi

if [ $USER != "chess" ]; then
	echo "Error: must run as user 'chess'"
	echo " Current user is $USER"
	exit 2
fi

mix deps.get
(cd assets && npm install)
(cd assets && ./node_modules/brunch/bin/brunch b -p)
mix phx.digest
mix release --env=prod

mkdir -p ~/www
mkdir -p ~/old

NOW=`date +%s`
if [ -d ~/www/chess ]; then
	echo mv ~/www/chess ~/old/$NOW
	mv ~/www/chess ~/old/$NOW
fi

mkdir -p ~/www/chess
REL_TAR=~/src/chess/_build/prod/rel/chess/releases/0.0.1/chess.tar.gz
(cd ~/www/chess && tar xzvf $REL_TAR)

crontab - <<CRONTAB
@reboot bash /home/chess/src/chess/start.sh
CRONTAB

#. start.sh