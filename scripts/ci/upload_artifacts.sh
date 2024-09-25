#!/bin/bash

set -e

# If we have secure env vars and are in either a pull request or a tag, we need to upload artifacts
if [[ "${S3CFG}" ]]; then
	echo -e "\e[31mAbout to upload build artifacts\e[0m"

	#FILENAME_AAB="${CI_PACKAGE_NAME}-${CI_PACKAGE_FILE_SUFFIX}-${NAME}.aab"
	FILENAME_APK="${CI_PACKAGE_NAME}-${CI_PACKAGE_FILE_SUFFIX}-${NAME}.apk"

	# skip AAB upload until we need it
	#mv ${CMAKE_BUILD_DIR}/android-build/build/outputs/bundle/release/android-build-release.aab /tmp/${FILENAME_AAB}
	#echo "${S3CFG}" > ~/.s3cfg
	#s3cmd put --acl-public /tmp/${FILENAME_AAB} s3://smartfieldapks/ci-builds/${FILENAME_AAB}
	#echo -e "\e[31mUploaded to https://sos-ch-dk-2.exo.io/smartfieldapks/ci-builds/${FILENAME_AAB} \e[0m"
	#s3cmd modify --add-header=content-type:application/octet-stream s3://smartfieldapks/ci-builds/${FILENAME_AAB}
	#echo -e "\e[31mcontent-type modified \e[0m"

	mv ${CMAKE_BUILD_DIR}/src/app/android-build/build/outputs/apk/release/android-build-release-signed.apk /tmp/${FILENAME_APK}
	echo "${S3CFG}" >~/.s3cfg
	s3cmd put --acl-public -m 'application/vnd.android.package-archive' /tmp/${FILENAME_APK} s3://smartfieldapks/ci-builds/${FILENAME_APK}
	echo -e "\e[31mUploaded to https://sos-ch-dk-2.exo.io/smartfieldapks/ci-builds/${FILENAME_APK} \e[0m"
	rm ~/.s3cfg
else
	echo -e "Not uploading artifacts ..."
fi
