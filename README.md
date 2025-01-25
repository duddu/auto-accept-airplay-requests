# (Auto) Accept AirPlay Requests

<picture>
  <source media="(min-width: 880px)" srcset="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/airplay-notification.png 2x" />
  <img align="right" alt="AirPlay notification alert" src="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/empty.png" />
</picture>

A lightweight, single-purpose macOS app that automatically allows other devices to AirPlay to your computer, eliminating the need for manual intervention—otherwise required when the device is signed into a different iCloud account. It intercepts incoming notification alerts for devices attempting to AirPlay to your Mac and programmatically accepts them.

## Feature Highlights

- Extremely **minimal footprint** and resource consumption
- Written in modern **Swift** for maintainability and performance
- Operates as a low-priority, self-recovering **background process**
- Auto-startup at login (embedded **Launch Agent** registration)
- Gracefully manages **security permissions** (and lack thereof)

## Get Started

- Download the [latest release](https://github.com/duddu/auto-accept-airplay-requests/releases/latest)
- Extract the app anywhere on your Mac
- Open it and follow the prompt for permissions

The app is now running in the background (i.e. no active icon in the Dock), and will only make itself visible if any user action is required (e.g. missing security permissions).

> [!TIP]
> The first time you open the app, macOS will warn that it is from an **unidentified developer** (i.e. not paying Apple $99/yr). To proceed, go to System Settings > Privacy & Security and click [*Open Anyway*](https://support.apple.com/en-us/102445#openanyway). However, you can still verify the app's **code signature** yourself by following the instructions in the release notes.

## Who needs it

Anyone wishing to regularly use a Mac as an AirPlay receiver from a device not logged into the same iCloud account, especially if they cannot always promptly react to incoming notifications on that computer.

E.g. let's say you have a Mac at home that you use mainly as a media/data server, so it may not always be connected to a physical monitor, mouse, or keyboard (e.g. maybe you mainly access it via VNC or SSH). You just want anybody on your network to be able to AirPlay to it from their device. Sounds easy? Right! Sadly, this will never happen without your manual intervention: macOS will *always* pop up a notification alert for you to accept, *unless* you are logged into iCloud with the very same Apple account on both the device and the receiver Mac.  
This happens even if you both are **on the same network**, even if you **previously approved** the same device, and even if the device user is in your **same iCloud Family**.

<picture>
  <source media="(min-width: 1070px)" srcset="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/allow-airplay-for-settings.png 2x" />
  <img align="right" alt="Allow AirPlay for" src="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/empty.png" />
</picture>

> [!NOTE]
> This behavior is not affected by the option you selected in System Settings > General > AirDrop & Handoff > **Allow AirPlay for**—that setting (albeit still needed) only determines which devices will be able to *detect* your Mac as an AirPlay receiver.

## Usage & Configuration

### Security

<picture>
  <source media="(min-width: 980px)" srcset="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/accessibility-permission.png 2x" />
  <img align="right" alt="Accessibility permission" src="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/empty.png" />
</picture>

The only required security permission is System Settings > Privacy & Security > **Accessibility** (needed to emulate clicking the *Accept* button on AirPlay request notifications). The app automatically checks if this permission has been granted and provides instructions if not.

### Quit

<picture>
  <source media="(min-width: 980px)" srcset="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/allow-in-the-background.png 2x" />
  <img align="right" alt="Allow in the Background" src="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/empty.png" />
</picture>

After the first launch, the app runs as a background process (i.e. no active icon in the Dock). To manage it, go to System Settings > General > Login Items & Extensions > **Allow in the Background**. Disabling it there will stop the running process and prevent it from launching automatically at login.

### Update

To update the app to a different [release version](https://github.com/duddu/auto-accept-airplay-requests/releases), you must first [quit](#quit) the running background process. Then, simply replace the existing application bundle (*Accept AirPlay Requests.app*) and re-enable the background process.

### Uninstall

First [quit](#quit) the running background process, then move the application bundle (*Accept AirPlay Requests.app*) to the Trash. Any related configurations will be automatically removed from System Settings at the next reboot.

## Development

Feel free to report any issue or suggest an enhancement. Any contribution is more than welcome: please open your Pull Request against the *latest* branch.

### Logging

Run the following command from your terminal to live-stream all logs emitted by the app:

```sh
log stream --predicate 'subsystem CONTAINS "dev.duddu.AcceptAirPlayRequests"' --level debug
```
