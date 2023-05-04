#! /bin/bash

# Copyright 2020 New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -x

VERSIONED_MODE="${VERSIONED_MODE:---minor}"
SAMPLES="${SAMPLES:-10}"
export NODE_OPTIONS="--max-old-space-size=4096"

# Determine context manager for sanity sake
if [[ $NEW_RELIC_FEATURE_FLAG_ASYNC_LOCAL_CONTEXT == 1 ]];
then
  CTX_MGR="AsyncLocalStorage"
else
  CTX_MGR="Legacy"
fi

set -f
directories=()
if [[ "$1" != '' ]];
then
  directories=(
    "test/versioned/${1}"
    "test/versioned-external/TEMP_TESTS/${1}"
    "test/versioned-external/TEMP_TESTS/${1}/tests/versioned"
  )
else
  directories=(
    "test/versioned/"
    "test/versioned-external"
  )
fi

# When C8 is set as an env var the intention is to
# run versioned tests without coverage.
if [[ -z "$C8" ]];
then
  # C8 runs out of heap when running against
  # patch/minor flag.  We will just skip it
  # and figure out another way to get coverage
  # when running on main branch. 
  if [[ $VERSIONED_MODE == '--major' ]];
  then
    # lcovonly only generates lcov report which will cut down on amount of time generating reports
    C8="c8 -o ./coverage/versioned -r lcovonly"
  else 
    C8=""
  fi
else 
  # C8 was pass in as an env var which is intended to skip 
  # running versioned tests with c8
  C8=""
fi

export AGENT_PATH=`pwd`

# Runner will default to CPU count if not specified.
echo "JOBS = ${JOBS}"
echo "NPM7 = ${NPM7}"
echo "CONTEXT MANAGER = ${CTX_MGR}"
echo "C8 = ${C8}"

# if $JOBS is not empy
if [ ! -z "$JOBS" ];
then
  JOBS_ARGS="--jobs $JOBS"
fi

if [[ "${NPM7}" = 1 ]];
then
  time $C8 ./node_modules/.bin/versioned-tests $VERSIONED_MODE -i 2 --all --strict --samples $SAMPLES $JOBS_ARGS ${directories[@]}
else
  time $C8 ./node_modules/.bin/versioned-tests $VERSIONED_MODE -i 2 --strict --samples $SAMPLES $JOBS_ARGS ${directories[@]}
fi
