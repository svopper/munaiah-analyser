#!/bin/bash

function countActions() {
  local pwd="$(pwd)/$1"
  local workflows=$(find "$pwd" -type f \( -name "*.yml" -o -name "*.yaml" \))
  local count=$(echo "$workflows" | wc -l)
  echo "running script in $pwd"
  echo "workflows count: $count"
  echo ""
  for workflow in $workflows; do
    echo "counting actions in: $workflow"
    yq eval '.jobs.[].steps[].uses' $workflow | grep -Ev "null|---" > "$workflow.action_count.txt"
  done
}

function main() {
  if [ -n "$1" ];
  then
    countActions "$1"
  else
    echo 'no target folder provided'
  fi
} 

main "$@"