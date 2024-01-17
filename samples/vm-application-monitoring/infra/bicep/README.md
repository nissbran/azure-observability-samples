# Deploy resources with Bicep

To deploy the resources with Bicep you need to have the following tools installed:
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)


## Deploy the setup

To deploy first create a parameter file **main.bicepparam** with the following content:

```bicep
using 'main.bicep'

param location = 'yourlocation' // Replace with your own location e.g. northeurope
param vmPassword = 'yourpassword'
param ipAddressSource = 'youripaddressIP4'
param emailAddress = [
  'youremailaddress'
]
```

Top deploy the resources run the following command, replacing the location with your own values:

```bash
az deployment sub create -n vmmondemo -l yourlocation --template-file main.bicep --parameters main.bicepparam
```
