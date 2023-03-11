all: 

.PHONY: install
install: 
	adduser invokeai --system
	usermod -aG docker invokeai
	mkdir -p /opt/job
	( \
		cd /opt/job; \
		git clone --depth=1 https://github.com/invoke-ai/InvokeAI.git; \
		cd ./InvokeAI; \
		rm -rf .git; \
		cp -p ./docker/run.sh ./docker/run.sh.old; \
		sed --in-place --regexp-extended 's#^  --mount type=bind,source="$(pwd)"/outputs/,#  --mount type=volume,volume-driver=local,source=invokeai_data#g' ./docker/run.sh; \
		sed --in-place --regexp-extended 's#^\[\[ -d \./outputs \]\] || mkdir \./outputs#docker volume create invokeai_data --opt o=uid=1000#g' ./docker/run.sh; \
		cd ..; \
		chown -R invokeai:nogroup ./InvokeAI; \
		chmod -R -0077 ./InvokeAI; \
	)
	install --owner invokeai --group nogroup --mode 0700 ./service.sh /opt/job/InvokeAI
	install --owner root --group root --mode 0700 invokeai.service /etc/systemd/system
	systemctl daemon-reload
	systemctl enable invokeai
	adduser ngrok --system
	( \
		cd /opt/job; \
		git clone --depth=1 https://github.com/ngrok/ngrok-systemd.git; \
		cd ngrok-systemd; \
		rm -rf .git; \
		sed --in-place --regexp-extended 's#<path>#/opt/job/ngrok-systemd#g' ./ngrok-systemd/ngrok.service; \
		cd ..; \
		chown -R ngrok:nogroup ./ngrok-systemd; \
		chmod -R -0077 ./ngrok-systemd; \
	)
	install --owner root --group root --mode 0700 /opt/job/ngrok-systemd/ngrok.service /etc/systemd/system
	install --owner ngrok --group nogroup --mode 0600 ./ngrok.yml /opt/job/ngrok-systemd
	systemctl daemon-reload
	systemctl enable ngrok.service

.PHONY: remove
remove:
	systemctl stop invokeai
	systemctl disable invokeai
	rm -f /etc/systemd/system/invokeai.service
	systemctl daemon-reload
	rm -rf /opt/job/InvokeAI
	systemctl stop ngrok
	systemctl disable ngrok
	rm -rf /opt/job/ngrok-systemd