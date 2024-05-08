set -eo pipefail        # some CI systems do this by default, but just in case
BIN_OS=${BIN_OS:-'linux'}            # choose linux, macos
BIN_ARCH=${BIN_ARCH:-'amd64'}          # choose amd64, arm64 -- note that not all combinations are available
SHACMD=${SHACMD:-}"sha256sum -c"   # change to command that will check the SHA256 checksum. on macOS this is 'shasum -a 256 -c'

# the path to save 'endorctl' to, including the name of the binary
BIN_NAME=${BIN_NAME:-".endorlabs/endorctl"} 

## download the lastest binary for OS and ARCH
>&2 echo "Donwnloading endorctl for $BIN_OS on $BIN_ARCH as '$BIN_NAME'"
mkdir -p "$(dirname "$BIN_NAME")"
curl -o "$BIN_NAME" "https://api.endorlabs.com/download/latest/endorctl_${BIN_OS}_${BIN_ARCH}" >&2

## Verify SHA256 checksum
>&2 echo "Verifying SHA256 sum of '$BIN_NAME' using '$SHACMD'"
SHASUM=$(curl -s "https://api.endorlabs.com/sha/latest/endorctl_${BIN_OS}_${BIN_ARCH}")  ## get the checksum
if (echo "$SHASUM  $BIN_NAME" | $SHACMD)
then
    chmod +x "$BIN_NAME"  ## since it's verified, mark it OK to execute
else
    >&2 echo "Verification failed; expected '$SHASUM'"
    rm -f "$BIN_NAME"  ## it didn't validate, so delete it
fi

echo "$BIN_NAME"  ## lets you use the output of this 
