#!/bin/bash

# Run the image with no device attached: the IOC must start, iocStats must
# update and the device and iocStats screens must be generated. The generated
# screens are left in the folder given as the second argument.

TAG=${1:?usage: check-screens.sh <image> <opi output folder>}
OPI=${2:?usage: check-screens.sh <image> <opi output folder>}
THIS=$(realpath $(dirname $0))

set -x
mkdir -p ${OPI}
chmod 777 ${OPI}

result=$(docker run --rm --security-opt=label=disable \
    -v ${THIS}/screens-config:/epics/ioc/config:ro \
    -v ${OPI}:/epics/opi \
    ${TAG} /epics/ioc/start.sh 2>&1)
set +x

echo "${result}"
ls -laR ${OPI}

status=0
for screen in OXNH700 iocAdminSoft; do
    if ! find ${OPI} -name "*.bob" | xargs grep -l "${screen}" > /dev/null; then
        find ${OPI} -iname "*${screen}*" | grep -q . || {
            echo "ERROR: no generated screen for ${screen}"
            status=1
        }
    fi
done
if ! echo "${result}" | grep -q "UPTIME\|DBF_STRING"; then
    echo "ERROR: IOC did not reach its post startup commands"
    status=1
fi
exit ${status}
