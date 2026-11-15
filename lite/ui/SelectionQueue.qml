import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import TimeSlice.UI 1.0
import "."
Item {
  id:strip
  property var st:studio.uiState
  property bool vertical:false
  Glass {anchors.fill:parent;radius:16;color:Theme.panel}
  ColumnLayout {anchors.fill:parent;anchors.margins:8;spacing:5
   RowLayout {Layout.fillWidth:true
    Label {text:qsTr("已选 ")+strip.st.selectedCount;font.pixelSize:11;font.weight:Font.DemiBold}
    Label {visible:!strip.vertical;text:strip.st.selectionDuration.toFixed(1)+qsTr(" 秒");font.pixelSize:10}
    Item {Layout.fillWidth:true}
    Label {visible:!strip.vertical;text:qsTr("拖动排序");font.pixelSize:10}
   }
   ListView {
    id:sequenceList;objectName:strip.vertical?"selectedSide":"selectedBottom"
    Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:8
    orientation:strip.vertical?ListView.Vertical:ListView.Horizontal;model:studio.selectionModel
    property int previousCount:0
    add:Transition {NumberAnimation {properties:"opacity";from:0;to:1;duration:150}}
    onCountChanged:{if(count>previousCount)Qt.callLater(function(){sequenceList.positionViewAtEnd()});previousCount=count}
    ScrollBar.horizontal:ScrollBar {policy:strip.vertical?ScrollBar.AlwaysOff:ScrollBar.AsNeeded}
    ScrollBar.vertical:ScrollBar {policy:strip.vertical?ScrollBar.AsNeeded:ScrollBar.AlwaysOff}
    displaced:Transition {NumberAnimation {properties:"x,y";duration:150;easing.type:Easing.OutCubic}}
    delegate:DropArea {
     id:dropCell
     required property var entry;required property int index
     width:strip.vertical?sequenceList.width:112;height:strip.vertical?112:sequenceList.height
     keys:["timeslice-selected"]
     onEntered:drag=>{if(drag.source && drag.source.effectId!==entry.id)studio.moveSelection(drag.source.effectId,index)}
     Rectangle {anchors.fill:parent;radius:12;color:Theme.control;border.color:Theme.line}
     Rectangle {
      id:sequenceCard;objectName:"selectedCard_"+entry.id
      property int effectId:entry.id
      width:dropCell.width;height:dropCell.height;radius:12
      color:strip.st.active===entry.id?Theme.selected:Theme.control
      border.width:strip.st.active===entry.id?2:1;border.color:strip.st.active===entry.id?Theme.blue:Theme.line
      opacity:cardDrag.active?.90:1;scale:cardDrag.active?1.035:1;z:cardDrag.active?100:0
      Drag.active:cardDrag.active;Drag.source:sequenceCard;Drag.keys:["timeslice-selected"]
      Drag.hotSpot.x:width/2;Drag.hotSpot.y:height/2
      states:State {when:cardDrag.active;ParentChange {target:sequenceCard;parent:Overlay.overlay}}
      RoundedPreview {
       x:3;y:3;width:parent.width-6;height:Math.max(28,parent.height-36);radius:9
       source:studio.assets+"thumbnails/"+entry.key+".jpg"
      }
      Label {x:7;y:parent.height-29;width:parent.width-14;text:entry.name;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;font.pixelSize:10;font.weight:Font.Medium}
      Label {x:7;y:parent.height-15;width:parent.width-14;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;text:entry.seconds.toFixed(1)+qsTr(" 秒");font.pixelSize:9}
      Rectangle {x:7;y:7;width:19;height:19;radius:9.5;color:Theme.panel
       Label {anchors.centerIn:parent;text:entry.rank;font.pixelSize:10;font.weight:Font.DemiBold}
      }
      TapHandler {onTapped:(point,button)=>{if(point.position.x>sequenceCard.width-30 && point.position.y<30)studio.removeSelection(entry.id);else studio.activateSelection(entry.id)}}
      DragHandler {
       id:cardDrag;target:sequenceCard;enabled:!strip.st.rendering;cursorShape:active?Qt.ClosedHandCursor:Qt.OpenHandCursor
       onActiveChanged:if(!active)Qt.callLater(function(){if(sequenceCard && sequenceCard.parent===dropCell){sequenceCard.x=0;sequenceCard.y=0}})
      }
      Rectangle {anchors.top:parent.top;anchors.right:parent.right;anchors.margins:6;width:19;height:19;radius:9.5;color:Theme.panel
       Label {anchors.centerIn:parent;text:"×";font.pixelSize:14}
       HoverHandler {cursorShape:Qt.PointingHandCursor}
       Accessible.role:Accessible.Button;Accessible.name:qsTr("移除 ")+entry.name;Accessible.onPressAction:studio.removeSelection(entry.id)
      }
      Accessible.role:Accessible.Button;Accessible.name:entry.rank+" · "+entry.name;Accessible.onPressAction:studio.activateSelection(entry.id)
     }
    }
   }
  }
 }
