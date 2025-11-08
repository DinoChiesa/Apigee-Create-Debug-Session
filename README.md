# Shows how to create a Debug Session in Apigee

This repo shows how you can programmatically create a Debug Session within
Apigee, invoke API transactions, and then examine the output of the debug session.
This can be the basis for a more formal API testing effort.

## Pre-requisites

You MAY just want to examine the code and API proxy configuration here.

If you actually want to _use it_, then you will need:

- a provisioned Apigee instance
- a user with permissions to create and deploy proxies. Get these permissions via the Apigee orgadmin role, or the API Admin role (`roles/apigee.apiAdminV2`). ([more on Apigee-specific roles](https://cloud.google.com/apigee/docs/api-platform/system-administration/apigee-roles#apigee-specific-roles))

For your shell,
- a Linux shell, and utilities like jq, curl, and mktemp
- the [gcloud command line tool](https://cloud.google.com/sdk/docs/install)

[Google Cloud Shell](https://cloud.google.com/shell/docs) is sufficient, and has all of these preconfigured, but you can use your own workstation.


# Using this example

1. Using a text editor, modify the environment file `env.sh`, to suit your purposes.
   Open your shell, and source the file:
   ```sh
   source ./env.sh
   ```

2. Import and deploy the proxy:
   ```sh
   ./1-import-and-deploy-proxy.sh
   ```

3. Create a Debug session, and Invoke the proxy:
   ```sh
   2-invoke-with-debug-session.sh
   ```

   You should see the debug session data on the terminal.

   One could imagine building assertions from the data provided
   in that debug session.

   While the debug session schema is not a documented part of Apigee,
   it is stable and unlikely to change, as many tools depend on it.





## Disclaimer

This example is not an official Google product, nor is it part of an
official Google product.


## License

This material is [Copyright © 2025 Google LLC](./NOTICE).
and is licensed under the [Apache 2.0 License](LICENSE). This includes the Java
code as well as the API Proxy configuration.

## Support

This example is open-source software, and is not a supported part of Apigee.  If
you need assistance, you can try inquiring on [the Google Cloud Community forum
dedicated to Apigee](https://goo.gle/apigee-community) There is no service-level
guarantee for responses to inquiries posted to that site.
