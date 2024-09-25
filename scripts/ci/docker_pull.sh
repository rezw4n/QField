#!/bin/bash

echo "::group::docker-pull"
docker pull opengisch/smartfield-sdk:${SMARTFIELD_SDK_VERSION}
echo "::endgroup::"
