#!/usr/bin/env bash

set -euo pipefail

## print usage
printUsage(){
    cat << EOF
Usage: $0 -t <timecapsule> -s <redactionList> [-p <No of parallel workers>]
    
    -t Input timecapsule tar.gz to sanitise (required)
    -s File containing list of sensitive items to be redacted (required)
    -p Number of parallel workers to run redaction (optional, defaul=2)
    -h Print this help
EOF
    exit 1;
}

OG_TIMECAPSULE=""
REDACTION_LIST=""
PARALLELISM=2
LOG_FILE="/tmp/redactall-$(date '+%Y%m%d-%H%M%S').INFO"

while getopts ":t:s:p:h" opt;do
    case "$opt" in
        t) OG_TIMECAPSULE="$OPTARG" ;;
        s) REDACTION_LIST="$OPTARG" ;;
        p) PARALLELISM="$OPTARG" ;;
        h) printUsage ;;
        *) printUsage ;;
    esac
done

## CHeck if entered args are valid
if [[ -z "$OG_TIMECAPSULE" || -z "$REDACTION_LIST" ]]; then
    printUsage
fi

## Check and create log file
if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
    echo "Logs stored at $LOG_FILE"
fi

## Custom logger to log to console + log file
cflog(){
    echo "[$(date '+%Y%m%d-%H%M%S')] $*" | tee -a "$LOG_FILE"
}

## Custom logger to only log to file
flog(){
    echo "[$(date '+%Y%m%d-%H%M%S')] $*" >> "$LOG_FILE"
}

if ! [[ "$PARALLELISM" =~ ^[0-9]+$ ]] || [[ "$PARALLELISM" -lt 1 ]]; then
    cflog "Parallelism set incorrectly , defaulting to 2"
    PARALLELISM=2
fi

## Setup workspace 
flog "Setting up env variables"
OG_TIMECAPSULE="$(cd "$(dirname "$OG_TIMECAPSULE")" && pwd)/$(basename "$OG_TIMECAPSULE")"
REDACTION_LIST="$(cd "$(dirname "$REDACTION_LIST")" && pwd)/$(basename "$REDACTION_LIST")"
TEMP_WORK_DIR="$(mktemp -d)"
REDACTED_TIMECAPSULE="$(basename "${OG_TIMECAPSULE%.tar.gz}")-REDACTED.tar.gz"

flog "OG_TIMECAPSULE        = $OG_TIMECAPSULE"
flog "REDACTION LIST        = $REDACTION_LIST"
flog "TEMP_WORK_DIR         = $TEMP_WORK_DIR"
flog "REDACTED_TIMECAPSULE  = $REDACTED_TIMECAPSULE"
flog "PARALLELISM           = $PARALLELISM"

# Cleanup after unexpected exit
CLEANED_UP=0
cleanup(){
    [[ $CLEANED_UP -eq 1 ]] && return
    CLEANED_UP=1
    if [[ "$TEMP_WORK_DIR" != "" && -d "$TEMP_WORK_DIR" ]];then
        rm -r "$TEMP_WORK_DIR"
        cflog "Cleaned up temporary working directory $TEMP_WORK_DIR"
    fi
}
trap cleanup EXIT INT TERM

cflog "[1/7] Preparing workspace....."
cp "$OG_TIMECAPSULE" "$TEMP_WORK_DIR/"
cd "$TEMP_WORK_DIR"
cflog "[1/7] Preparing workspace done"

cflog "[2/7] Extracting top level tar ball....."
tar -xzf "$(basename "$OG_TIMECAPSULE")"
rm -f "$(basename "$OG_TIMECAPSULE")"
cflog "[2/7] Extracting top level tar ball done"

cflog "[3/7] Recursively extracting subdirectories....."
depth=1
while true; do
  mapfile -d '' TARS < <(find . -type f -name "*.tar.gz" -print0)
  [[ ${#TARS[@]} -eq 0 ]] && break

  cflog "      -  Extracting ${#TARS[@]} archives at depth $depth" 
  # shellcheck disable=SC2016
  printf '%s\0' "${TARS[@]}" | xargs -0 -n 1 -P "$PARALLELISM" bash -c '
    f="$1"
    dir="$(dirname "$f")"
    tar --no-same-owner --no-same-permissions -xzf "$f" -C "$dir" && rm -f "$f"
  ' _
  ((depth++))
done
cflog "[3/7] Recursively extracting subdirectories done"