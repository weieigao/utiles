#!/bin/bash

PROXY_HOST=${PROXY_HOST:-127.0.0.1}
PROXY_PORT=${PROXY_PORT:-80}

echo proxy host: $PROXY_HOST
echo proxy port: $PROXY_PORT

# Basic http(s) proxy setting
echo "export http_proxy=\"http://$PROXY_HOST:$PROXY_PORT\"" > ~/.proxy
echo "export https_proxy=\"https://$PROXY_HOST:$PROXY_PORT\"" >> ~/.proxy
chmod +x ~/.proxy
echo "Run command 'source ~/.proxy' to apply http(s) proxy setting"

# Apt proxy setting
(
 echo "Acquire::http::Proxy \"http://$PROXY_HOST:$PROXY_PORT\";"
 echo "Acquire::https::Proxy \"https://$PROXY_HOST:$PROXY_PORT\";"
) | sudo tee /etc/apt/apt.conf > /dev/null

# Wget proxy setting
(
 echo "http_proxy=http://$PROXY_HOST:$PROXY_PORT"
 echo "use_proxy=on"
 echo "wait=15"
) > ~/.wgetrc

# Git protocol setting
if ! (which git > /dev/null); then
  echo "Git not installed. Ignore git protocol proxy setting."
  exit
fi
# Use socat to set git proxy
if ! (which socat > /dev/null); then
  sudo apt-get update
  sudo apt-get install socat
fi

(
 echo "PROXY=$PROXY_HOST"
 echo "PROXYPORT=$PROXY_PORT"
 echo "exec socat STDIO PROXY:\$PROXY:\$1:\$2,proxyport=\$PROXYPORT"
) | sudo tee /usr/bin/gitproxy > /dev/null

sudo chmod a+x /usr/bin/gitproxy
# Add global git proxy setting
git config --global core.gitproxy gitproxy
