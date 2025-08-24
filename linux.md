# Linux (CLI)

<!--toc:start-->
- [Linux (CLI)](#linux-cli)
  - [Files and folders](#files-and-folders)
  - [Scripting](#scripting)
  - [System](#system)
  - [Managing software on Ubuntu (or Debian)](#managing-software-on-ubuntu-or-debian)
  - [Manage services](#manage-services)
<!--toc:end-->

## Files and folders

The file system key in Linux.

```sh
# Change directory
cd Documents

# Navigate to parent folder
cd .

# Go to home (your users) folder
cd ~

# Print current working directory
pwd

# List files
ls

# List files in a specific directory
ls Documents

# List files with details (long)
ls -l

# List hidden files also
ls -a
# NOTE: hidden files start with a "." (dot)

# Make an empty file
touch file.txt
# NOTE: actually "touch" is meant to update the last accessed/modified timestamp, but it will also create the file if it doesn't exist.

# Append some text to a file
echo "Hello World" >> file.txt

# Print content of a file
cat file1.txt

# Print concatenated content of several files
cat file1.txt file2.txt

# Scroll through a file
less file.txt

# Remove a file
rm file.txt

# Remove a directory and all of its contents (no trash/recycle bin)
rm -r Documents
```

## Scripting

```sh
# To execute a file or script
/path/to/file

# To execute a file or script in your current folder
./file

# Scripts often end with .sh
./script.sh

# Set a variable
MY_VAR="some value"

# Set a variable that can be access in subprocesses
export MY_VAR="some value"

# Check the value of a variable
echo $MY_VAR

# There are also some build in variables

# See what shell you are running
echo $SHELL

# Check all variable set in your shell (environment)
env

# Conditions
if [ $SHELL = "/bin/bash" ]
then
  echo "Your are running bash!"
else
  echo "Guess you are using $SHELL"
fi

# For each loop
for i in 1 2 3; do echo $i; done

# For each in range
for i in {1..10}; do echo $i; done

# While loop
while [ $i -le 5 ]
do
  echo $i
  let "i+=1"
done
# NOTE: The following is used for integer comparison: -eq -le -lt -ge -gt
```

## System

```sh
# List processes
ps

# List all processes for all users
ps aux

# Show addresses of network adapters (MAC + IP)
ip addr show
# Same on older systems
ifconfig

# Display free disk (storage) space
df

# Display free disk (storage) space, but human readable
df -h

# Display free memory
free

# Display free memory, but human readable
free -h
```

## Managing software on Ubuntu (or Debian)

This is a bit different then what you are likely used to on Windows an macOS.
On Linux you have something called a package manager to install and manage
software for you.
In means that don't have to go to websites and download an installation file manually.
An amazing thing about package managers is that if a piece of software depends
on another pieces of software being installed to function then it will install
that other piece automatically.

The commands below a specific to the
[APT](<https://en.wikipedia.org/wiki/APT_(software)>) package manager found in
Ubuntu and Debian.

```sh
# List software you have installed (warning long list)
sudo apt list

# List software that can be upgraded
sudo apt list --upgradeable

# Update list  packages
sudo apt update

# Upgrade installed packages
sudo apt upgrade

# Search for a package (here we are searching for "node")
sudo apt search node

# Install a package (here the package "nodejs")
sudo apt install nodejs

# Remove a package (here "nodejs")
sudo apt remove nodejs

# Remove a package with its dependencies ("nodejs")
sudo apt autoremove nodejs
```

Changing installed software requires super-user (aka root) privileges.
To execute a command with those privileges you can prefix it with `sudo` which
is short for "super-user do".

Some commands like `apt install ...` might prompt you to answer some questions.
If you don't want to be prompted, then you can answer yes to all questions with
`apt -y install` instead.
Not recommended unless you really know what you are doing.

## Manage services

Services on modern Linux is managed by systemd.
A service (in this context) is a program that users don't interact with
directly, they are running in the background doing various task such as
managing network connections or running a web server.
A service is also sometimes referred to as a
[daemon](<https://en.wikipedia.org/wiki/Daemon_(computing)>).

The command we use to interact with systemd services is `systemctl` (ctl for
control).

```sh
# See status of a service (using "ssh" example)
systemctl status ssh

# Start a service
systemctl start ssh

# Stop a service
systemctl stop ssh

# Restart a service
systemctl restart ssh

# View log (aka journal) of a service (aka unit)
journalctl -u ssh

# Same, but with some explanation
journal -ux ssh
```
