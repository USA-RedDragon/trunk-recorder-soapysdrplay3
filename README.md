# Trunk Recorder with SoapySDRPlay3

These are images of [robotastic/trunk-recorder](https://github.com/robotastic/trunk-recorder) builds with the [pothosware/SoapySDRPlay3](https://github.com/pothosware/SoapySDRPlay3) library installed along with the [SDRPlay API v3.07](https://www.sdrplay.com/api/). These builds are `amd64` only for now.

## Fork note

This uses [a fork of Trunk Recorder](https://github.com/USA-RedDragon/trunk-recorder/tree/main) until [this fix for SoapySDRPlay3](https://github.com/robotastic/trunk-recorder/pull/853) can be merged upstream, so upstream changes may be slightly delayed.

## Images

- `ghcr.io/usa-reddragon/trunk-recorder-soapysdrplay3:main`  - just Trunk Recorder with the libraries for SDRPlay units
- `ghcr.io/usa-reddragon/trunk-recorder-soapysdrplay3-prometheus:main` - Same as above, but contains the [Prometheus plugin for Trunk Recorder](https://github.com/USA-RedDragon/trunk-recorder-prometheus)
