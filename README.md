# Entra Tester
This project contains a set of scripts to test the access token form an Entra SSO flow.

>This script ONLY runs on Linux like machines 

To be able to use this script to test the access token sent by Entra, you need to add an extra redirect_url to your SSO application in Entra.

- Open up Entra and go to your App Registration.
- In the overview page: make a note of the client_id and tenant_id, you need them in the oidc.env file
- Get the client secret (or create a new one and make a note of it, the value not the id!!)
- Add the following url to the Redirect URIs: http://localhost:12345/oauth/complete  
You can remove it when the test is done...

Make sure the following tools are available on your machine 
- jq (to deal with json)
- curl (to communicate with Entra)
- open (to start the browser)
- python3, to run some scripts

The repo contains 3 scripts:
- gen_token.sh, this one does the login and returns the token
- decode-jwt.sh, this one decodes the token
- show-token.sh, the wrapper around both scripts

Create a file named [your oidc].env with the following entries:
```
tenant_id=[your tenant_id here]
client_id=[your client_id here]
client_secret=[your client secret here ]
```

Run the script:
```
./show_token.sh [your oidc].env
```
Follow the steps in the browser. After the script ran to completion you can close the browser and analyse the token.

Sample output (your mileage may vary):
```
./show_token.sh oidc.env
🔐 JWT Header:
{
  "typ": "JWT",
  "alg": "RS256",
  "kid": "[some identifier]"
}

📦 JWT Payload:
{
  "aud": "[Audience]",
  "iss": "https://login.microsoftonline.com/[your tenant_id]/v2.0",
  "iat": [Issued At timestamp],
  "nbf": [Not Before timestamp],
  "exp": [Expiration timestamp],
  "email": "[your email address]",
  "family_name": "[Lastname]",
  "given_name": "[Firstname]",
  "name": "[Fullname]",
  "oid": "[Object ID]",
  "preferred_username": "[your preferred_username]",
  "rh": "[Refresh Token hash]",
  "sid": "[Session ID]",
  "sub": "[Subject]",
  "tid": "[Tenant ID]",
  "uti": "[Token ID]",
  "ver": "[Token Version, usually 1.0 or 2.0]",
  "employeeid": "[some custom claim]"
}

✍️ Signature (not decoded):
YGuzyEX49aEzlI7ey0QizSgv8dK1L-tXO0wOPGeg6-QFarEXP-T-dUW24WtvtlBbYbOMmUIFwgG37G-zClqnEGecK4mxPt6THuP9RTweUp0KFiBQcJRlyZKJ0ONWxZonPIL_ooU-qvqv85I_DN1qdMdOeez_A4qkKL4DhAXUyR669ymMyboI-rrx0O-wg5AAHD1UOLJ-OrOJSGVfYeFu9KEJ9ipZ02BVhPx-O5esMtk2D57TD2pYcdDj96W4ooFGUp2qLcEe6LOcmGukLzNySFNhatemZ2kQQRpjwrmk50uY4Ji5nhsD2fQx3mjcDDy9gZrKIdLRmXOwjhOerlCVfA
```
