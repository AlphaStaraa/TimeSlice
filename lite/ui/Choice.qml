import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."
ComboBox {
 id:choice
 implicitHeight:34;Layout.fillWidth:true;Layout.minimumWidth:0
 opacity:enabled?1:.45
 background:Glass {radius:11;color:choice.popup.visible?Theme.selected:Theme.control;border.color:choice.activeFocus?Theme.blue:Theme.line}
 contentItem:Label {text:choice.displayText;font.pixelSize:12;leftPadding:22;rightPadding:22;horizontalAlignment:Text.AlignHCenter}
 indicator:Label {x:choice.width-20;y:(choice.height-height)/2;text:"⌄";font.pixelSize:15;color:Theme.muted}
 delegate:ItemDelegate {
  id:entry
  required property var modelData;required property int index
  width:choice.popup.availableWidth;implicitHeight:34
  highlighted:choice.highlightedIndex===index
  background:Glass {radius:8;color:entry.highlighted?Theme.hover:entry.index===choice.currentIndex?Theme.selected:"transparent";border.color:"transparent"}
  contentItem:Label {text:String(entry.modelData);font.pixelSize:12;horizontalAlignment:Text.AlignHCenter;leftPadding:12;rightPadding:12}
 }
 popup:Popup {
  popupType:Popup.Item;y:choice.height+5;width:choice.width;padding:6
  implicitHeight:Math.min(310,contentItem.implicitHeight+12)
  background:Glass {radius:15}
  contentItem:ListView {clip:true;implicitHeight:contentHeight;model:choice.popup.visible?choice.delegateModel:null;currentIndex:choice.highlightedIndex;ScrollIndicator.vertical:ScrollIndicator{}}
 }
}
