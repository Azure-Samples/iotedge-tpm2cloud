param location string = resourceGroup().location

resource iotHub 'Microsoft.Devices/IotHubs@2021-07-01' = {
  name: '${uniqueString(resourceGroup().id)}-iothub'
  location: location
  sku: {
    capacity: 1
    name: 'S1'
  }
  properties: {}
}

resource dps 'Microsoft.Devices/provisioningServices@2020-01-01' = {
  name: '${uniqueString(resourceGroup().id)}-dps'
  location: location
  sku: {
    name: 'S1'
    capacity: 1
  }

  properties: {
    iotHubs: [
      {
        connectionString: 'HostName=${iotHub.name}.azure-devices.net;SharedAccessKeyName=${listKeys(iotHub.id, '2020-04-01').value[0].keyName};SharedAccessKey=${listKeys(iotHub.id, '2020-04-01').value[0].primaryKey}'
        location: location
      }
    ]
  }
}
