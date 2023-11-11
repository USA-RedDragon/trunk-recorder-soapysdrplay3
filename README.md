# Trunk Recorder with SoapySDRPlay3

These are images of [robotastic/trunk-recorder](https://github.com/robotastic/trunk-recorder) builds with the [pothosware/SoapySDRPlay3](https://github.com/pothosware/SoapySDRPlay3) library installed along with the [SDRPlay API v3.07](https://www.sdrplay.com/api/). These builds are `amd64` only for now.

## Fork note

This uses [a fork of Trunk Recorder](https://github.com/USA-RedDragon/trunk-recorder/tree/main) until [this fix for SoapySDRPlay3](https://github.com/robotastic/trunk-recorder/pull/853) can be merged upstream, so upstream changes may be slightly delayed.

## Images

- `ghcr.io/usa-reddragon/trunk-recorder-soapysdrplay3:main`  - just Trunk Recorder with the libraries for SDRPlay units
- `ghcr.io/usa-reddragon/trunk-recorder-soapysdrplay3-prometheus:main` - Same as above, but contains the [Prometheus plugin for Trunk Recorder](https://github.com/USA-RedDragon/trunk-recorder-prometheus)

## SDRPlay Copyright

I believe this would be considered a "derivative work" of the SDRPlay API, so I am including the following notice:

> This project uses the SDRPlay API licensed by SDRplay Limited, a company registered in England (No. 09035244), whose registered office is 21 Lenten Street ALTON Hampshire GU34 1HG UK(“SDRplay”)
> This product distributes the unmodified, binary form of the SDRPlay API.
> The relevant license for the SDRPlay API can be found at [LICENSE.sdrplay](./LICENSE.sdrplay)
> The SDRPlay API is available from <https://www.sdrplay.com/api/>
