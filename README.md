## Auto-accept AirPlay requests

***Allow other devices to AirPlay to your mac without the need to manually approve each request***

This is a lightweight macOS application that intercepts incoming notifications alerts about devices requesting to AirPlay to your computer and automatically accepts them.

### Features

- Extremely minimal footprint and resource consumption
- No network requests, runs local code only
- Runs as low priority background process
- Automates Launch Agent registration 
- Gracefully handles security permissions (and lack thereof)
- Auto-recovers from crashes

### Installation

- Get the [latest release](https://github.com/duddu/auto-accept-airplay-requests/releases/latest)
- Save the app anywhere on your mac
- Launch it and follow the prompt for permissions

The app is now up and running in the background, and will only make itself visible if anything changes in terms of permissions.

### Who is it for

Anyone wishing to use more than once a macOS machine as an AirPlay receiver/speaker from a device not logged into the same exact iCloud account; especially if they cannot always promptly react to incoming notifications on that machine.  
E.g. you got a mac at home you use as media server, you just want anybody on your network to be able to AirPlay to it from their device. Sounds easy? Right! Sadly, this will never happen without your manual intervention: unless the same iCloud account is logged in on both device and receiver, you'll keep having to manually click "Accept" on the AirPlay request notification. Even if you are on the same network, even if you previously approved the same device, and even if the device user is in your same iCloud Family. And yes, it doesn't matter which option you chose in "Allow AirPlay for" settings (that only determines which devices will be able to *detect* your mac as a receiver).

### License

Mozilla Public License Version 2.0
