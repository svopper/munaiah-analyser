#!/bin/bash
mkdir actions_out
for file in `find ../out -type f \( -name "*.yml" -o -name "*.yaml" \)`; do
  fileName=`echo $file | cut -d / -f 3-`
  count=`yq eval '.jobs.[].steps[].uses' $file | grep -Ev "null|---" | wc -l`
  echo $fileName $count >> ../actions_out/actions_count_by_file.txt
done
