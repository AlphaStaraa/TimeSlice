import QtQuick
import "."
Rectangle {
 id:glass
 property bool gloss:true
 color:Theme.panel;radius:16;border.color:Theme.line;antialiasing:true
 Rectangle {
  anchors.fill:parent;anchors.margins:1;radius:Math.max(0,glass.radius-1)
  visible:glass.gloss;antialiasing:true
  gradient:Gradient {
   GradientStop {position:0;color:Theme.dark?"#14FFFFFF":"#80FFFFFF"}
   GradientStop {position:.55;color:"transparent"}
   GradientStop {position:1;color:Theme.dark?"#08253043":"#08608CCD"}
  }
 }
}
