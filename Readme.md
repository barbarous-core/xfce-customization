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