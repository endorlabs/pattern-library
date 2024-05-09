# exec, source, or paste this in CI using a bash shell
## this assumes endorctl and BAZEL are in the PATH! adjust accordingly
set -e
ENDORCTL=$(which endorctl)
BAZEL=$(which bazel)

MAIN_BRANCH=$(git symbolic-ref --short refs/remotes/origin/HEAD)
COMMIT_RANGE=${COMMIT_RANGE:-$(git merge-base ${MAIN_BRANCH} HEAD)".."}

# Go to the root of the repo
WD=$(pwd)
cd "$(git rev-parse --show-toplevel)"

# Get a list of the current files in package form by querying Bazel.
files=()
for file in $(git diff --name-only "${COMMIT_RANGE}" ); do
  files+=("$(bazel query "$file")")
  bazel query "$file"
done

# Query for the associated buildables
buildables=$("$BAZEL" query \
  --keep_going \
  --noshow_progress \
  "kind('py_binary|go_binary|java_binary', rdeps(//..., set(${files[*]})))")
# Run the tests if there were results
if [[ ! -z $buildables ]]; then
  buildables_tmp=$(echo $buildables | tr '\n' ',')
  buildables_list="${buildables_tmp%,}"  
  set +e
  >&2 echo "Found buildables '${buildables_list}'"

  set +e
  "$ENDORCTL" scan --use-bazel --bazel-include-targets="$buildables_list"
  EXIT_CODE=$?
  set -e
else
    >&2 echo "Unable to find a list of buildables with changes"
fi

cd "$WD"
case "$EXIT_CODE" in
    0)
        >&2 echo "Scan completed without errors or WARN/BREAK policies triggered"
        exit 0
        ;;
    128)
        >&2 echo "Scan completed with WARN policy violations"
        exit 0
        ;;
    129)
        >&2 echo "Scan completed with BLOCK policy violations, exiting with $EXIT_CODE"
        exit $EXIT_CODE
        ;;
    *)
        >&2 echo "SCAN FAILED with code $EXIT_CODE"
        ;;
esac

# change following block to just `exit $EXIT_CODE` to block on scan failures
[[ $EXIT_CODE -lt 128 ]] && { 
    echo "Scan failures are configured as not blocking"
    exit 0  
}

