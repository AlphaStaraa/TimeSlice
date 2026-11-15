import QtQuick
import QtQuick.Controls
import "."
Switch {
 id:toggle
 implicitWidth:38;implicitHeight:26;padding:0
 indicator:Rectangle {
  width:34;height:20;x:2;y:3;radius:10;color:toggle.checked?Theme.blue:Theme.line
  Rectangle {x:toggle.checked?16:2;y:2;width:16;height:16;radius:8;color:"white";Behavior on x {NumberAnimation{duration:110}}}
 }
}
