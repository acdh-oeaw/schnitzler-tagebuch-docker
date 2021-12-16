FROM python:3.8-buster

USER root


WORKDIR /tmp

RUN apt-get update && apt-get -y install git ant && pip install -U pip 
RUN pip install acdh-tei-pyutils==0.16

RUN git clone --depth=1 --branch master --single-branch https://github.com/acdh-oeaw/schnitzler-tagebuch.git /tmp/app && cd /tmp/app && git fetch --all && git pull origin master && git submodule update --init --recursive
RUN git clone --depth=1 --branch master --single-branch https://github.com/acdh-oeaw/schnitzler-tagebuch-data.git /tmp/schnitzler-tagebuch-data-public

RUN add-attributes -g "/tmp/schnitzler-tagebuch-data-public/editions/*.xml" -b "https://id.acdh.oeaw.ac.at/schnitzler/schnitzler-tagebuch/editions" \
    && add-attributes -g "/tmp/schnitzler-tagebuch-data-public/indices/list*.xml" -b "https://id.acdh.oeaw.ac.at/schnitzler/schnitzler-tagebuch/indices"

RUN cd /tmp/schnitzler-tagebuch-data-public
# RUN mkdir /tmp/app/data && cp -rf /tmp/schnitzler-tagebuch-data-public/indices /tmp/app/data/shadowindices \
#     && mentions-to-indices -t "erwähnt in " -i "/tmp/app/data/shadowindices/*.xml" -f "/tmp/schnitzler-tagebuch-data-public/editions/*.xml"
RUN ant -f /tmp/app/build.xml

# START STAGE 2
FROM acdhch/existdb:5.2.0-java11-ShenGC

COPY --from=0 /tmp/app/build/*.xar /exist/autodeploy

EXPOSE 8080 8443

RUN [ "java", \
    "org.exist.start.Main", "client", "-l", \
    "--no-gui",  "--xpath", "system:get-version()" ]

CMD [ "java", "-jar", "start.jar", "jetty" ]
