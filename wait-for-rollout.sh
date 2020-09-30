#!/bin/bash

DEPLOYMENTCONFIG="${DEPLOYMENTCONFIG:-mysql}"

# get the latest version of the DC
LATEST="$(oc get dc/${DEPLOYMENTCONFIG} -o jsonpath='{.status.latestVersion}')"

# compose the name of the deployer pod
DEPLOYER="${DEPLOYMENTCONFIG}-${LATEST}-deploy"

# get the status of that pod
DEPLOYER_STATUS="$(oc get pod ${DEPLOYER} -o jsonpath='{.status.phase}')"

# report on progress
echo "The state of DC called ${DEPLOYMENTCONFIG} (and its deployer pod, ${DEPLOYER}) is currently ${DEPLOYER_STATUS}."

# wait for it to complete if not yet there
if [ "${DEPLOYER_STATUS}" != "Running" ] && [ "${DEPLOYER_STATUS}" != "Pending" ]; then
	echo "Nothing to wait for."
	exit 0
fi

while [ "${DEPLOYER_STATUS}" = "Running" ] || [ "${DEPLOYER_STATUS}" = "Pending" ]; do
	echo "Waiting..."
	sleep 1

	# refresh status of that pod
	DEPLOYER_STATUS="$(oc get pod ${DEPLOYER} -o jsonpath='{.status.phase}')"
done

# report on progress again
echo "The state of DC called ${DEPLOYMENTCONFIG} (and its deployer pod, ${DEPLOYER}) is currently ${DEPLOYER_STATUS}."

