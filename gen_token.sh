#! /bin/sh -e

if [[ -z "$1" ]]; then
  . ./oidc.env
else
 . $1
fi

discovery="https://login.microsoftonline.com/$tenant_id/v2.0/.well-known/openid-configuration"
#scope="openid+email+profile+api://2fab98bf-8c75-4ca2-8692-d2fefdf5ff95/Read"
#scope="openid+email+profile"
scope="openid+email+profile"

redirect_uri=http://localhost:12345/oauth/complete
state="`head -c 6 /dev/urandom | base64 | sed -e s/=//g -e 'y%+/%-_%'`"
pkceVerifier="`head -c 32 /dev/urandom | base64 | sed -e s/=//g -e 'y%+/%-_%'`"
pkceChallenge="`printf "%s" "$pkceVerifier" | openssl sha256 -binary | base64 | sed -e s/=//g -e 'y%+/%-_%'`"

authtmp="`mktemp`"
trap "rm '$authtmp'" EXIT
curl -s -o "$authtmp" "$discovery"
token_endpoint="`jq -r .token_endpoint < "$authtmp"`"
authorization_endpoint="`jq -r .authorization_endpoint < "$authtmp"`"

open "$authorization_endpoint?client_id=$client_id&redirect_uri=$redirect_uri&response_type=code$prompt&scope=$scope&code_challenge=$pkceChallenge&code_challenge_method=S256&state=$state"

nc -l 12345 > "$authtmp" <<ENDL
HTTP/1.1 200 OK

<!DOCTYPE html>
<html>
<head>
    <!-- ?error=access_denied&error_subcode=cancel&state=PcgNbmeO&error_description=AADSTS65004%3a+User+declined+to+consent+to+access+the+app. -->
    <style>
        .noshow {
            display: none;
        }
        .show {
            display: inline;
        }
        .success {
            display: block;
        }
        /* table entries should be in bold red */
        .error {
            /*border-collapse: collapse;*/
            display: block;
            color: #d32f2f;
            background-color: #ffebee;
            border: 1px solid #d32f2f;
            padding: 10px;
            margin: 10px;
            font-weight: 500;
            border-radius: 4px;
        }
    </style>
    <script>
        function setup() {
            const urlParams = new URLSearchParams(window.location.search);
            if (urlParams.has('error')) {
                let error = urlParams.get('error');
                const error_subcode = urlParams.get('error_subcode');
                if (error_subcode) {
                    error += ' (' + error_subcode + ')';
                }
                const error_description = urlParams.get('error_description');
                if (error_description) {
                    error += ': ' + error_description;
                }
                document.getElementById('error').innerText = error;
                const error_uri = urlParams.get('error_uri');
                if (error_uri) {
                    document.getElementById('error_uri_text').innerText = error_uri;
                    document.getElementById('error_uri_href').href = error_uri;
                    document.getElementById('error_uri_container').className = 'show';
                }
                document.getElementById('error_table').className = 'error';
            } else {
                document.getElementById('success_note').className = 'success';
            }
        }
    </script>
</head>
<body onload="setup()">
<div id="error_table" class="noshow">
	<p>
        <span id="error"></span>
        <span id="error_uri_container" class="noshow">[See <a id="error_uri_href"><span id="error_uri_text"></span></a>.]</span>
	</p>
	<p>Authorization request unsuccessful.  You may close this browser window.  Return to the terminal to try again.</p>
</div>
<p id="success_note" class="noshow">Authorization request completed; see terminal for result. You may close this
    browser window.</p>
</body>
</html>
ENDL

responseURL="`head -n 1 "$authtmp" | sed -e "s/\r//g" -e 's/^GET //' -e 's% HTTP/1.1$%%'`"
extractParamScript='import sys, urllib.parse; p = urllib.parse.parse_qs(urllib.parse.urlparse(sys.argv[1]).query).get(sys.argv[2]); print(p[0] if p else "")'

if grep '[?&]code=' "$authtmp" > /dev/null 2>&1
then
	code="`python3 -c "$extractParamScript" "$responseURL" code`"
	if [ "$client_secret" = "" ]
	then
		curl -s -o "$authtmp" -d grant_type=authorization_code -d "client_id=$client_id" -d "code=$code" -d "redirect_uri=$redirect_uri" -d "code_verifier=$pkceVerifier" "$token_endpoint" 
	else
		curl -s -o "$authtmp" -d grant_type=authorization_code -d "client_id=$client_id" -d "code=$code" -d "redirect_uri=$redirect_uri" -d "code_verifier=$pkceVerifier" -d "client_secret=$client_secret" "$token_endpoint" 
	fi
	if echo "$scope" | grep openid > /dev/null
	then
		token="`jq -r .id_token < "$authtmp"`"
	else
		token="`jq -r .access_token < "$authtmp"`"
	fi
	
	if [ "$token" = "" -o "$token" = null ]
	then
		cat "$authtmp" >&2
		(echo ; echo ; echo "ERROR: token request failure") >&2
		exit 1
	fi
	echo $token
else
	error="`python3 -c "$extractParamScript" "$responseURL" error`"
	error_subcode="`python3 -c "$extractParamScript" "$responseURL" error_subcode`"
	if [ "$error_subcode" != "" ]
	then
		error="$error ($error_subcode)"
	fi
	error_description="`python3 -c "$extractParamScript" "$responseURL" error_description`"
	if [ "$error_description" != "" ]
	then
		error="$error: $error_description"
	fi
	echo "$error" >&2
	error_uri="`python3 -c "$extractParamScript" "$responseURL" error_uri`"
	if [ "$error_uri" != "" ]
	then
		echo "   for more information see: $error_uri" >&2
	fi
	exit 1
fi
