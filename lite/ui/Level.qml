import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."
RowLayout {
 id:level
 property real value:0
 property real from:0
 property real to:1
 property bool percent:true
 signal adjusted(real amount)
 Layout.fillWidth:true;Layout.minimumWidth:0;spacing:6
 Slider {
  id:slider;Layout.fillWidth:true;Layout.minimumWidth:30
  from:level.from;to:level.to;value:level.value;onMoved:level.adjusted(value)
  background:Rectangle {x:slider.leftPadding;y:slider.topPadding+slider.availableHeight/2-height/2;width:slider.availableWidth;height:4;radius:2;color:Theme.line
   Rectangle {width:slider.visualPosition*parent.width;height:4;radius:2;color:Theme.blue}
  }
  handle:Rectangle {x:slider.leftPadding+slider.visualPosition*(slider.availableWidth-width);y:slider.topPadding+(slider.availableHeight-height)/2;width:15;height:15;radius:7.5;color:Theme.dark?"#DCE7F5":"white";border.color:Theme.line}
 }
 Label {text:level.percent?Math.round(level.value*100)+"%":Number(level.value.toFixed(1)).toString();Layout.preferredWidth:38;horizontalAlignment:Text.AlignRight;font.pixelSize:11;color:Theme.muted}
}
