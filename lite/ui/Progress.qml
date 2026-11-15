import QtQuick
import QtQuick.Controls
import "."
ProgressBar {
 id:bar
 implicitHeight:6
 background:Rectangle {radius:3;color:Theme.line}
 contentItem:Item {Rectangle {width:bar.visualPosition*parent.width;height:parent.height;radius:3;color:Theme.blue;Behavior on width {NumberAnimation{duration:120}}}}
}
