#!/bin/bash
#
# make sure the SA has permissions on target project:
#			get buildconfigs,builds
#			create buildconfigs/instantiate

###### START OF CONFIGURABLE DATA #######

# cluster
CLUSTER="${CLUSTER:-https://kubernetes.default/}"

# project
PROJECT="${PROJECT:-$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)}"

# token secret file
TOKEN_SECRET_FILE="${TOKEN_SECRET_FILE:-/var/run/secrets/kubernetes.io/serviceaccount/token}"

# make sure buildconfig is specified
if [ -z "${BUILDCONFIG}" ]; then
	echo "FATAL: Must have a build configuration specified in BUILDCONFIG environment variable!"
	exit 1
fi

###### END OF CONFIGURABLE DATA #######

# token
TOKEN="$(cat "${TOKEN_SECRET_FILE}")"

# TODO: check that the login succeeded ($? or "oc whoami")
echo "Running as OpenShift user $(oc --token="${TOKEN}" whoami)"

# TODO: check that the buildconfig exists

# get the latest build number
LATEST="$(oc --token="${TOKEN}" -n "${PROJECT}" get bc/${BUILDCONFIG} -o jsonpath='{.status.lastVersion}')"

# get the commit id from latest build
COMMITID="$(oc --token="${TOKEN}" -n "${PROJECT}" get builds/${BUILDCONFIG}-${LATEST} -o jsonpath='{.spec.revision.git.commit}')"

# get the git repository url
REPO_URL="$(oc --token="${TOKEN}" -n "${PROJECT}" get bc/${BUILDCONFIG} -o jsonpath='{.spec.source.git.uri}')"

# get the latest available commit from git server
LATEST_COMMITID="$(git ls-remote ${REPO_URL} HEAD | cut -f1)"

# TODO: check that the above ls-remote returned something useful
# 	check that the latest commitid is actually newer than latest built

# quit if the commits are the same
if [ "${COMMITID}" = "${LATEST_COMMITID}" ]; then
	echo "Commit ID ${COMMITID} has already been built in builds/${BUILDCONFIG}-${LATEST}"
	exit 0
fi

# start a build
oc --token="${TOKEN}" -n "${PROJECT}" start-build ${BUILDCONFIG}

# not needed because we can rely on build sequence numbers for now:
# get the latest build id again, to work with the new build name

# wait for it to complete
FINISHED=0
echo -n "Waiting for build ${BUILDCONFIG}-$((LATEST + 1)) to complete"
while [ ${FINISHED} -ne 1 ]; do
	BUILD_PHASE="$(oc --token="${TOKEN}" -n "${PROJECT}" get builds/${BUILDCONFIG}-$((LATEST + 1)) -o jsonpath='{.status.phase}')"
	if [ "${BUILD_PHASE}" = "Complete" ] || \
	       [ "${BUILD_PHASE}" = "Failed" ] || \
	       [ "${BUILD_PHASE}" = "Error" ] || \
	       [ "${BUILD_PHASE}" = "Cancelled" ]; then
		FINISHED=1
	fi
	echo -n "."
	sleep 3
done
echo " done."

echo "Build ${BUILDCONFIG}-$((LATEST + 1)) finished with status ${BUILD_PHASE}."

# that's it, folks!
