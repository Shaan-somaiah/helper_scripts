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
    cflog "Parallelism set incorrectly , defaulting to 4"
    PARALLELISM=4
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
        rm -r -- "$TEMP_WORK_DIR"
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
rm -f -- "$(basename "$OG_TIMECAPSULE")"
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
    tar --no-same-owner --no-same-permissions -xzf "$f" -C "$dir" && rm -f -- "$f"
  ' _
  ((depth++))
done
cflog "[3/7] Recursively extracting subdirectories done"

## escape special characters so that sed treats
## what is passed in redaction source list literally 
escapedSed() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g' -e 's/[][$.^*(){}+?|\\-]/\\&/g'
}

## some logs like /logs/system/home_cohesity_data_support-toolbox_html/hc_cli_results.html 
## contain ips in following format for some reason:
## 192-168-0-1
## This does not literal match with 192.168.0.1 hence an entire another pass is required with format 192-168-0-1
allFormats(){
    l_redactsource=$1
    printf '%s\n' "$1" "${l_redactsource//./-}"
}


cflog "[4/7] Redacting file contents....."
while IFS= read -r redactlist || [[ -n "$redactlist" ]]; do
    [[ -z "$redactlist" || "$redactlist" =~ ^# ]] && continue;

    while IFS= read -r redactsource; do
        safe_redactsource=$(escapedSed "$redactsource")
        cflog "      -  Redacting $redactsource from logs"

        # shellcheck disable=SC2016
        find . -type f -print0 | xargs -0 -n 100 -P "$PARALLELISM" bash -c '
            safe="$1"; shift
            for f in "$@"; do
                LC_ALL=C sed -i.bak "s|$safe|redacted|g" "$f" 2>/dev/null || true
                rm -f -- "$f.bak"
            done
        ' _ "$safe_redactsource"
    done < <(allFormats "$redactlist")
done < "$REDACTION_LIST" 
cflog "[4/7] Redacting file contents done"


cflog "[7/7] Retaring redacted Timecapsule....."
# shellcheck disable=SC2012
TOP_DIR="$(ls -1 | head -1)"
tar -czf "$REDACTED_TIMECAPSULE" "$TOP_DIR"
mv "$REDACTED_TIMECAPSULE" /tmp/
cflog  "Retaring redacted Timecapsule done"

cflog "Sanitized archive: /tmp/$REDACTED_TIMECAPSULE"
cflog "Log file: $LOG_FILE"