#!/bin/bash

export ciop_job_include="/usr/lib/ciop/libexec/ciop-functions.sh"
source ./test_common.sh
source ../main/app-resources/aux/lib/functions.sh

test_bash_n_run() {

  bash -n ../main/app-resources/aux/run
  res=$?
  assertEquals "bash -n validation failed" \
  "0" "${res}"
}

test_bash_n_lib() {

  bash -n ../main/app-resources/aux/lib/functions.sh
  res=$?
  assertEquals "bash -n validation failed" \
  "0" "${res}"

}

test_get_aux_1() {

  local atom="https://catalog.terradue.com/envisat/search?uid=ASA_IM__0CNPDE20100328_175019_000000162088_00084_42222_9504.N1"
  local osd="https://catalog.terradue.com/envisat/search"
  local series="ASA_CON_AX"
  
  tmp_file=$( mktemp /tmp/test_get_aux.XXXXXX )
  getAUXref ${atom} ${osd} ${series} > ${tmp_file}
   
  diff ${tmp_file} ./tests.d/artifacts/get_aux_artifact_1
  res=$?

  assertEquals "Expectations not met for ASA_CON_AX" \
  "0" "${res}" 

  rm -f ${tmp_file} 
  
}

test_get_aux_2() {

  local atom="https://catalog.terradue.com/envisat/search?uid=ASA_IM__0CNPDE20100328_175019_000000162088_00084_42222_9504.N2"
  local osd="https://catalog.terradue.com/envisat/search"
  local series="ASA_CON_AX"

  getAUXref ${atom} ${osd} ${series} > /dev/null 
  res=$?
  
  assertEquals "Got wrong error code" \
  "10" "${res}"

}

test_get_aux_3() {

  local atom="https://catalog.terradue.com/envisat/search?uid=ASA_IM__0CNPDE20100328_175019_000000162088_00084_42222_9504.N1"
  local osd="https://catalog.terradue.com/envisat/search"
  local series="ASA_CON_XX"

  getAUXref ${atom} ${osd} ${series} > /dev/null
  res=$?

  assertEquals "Got wrong error code" \
  "30" "${res}"

}


test_run_aux() {

  function ciop-publish() {
    cat 
  }

  local atom="https://catalog.terradue.com/envisat/search?uid=ASA_IM__0CNPDE20100328_175019_000000162088_00084_42222_9504.N1"  
  local osd="https://catalog.terradue.com/envisat/search"

  tmp_file=$( mktemp /tmp/test_get_aux.XXXXXX )
  runAux "${atom}" "${osd}" > ${tmp_file}

  diff ${tmp_file} ./tests.d/artifacts/get_aux_artifact_2
  res=$?

  assertEquals "Expectations not met for ASA_CON_AX" \
  "0" "${res}"

  rm -f ${tmp_file}

}


. ${SHUNIT2_HOME}/shunit2
