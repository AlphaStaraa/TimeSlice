import QtQuick
import QtQuick.Controls
import TimeSlice.UI 1.0
import "."
Item {
 id:card
 property var entry
 property bool batch:false
 property bool selected:false
 property bool active:false
 property bool busy:false
 height:108
 Glass {anchors.fill:parent;radius:14;color:card.active?Theme.selected:Theme.control;border.width:card.active?2:1;border.color:card.active?Theme.blue:Theme.line}
 RoundedPreview {
  x:4;y:4;width:parent.width-8;height:70;radius:10
  source:studio.assets+"thumbnails/"+card.entry.key+".jpg"
  animationSource:studio.assets+"thumbnails/"+card.entry.key+".gif"
  playing:hover.hovered&&!card.busy
 }
 Label {x:7;y:79;width:parent.width-14;height:20;text:card.entry.name;font.pixelSize:11;font.weight:card.active?Font.DemiBold:Font.Normal;horizontalAlignment:Text.AlignHCenter}
 Rectangle {
  visible:card.batch||card.selected;x:parent.width-26;y:8;width:18;height:18;radius:9
  color:card.selected?Theme.blue:Theme.panel;border.color:card.selected?"transparent":Theme.line
  Label {anchors.centerIn:parent;text:card.selected?"✓":"";color:"white";font.pixelSize:11}
  TapHandler {enabled:card.batch&&!card.busy;onTapped:studio.toggleEffect(card.entry.id)}
 }
 HoverHandler {id:hover;cursorShape:Qt.PointingHandCursor}
 TapHandler {enabled:!card.busy;onTapped:(point,button)=>{if(!card.batch||point.position.x<card.width-30||point.position.y>30)studio.setActive(card.entry.id)}}
 Accessible.role:Accessible.Button;Accessible.name:entry.name;Accessible.onPressAction:studio.setActive(entry.id)
}
