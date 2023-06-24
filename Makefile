all: 

.PHONY: install-invokeai
.ONESHELL:
SHELL = /bin/bash
install-invokeai: 
	if grep -qE '^nogroup:' /etc/group; then
		# Debian, Ubuntu, and friends
		GROUP="nogroup"
		adduser invokeai --system || true
	else 
		# Arch, SteamOS
		GROUP="nobody"
		useradd -r -m -s /usr/bin/nologin invokeai || true
	fi
	usermod -aG docker invokeai
	mkdir -p /opt/job
	chmod +0055 /opt/job
	pushd /opt/job
	git clone --depth=1 --branch v2.3.5.post2 https://github.com/invoke-ai/InvokeAI.git
	pushd ./InvokeAI
	pushd ./docker
	cp -p ./run.sh ./run.sh.old
	sed --in-place --regexp-extended 's#^\s{0,8}--mount type=bind,source=[^,]{0,30},target=/data/outputs/?# --mount type=volume,volume-driver=local,source=invokeai_outputs,target=/outputs/#g' ./run.sh
	sed --in-place --regexp-extended '/^\s{0,8}--interactive/d' ./run.sh
	sed --in-place --regexp-extended '/^\s{0,8}--tty/d' ./run.sh
	popd
	popd
	chown -R "invokeai:$$GROUP" ./InvokeAI
	chmod -R -0077 ./InvokeAI
	popd
	install --owner invokeai --group "$$GROUP" --mode 0700 ./service.sh /opt/job/InvokeAI
	install --owner root --group root --mode 0755 invokeai.service /etc/systemd/system
	systemctl daemon-reload
	systemctl enable invokeai
	systemctl start invokeai

.PHONY: install-ngrok
.ONESHELL:
SHELL = /bin/bash
install-ngrok:
	if grep -qE '^nogroup:' /etc/group; then
		# Debian, Ubuntu, and friends
		GROUP="nogroup"
		adduser ngrok --system || true
	else 
		# Arch, SteamOS
		GROUP="nobody"
		useradd -r -m -s /usr/bin/nologin ngrok || true
	fi
	pushd /opt/job
	git clone --depth=1 https://github.com/ngrok/ngrok-systemd.git
	pushd ngrok-systemd
	sed --in-place --regexp-extended 's#<path>#/opt/job/ngrok-systemd#g' ./ngrok.service
	install --owner root --group root --mode 0755 ./ngrok.service /etc/systemd/system
	popd
	chown -R "ngrok:$$GROUP" ./ngrok-systemd
	chmod -R -0077 ./ngrok-systemd
	popd
	install --owner ngrok --group "$$GROUP" --mode 0600 ./ngrok.yml /opt/job/ngrok-systemd
	install --owner ngrok --group "$$GROUP" --mode 0700 ./ngrok /opt/job/ngrok-systemd
	systemctl daemon-reload
	systemctl enable ngrok.service
	systemctl start ngrok

.PHONY: install
install: install-invokeai install-ngrok

.PHONY: remove-invokeai
.ONESHELL:
SHELL = /bin/bash
remove-invokeai:
	systemctl stop invokeai
	systemctl disable invokeai
	rm -f /etc/systemd/system/invokeai.service
	systemctl daemon-reload
	rm -rf /opt/job/InvokeAI
	userdel -r invokeai || true

.PHONY: remove-ngrok
remove-ngrok:
	systemctl stop ngrok
	systemctl disable ngrok
	rm -rf /opt/job/ngrok-systemd
	systemctl daemon-reload
	userdel -r ngrok || true

.PHONY: remove
remove: remove-invokeai remove-ngrok
