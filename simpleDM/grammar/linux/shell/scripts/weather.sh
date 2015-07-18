#!/bin/sh

if [[ $(ps -Al | grep rhythmbox) =~ 'rhythmbox' ]]
then
  rhythmbox-client --pause
fi
inxi -w -c 0
if [[ $(inxi -w -c 0) =~ 'Weather:' ]]
then
  inxi -w -c 0 | awk '{print $5, "Selsius", $8 $9}' | festival --tts # using phonetic spelling for Celcius
fi

if [[ $(ps -Al | grep rhythmbox) =~ 'rhythmbox' ]]
then
  rhythmbox-client --play
fi
