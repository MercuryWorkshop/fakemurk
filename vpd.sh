#!/bin/bash
# vpd.sh v2.0.0
# made by r58Playz
# version history:
# 2.0.0 - complete rewrite lol
# 1.0.0 - implemented basic functionality


##########
# Config #
##########
# VPD options file path. Used for RO and RW vpd options.
VPDOPTIONSFILEPATH="/mnt/stateful_partition/mwtrollinggoogleforfakemurk_VPD"
#VPDOPTIONSFILEPATH="mwtrollinggoogleforfakemurk_VPD"


##############################################################################################################################################################################
#                               YOU SHOULD NOT NEED TO MODIFY THIS PART OF THE SCRIPT IF YOU ARE JUST A CONSUMER! BELOW IS THE INTERNAL LOGIC!                               #
##############################################################################################################################################################################
pname="vpd.sh"

help() {
    echo "${pname} made by r58Playz"
    echo "Usage: ${pname} [OPTION] ..."
    echo "   OPTIONs include:"
    echo "      -h               This help page and version."
    echo "      -f <filename>    The output file name."
    echo "      -E <address>     EPS base address (default: 0x240000)."
    echo "      -S <key=file>    To add/change a string value, reading its"
    echo "                       base64 contents from a file."
    echo "      -s <key=value>   To add/change a string value."
    echo "      -p <pad length>  Pad if length is shorter."
    echo "      -i <partition>   Specify VPD partition name in fmap."
    echo "      -l               List content in the file."
    echo "      --sh             Dump content for shell script."
    echo "      --raw            Parse from a raw blob (without headers)."
    echo "      -0/--null-terminated"
    echo "                       Dump content in null terminate format."
    echo "      -O               Overwrite and re-format VPD partition."
    echo "      -g <key>         Print value string only."
    echo "      -d <key>         Delete a key."
    echo ""
    echo "   Notes:"
    echo "      You can specify multiple -s and -d. However, vpd always"
    echo "         applies -s first, then -d."
    echo "      -g and -l must be mutually exclusive."
}

# parse the command-line
GETOPTOUT=$(getopt -o "hf:E:s:S:p:i:lOg:d:0" --long "help,file:,epsbase:,string:,base64file:,pad:,partition:,list,overwrite,filter:,delete:,null-terminated,sh,raw" -n "${pname}" -- "$@")
if [ $? -ne 0 ]; then
    help >&2
    exit 1;
fi

eval set -- "$GETOPTOUT"
unset GETOPTOUT

# load vpd options
touch "${VPDOPTIONSFILEPATH}"
chmod a+rw "${VPDOPTIONSFILEPATH}"
source "${VPDOPTIONSFILEPATH}"

FLAG_partition="RO_VPD"
FLAG_getvalue=""
FLAG_shouldlist=0
FLAG_getlistmutuallyexclusive=0

getvalue() {
    if [[ -n "${1}" ]]; then
        echo "${!1}"
    else
        echo "findString(): Vpd data '$1' was not found." >&2
    fi
}

list() {
    if [[ $1 == "RO_VPD" ]]; then
        echo "${ROVPDFULL}"
    elif [[ $1 == "RW_VPD" ]]; then
        echo "${RWVPDFULL}"
    else
        echo "[ERROR] The VPD partition [${FLAG_partition}] is not found." >&2
        exit 1
    fi
}


addoreditvalueinreads() {
    key="${1}"
    value="${2}"
    containsvalue="${3}"
    partition="${4}"
    if [[ ${containsvalue} -eq 0 ]]; then
        sed -i "s/\"${key}\".*/\"${key}\"=\"${value}\"/" ${VPDOPTIONSFILEPATH}
    else
        if [[ ${partition} == "RO_VPD" ]]; then
            sed -i "/ROVPDFULLEND/i \"${key}\"=\"${value}\"" ${VPDOPTIONSFILEPATH}
        elif [[ ${partition} == "RW_VPD" ]]; then
            sed -i "/RWVPDFULLEND/i \"${key}\"=\"${value}\"" ${VPDOPTIONSFILEPATH}
        fi
    fi
}

editvalue() {
    aft="${1#*\=}" # value to set
    bef="${1%\=*}" # key
    partition="${2}"
    containsvalue=$(source ${VPDOPTIONSFILEPATH} >/dev/null 2>&1; [[ -z "${!aft}" ]] && echo 1 || echo 0)
    if [[ ${containsvalue} -eq 0 ]]; then # vpd.sh: line 91: 0: command not found
        sed -i "s/^[^\"]*${bef}.*/${bef}=${aft}/" ${VPDOPTIONSFILEPATH}
        addoreditvalueinreads "${bef}" "${aft}" "${containsvalue}" "${partition}"
    else
        addoreditvalueinreads "${bef}" "${aft}" "${containsvalue}" "${partition}"
        echo "${bef}=${aft}" >> ${VPDOPTIONSFILEPATH}
    fi
}

# thanks /usr/share/doc/util-linux/getopt-example.bash
while true; do
    case "$1" in
        '-h'|'--help')
            help
            shift
            continue
        ;;
        '-i'|'--partition')
            FLAG_partition=$2
            shift 2
            continue
        ;;
        '-s'|'--string')
            editvalue "${2}" "${FLAG_partition}"
            shift
            continue
        ;;
        '-l'|'--list')
            if [ $FLAG_getlistmutuallyexclusive -eq 1 ]; then
                echo "vpd.sh: -g and -l are mutually exclusive" >&2
                help >&2
                exit 1
            fi
            FLAG_getlistmutuallyexclusive=1
            FLAG_shouldlist=1
            shift
            continue
        ;;
        '-g'|'--filter')
            if [ $FLAG_getlistmutuallyexclusive -eq 1 ]; then
                echo "vpd.sh: -g and -l are mutually exclusive" >&2
                help >&2
                exit 1
            fi
            FLAG_getlistmutuallyexclusive=1
            FLAG_getvalue="$2"
            shift 2
            continue
        ;;
        '--')
            shift
            break
        ;;
        *)
            shift
            continue
        ;;
    esac
done

if [[ -n "${FLAG_getvalue}" ]]; then
    getvalue "${FLAG_getvalue}"
fi
if [[ ${FLAG_shouldlist} -eq 1 ]]; then
    list "${FLAG_partition}"
fi
