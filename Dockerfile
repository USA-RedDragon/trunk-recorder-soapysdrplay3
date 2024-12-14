ARG BASE_IMAGE=ghcr.io/robotastic/trunk-recorder:edge@sha256:e6c5f9b15b1227adfe5ccab88e8f0cc88f419d52e96d513f3068455a551c73d2
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
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
      git \
      cmake \
      libsoapysdr-dev \
      build-essential && \
    git clone https://github.com/pothosware/SoapySDRPlay3.git -b ${SOAPYSDRPLAY3_VERSION} /tmp/SoapySDRPlay3 && \
    OLDPWD=$(pwd) && \
    cd /tmp/SoapySDRPlay3 && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd "${OLDPWD}" && \
    rm -rf /tmp/SoapySDRPlay3 && \
    apt-get remove -y libsoapysdr-dev cmake git build-essential && \
    rm -rf /var/lib/apt/lists/*

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

echo -n 5 > /etc/s6-overlay/s6-rc.d/sdrplay_apiService/max-death-tally
echo -n 5 > /etc/s6-overlay/s6-rc.d/trunk-recorder/max-death-tally

chmod +x /etc/s6-overlay/s6-rc.d/*/run
__DOCKER__EOF__

ENV S6_CMD_RECEIVE_SIGNALS=1

ENTRYPOINT ["/init"]
