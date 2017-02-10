set -x

# define the exit codes
SUCCESS=0
ERR_AUX=2
ERR_VOR=4
#export HOME=/tmp
# add a trap to exit gracefully
function cleanExit ()
{

  local retval=$?
  local msg=""
  case "${retval}" in
    ${SUCCESS}) msg="Processing successfully concluded";;
    ${ERR_AUX}) msg="Failed to retrieve reference to auxiliary data";;
    ${ERR_VOR}) msg="Failed to retrieve reference to orbital data";;
    *) msg="Unknown error";;
  esac

  [ "${retval}" != "0" ] && ciop-log "ERROR" "Error ${retval} - ${msg}, processing aborted" || ciop-log "INFO" "${msg}"
  exit ${retval}
}

trap cleanExit EXIT


function getAUXref() {

  local atom=$1
  local ods=$2
  local series=$3 
 
  startdate=$( opensearch-client ${atom} startdate | tr -d "Z")
  [ -z "${startdate}" ] && exit ${ERR_NOSTARTDATE}
  
  stopdate=$( opensearch-client ${atom} enddate | tr -d "Z")
  [ -z "${stopdate}" ] && exit ${ERR_NOSTOPDATE}
  
  opensearch-client -p "pi=${series}" -p "time:start=${startdate}" -p "time:end=${stopdate}" ${ods}

}

function runAux() {

  local input=$1
	
  for aux in ASA_CON_AX ASA_INS_AX ASA_XCA_AX ASA_XCH_AX
  do
    ciop-log "INFO" "Getting a reference to ${aux}"
		
      for url in $( getAUXref $input $cat_osd_root $aux )
      do
        ciop-log "INFO" "the url is ${url}"
 			
        #pass the aux reference to the next node
	[ "${url}" != "" ] && echo "aux=${url}" | ciop-publish -s || exit ${ERR_AUX}
      done
		
  done
	
  # DOR_VOR_AX
  ciop-log "INFO" "Getting a reference to DOR_VOR_AX"
  ref=$( getAUXref $input $cat_osd_root DOR_VOR_AX )
		
  #pass the aux reference to the next node
  [ "${ref}" != "" ] && echo "vor=${ref}" | ciop-publish -s || exit ${ERR_VOR}
		
  # pass the SAR reference to the next node
  echo "sar=${input}" | ciop-publish -s
 
}

function main() {

  local master=$1

  # get the catalogue access point
  cat_osd_root="$( ciop-getparam aux_catalogue )"

  slave="$( ciop-getparam slave )"
  ciop-log "INFO" "Slave: ${slave}"

  runAux ${slave}
  resSlave=$?

  exit ${resSlave}

  ciop-log "INFO" "Master: ${master}"

  runAux ${master}
  resMaster=$?

  [ "${resMaster}" -ne 0 ] && exit ${resMaster}

}
