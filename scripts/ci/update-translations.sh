#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
SOURCE_DIR=${DIR}/../..
source ${SOURCE_DIR}/scripts/version_number.sh

lupdate -recursive ${SOURCE_DIR} -ts ${SOURCE_DIR}/i18n/smartfield_en.ts

# release only if the branch is master
if [[ ${CI_BRANCH} = master ]]; then
	# push source files only
	./tx push --source
fi
