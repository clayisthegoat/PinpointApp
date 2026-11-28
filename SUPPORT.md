# Pinpoint Support

Pinpoint is maintained on a best-effort basis. Community support does not carry
a guaranteed response time, and cellular behavior can vary with the iPhone,
iOS build, VPN state, installation method, and signing and provisioning state.

## Before asking for help

1. Read the [requirements, setup, and limitations](README.md).
2. Install the latest [Pinpoint release](https://github.com/clayisthegoat/PinpointApp/releases/latest).
3. Confirm Developer Mode is enabled and LocalDevVPN is installed and permitted.
4. Search [existing issues](https://github.com/clayisthegoat/PinpointApp/issues).

Use the repository's issue forms for:

- A reproducible Pinpoint bug
- An iPhone, iOS, network, or destination-app compatibility result
- A focused feature request

For troubleshooting, include the Pinpoint version, exact iOS version, iPhone
model, installation method, connection type, LocalDevVPN status, reproduction
steps, expected behavior, and actual behavior. Screenshots and logs must be
sanitized first.

> [!CAUTION]
> Never share a `.mobiledevicepairing` file, pairing-record contents, Apple or
> signing credentials, device tokens, private keys, or secrets embedded in
> callback URLs. Remove UDIDs, account details, and unrelated personal data from
> screenshots and logs.

If the problem may expose credentials, bypass a security boundary, or affect
other users, stop troubleshooting publicly and follow the private process in
[SECURITY.md](SECURITY.md).
