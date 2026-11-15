import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."
Button {
 id:button
 property bool primary:false
 property bool quiet:false
 implicitHeight:34;implicitWidth:Math.max(54,measure.advanceWidth+28)
 padding:10;opacity:enabled?1:.42
 scale:down?.97:1
 Behavior on scale {NumberAnimation{duration:100}}
 TextMetrics {id:measure;text:button.text;font:button.font}
 font.family:Theme.font;font.pixelSize:12;font.weight:Font.Medium
 background:Glass {
  radius:12;gloss:!button.quiet
  color:button.primary?Theme.blue:button.hovered?Theme.hover:button.quiet?"transparent":Theme.control
  border.color:button.activeFocus?Theme.blue:button.quiet?"transparent":Theme.line
 }
 contentItem:Text {text:button.text;font:button.font;color:button.primary?"white":Theme.ink;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight}
}
