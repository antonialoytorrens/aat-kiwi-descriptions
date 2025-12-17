#!/bin/bash
set -eu -o pipefail

cd $(dirname $0)
find .. -name "*.xml" -exec sh -c "echo '======= ' && basename {} && echo ' =======\n' && cat {}" \; > ../contents.txt 2>&1
