#!/bin/bash

app_name="crunch"
usage_string="Usage: ./make-${app_name}.sh /path/to/pier /path/to/${app_name}"

# Parse args.
if [ $# -ne 2 ]; then
    echo "$usage_string"
    echo ""
    echo "Set up ${app_name}."
    echo ""
    echo "This script should be copied to and run"
    echo "in the pkg directory in the Urbit repo."
    echo ""
    echo "Requires the ship pier be already mounted"
    echo "and a ${app_name} desk already made, e.g. via"
    echo ""
    echo "|mount %"
    echo "|merge %${app_name} our %base"
    echo "|mount %${app_name}"
    echo ""
    echo "After running this script, run"
    echo ""
    echo "|commit %${app_name}"
    exit 1
fi
path_to_pier=$1
path_to_app_code=$2

# Clean and prepare workspace in `pkg`.
if [ -f "$app_name" ]; then
    rm -r $app_name
fi

if [ -f "${app_name}-dev-tmp" ]; then
    rm -r "./${app_name}-dev-tmp"
fi
cp -r "$(dirname $path_to_app_code)/${app_name}-dev" "./${app_name}-dev-tmp"

if [ -f "${app_name}-tmp" ]; then
    rm -r "./${app_name}-tmp"
fi
cp -r $path_to_app_code "./${app_name}-tmp"

# Build the desk.
./symbolic-merge.sh landscape $app_name
./symbolic-merge.sh base-dev $app_name
./symbolic-merge.sh garden-dev $app_name
./symbolic-merge.sh ${app_name}-dev-tmp $app_name
if [ "$path_to_app_code" != "" ]; then
    ./symbolic-merge.sh "./${app_name}-tmp" $app_name
    if [ -f "./${app_name}-tmp/desk.bill" ]; then
        cp "./${app_name}-tmp/desk.bill" $app_name
    fi
fi

echo "[%zuse 418]" > ${app_name}/sys.kelvin

# Place the desk in given pier.
rm -r "${path_to_pier}/${app_name}"
cp -Lr $app_name $path_to_pier

# Clean up.
rm -r $app_name
rm -r "./${app_name}-dev-tmp"
rm -r "./${app_name}-tmp"

echo "Done."
