
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    var desk = desktopsArray[j];
    desk.wallpaperPlugin = "org.kde.slideshow";
    desk.addWidget("org.kde.plasma.digitalclock");
    desk.addWidget("org.kde.plasma.folder");
//    desk.addWidget("org.kde.plasma.mycroftplasmoid");

    desk.currentConfigGroup = new Array("Wallpaper","org.kde.slideshow","General");
    desk.writeConfig("SlideInterval", 480);
    desk.writeConfig("SlidePaths", "/usr/share/wallpapers/");
}

var panel = new Panel("org.kde.mycroft.panel")
panel.location = "top";
panel.height = 2 * gridUnit;
panel.addWidget("org.kde.plasma.networkmanagement");
//panel.hiding = "windowsbelow";
