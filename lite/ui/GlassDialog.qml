import QtQuick
import QtQuick.Controls
import "."

Dialog {
 id: panel
 padding:20; spacing:8
 background:Glass {radius:24}
 header:Label {
  text:panel.title;visible:text.length>0
  leftPadding:22;rightPadding:22;topPadding:20;bottomPadding:6
  color:Theme.ink;font.family:Theme.font;font.pixelSize:17;font.weight:Font.DemiBold
  elide:Text.ElideRight
 }
 footer:DialogButtonBox {
  visible:count>0;padding:16;spacing:8;background:null
  delegate:Action {implicitWidth:Math.max(88,implicitContentWidth+32)}
 }
}
