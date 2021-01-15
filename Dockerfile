FROM alpine:3.12 AS BUILD

RUN mkdir /minecraft

WORKDIR /minecraft

COPY . .

RUN mkdir -p ~/.ssh
RUN mv id_rsa_maps_pgm /root/.ssh/id_rsa_maps_pgm && chmod og-rwx ~/.ssh/id_rsa_maps_pgm

RUN apk upgrade --no-cache \
    && apk add --no-cache git openssh-client curl maven jq

RUN curl https://github.com/itzg/mc-server-runner/releases/download/1.4.3/mc-server-runner_1.4.3_linux_amd64.tar.gz \
    -Lo mc-server-runner.tar.gz && tar xzf mc-server-runner.tar.gz && \
    rm LICENSE* README* mc-server-runner.tar.gz && mv mc-server-runner bin && chmod +x bin/mc-server-runner

RUN curl https://github.com/itzg/mc-monitor/releases/download/0.6.0/mc-monitor_0.6.0_linux_amd64.tar.gz \
    -Lo mc-monitor.tar.gz && tar xzf mc-monitor.tar.gz && \
    rm LICENSE* README* mc-monitor.tar.gz && mv mc-monitor bin && chmod +x bin/mc-monitor

RUN curl https://github.com/itzg/rcon-cli/releases/download/1.4.8/rcon-cli_1.4.8_linux_amd64.tar.gz \
    -Lo rcon-cli.tar.gz && tar xzf rcon-cli.tar.gz && \
    rm LICENSE* README* rcon-cli.tar.gz && mv rcon-cli bin && chmod +x bin/rcon-cli

RUN GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa_maps_pgm" \
        git clone --depth=1 --branch=master git@github.com:bolt-rip/maps.git maps
RUN GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" \
        git clone https://github.com/OvercastCommunity/scrimmage-maps.git scrimmage-maps
RUN rm -rf ./maps/.git
RUN rm -rf ./scrimmage-maps/.git

RUN mvn dependency:get -DrepoUrl=https://repo.repsy.io/mvn/boltrip/public -Dartifact=rip.bolt:ingame:1.0.0-SNAPSHOT -Ddest=plugins
RUN mvn dependency:get -DrepoUrl=https://repo.repsy.io/mvn/boltrip/public -Dartifact=rip.bolt:antiafk:0.0.1-SNAPSHOT -Ddest=plugins

RUN curl https://pkg.ashcon.app/pgm -Lo plugins/pgm.jar
RUN ash -c "curl $(curl -sL https://api.github.com/repos/PGMDev/Events/releases/latest | jq -r '.assets[].browser_download_url') -Lo plugins/events.jar"
RUN curl https://pkg.ashcon.app/sportpaper -Lo sportpaper.jar

FROM adoptopenjdk/openjdk8-openj9:alpine-slim

RUN addgroup -g 1000 minecraft && \
    adduser -u 1000 -D -G minecraft minecraft

RUN mkdir /minecraft
RUN chown minecraft:minecraft -R /minecraft
WORKDIR /minecraft
COPY --from=BUILD --chown=minecraft:minecraft /minecraft .

RUN apk add --no-cache curl grep jq && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing kubectl

USER minecraft
ENTRYPOINT [ "/minecraft/run.sh" ]
