#!/bin/bash

echo "Check certs"

BAD_SERIAL='serial=XXXXXXXXXXXXXXXXXXX'

function checkCert() {
	CERT=$1
	echo -n "Host [${CERT}] responding :: "
	TEST_CONN=$( nc -vz -w2 ${CERT} 443 2>&1 ) 
	if [ "$?" == "1" ]; then
		echo "Nothing listens at port 443"
		return
	else
		echo -n "OK :: "
	fi
	

	echo -n "Checking cert :: (${CERT}) => "
	SERIAL=$( echo -n | openssl s_client -connect ${CERT}:443 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -noout -serial 2>&1 | grep serial )
	echo -n "(${SERIAL}) :: "
	if [ "${BAD_SERIAL}" == "${SERIAL}" ]; then
		echo "Certificate MATCH! - must be replaced"
	else
		echo "Certificate not match"
	fi
}

## Read directly from blackbox_exporter list of hosts
while IFS= read -r line
do
	if [[ ${line} == *".<domain>"* ]]; then
		STRIPPED_LINE=$( echo "${line}" | sed 's|  - https://||' )
		checkCert "${STRIPPED_LINE}"
	fi
done < "blackbox_https_ssl.yml"
