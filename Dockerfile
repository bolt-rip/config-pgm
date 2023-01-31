FROM alpine:3.12 AS BUILD

RUN mkdir /minecraft

WORKDIR /minecraft

COPY . .

RUN apk add --no-cache jq wget curl

RUN wget -q https://github.com/itzg/mc-server-runner/releases/download/1.4.3/mc-server-runner_1.4.3_linux_amd64.tar.gz \
            https://github.com/itzg/mc-monitor/releases/download/0.6.0/mc-monitor_0.6.0_linux_amd64.tar.gz \
            https://github.com/itzg/rcon-cli/releases/download/1.4.8/rcon-cli_1.4.8_linux_amd64.tar.gz
            
RUN ls *.tar.gz | xargs -n1 tar -xzf && \
    chmod +x mc-server-runner mc-monitor rcon-cli && \
    mv mc-monitor mc-server-runner rcon-cli bin/ && \
    rm LICENSE* README* *.tar.gz

WORKDIR /minecraft/plugins

RUN ash -c "wget --content-disposition -q $(curl -sL https://api.github.com/repos/bolt-rip/ingame/releases/latest | jq -r '.assets[].browser_download_url') \
            $(curl -sL https://api.github.com/repos/bolt-rip/AntiAFK/releases/latest | jq -r '.assets[].browser_download_url') \
            $(curl -sL https://api.github.com/repos/bolt-rip/Events/releases/latest | jq -r '.assets[].browser_download_url') \
            $(curl -sL https://api.github.com/repos/applenick/autokiller/releases/latest | jq -r '.assets[].browser_download_url') \
            $(curl -sL https://api.github.com/repos/applenick/Bolty/releases/latest | jq -r '.assets[].browser_download_url') \
            https://cdn.discordapp.com/attachments/831301239584325713/1070112878641815662/PGM.jar"
            
WORKDIR /minecraft

# RUN wget -q https://pkg.ashcon.app/sportpaper -O sportpaper.jar

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
