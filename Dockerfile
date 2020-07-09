FROM alpine:3.12 AS BUILD

RUN mkdir /minecraft

WORKDIR /minecraft

COPY . .

RUN mkdir -p ~/.ssh
RUN mv id_rsa_maps_pgm /root/.ssh/id_rsa_maps_pgm && chmod og-rwx ~/.ssh/id_rsa_maps_pgm

RUN apk upgrade --no-cache \
    && apk add --no-cache git openssh-client curl maven

RUN curl https://github.com/itzg/mc-server-runner/releases/download/1.4.3/mc-server-runner_1.4.3_linux_amd64.tar.gz \
    -Lo mc-server-runner.tar.gz && tar xzf mc-server-runner.tar.gz && \
    rm LICENSE* README* mc-server-runner.tar.gz && chmod +x mc-server-runner

RUN curl https://github.com/itzg/mc-monitor/releases/download/0.6.0/mc-monitor_0.6.0_linux_amd64.tar.gz \
    -Lo mc-monitor.tar.gz && tar xzf mc-monitor.tar.gz && \
    rm LICENSE* README* mc-monitor.tar.gz && chmod +x mc-monitor

RUN GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa_maps_pgm" \
    git clone --depth=1 --branch=master git@github.com:bolt-rip/maps.git maps
RUN rm -rf ./maps/.git

RUN mvn dependency:get -DrepoUrl=https://repo.repsy.io/mvn/boltrip/public -Dartifact=rip.bolt:ingame:1.0.0-SNAPSHOT -Ddest=plugins
RUN mvn dependency:get -DrepoUrl=https://repo.repsy.io/mvn/boltrip/public -DgroupId=tc.oc.pgm -DartifactId=core -Dversion=0.9-bolt-SNAPSHOT -Ddest=plugins

RUN curl https://pkg.ashcon.app/sportpaper -Lo sportpaper.jar
RUN curl https://github.com/PGMDev/PGM/releases/download/v0.8/PGM.jar -Lo plugins/pgm.jar

FROM adoptopenjdk/openjdk8-openj9:alpine-slim

RUN addgroup -g 1000 minecraft && \
    adduser -u 1000 -D -G minecraft minecraft

RUN mkdir /minecraft
RUN chown minecraft:minecraft -R /minecraft
WORKDIR /minecraft
COPY --from=BUILD --chown=minecraft:minecraft /minecraft .

USER minecraft
ENTRYPOINT [ "/minecraft/run.sh" ]
