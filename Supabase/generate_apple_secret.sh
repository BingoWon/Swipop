#!/bin/bash
# Generate Apple Sign in with Apple JWT Secret
# Run this every 6 months to refresh the secret
# Usage: ./Supabase/generate_apple_secret.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Apple configuration
TEAM_ID="5C4299VVGU"
KEY_ID="6AGJN2WW5G"
CLIENT_ID="com.swipop.auth"
KEY_FILE="$PROJECT_DIR/AuthKey_6AGJN2WW5G.p8"

if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Key file not found: $KEY_FILE"
    exit 1
fi

node << EOF
const crypto = require('crypto');
const fs = require('fs');

const teamId = '$TEAM_ID';
const keyId = '$KEY_ID';
const clientId = '$CLIENT_ID';
const privateKey = fs.readFileSync('$KEY_FILE', 'utf8');

const now = Math.floor(Date.now() / 1000);
const exp = now + 15777000; // ~6 months

const header = { alg: 'ES256', kid: keyId };
const payload = {
  iss: teamId,
  iat: now,
  exp: exp,
  aud: 'https://appleid.apple.com',
  sub: clientId
};

function base64url(str) {
  return Buffer.from(str).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

const headerB64 = base64url(JSON.stringify(header));
const payloadB64 = base64url(JSON.stringify(payload));
const unsigned = headerB64 + '.' + payloadB64;

const sign = crypto.createSign('SHA256');
sign.update(unsigned);
const signature = sign.sign(privateKey);

function derToRaw(derSig) {
  let offset = 2;
  const rLen = derSig[offset + 1];
  let r = derSig.slice(offset + 2, offset + 2 + rLen);
  offset = offset + 2 + rLen;
  const sLen = derSig[offset + 1];
  let s = derSig.slice(offset + 2, offset + 2 + sLen);
  if (r.length === 33 && r[0] === 0) r = r.slice(1);
  if (s.length === 33 && s[0] === 0) s = s.slice(1);
  while (r.length < 32) r = Buffer.concat([Buffer.from([0]), r]);
  while (s.length < 32) s = Buffer.concat([Buffer.from([0]), s]);
  return Buffer.concat([r, s]);
}

const rawSig = derToRaw(signature);
const sigB64 = rawSig.toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

const expDate = new Date(exp * 1000).toISOString().split('T')[0];
console.log('\\n=== Apple Sign in with Apple JWT Secret ===');
console.log('Generated: ' + new Date().toISOString().split('T')[0]);
console.log('Expires: ' + expDate);
console.log('\\nSecret Key (copy this to Supabase):');
console.log(unsigned + '.' + sigB64);
console.log('');
EOF

echo "Go to: https://supabase.com/dashboard/project/axzembhfbmavvklsqsjs/auth/providers"
echo "Update the Apple Secret Key with the value above."

