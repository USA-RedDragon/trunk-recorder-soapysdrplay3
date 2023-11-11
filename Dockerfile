FROM ghcr.io/usa-reddragon/trunk-recorder:main@sha256:bc831c286783e92b7e5cfbceeca94e3965f12ed1d6c61c7665080023b8ae6633 as base

RUN curl -fSsL https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.07.1.run -o /tmp/sdrplay.run && \
    mkdir -p /tmp/sdrplay && \
    cd /tmp/sdrplay && \
    chmod a+x /tmp/sdrplay.run && \
    /tmp/sdrplay.run --tar xf && \
    ls -lah && \
    _apivers=$(sed -n 's/^VERS="\(.*\)"/\1/p' install_lib.sh) && \
    install -D -m644 sdrplay_license.txt /usr/share/licenses/libsdrplay/LICENSE && \
    install -D -m644 "x86_64/libsdrplay_api.so.${_apivers}" "/usr/lib/libsdrplay_api.so.${_apivers}" && \
    install -D -m755 x86_64/sdrplay_apiService /usr/bin/sdrplay_apiService && \
    install -D -m644 inc/sdrplay_api.h "/usr/include/sdrplay_api.h" && \
    install -D -m644 inc/sdrplay_api_callback.h "/usr/include/sdrplay_api_callback.h" && \
    install -D -m644 inc/sdrplay_api_control.h "/usr/include/sdrplay_api_control.h" && \
    install -D -m644 inc/sdrplay_api_dev.h "/usr/include/sdrplay_api_dev.h" && \
    install -D -m644 inc/sdrplay_api_rsp1a.h "/usr/include/sdrplay_api_rsp1a.h" && \
    install -D -m644 inc/sdrplay_api_rsp2.h "/usr/include/sdrplay_api_rsp2.h" && \
    install -D -m644 inc/sdrplay_api_rspDuo.h "/usr/include/sdrplay_api_rspDuo.h" && \
    install -D -m644 inc/sdrplay_api_rspDx.h "/usr/include/sdrplay_api_rspDx.h" && \
    install -D -m644 inc/sdrplay_api_rx_channel.h "/usr/include/sdrplay_api_rx_channel.h" && \
    install -D -m644 inc/sdrplay_api_tuner.h "/usr/include/sdrplay_api_tuner.h" && \
    install -D -m644 66-mirics.rules "/etc/udev/rules.d/66-mirics.rules" && \
    cd /usr/lib && \
    ln -s "libsdrplay_api.so.${_apivers}" libsdrplay_api.so.2 && \
    ln -s "libsdrplay_api.so.${_apivers}" libsdrplay_api.so && \
    cd - && \
    rm -rf /tmp/sdrplay.run /tmp/sdrplay

RUN git clone https://github.com/pothosware/SoapySDRPlay3.git /tmp/SoapySDRPlay3 && \
    OLDPWD=$(pwd) && \
    cd /tmp/SoapySDRPlay3 && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd "${OLDPWD}" && \
    rm -rf /tmp/SoapySDRPlay3


ARG S6_OVERLAY_VERSION=3.1.6.0
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

RUN <<__DOCKER__EOF__
mkdir -p /etc/s6-overlay/s6-rc.d/sdrplay_apiService/dependencies.d /etc/s6-overlay/s6-rc.d/trunk-recorder/dependencies.d

echo longrun > /etc/s6-overlay/s6-rc.d/sdrplay_apiService/type
echo longrun > /etc/s6-overlay/s6-rc.d/trunk-recorder/type

touch /etc/s6-overlay/s6-rc.d/user/contents.d/sdrplay_apiService
touch /etc/s6-overlay/s6-rc.d/user/contents.d/trunk-recorder
touch /etc/s6-overlay/s6-rc.d/sdrplay_apiService/dependencies.d/base
touch /etc/s6-overlay/s6-rc.d/trunk-recorder/dependencies.d/sdrplay_apiService

cat <<__EOF__ > /etc/s6-overlay/s6-rc.d/sdrplay_apiService/run
#!/command/execlineb -P
/usr/bin/sdrplay_apiService
__EOF__

cat <<__EOF__ > /etc/s6-overlay/s6-rc.d/trunk-recorder/run
#!/command/execlineb -P
trunk-recorder --config=/app/config.json
__EOF__

cat <<__EOF__ > /etc/s6-overlay/s6-rc.d/sdrplay_apiService/finish
#!/bin/bash

# Check if /tmp/sdrplay_apiService-stops exists
if [ -f /tmp/sdrplay_apiService-stops ]; then
    # If it does, then we need to grab the count out of it
    _count=\$(cat /tmp/sdrplay_apiService-stops)
    # If the count is greater than 0, then we need to decrement it and write it back
    if [ \$_count -gt 0 ]; then
        _count=\$((_count-1))
        echo \$_count > /tmp/sdrplay_apiService-stops
        # If the count is 0, then we need to stop the container
        if [ \$_count -eq 0 ]; then
            echo "sdrplay_apiService has stopped 5 times, stopping container"
            echo 1 > /run/s6-linux-init-container-results/exitcode
            /run/s6/basedir/bin/halt
        fi
    fi
else
    # If the file doesnt exist, then we need to create it and write 5 to it
    echo 5 > /tmp/sdrplay_apiService-stops
fi
__EOF__

cat <<__EOF__ > /etc/s6-overlay/s6-rc.d/trunk-recorder/finish
#!/bin/bash

# Check if /tmp/trunk-recorder-stops exists
if [ -f /tmp/trunk-recorder-stops ]; then
    # If it does, then we need to grab the count out of it
    _count=\$(cat /tmp/trunk-recorder-stops)
    # If the count is greater than 0, then we need to decrement it and write it back
    if [ \$_count -gt 0 ]; then
        _count=\$((_count-1))
        echo \$_count > /tmp/trunk-recorder-stops
        # If the count is 0, then we need to stop the container
        if [ \$_count -eq 0 ]; then
            echo "trunk-recorder has stopped 5 times, stopping container"
            echo 1 > /run/s6-linux-init-container-results/exitcode
            /run/s6/basedir/bin/halt
        fi
    fi
else
    # If the file doesnt exist, then we need to create it and write 5 to it
    echo 5 > /tmp/trunk-recorder-stops
fi
__EOF__

chmod +x /etc/s6-overlay/s6-rc.d/*/run /etc/s6-overlay/s6-rc.d/*/finish
__DOCKER__EOF__

ENV S6_CMD_RECEIVE_SIGNALS=1

CMD ["/init"]
ENTRYPOINT ["/init"]
