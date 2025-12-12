<img width="256" height="256" alt="Icon1" src="https://github.com/user-attachments/assets/4eba1133-0757-4178-8708-601c5b938c42" />

# Windows Search Rebind to Command Palette
Rebind Windows search to Microsoft PowerToys Command Palette

## Information
The app intercepts the Win+S command using the windows API, after which it finds the HWND of the Powertoys Command Palette window and send It a message as if the tray icon were clicked, this message than in turns shows the main window. Aditionally, the app also brings the window to the top and focuses it. This last part is why the app requires administrative priviledges, because Windows does not allow unpriviledged windows to change the actively focused window.

### Important
You will need to manually add a Task Scheduler task to automatically run the app at startup. I didn't have time to make an installed and add such a feature.

# Download
https://www.codrutsoft.com/apps/windows-search-rebind-to-command-palette

## Command Palette
https://learn.microsoft.com/en-us/windows/powertoys/command-palette/overview

## Image
<img width="1012" height="711" alt="Screenshot 2025-12-12 195657" src="https://github.com/user-attachments/assets/56812ff3-0752-447c-a333-3a5adac171bd" />
