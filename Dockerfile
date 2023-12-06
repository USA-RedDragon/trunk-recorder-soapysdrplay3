ARG BASE_IMAGE=ghcr.io/robotastic/trunk-recorder:edge@sha256:ed656cd3ffe1f866715599bdb8578c3e1b19daea84e4d014b17b98fad91cb797
FROM ${BASE_IMAGE}

ARG TARGETPLATFORM
ARG TARGETARCH

# https://www.sdrplay.com/software/SDRplay_RSP_API-ARM32-3.07.2.run ./armv7l
# https://www.sdrplay.com/software/SDRplay_RSP_API-ARM64-3.07.1.run ./aarch64
# https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.07.1.run ./x86_64

RUN PLATFORM=$(echo ${TARGETPLATFORM} | awk -F/ '{print $1}') && \
    case ${PLATFORM} in \
        linux) \
            echo "Building for linux" \
            ;; \
        *) \
            echo "Unknown platform: ${PLATFORM}" \
            exit 1 \
            ;; \
    esac && \
    DOCKER_ARCH=$(echo ${TARGETPLATFORM} | awk -F/ '{print $2}') && \
    case ${DOCKER_ARCH} in \
        amd64) \
            _sdrplay_arch_version="Linux-3.07.1" \
            _sdrplay_arch="x86_64" \
            ;; \
        arm64) \
            _sdrplay_arch_version="ARM64-3.07.1" \
            _sdrplay_arch="aarch64" \
            ;; \
        arm) \
            _sdrplay_arch_version="ARM32-3.07.2" \
            _sdrplay_arch="armv7l" \
            ;; \
        *) \
            echo "Unknown docker arch: ${DOCKER_ARCH}" \
            exit 1 \
            ;; \
    esac && \
    curl -fSsL https://www.sdrplay.com/software/SDRplay_RSP_API-${_sdrplay_arch_version}.run -o /tmp/sdrplay.run && \
    mkdir -p /tmp/sdrplay && \
    cd /tmp/sdrplay && \
    chmod a+x /tmp/sdrplay.run && \
    /tmp/sdrplay.run --tar xf && \
    _apivers=$(sed -n 's/^\(export \)\{0,1\}VERS="\(.*\)"/\2/p' install_lib.sh) && \
    install -D -m644 sdrplay_license.txt /usr/share/licenses/libsdrplay/LICENSE && \
    install -D -m644 "${_sdrplay_arch}/libsdrplay_api.so.${_apivers}" "/usr/lib/libsdrplay_api.so.${_apivers}" && \
    install -D -m755 "${_sdrplay_arch}/sdrplay_apiService" /usr/bin/sdrplay_apiService && \
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

# renovate: datasource=github-tags depName=pothosware/SoapySDRPlay3
ARG SOAPYSDRPLAY3_VERSION=soapy-sdrplay3-0.4.2
RUN git clone https://github.com/pothosware/SoapySDRPlay3.git -b ${SOAPYSDRPLAY3_VERSION} /tmp/SoapySDRPlay3 && \
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

# renovate: datasource=github-releases depName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION=v3.1.6.0
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
RUN \
    case ${TARGETARCH} in \
        amd64) \
            filename="s6-overlay-x86_64.tar.xz" \
            ;; \
        arm64) \
            filename="s6-overlay-aarch64.tar.xz" \
            ;; \
        arm) \
            filename="s6-overlay-arm.tar.xz" \
            ;; \
        *) \
            echo "Unknown target arch: ${TARGETARCH}" \
            exit 1 \
            ;; \
    esac && \
    curl -fSsL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/${filename} -o /tmp/${filename} && \
    tar -C / -Jxpf /tmp/${filename} && \
    rm -rf /tmp/${filename}

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

ENTRYPOINT ["/init"]
