# InvokeAI + ngrok

1. Download the ngrok binary to this folder.
1. Edit the service.sh, enter your hugging face token.
1. Edit the ngrok.yml, enter (at least) your token. Add other configurations here that you're using, like an edge label.

```bash
sudo make install
```

4. Take a backup

## What about just InvokeAI?
Not using ngrok? Have a different networking solution in mind?

```bash
sudo make install-invokeai
```

# Save to backup
Make a backup of the container image and the model files, so you don't have to redownload them later on.

```bash
# SAVE TO BACKUP
sudo systemctl stop invokeai

#Assign which backup name to use
#BACKUP="2023-03-19"
read BACKUP

mkdir "$BACKUP"
pushd "$BACKUP"

docker save ghcr.io/invokeai/invokeai | zstd --ultra -22 -T0 -o invokeai.tar.zst

docker build --tag util - <<'EOF'
ARG DEBIAN_FRONTEND=noninteractive
FROM debian:stable
RUN apt update
RUN apt upgrade -y
RUN apt install -y tar zstd
EOF

docker run --rm --network=none -v invokeai_data:/data:ro -v "$PWD:/out" util bash -c 'tar cv /data -f - | zstd --ultra -22 -T0 /out/invokeai_data.tar.zst'

docker run --rm --network=none -v invokeai_outputs:/outputs -v "$PWD:/out" util bash -c 'tar cv /outputs -f - | zstd --ultra -22 -T0 /out/invokeai_outputs.tar.zst'

popd

sudo systemctl start invokeai
```

# Restore from backup
Remember to test your backups, in all things!

```bash
# LOAD FROM BACKUP
sudo systemctl stop invokeai

#Assign which backup name to use
#BACKUP="2023-07-04"
read BACKUP
pushd "$BACKUP"

docker rmi $(docker images -q ghcr.io/invokeai/invokeai)
zstdcat invokeai.tar.zst | docker load

docker build --tag util - <<'EOF'
ARG DEBIAN_FRONTEND=noninteractive
FROM debian:stable
RUN apt update
RUN apt upgrade -y
RUN apt install -y tar zstd
EOF

docker volume rm invokeai_data
docker run --rm --network=none -v "$PWD:/backup:ro" -v invokeai_data:/data util bash -c 'zstdcat /backup/invokeai_data.tar.zst | tar xv --strip-components=1 -C /data'

docker volume rm invokeai_outputs
docker run --rm --network=none -v "$PWD:/backup:ro" -v invokeai_outputs:/outputs util bash -c 'zstdcat /backup/invokeai_outputs.tar.zst | tar xv --strip-components=1 -C /outputs'

popd

sudo systemctl start invokeai
```

# Whoops I pooched it
Nuke the docker engine state from orbit. It's the only way to be sure.

```bash
sudo su -
systemctl stop docker
rm -rf /var/lib/docker
systemctl start docker
exit # sudo su
```

Now, restore from a backup you took earlier. 
YOU TOOK A BACKUP, RIGHT?


# Steam Deck
## SteamOS 3.4.x

```bash
# Set a password for `deck` if you haven't yet
passwd
# Disable the readonly filesystem configuration so that packages can be installed.
# You may find that files installed in locations normally marked `read-only` are not guaranteed to persist across SteamOS updates.
sudo steamos-readonly disable

# Initialize pacman's keys
sudo pacman-key --init
sudo pacman-key --populate archlinux

# Get into orbit. You're halfway to anywhere now.
sudo pacman -S docker base-devel

# default drive mapping on SteamOS 3.4 places the /var folder on a small mount.
# Way too small to hold what we're building here.
# Therefore, move the docker folder to the largest area, which is /home.
# ATTENTION: if you have a base model steam deck with only a small amount of eMMC, 
# consider pointing this at an sd card or USB disk instead.
echo '{ "data-root": "/home/docker" }' | sudo tee /etc/docker/daemon.json
sudo mkdir -p /home/docker

# If this doesn't fire up cleanly, double-check your docker data root location
sudo systemctl start docker


# Now let's install InvokeAI
git clone --depth=1 https://github.com/coricarson/invokeai-systemd.git
cd invokeai-systemd

# Add your huggingface token
nano ./service.sh

sudo make install-invokeai
```
