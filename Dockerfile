FROM python:3.8-slim

USER root


WORKDIR /tmp

RUN apt-get update && apt-get -y install git ant 
RUN pip install -U pip && pip install acdh-tei-pyutils

RUN git clone --depth=1 --branch master --single-branch https://github.com/acdh-oeaw/schnitzler-tagebuch.git /tmp/app && cd /tmp/app && git fetch --all && git pull origin master && git submodule update --init --recursive
RUN git clone --depth=1 --branch master --single-branch https://github.com/acdh-oeaw/schnitzler-tagebuch-data.git /tmp/schnitzler-tagebuch-data-public

RUN mentions-to-indices -t "erwähnt in " -i "/tmp/schnitzler-tagebuch-data-public/indices/*.xml" -f "/tmp/schnitzler-tagebuch-data-public/editions/*.xml"

RUN ant -f /tmp/app/build.xml

# START STAGE 2
FROM existdb/existdb:release
ENV JAVA_OPTS="-Xms256m -Xmx2048m -XX:+UseConcMarkSweepGC -XX:MaxHeapFreeRatio=20 -XX:MinHeapFreeRatio=10 -XX:GCTimeRatio=20"

COPY --from=0 /tmp/app/build/*.xar /exist/autodeploy

EXPOSE 8080 8443

RUN [ "java", \
    "org.exist.start.Main", "client", "-l", \
    "--no-gui",  "--xpath", "system:get-version()" ]

CMD [ "java", "-jar", "start.jar", "jetty" ]
