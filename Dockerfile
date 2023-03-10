FROM alpine:latest

RUN \
	mkdir -p /aws && \
	apk -Uuv add groff less python3 py3-pip curl unzip && \
	pip3 install --no-cache-dir awscli && \
	apk --purge -v del py-pip && \
	rm /var/cache/apk/*

COPY docker-entrypoint.sh /
COPY backup-and-cleanup.sh /
COPY restore-backup.sh /

RUN chmod +x /docker-entrypoint.sh /backup-and-cleanup.sh /restore-backup.sh

ENTRYPOINT /docker-entrypoint.sh