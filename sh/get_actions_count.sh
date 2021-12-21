#!/bin/bash
if [ ! -f ../actions_out/actions_raw.txt ]; then
  ./get_actions.sh
fi
sort ../actions_out/actions_raw.txt | uniq -c | sort -bgr > ../actions_out/actions_count.txt
