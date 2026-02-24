# SSH on Windows

## Enable the built-in OpenSSH Client (Windows 10/11)

- Open Settings
  - Windows 11: Settings → Apps → Optional features
  - Windows 10: Settings → Apps → Optional features
- Check if OpenSSH Client is installed
  - Look for OpenSSH Client in the installed features list.
- Install it if missing
  - Click View features (or Add a feature in some Windows 10 builds)
  - Search for OpenSSH Client
  - Check it and click Install
- Verify it works
  - Open Windows Terminal, PowerShell, or Command Prompt
  - Run: `ssh -V`
  - You should see an OpenSSH version string.

[Source](https://windowsforum.com/threads/set-up-windows-10-11-ssh-client-ssh-config-for-one-command-server-logins.401594/)
