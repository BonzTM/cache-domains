#!/bin/bash

echo ""
echo "============================================"
echo "Updating LANCache CDN lists"
echo "============================================"

CUR_DIR=$(pwd)
REPO_DIR=${HOME}/git/cache-domains/scripts/
DNSMASQ_DIR=/etc/dnsmasq.d/
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Fetch master branch from uklans
cd "${REPO_DIR}"
{
  git fetch
  git pull
  git diff master origin/master
} &> /dev/null

# Check for changes with local master branch
if git merge-base --is-ancestor origin/master master; then
  echo "No update required."
else
  echo "Updating CDN lists..."
  {
    # Update master
    git checkout master
    git pull origin master
    # Rebase custom branch on new master
    git checkout BonzTM
    git rebase master
    # Push custom branch to github fork
    git push -f BonzTM BonzTM
    # Update pihole dnsmasq
    ./create-dnsmasq.sh
    sudo cp -rf ./output/dnsmasq/* ${DNSMASQ_DIR}
  } &> /dev/null
  # Restart pihole to update lancache domains
  echo "Restarting Pi-hole DNS..."
  pihole restartdns
  echo "Done!"
fi

cd "${CUR_DIR}"
