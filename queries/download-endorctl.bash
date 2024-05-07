#!/usr/bin/env bash
## NOTE: you can download endorctl using the various package managers
##  See https://docs.endorlabs.com/endorctl/install-and-configure/ 
## outputs path to endorctl to stdout; all other messages on STDERR
set -eo pipefail

require() {
    if [[ -x "$1" ]]; then tool="$1"
    elif [[ -x "$(which "$1")" ]]; then tool="$(which "$1")"
    else >&2 "Unable to find '$1', which is required"; exit 1
    fi
    echo "$tool"
}

BIN_CURL=$(require curl)

## download endorctl for the rigth OS and arch, but only if we can't find it in your PATH
## this will echo the path we found or downloaeded endorctl
if BIN_ENDORCTL=$(require endorctl); then >&2 echo "Already found $(${BIN_ENDORCTL} --version) at ${BIN_ENDORCTL}, exiting";
else
    case "$(uname -m)" in
        arm64|aarch64)
            ARCH='arm64'
            ;;
        amd64|x86_64)
            ARCH='amd64'
            ;;
        *)
            >&2 echo "Unknown arch '$(uname -m)'"; exit 2
            ;;
    esac

    case "$(uname -o)" in
        Linux)
            OS='linux'
            SHACMD="$(require sha256sum) -c"
            ;;
        Darwin)
            OS='macos'
            SHACMD="$(require shasum) -a 256 -c"
            ;;
        *)
            >&2 echo "Unknown OS '$(uname -o)'"; exit 3
            ;;
    esac

    ## Download the latest CLI
    curl "https://api.endorlabs.com/download/latest/endorctl_${OS}_${ARCH}" -o endorctl

    ## Verify SHASUM -- because we `set -e`, the script will exit if the sum isn't valid
    ##  because we set `-o pipefail`, if this step fails, the exit code will be:
    ##  - the exit code of curl if curl failed
    ##  - the exit code of SHACMD if that failed
    >&2 echo "Checking hash using ${SHACMD}"
    echo "$(curl -s "https://api.endorlabs.com/sha/latest/endorctl_${OS}_${ARCH}")  endorctl" | $SHACMD
    chmod +x endorctl
    >&2 echo "Downloaded $(./endorctl --version)"
    BIN_ENDORCTL="$(pwd)/endorctl"
fi  # download or not

echo "$BIN_ENDORCTL"
