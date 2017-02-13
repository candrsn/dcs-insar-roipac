
# define the exit codes
SUCCESS=0
ERR_NOSTARTDATE=10
ERR_NOENDDATE=11
ERR_AUX=10
ERR_VOR=20
ERR_AUXREF=30

# add a trap to exit gracefully
function cleanExit () {

  local retval=$?
  local msg=""
  case "${retval}" in
    ${SUCCESS}) msg="Processing successfully concluded";;
    ${ERR_NOSTARTDATE}) err="Failed to retrieve auxiliary/orbital data start date";;
    ${ERR_NOENDDATE}) err="Failed to retrieve auxiliary/orbital data end date";;
    ${ERR_AUXREF}) msg="Failed to retrieve reference to auxiliary data";;
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
  local osd=$2
  local series=$3 
 
  startdate=$( opensearch-client ${atom} startdate | tr -d "Z")
  [ -z "${startdate}" ] && return ${ERR_NOSTARTDATE}
  
  stopdate=$( opensearch-client ${atom} enddate | tr -d "Z")
  [ -z "${stopdate}" ] && return ${ERR_NOENDDATE}
  
  ref="$( opensearch-client -p "pi=${series}" -p "time:start=${startdate}" -p "time:end=${stopdate}" ${osd} )" 
  [ -z "${ref}" ] && return ${ERR_AUXREF}
  
  echo ${ref}

}

function runAux() {

  local sar=$1
  local osd=$2	

  for aux in ASA_CON_AX ASA_INS_AX ASA_XCA_AX ASA_XCH_AX
  do
    ciop-log "INFO" "Getting a catalogue reference to ${aux}"
    
    ref=$( getAUXref ${sar} ${osd} ${aux} )		
    [ -z "${ref}" ] && return ${ERR_AUXREF}

    for url in ${ref}
    do
      ciop-log "INFO" "the url is ${url}"
 			
      #pass the aux reference to the next node
      [ "${url}" != "" ] && echo "aux=${url}" | ciop-publish -s 
    done
		
  done
	
  # DOR_VOR_AX
  ciop-log "INFO" "Getting a reference to DOR_VOR_AX"
  ref=$( getAUXref ${sar} ${osd} DOR_VOR_AX )
  [ -z "${ref}" ] && return ${ERR_VOR} || echo "vor=${ref}" | ciop-publish -s 		
		
  # pass the SAR reference to the next node
  echo "sar=${sar}" | ciop-publish -s
 
}

function main() {

  local master=$1

  # get the catalogue access point
  osd="$( ciop-getparam aux_catalogue )"

  slave="$( ciop-getparam slave )"
  ciop-log "INFO" "Slave: ${slave}"

  runAux "${slave}" "${osd}" || exit $?

  ciop-log "INFO" "Master: ${master}"
  runAux "${master}" "${osd}" || exit ${resMaster}

}
