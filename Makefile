all: 

.PHONY: install-invokeai
install-invokeai: 
	useradd -r -m -s /usr/bin/nologin invokeai || true
	usermod -aG docker invokeai
	mkdir -p /opt/job
	chmod +0055 /opt/job
	( \
		if grep -qE '^nobody:' /etc/group; then GROUP="nobody"; else GROUP="nouser"; fi; \
		cd /opt/job; \
		git clone --depth=1 https://github.com/invoke-ai/InvokeAI.git; \
		cd ./InvokeAI; \
		cp -p ./docker/run.sh ./docker/run.sh.old; \
		sed --in-place --regexp-extended 's#^\s{0,8}--mount type=bind,source=[^,]{0,30},target=/data/outputs/# --mount type=volume,volume-driver=local,source=invokeai_outputs,target=/outputs/#g' ./docker/run.sh; \
		sed --in-place --regexp-extended '/^\s{0,8}--interactive/d' ./docker/run.sh; \
		sed --in-place --regexp-extended '/^\s{0,8}--tty/d' ./docker/run.sh; \
		cd ..; \
		chown -R invokeai:${GROUP} ./InvokeAI; \
		chmod -R -0077 ./InvokeAI; \
		install --owner invokeai --group ${GROUP} --mode 0700 ./service.sh /opt/job/InvokeAI \
	)
	install --owner root --group root --mode 0755 invokeai.service /etc/systemd/system
	systemctl daemon-reload
	systemctl enable invokeai
	systemctl start invokeai

.PHONY: install-ngrok
install-ngrok:
	useradd -r -m -s /usr/bin/nologin ngrok || true
	( \
		cd /opt/job; \
		git clone --depth=1 https://github.com/ngrok/ngrok-systemd.git; \
		cd ngrok-systemd; \
		sed --in-place --regexp-extended 's#<path>#/opt/job/ngrok-systemd#g' ./ngrok.service; \
		cd ..; \
		chown -R ngrok:nobody ./ngrok-systemd; \
		chmod -R -0077 ./ngrok-systemd; \
	)
	install --owner root --group root --mode 0755 /opt/job/ngrok-systemd/ngrok.service /etc/systemd/system
	install --owner ngrok --group nobody --mode 0600 ./ngrok.yml /opt/job/ngrok-systemd
	install --owner ngrok --group nobody --mode 0700 ./ngrok /opt/job/ngrok-systemd
	systemctl daemon-reload
	systemctl enable ngrok.service
	systemctl start ngrok

.PHONY: install
install: install-invokeai install-ngrok

.PHONY: remove-invokeai
remove-invokeai:
	systemctl stop invokeai
	docker kill invokeai
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
