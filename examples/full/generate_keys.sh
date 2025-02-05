#!/usr/bin/env bash
#
# generate_keys.sh
#
# Generates a single Tor v3 onion address that starts with "test".
# It compiles mk224o from source in a temporary directory, then outputs
# the resulting key pair to ./keys/ (relative to where you invoke this script).
# It also generates a self-signed TLS certificate with the correct onion name as the SAN.
# Finally, it zips all the files in the keys folder into configuration.zip.
#
# Assumptions/Requirements:
# - No root privileges needed.
# - Works on Debian-based systems and macOS, provided build tools and libsodium are installed.
# - Produces exactly one onion address with prefix "test".
# - Cleans up after itself when done.

set -euo pipefail

[ ! -d keys ] || (echo "keys directory already exists" && exit 1)

# Create an output directory in the original location of the script
WORK_DIR=$( pwd )
OUT_DIR="${WORK_DIR}/keys"
mkdir -p "${OUT_DIR}"
echo "Using output directory: ${OUT_DIR}"

# Create a temporary working directory for cloning and building mkp224o
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'mkp224o')"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "Using temporary directory: ${TMP_DIR}"
cd "${TMP_DIR}"

# Clone the mkp224o repository
echo "Cloning mkp224o..."
git clone --depth=1 https://github.com/cathugger/mkp224o.git

export PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}
export CPPFLAGS=${CPPFLAGS:-}
export LDFLAGS=${LDFLAGS:-}

# Only set these on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Add typical Homebrew or fallback pkgconfig paths
  export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

  # Pull libsodium cflags (includes) into CPPFLAGS
  export CPPFLAGS="$(pkg-config --cflags libsodium) $CPPFLAGS"

  # Pull libsodium ldflags (linker opts) into LDFLAGS
  export LDFLAGS="$(pkg-config --libs libsodium) $LDFLAGS"

  echo "macOS detected. Using pkg-config to set CPPFLAGS and LDFLAGS for libsodium."
fi

# Enter the cloned repository and build
cd mkp224o
echo "Building mkp224o..."
./autogen.sh
./configure
make

echo "Generating one onion address with prefix 'test'..."
# -n 1 ensures only one matching address is generated
# -d tells mkp224o where to place results
./mkp224o test -n 1 -d "${OUT_DIR}"

echo
echo "Generating TLS certificate..."
cd "${OUT_DIR}"

# Get the onion address
ONION_DIR=$(ls)
ONION_ADDRESS=$(grep -o "^[a-z2-7]*" <<< "$ONION_DIR")

# Create a certificate with the onion address as SAN
openssl req -x509 -newkey rsa:2048 -nodes -keyout "${ONION_ADDRESS:0:20}-v3.pem" -out "${ONION_ADDRESS:0:20}-v3.cert" -days 365 -subj "/C=US/ST=Example/L=Example/O=Example/CN=${ONION_ADDRESS}.onion" -extensions EXT -config <(cat /usr/lib/ssl/openssl.cnf <(printf "[EXT]\nsubjectAltName=DNS:${ONION_ADDRESS}.onion\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth"))

# Rename the onion keys
mv "${OUT_DIR}/${ONION_DIR}/hs_ed25519_secret_key" "${ONION_ADDRESS}.v3sec.key"
mv "${OUT_DIR}/${ONION_DIR}/hs_ed25519_public_key" "${ONION_ADDRESS}.v3pub.key"
rm -rf "${ONION_DIR}"

cat > "${OUT_DIR}/sites.conf" <<EOF
set log_separate 1

set nginx_resolver 127.0.0.53 ipv6=off

set nginx_cache_seconds 60
set nginx_cache_size 64m
set nginx_tmpfile_size 8m

set x_from_onion_value 1

foreignmap facebookwkhpilnemxj7asaniu7vnjjbiltxjqhye3mhbshg7kx5tfyd.onion facebook.com
foreignmap twitter3e4tixl4xyajtrzo62zg5vztmjuricljdp2c5kshju4avyoid.onion twitter.com

set project sites

EOF

echo "hardmap ${ONION_ADDRESS} example.com" >> "${OUT_DIR}/sites.conf"

echo
echo "Creating configuration.zip..."
cd "${OUT_DIR}"
zip -j configuration.zip sites.conf *.v3sec.key *.v3pub.key *.pem *.cert

echo "Done! The configuration is zipped in:"
echo "  ${OUT_DIR}/configuration.zip"
echo
echo "The zip file contains the following files:"
echo "  - sites.conf (Onionspray configuration)"
echo "  - ${ONION_ADDRESS}.v3sec.key (Onion secret key)"
echo "  - ${ONION_ADDRESS}.v3pub.key (Onion public key)"
echo "  - ${ONION_ADDRESS:0:20}-v3.pem (TLS private key)"
echo "  - ${ONION_ADDRESS:0:20}-v3.cert (TLS certificate)"
echo
