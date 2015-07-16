#!/bin/sh
rhythmbox-client --pause
rhythmbox-client --print-playing 

if [[ $(festival -v) =~ 'festival: Festival Speech Synthesis System:' ]]
then
  rhythmbox-client --print-playing | festival --tts
fi

rhythmbox-client --play
