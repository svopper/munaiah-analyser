#!/bin/bash
mkdir actions_out
for file in `find ../out -type f \( -name "*.yml" -o -name "*.yaml" \)`; do
  yq eval '.jobs.[].steps[].uses' $file | grep -Ev "null|---"  # >> ../actions_out/actions_raw2.txt
done
