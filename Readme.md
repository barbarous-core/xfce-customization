# xfce configuration steps
## remove old configuration
mv ~/.config/xfce4 ~/.config/xfce4.bak
mv ~/.cache/xfce4 ~/.cache/xfce4.bak
## reseting panels 
xfce4-panel --quit
pkill xfconfd
rm -rf ~/.config/xfce4/panel
rm -rf ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
xfce4-panel &

or Setting > Panel 
![alt text](image.png)
## Downloading themes and icons 
## installing murring engine
sudo dnf install gtk-murrine-engine
## installing plnak
## installing conky
## install conky manager 
sudo dnf copr enable geraldosimiao/conky-manager2
sudo dnf install conky-manager2
## Downloading Wallpaper
---
## Setting initial stow



