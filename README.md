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

# Save to backupinvokeai_data.2023-03-19.tar
Make a backup of the container image and the model files, so you don't have to redownload them later on.

```bash
# SAVE TO BACKUP
sudo systemctl stop invokeai

#Assign which backup name to use
#BACKUP="2023-03-19"
read BACKUP

mkdir "$BACKUP"
pushd "$BACKUP"

docker save ghcr.io/invokeai/invokeai | zstd -19 -T0 -o invokeai.tar.zst

docker run --rm --network=none -v invokeai_data:/data:ro -v "$PWD:/out" busybox:stable tar cv /data -f /out/invokeai_data.tar
zstd -19 -T0 ./invokeai_data.tar -o invokeai_data.tar.zst
rm invokeai_data.tar

docker run --rm --network=none -v invokeai_outputs:/outputs -v "$PWD:/out" busybox:stable tar cv /outputs -f /out/invokeai_outputs.tar
zstd -19 -T0 ./invokeai_outputs.tar -o invokeai_outputs.tar.zst
rm invokeai_outputs.tar

popd

sudo systemctl start invokeai
```

# Restore from backup
Remember to test your backups, in all things!

```bash
# LOAD FROM BACKUP
sudo systemctl stop invokeai

#Assign which backup name to use
#BACKUP="2023-03-19"
read BACKUP
pushd "$BACKUP"

docker rmi $(docker images -q ghcr.io/invokeai/invokeai)
zstdcat invokeai.tar.zst | docker load

docker volume rm invokeai_data
zstd -d invokeai_data.tar.zst
docker run --rm --network=none -v "$PWD:/backup:ro" -v invokeai_data:/data busybox:stable tar xv --strip-components=1 -C /data -f /backup/invokeai_data.tar
rm invokeai_data.tar

docker volume rm invokeai_outputs
zstd -d invokeai_outputs.tar.zst
docker run --rm --network=none -v "$PWD:/backup:ro" -v invokeai_outputs:/outputs busybox:stable tar xv --strip-components=1 -C /outputs -f /backup/invokeai_outputs.tar
rm invokeai_outputs.tar

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
