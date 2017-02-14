#!/bin/bash

export ciop_job_include="/usr/lib/ciop/libexec/ciop-functions.sh"
source ./test_common.sh

test_bash_n_run()
{

  bash -n ../main/app-resources/roipac/run
  res=$?
  assertEquals "bash -n validation of roipac/run failed" \
  "0" "${res}"
}

test_bash_n_lib()
{

  bash -n ../main/app-resources/roipac/lib/functions.sh
  res=$?
  assertEquals "bash -n validation of roipac/lib/functions.sh failed" \
  "0" "${res}"
}

. ${SHUNIT2_HOME}/shunit2
