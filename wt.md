# Windows Terminal

Using Windows Terminal for command line is a nice quality of life improvement on Windows.

Go <https://aka.ms/terminal> then either download directly or install through Microsoft Store.

After install, press CTRL+R and type "wt" to open it.

### git-bash in WT

Here are steps to get a git-bash shell in Windows Terminal (WT).

Right click on the title bar, choose "settings" to open the settings tab.

Click "Open JSON file" in bottom left corner.
Then add the following JSON snippet under profile->list.

```json
{
    "commandline": "C:\\Program Files\\Git\\bin\\bash.exe",
    "guid": "{39ae0743-443f-483b-853a-bbcdf50efa9f}",
    "hidden": false,
    "name": "Git Bash"
}
```

Save the file to apply changes.
Click the small down-arrow next to last open tab in title bar and chose "Git Bash" from the dropdown.
