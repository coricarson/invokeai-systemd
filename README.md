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
BACKUP="2023-03-19"

mkdir "$BACKUP"
pushd "$BACKUP"

docker save ghcr.io/invokeai/invokeai -o invokeai.tar

docker run --rm --network=none -v invokeai_data:/data busybox:stable tar cv /data > invokeai_data.tar

docker run --rm --network=none -v invokeai_outputs:/outputs busybox:stable tar cv /outputs > invokeai_outputs.tar

popd

sudo systemctl start invokeai
```

# Restore from backup
Remember to test your backups, in all things!

```bash
# LOAD FROM BACKUP
sudo systemctl stop invokeai

#Assign which backup name to use
BACKUP="2023-03-19"
pushd "$BACKUP"

docker rmi $(docker images -q ghcr.io/invokeai/invokeai)
docker load -i invokeai.tar

docker volume rm invokeai_data
docker run --rm --network=none -v "$PWD:/backup:ro" -v invokeai_data:/data busybox:stable tar xv --strip-components=1 -C /data -f /backup/invokeai_data.tar

docker volume rm invokeai_outputs
docker run --rm --network=none -v "$PWD:/backup:ro" -v invokeai_outputs:/outputs busybox:stable tar xv --strip-components=1 -C /outputs -f /backup/invokeai_outputs.tar

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