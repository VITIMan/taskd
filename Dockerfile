FROM alpine:3.8

ENV TASKD_VERSION 1.1.0-r4

ENV TASKDDATA /var/taskd
ENV PGID="${PGID:-5000}"
ENV PUID="${PUID:-5000}"

# RUN addgroup -g ${PGID:-5000} taskd
# RUN adduser -S -s /sbin/nologin -u ${PUID:-5000} -h "/home/taskd" -G taskd taskd

RUN apk -q update \
    && apk -q --no-progress add --no-cache shadow sudo taskd-pki taskd="$TASKD_VERSION" \
    && rm -rf /var/cache/apk/*

EXPOSE 53589

VOLUME ["/var/taskd"]

ADD taskd.sh /home/taskd/taskd.sh
RUN chmod a+x /home/taskd/taskd.sh

ENTRYPOINT ["/home/taskd/taskd.sh"]
