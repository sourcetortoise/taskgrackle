#!/bin/sh
# Call this with a cronjob:
# 0 9-17 *   *   *   XDG_RUNTIME_DIR=/run/user/$(id -u) /home/pi/taskgrackle/vocalization.sh
#
# Every hour from 9-5, plays a random grackle sound from sound/ directory, if:
#  - the squawkblocker isn't in place
#  - it's been more than X hours since last interaction
#    - set X in `data/hours_til.grackle`

if [ ! -f "data/squawkblocker.txt" ]; then
  if [ -f "data/last.txt" ]; then

    LAST="$(cat data/last.txt)"
    NOW="$( date +%s )"
    HOURS_TIL_VOCAL="$(cat data/hours_til.grackle)"

    if [ $(($NOW-$LAST)) -gt $((60 * 60 * $HOURS_TIL_VOCAL)) ]; then
      # randomize sound files & play last one
      ls sound |sort -R |tail -1 |while read file; do
        cvlc --play-and-exit sound/$file
      done
    fi
  fi
fi
