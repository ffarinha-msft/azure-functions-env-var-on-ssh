ARG JAVA_VERSION=11u7

FROM mcr.microsoft.com/java/jre-headless:${JAVA_VERSION}-zulu-debian10-with-tools as jre
FROM mcr.microsoft.com/dotnet/core/runtime-deps:3.1
ARG HOST_VERSION

EXPOSE 2222 80

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    HOME=/home \
    FUNCTIONS_WORKER_RUNTIME=java \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    HOST_VERSION=${HOST_VERSION}

COPY --from=runtime-image [ "/azure-functions-host", "/azure-functions-host" ]
COPY --from=runtime-image [ "/workers/java", "/azure-functions-host/workers/java" ]
COPY --from=jre [ "/usr/lib/jvm/zre-hl-tools-11-azure-amd64", "/usr/lib/jvm/zre-11-azure-amd64" ]

## Using this method with ../ requires the docker build be run from the /out/ folder.
## Alternative solution would be to copy the main files for sshd and start.sh to each lang folder
COPY ../shared/sshd_config /etc/ssh/
COPY ../shared/start.sh /azure-functions-host/
COPY --from=runtime-image [ "/FuncExtensionBundles", "/FuncExtensionBundles" ]

ENV JAVA_HOME /usr/lib/jvm/zre-11-azure-amd64

RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-server dialog && \
    echo "root:Docker!" | chpasswd

RUN chmod +x /azure-functions-host/start.sh

ENTRYPOINT ["/azure-functions-host/start.sh"]