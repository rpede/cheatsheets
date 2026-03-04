# SSH on Windows

These instructions should work for Windows 10/11.
Let me know if you have any trouble.

## Install Windows Terminal

Go to <https://aka.ms/terminal>.
Then either download directly or install through Microsoft Store.

After install, press CTRL+R and type "wt" to open it.

## Enable the built-in OpenSSH Client

- Open Settings
  - Settings → Apps → Optional features
- Check if OpenSSH Client is installed
  - Look for OpenSSH Client in the installed features list.
- Install it if missing
  - Click View features (or Add a feature in some Windows 10 builds)
  - Search for OpenSSH Client
  - Check it and click Install
- Verify it works
  - Open Windows Terminal
  - Run: `ssh -V`
  - You should see an OpenSSH version string.

[Source](https://windowsforum.com/threads/set-up-windows-10-11-ssh-client-ssh-config-for-one-command-server-logins.401594/)
