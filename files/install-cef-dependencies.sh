#!/bin/bash
set -e

apt-get install -y --no-install-recommends \
  git \
  wget \
  python3 \
  python3-pip \
  lsb-release \
  file

wget -O- "https://chromium.googlesource.com/chromium/src/+/refs/tags/${CHROMIUM_VERSION}/build/install-build-deps.sh?format=TEXT" | base64 -d > install-build-deps.sh
wget -O- "https://chromium.googlesource.com/chromium/src/+/refs/tags/${CHROMIUM_VERSION}/build/install-build-deps.py?format=TEXT" | base64 -d > install-build-deps.py
chmod 755 install-build-deps.sh
chmod 755 install-build-deps.py

# The install script expects sudo, so make a placeholder that transparently forwards commands.
if type sudo 2>/dev/null; then
    echo "The sudo command already exists... Skipping.";
else
    echo -e "#!/bin/bash\n\${@}" > /usr/sbin/sudo;
    chmod +x /usr/sbin/sudo;
fi

# Remove the "Installing locales" step which fails with sed errors.
# TODO: This trims all the way to end-of-file. Fix the sed error or
# add a more nuanced approach in the future if necessary.
# line_num="$(grep -n 'echo \"Installing locales.\"' install-cef-build-deps.sh | head -n 1 | cut -d: -f1)"
# sed -i "${line_num},\$ d" install-cef-build-deps.sh

./install-build-deps.sh --no-chromeos-fonts --no-nacl --no-prompt --arm
rm -f install-build-deps.sh

# Workaround for untar operations failing in Podman with "cannot change ownership
# to uid" errors.
# mv /bin/tar{,.real}
# cat << EOF > /bin/tar
# #!/bin/bash
# exec /bin/tar.real "\$@" --no-same-owner
# EOF
# chmod a+x /bin/tar

wget https://bitbucket.org/chromiumembedded/cef/raw/master/tools/automate/automate-git.py
mkdir -p /cef
mv automate-git.py /cef

apt-get clean
apt-get purge -y --auto-remove
rm -rf /var/lib/apt/lists/*
