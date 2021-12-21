#!/bin/sh

XP_RUNNERS_URL=https://baltocdn.com/xp-framework/xp-runners/distribution/downloads/e/entrypoint/xp-run-8.5.1.sh

case $1 in
  install)
    printf "\033[33;1mInstalling XP Runners\033[0m\n"
    echo $XP_RUNNERS_URL
    curl -SL $XP_RUNNERS_URL > xp-run
    echo

    printf "\033[33;1mRunning Composer\033[0m\n"
    composer install
  ;;

  run-tests)
    echo test.xar > test.pth
    result=0
    for file in `ls -1 src/test/config/unittest/*.ini`; do
      printf "\033[33;1mTesting %s\033[0m\n" $file
      sh xp-run xp.unittest.Runner $file || result=1
      echo
    done
    exit $result
  ;;
esac