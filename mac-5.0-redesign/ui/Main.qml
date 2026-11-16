import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Shapes
import QtQuick.Window
import TimeSlice.UI 1.0

ApplicationWindow {
 id: root; width: 1320; height: 842; minimumWidth: root.st.language === "en" ? 1120 : 994; minimumHeight: 662; visible: true
 title: qsTr("时刃") + " · " + root.st.version; color: root.surface
 property var st: studio.uiState
 property bool dark: Qt.styleHints.colorScheme === Qt.ColorScheme.Dark
 Connections {
  target: studio
  // 切换语言前保存当前面板选择。
  function onLanguageChanging() {root.languageInspectorPage=inspectorTabs.currentIndex}
  // 切换语言后恢复面板与参数绑定，避免选择跳动。
  function onLanguageChanged(language) {
   Qt.callLater(function() {
    inspectorTabs.currentIndex=root.languageInspectorPage
    previewLanguageSegments.currentIndex=Qt.binding(function(){return root.st.viewMode})
    gradeLanguageSegments.currentIndex=Qt.binding(function(){return root.colorEndpoint})
    freezeModeSegments.currentIndex=Qt.binding(function(){return root.st.freezeSplit?1:0})
   })
  }
 }
 property color ink: dark ? "#F3F6FF" : "#172132"
 property color muted: dark ? "#BCC8DC" : "#526179"
 property color accent: dark ? "#8CC9FF" : "#075EBC"
 property color blue: dark ? "#176ACA" : "#086AD4"
 property color line: dark ? "#3DB2CCEF" : "#3A8095BE"
 property color surface: dark ? "#182235" : "#EEF2FA"
 property color sidebar: dark ? "#9C111B2B" : "#69F7F9FF"
 property color control: dark ? "#64364B68" : "#AEFFFFFF"
 property color hoverFill: dark ? "#7C55759B" : "#E6FFFFFF"
 property color selection: dark ? "#80528BCE" : "#B8D4E8FF"
 property color glassStroke: dark ? "#58BCDAFF" : "#C2FFFFFF"
 property color glassShadow: dark ? "#50060C16" : "#27414C76"
 property color dialogTint: dark ? "#ED1B273B" : "#F4F6FAFF"
 readonly property var symbols: ({
  "import": "M12 3v11m-4-4 4 4 4-4M5 15v4q0 2 2 2h10q2 0 2-2v-4",
  "export": "M12 15V3m-4 4 4-4 4 4M5 14v5q0 2 2 2h10q2 0 2-2v-5",
  "folder": "M3 8V6q0-2 2-2h5l2 3h7q2 0 2 2v9q0 2-2 2H5q-2 0-2-2Z",
  "spark": "M12 3q0 8 8 9-8 0-8 9-1-9-8-9 7-1 8-9Z",
  "frame": "M8 4H5q-1 0-1 1v3m12-4h3q1 0 1 1v3m0 8v3q0 1-1 1h-3M8 20H5q-1 0-1-1v-3",
  "waves": "M3 8q3-4 6 0t6 0 6 0M3 13q3-4 6 0t6 0 6 0M3 18q3-4 6 0t6 0 6 0",
  "sliders": "M4 7h7m4 0h5M4 17h4m4 0h8M11 4v6m-3 4v6",
  "shadow": "M15 4a8 8 0 1 0 5 11 8 8 0 0 1-5-11Z",
  "search": "M15 15l5 5M10 4a6 6 0 1 0 0 12 6 6 0 0 0 0-12Z",
  "play": "M8 5q-1 0-1 1v12q0 1 1 1l11-6q1-1 0-2Z",
  "pause": "M7 5h3v14H7ZM14 5h3v14h-3Z",
  "check": "M5 12l4 4 10-9",
  "stop": "M8 8h8v8H8Z",
  "close": "M6 6l12 12M18 6L6 18",
  "chevron": "M7 10l5 5 5-5"
 })
 readonly property real cardRadius:16
 readonly property real cardInset:4
 readonly property real thumbnailRadius:cardRadius-cardInset
 property bool showQueue: false
 property bool exporting: root.st.rendering
 onExportingChanged: if (exporting) showQueue = root.height >= 860
 property bool advanced: false
 property bool exportAdvanced: false
 property alias inspectorPage: inspectorTabs.currentIndex
 readonly property bool portraitSource:!!root.st.source && root.st.source.height>root.st.source.width
 property bool fullPreview: false
 property int colorEndpoint: 0
 property int hslBand: 0
 property int languageInspectorPage: 0
 font.family: studio.interfaceFont
 font.pixelSize: 13
 palette.window: root.surface
 palette.base: root.control
 palette.text: root.ink
 palette.windowText: root.ink
 palette.placeholderText: root.muted
 palette.button: root.control
 palette.buttonText: root.ink
 palette.highlight: root.accent
 palette.highlightedText: "white"

 Image {
  anchors.fill: parent
  source: studio.assets + (root.dark ? "wallpaper-dark.svg" : "wallpaper-light.svg")
  fillMode: Image.Stretch
  asynchronous: true
  smooth: true
 }

 component Glyph: Item {
  id: glyph
  property string symbol: ""
  property color ink: root.ink
  implicitWidth: 16
  implicitHeight: 16
  Shape {
   width: 24; height: 24
   transformOrigin: Item.TopLeft
   scale: glyph.width / 24
   ShapePath {
    strokeColor: ["play","pause","stop"].includes(glyph.symbol) ? "transparent" : glyph.ink
    fillColor: ["play","pause","stop"].includes(glyph.symbol) ? glyph.ink : "transparent"
    strokeWidth: 1.7
    capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
    PathSvg {path: root.symbols[glyph.symbol] || ""}
   }
  }
 }
 component GlassPlate: Item {
  id: glass
  property int radius: 16
  property color tint: root.sidebar
  property color rim: root.glassStroke
  property bool raised: true
  property bool gloss: true
  Rectangle {
   visible: glass.raised
   x: -2; y: 3; width: parent.width+4; height: parent.height+2
   radius: glass.radius+2; color: root.glassShadow
   opacity: .50
  }
  Rectangle {
   visible: glass.raised
   x: 0; y: 2; width: parent.width; height: parent.height
   radius: glass.radius; color: root.glassShadow
  }
  Rectangle {
   anchors.fill: parent; radius: glass.radius
   color: glass.tint; border.color: glass.rim
   antialiasing: true
  }
  Rectangle {
   visible: glass.gloss
   anchors.fill: parent; anchors.margins: 1
   radius: Math.max(0,glass.radius-1); antialiasing: true
   gradient: Gradient {
    GradientStop {position: 0; color: root.dark ? "#27FFFFFF" : "#83FFFFFF"}
    GradientStop {position: .26; color: root.dark ? "#0EFFFFFF" : "#27FFFFFF"}
    GradientStop {position: .76; color: "#00FFFFFF"}
    GradientStop {position: 1; color: root.dark ? "#22263251" : "#1485A4D5"}
   }
  }
 }

 component LabelText: Text { font.family:studio.interfaceFont; Layout.minimumWidth:0; elide:Text.ElideRight; color: root.ink; font.pixelSize: 13; renderType: Text.NativeRendering }
 component MutedText: Text { font.family:studio.interfaceFont; Layout.minimumWidth:0; elide:Text.ElideRight; color: root.muted; font.pixelSize: 11; renderType: Text.NativeRendering }
 component Action: Button {
  id: button
  property bool primary: false
  property bool quiet: false
  property string symbol: ""
  readonly property real measuredTextWidth: text ? Math.ceil(buttonMeasure.advanceWidth)+2 : 0
  implicitHeight: 33; implicitWidth: Math.max(text ? 56 : 34, measuredTextWidth+(symbol?22:0)+24)
  leftPadding:button.text?12:8;rightPadding:button.text?12:8;topPadding:6;bottomPadding:6
  scale: down ? .963 : 1
  Behavior on scale {NumberAnimation {duration: 120; easing.type: Easing.OutCubic}}
  background: GlassPlate {
   radius: height / 2
   raised: button.enabled && !button.quiet && !button.down
   gloss: !button.quiet || button.hovered
   tint: button.primary ? (button.down ? Qt.darker(root.blue,1.14) : root.blue)
         : button.hovered || button.down ? root.hoverFill : button.quiet ? "transparent" : root.control
   rim: button.activeFocus && !button.primary ? root.accent
        : button.quiet && !button.hovered ? "transparent" : root.glassStroke
   opacity: button.enabled ? 1 : .43
  }
  TextMetrics {id:buttonMeasure;text:button.text;font.pixelSize:12;font.family:studio.interfaceFont;font.weight:button.primary?Font.DemiBold:Font.Medium}


  contentItem: Item {
   implicitHeight:18
   Row {
    id:actionContent;objectName:"actionContentGroup"
    width:Math.min(parent.width,button.measuredTextWidth+(button.symbol?16:0)+(button.symbol&&button.text?6:0));height:parent.height
    anchors.centerIn:parent;anchors.alignWhenCentered:false;spacing:button.symbol&&button.text?6:0
    Glyph {visible:!!button.symbol;symbol:button.symbol;ink:button.primary?"white":root.ink;width:16;height:16;anchors.verticalCenter:parent.verticalCenter}
    Text {
     objectName:"actionText"
     width:Math.max(0,parent.width-(button.symbol?16:0)-(button.symbol&&button.text?6:0));height:parent.height
     text:button.text;visible:!!button.text;elide:Text.ElideRight
     horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
     color:button.primary?"white":root.ink;font.pixelSize:12;font.family:studio.interfaceFont
     font.weight:button.primary?Font.DemiBold:Font.Medium
    }
   }
  }
 }
 component Choice: ComboBox {
  id:choice
  readonly property bool glassChoiceControl:true
  implicitHeight:34;padding:0;Layout.fillWidth:true;Layout.minimumWidth:0
  background:GlassPlate {
   tint:choice.popup.visible?root.selection:root.control;radius:12;raised:false
   rim:choice.activeFocus||choice.popup.visible?root.accent:root.line
  }
  contentItem:Text {
   objectName:"choiceCenteredLabel";text:choice.displayText;leftPadding:28;rightPadding:28
   horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
   color:choice.enabled?root.ink:root.muted;font.pixelSize:12;font.family:studio.interfaceFont
   elide:Text.ElideRight
  }
  indicator:Glyph {
   x:choice.width-width-10;y:(choice.height-height)/2;width:13;height:13
   symbol:"chevron";ink:root.muted
  }
  delegate:ItemDelegate {
   id:glassOption
   required property var modelData;required property int index
   objectName:"glassChoiceOption";width:choice.popup.availableWidth;implicitHeight:34;padding:0
   text:String(modelData);highlighted:choice.highlightedIndex===index
   background:GlassPlate {
    radius:10;raised:false
    tint:glassOption.down?root.selection:glassOption.highlighted||glassOption.hovered?root.hoverFill:glassOption.index===choice.currentIndex?root.selection:"transparent"
    rim:glassOption.activeFocus?root.accent:"transparent";gloss:glassOption.index===choice.currentIndex||glassOption.hovered
   }
   contentItem:Text {
    objectName:"glassOptionLabel";text:glassOption.text;leftPadding:24;rightPadding:24
    horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
    font.family:studio.interfaceFont;font.pixelSize:12
    font.weight:glassOption.index===choice.currentIndex?Font.DemiBold:Font.Normal
    color:root.ink;elide:Text.ElideRight
   }
   Glyph {visible:glassOption.index===choice.currentIndex;symbol:"check";ink:root.accent;width:13;height:13;x:parent.width-width-9;y:(parent.height-height)/2}
  }
  popup:Popup {
   id:glassMenu;objectName:"glassChoicePopup";popupType:Popup.Item
   y:choice.height+6;width:choice.width;padding:6;margins:8
   implicitHeight:Math.min(choice.count*34+12,root.height*.6)
   closePolicy:Popup.CloseOnEscape|Popup.CloseOnPressOutsideParent
   background:GlassPlate {radius:16;tint:root.dark?"#F01B2B40":"#F2F5F9FF";rim:root.glassStroke;raised:true}
   contentItem:ListView {
    clip:true;model:choice.delegateModel;currentIndex:choice.highlightedIndex
    boundsBehavior:Flickable.StopAtBounds
    ScrollIndicator.vertical:ScrollIndicator {}
   }
  }
 }
 component Knob: Slider {
  Layout.fillWidth: true; implicitHeight: 25
  background: Rectangle {x:parent.leftPadding;y:parent.topPadding+parent.availableHeight/2-2;width:parent.availableWidth;height:4;radius:2;color:root.line; Rectangle {width:parent.parent.visualPosition*parent.width;height:4;radius:2;color:root.blue}}
  handle: GlassPlate {x:parent.leftPadding+parent.visualPosition*(parent.availableWidth-width);y:parent.topPadding+parent.availableHeight/2-height/2;width:parent.pressed?19:15;height:15;radius:8;tint:"#F5FFFFFF";rim:root.line;Behavior on width {NumberAnimation {duration:130}}}
 }
 component NumberInput: TextField {
  implicitHeight:34; Layout.fillWidth:true; Layout.minimumWidth:0; color:root.ink;selectByMouse:true;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;leftPadding:10;rightPadding:10
  background:GlassPlate {tint:root.control;radius:11;raised:false;rim:parent.activeFocus?root.accent:root.line}
 }
 component InspectorRow: RowLayout {
  property string caption
  property string hint: ""
  default property alias field: fields.data
  Layout.fillWidth: true
  spacing: 10
  LabelText {
   text: parent.caption;Accessible.description:parent.hint;Layout.alignment:Qt.AlignVCenter;verticalAlignment:Text.AlignVCenter; Layout.preferredWidth: root.st.language === "en" ? 100 : 68; Layout.minimumWidth:0; wrapMode:Text.WordWrap; font.pixelSize:12
  }
  RowLayout {id: fields; Layout.fillWidth: true; Layout.minimumWidth: 0; spacing: 7}
 }
 component Level: RowLayout {
  id: level
  property real value: 0
  property real from: 0
  property real to: 1
  property bool percent: true
  property string name: ""
  signal adjusted(real amount)
  Layout.fillWidth: true
  spacing: 8
  Knob {
   from: level.from; to: level.to; value: level.value
   onMoved: level.adjusted(value); Accessible.name: level.name
  }
  MutedText {
   text: level.percent ? Math.round(level.value * 100) + "%" : level.value.toFixed(2)
   horizontalAlignment: Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;Layout.alignment:Qt.AlignVCenter; Layout.preferredWidth: 48
   font.family: studio.monoFont; font.pixelSize: 10
  }
 }
 component Toggle: Switch {
  id: toggle
  implicitHeight: 27
  leftPadding: 0; rightPadding: 0
  indicator: Rectangle {
   implicitWidth: 34; implicitHeight: 20; radius: 10
   x: toggle.leftPadding; y: (toggle.height - height) / 2
   color: toggle.checked ? root.blue : root.line
   Behavior on color {ColorAnimation {duration: 150}}
   border.color: toggle.activeFocus ? root.accent : "transparent"
   GlassPlate {
    x: toggle.checked ? 16 : 2; y: 2; width: 16; height: 16
    radius: 8; tint: "#F9FFFFFF"; rim: "#DDFFFFFF"; raised: false
    Behavior on x {NumberAnimation {duration: 155; easing.type: Easing.OutCubic}}
   }
  }
  Accessible.name: text
 }
 component SegmentBar: TabBar {
  id: bar
  property var labels: []
  property var icons: []
  signal selected(int index)
  implicitWidth:240;implicitHeight:35;Layout.minimumWidth:0;padding:3;spacing:0
  background: Item {
   GlassPlate {anchors.fill: parent; tint: root.dark ? "#603B516C" : "#50F5FAFF"; radius: height/2; raised: false; rim: root.line}
   GlassPlate {
    objectName: "glassSelection"
    x: bar.leftPadding + Math.max(0,bar.currentIndex)*width
    y: bar.topPadding; width: Math.max(0,bar.availableWidth/Math.max(1,bar.labels.length))
    height: bar.availableHeight; radius: height/2
    tint: root.dark ? "#BD4C719E" : "#EAF4FAFF";rim:root.glassStroke;raised:true
    Behavior on x {NumberAnimation {duration: 195; easing.type: Easing.OutCubic}}
   }
  }
  Repeater {
   model: bar.labels
   TabButton {
    id: segment
    width:bar.availableWidth/Math.max(1,bar.labels.length);padding:4
    required property string modelData
    required property int index
    objectName: "segment-" + index
    text: modelData
    onClicked: bar.selected(index)
    background: Rectangle {
     radius: height/2; color: segment.hovered && !segment.checked ? root.hoverFill : "transparent"
     border.color: segment.activeFocus ? root.accent : "transparent"
    }


    TextMetrics {id:segmentMeasure;text:segment.text;font.family:studio.interfaceFont;font.pixelSize:12;font.weight:segment.checked?Font.DemiBold:Font.Medium}
    contentItem:Item {
     implicitHeight:18
     Row {
      id:segmentContent;objectName:"segmentContentGroup"
      readonly property bool hasIcon:!!(bar.icons[segment.index]||"")
      width:Math.min(parent.width,segmentMeasure.advanceWidth+(hasIcon?18:0));height:parent.height
      anchors.centerIn:parent;anchors.alignWhenCentered:false;spacing:hasIcon?4:0
      Glyph {symbol:bar.icons[segment.index]||"";visible:!!symbol;width:14;height:14;ink:segment.checked?root.accent:root.muted;anchors.verticalCenter:parent.verticalCenter}
      LabelText {
       width:Math.max(0,parent.width-(segmentContent.hasIcon?18:0));height:parent.height
       text:segment.text;font.pixelSize:12;font.weight:segment.checked?Font.DemiBold:Font.Medium
       color:segment.checked?root.ink:root.muted;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight
      }
     }
    }
   }
  }
 }
 // 按几何类型返回界面方向标签。
 function directions(shape) {
  if ([3, 4, 9].indexOf(shape) >= 0) return [qsTr("顺时针"), qsTr("逆时针")]
  if ([5, 6, 7, 13, 14].indexOf(shape) >= 0) return [qsTr("向外"), qsTr("向内")]
  if (shape === 0 || shape === 11) return [qsTr("左 → 右"), qsTr("右 → 左"), qsTr("由中心"), qsTr("向中心")]
  if (shape === 1) return [qsTr("上 → 下"), qsTr("下 → 上"), qsTr("由中心"), qsTr("向中心")]
  return [qsTr("顺向"), qsTr("反向"), qsTr("由中心"), qsTr("向中心")]
 }
 // 根据切线几何返回可理解的阴影边位标签。
 function shadowSides(effect, settings) {
  if (effect.shape === 1) return [qsTr("向上渐隐"), qsTr("向下渐隐")]
  if ([3,4,9].includes(effect.shape)) return [qsTr("逆时针渐隐"), qsTr("顺时针渐隐")]
  if ([5,6,7,13,14].includes(effect.shape)) return [qsTr("内侧渐隐"), qsTr("外侧渐隐")]
  return [qsTr("向左渐隐"), qsTr("向右渐隐")]
 }
 component SelectionQueue: Item {
  id:strip
  property bool vertical:false
  GlassPlate {anchors.fill:parent;radius:16;tint:root.sidebar}
  ColumnLayout {anchors.fill:parent;anchors.margins:8;spacing:5
   RowLayout {Layout.fillWidth:true
    LabelText {text:qsTr("已选 ")+root.st.selectedCount;font.pixelSize:11;font.weight:Font.DemiBold}
    MutedText {visible:!strip.vertical;text:root.st.selectionDuration.toFixed(1)+qsTr(" 秒");font.pixelSize:10}
    Item {Layout.fillWidth:true}
    MutedText {visible:!strip.vertical;text:qsTr("拖动排序");font.pixelSize:10}
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
     Rectangle {anchors.fill:parent;radius:12;color:root.control;border.color:root.line}
     Rectangle {
      id:sequenceCard;objectName:"selectedCard_"+entry.id
      property int effectId:entry.id
      width:dropCell.width;height:dropCell.height;radius:12
      color:root.st.active===entry.id?root.selection:root.control
      border.width:root.st.active===entry.id?2:1;border.color:root.st.active===entry.id?root.accent:root.line
      opacity:cardDrag.active?.90:1;scale:cardDrag.active?1.035:1;z:cardDrag.active?100:0
      Drag.active:cardDrag.active;Drag.source:sequenceCard;Drag.keys:["timeslice-selected"]
      Drag.hotSpot.x:width/2;Drag.hotSpot.y:height/2
      states:State {when:cardDrag.active;ParentChange {target:sequenceCard;parent:Overlay.overlay}}
      RoundedPreview {
       x:3;y:3;width:parent.width-6;height:Math.max(28,parent.height-36);radius:9
       source:studio.assets+"thumbnails/"+entry.key+".jpg"
      }
      LabelText {x:7;y:parent.height-29;width:parent.width-14;text:entry.name;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;font.pixelSize:10;font.weight:Font.Medium}
      MutedText {x:7;y:parent.height-15;width:parent.width-14;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;text:entry.seconds.toFixed(1)+qsTr(" 秒");font.pixelSize:9}
      Rectangle {x:7;y:7;width:19;height:19;radius:9.5;color:root.dialogTint
       LabelText {anchors.centerIn:parent;text:entry.rank;font.pixelSize:10;font.weight:Font.DemiBold}
      }
      TapHandler {onTapped:(point,button)=>{if(point.position.x>sequenceCard.width-30 && point.position.y<30)studio.removeSelection(entry.id);else studio.activateSelection(entry.id)}}
      DragHandler {
       id:cardDrag;target:sequenceCard;enabled:!root.st.rendering;cursorShape:active?Qt.ClosedHandCursor:Qt.OpenHandCursor
       onActiveChanged:if(!active)Qt.callLater(function(){if(sequenceCard && sequenceCard.parent===dropCell){sequenceCard.x=0;sequenceCard.y=0}})
      }
      Rectangle {anchors.top:parent.top;anchors.right:parent.right;anchors.margins:6;width:19;height:19;radius:9.5;color:root.dialogTint
       Glyph {anchors.centerIn:parent;width:11;height:11;symbol:"close";ink:root.ink}
       HoverHandler {cursorShape:Qt.PointingHandCursor}
       Accessible.role:Accessible.Button;Accessible.name:qsTr("移除 ")+entry.name;Accessible.onPressAction:studio.removeSelection(entry.id)
      }
      Accessible.role:Accessible.Button;Accessible.name:entry.rank+" · "+entry.name;Accessible.onPressAction:studio.activateSelection(entry.id)
     }
    }
   }
  }
 }
 component ExportProgress: ProgressBar {
  id: meter
  from: 0
  to: 1
  padding: 0
  background: Rectangle {implicitHeight: 6; radius: height / 2; color: root.line}
  contentItem: Item {
   implicitHeight: 6
   Rectangle {
    width: parent.width * meter.visualPosition; height: parent.height; radius: height / 2
    gradient: Gradient {
     orientation: Gradient.Horizontal
     GradientStop {position: 0; color: root.blue}
     GradientStop {position: 1; color: root.dark ? "#A2D9FF" : "#469DEC"}
    }
    Behavior on width {NumberAnimation {duration: 160; easing.type: Easing.OutCubic}}
   }
  }
 }
 component Rule: Rectangle {Layout.fillWidth:true;height:1;color:root.line;opacity:.65}
 FileDialog {id: sourceDialog; title:qsTr("选择延时视频");nameFilters:[qsTr("视频 (*.mp4 *.mov *.mkv *.m4v *.avi *.webm)"),qsTr("所有文件 (*)")];onAccepted:studio.importSource(selectedFile.toString())}
 FileDialog {id: mapDialog;title:qsTr("选择黑白时间图");nameFilters:[qsTr("时间图 (*.png *.tif *.tiff *.jpg *.jpeg)")];onAccepted:studio.importMap(selectedFile.toString())}
 component GlassDialog: Dialog {
  id: panel
  padding: 20
  spacing: 8
  background: GlassPlate {tint: root.dialogTint; radius: 24}
  header: Label {
   text: panel.title; visible: text.length > 0
   leftPadding: 22; rightPadding: 22; topPadding: 20; bottomPadding: 6
   color: root.ink; font.family: studio.interfaceFont; font.pixelSize: 17; font.weight: Font.DemiBold
   elide: Text.ElideRight; background: null
  }
  footer: DialogButtonBox {
   visible: count > 0; padding: 16; spacing: 8; background: null
   delegate: Action {implicitWidth: Math.max(88, measuredTextWidth+32)}
  }
 }
 FolderDialog {
  id: outputDialog
  title: qsTr("选择导出文件夹")
  acceptLabel: qsTr("选择此文件夹")
  onAccepted: studio.setOutput(selectedFolder.toString())
  onRejected: studio.rejectOutput()
 }
 Shortcut {sequences: [StandardKey.Open]; enabled: !root.st.rendering; onActivated: sourceDialog.open()}
 GlassDialog {
  id: aboutDialog
  objectName: "aboutDialog"
  title: qsTr("关于时刃")
  modal: true
  anchors.centerIn: parent
  width: Math.min(root.width - 64, 520)
  standardButtons: Dialog.Close
  contentItem: ColumnLayout {
   spacing: 12
   Image {source: studio.assets + "app-icon-glass.png"; Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 72; Layout.preferredHeight: 72}
   LabelText {text: qsTr("时刃 ") + root.st.version; font.pixelSize: 20; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter}
   MutedText {text: "AlphaStar · " + qsTr("免费开源"); Layout.alignment: Qt.AlignHCenter}
   ScrollView {
    Layout.fillWidth: true
    Layout.preferredHeight: 262
    contentWidth: availableWidth
    TextArea {text: studio.localizedLicense; readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap; color: root.ink; background: Rectangle {color: root.sidebar; radius: 7}}
   }
  }
 }
 Overlay.modal: Rectangle {color: root.dark ? "#79060E1D" : "#47142238"}
 onClosing: function(close) {if(st.rendering||st.loading){close.accepted=false;quitDialog.open()}}
 GlassDialog {id:quitDialog;objectName:"quitDialog";title:qsTr("仍有任务正在进行");anchors.centerIn:parent;modal:true;width:370;standardButtons:Dialog.Yes|Dialog.No
  LabelText {width:parent.width;wrapMode:Text.WordWrap;text:qsTr("退出会取消当前任务。已完成的视频会保留。确定退出吗？")}
  onAccepted:{studio.cancelRender();Qt.quit()}
 }
 GlassDialog {id:errorDialog;objectName:"errorDialog";title:qsTr("这一步没有完成");anchors.centerIn:parent;modal:true;width:Math.min(520,root.width-64);standardButtons:Dialog.Ok
  LabelText {width:parent.width;wrapMode:Text.WrapAnywhere;text:root.st.error;lineHeight:1.4}
  onAccepted:studio.dismissError()
  onRejected:studio.dismissError()
  onClosed:studio.dismissError()
 }
 ListModel {id: queueRows}
 Connections {
  target: studio
  // 接收控制器的目录选择请求并打开系统目录窗口。
  function onOutputPickerRequested(folder) { outputDialog.currentFolder = folder; outputDialog.open() }
  // 响应控制器状态变化并刷新关联的界面绑定。
  function onChanged() {
   const items = root.st.queue
   if (queueRows.count !== items.length)
    queueRows.clear()
   for (let i = 0; i < items.length; i++) {
    const row = {effectName: items[i].name, amount: items[i].progress, stageName: items[i].status}
    if (i < queueRows.count)
     queueRows.set(i, row)
    else
     queueRows.append(row)
   }
   if (root.st.error && !errorDialog.visible) errorDialog.open()
  }
 }
 DropArea {
  anchors.fill: parent
  onDropped: function(drop) {
   if (!drop.hasUrls || root.st.rendering || root.st.loading) return
   const url = drop.urls[0].toString()
   studio.importSource(url)
   drop.acceptProposedAction()
  }
 }

 ColumnLayout {
  anchors.fill:parent; anchors.margins: 12; spacing: 8
  Item {
   Layout.fillWidth: true
   Layout.preferredHeight: 60
   GlassPlate {anchors.fill: parent; radius: 19}
   RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    spacing: 10
    Image {source: studio.assets + "app-icon-glass.png"; Layout.preferredWidth: 45; Layout.preferredHeight: 45; mipmap: true}
    Column {
     LabelText {text: qsTr("时刃"); font.pixelSize: 19; font.weight: Font.DemiBold}
     MutedText {text: qsTr("延时 · 切片")}
    }
    Item {Layout.fillWidth: true}
    Choice {
     Layout.preferredWidth: 118
     Layout.minimumWidth: 118; Layout.maximumWidth: 118; Layout.fillWidth: false
     model: [qsTr("简体中文"), "English"]
     currentIndex: root.st.language === "en" ? 1 : 0
     onActivated: studio.setLanguage(currentIndex === 1 ? "en" : "zh")
     Accessible.name: qsTr("界面语言")
    }
    Action {text: qsTr("关于"); quiet: true; onClicked: aboutDialog.open()}
    Action {objectName: "importVideoAction"; text: qsTr("导入视频…"); symbol: "import"; primary: !root.st.source; enabled: !root.st.rendering; onClicked: sourceDialog.open()}
    Action {
     text: root.st.rendering ? qsTr("取消导出") : root.st.language === "en" ? "Export "+root.st.selectedCount+(root.st.selectedCount===1?" item":" items") : qsTr("导出 ") + root.st.selectedCount + qsTr(" 项")
     symbol: root.st.rendering ? "stop" : "export"
     objectName: "exportVideoAction"
     primary: enabled && !root.st.rendering
     enabled: root.st.rendering || (!!root.st.source && !root.st.loading && root.st.selectedCount > 0 && !root.st.processing)
     Layout.minimumWidth: implicitWidth
     onClicked: root.st.rendering ? studio.cancelRender() : studio.startRender()
    }
   }
  }
  Item {
   Layout.fillWidth: true
   Layout.preferredHeight: 38
   GlassPlate {anchors.fill: parent; radius: 14; raised: false; tint: root.sidebar}
   RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    spacing: 10
    Glyph {symbol: "folder"; ink: root.muted}
    LabelText {text: qsTr("导出位置"); font.weight: Font.Medium; font.pixelSize: 12}
    LabelText {
     id: destination
     Layout.fillWidth: true
     Layout.minimumWidth: 0
     elide: Text.ElideMiddle
     color: root.muted
     text: root.st.result || root.st.output || qsTr("首次导出时选择文件夹")
    }
    Action {text: root.st.output ? qsTr("更改…") : qsTr("选择文件夹…"); quiet: true; enabled: !root.st.rendering; implicitHeight: 27; onClicked: studio.chooseOutput()}
    Action {text: qsTr("在访达中显示"); quiet: true; enabled: !!root.st.output; implicitHeight: 27; onClicked: studio.openOutput()}
   }
  }
  SplitView {
   Layout.fillWidth: true
   Layout.fillHeight: true
   orientation: Qt.Horizontal
   handle: Item {
    implicitWidth: 9
    Rectangle {
     anchors.centerIn: parent; height: 36; width: 3; radius: 2
     color: parent.SplitHandle.hovered || parent.SplitHandle.pressed ? root.accent : root.line
    }
   }
   // Effect library.
   Item {visible:!root.fullPreview;SplitView.preferredWidth:259;SplitView.minimumWidth:221;SplitView.maximumWidth:400
    GlassPlate {anchors.fill: parent; radius: 20}
    ColumnLayout {anchors.fill:parent;anchors.margins:15;spacing:11
     RowLayout {Layout.fillWidth:true;LabelText {text:qsTr("效果库");font.pixelSize:17;font.weight:Font.DemiBold}Item {Layout.fillWidth:true}MutedText {text:root.st.catalogueCount + qsTr(" 项")}}
     TextField {
      Layout.fillWidth:true; implicitHeight:35; leftPadding:32
      placeholderText:qsTr("搜索效果…"); color:root.ink; selectByMouse:true; onTextEdited:studio.searchEffects(text)
      background: GlassPlate {
       tint:root.control; radius:height/2; raised:false; rim: parent.activeFocus ? root.accent : root.line
       Glyph {x: 10; y: (parent.height-height)/2; symbol:"search"; ink:root.muted}
      }
     }
     GridLayout {columns:2;columnSpacing:6;rowSpacing:6;Layout.fillWidth:true
      Repeater {model:[qsTr("冻结展开"),qsTr("时间切片"),qsTr("创意实验")]
       delegate:Action {required property int index;required property string modelData;text:modelData;Layout.fillWidth:true;implicitHeight:32;primary:root.st.family===[0,1,3][index];onClicked:studio.setFamily([0,1,3][index])}
      }
     }
     SegmentBar {
      id:freezeModeSegments;objectName:"freezeModeSegments";visible:root.st.family===0
      Layout.fillWidth:true;labels:[qsTr("标准冻结"),qsTr("昼夜分割")]
      currentIndex:root.st.freezeSplit?1:0;enabled:!root.st.rendering
      onSelected:index=>studio.setFreezeSplit(index===1)
     }
     RowLayout {Layout.fillWidth:true;MutedText {text:root.st.language === "en" ? root.st.effects.length+(root.st.effects.length===1?" effect":" effects") : root.st.effects.length + qsTr(" 项效果");font.pixelSize:10}Item {Layout.fillWidth:true}Action {text:qsTr("全选");quiet:true;implicitHeight:25;onClicked:studio.selectFamily();}}
     GridView {id: effectGrid;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;cellWidth:width/2;cellHeight:151;model:studio.effectModel;objectName:"effectGrid"
      ScrollBar.vertical: ScrollBar {policy:ScrollBar.AsNeeded}
      delegate: Item {
       required property var entry;property var modelData:entry;required property int index;width:effectGrid.cellWidth;height:effectGrid.cellHeight
       Rectangle {
        anchors.fill:parent;anchors.rightMargin:8;anchors.bottomMargin:8;radius:root.cardRadius
        color:root.st.activeCatalogue===modelData.catalogueKey ? root.selection : cardPointer.containsMouse ? root.hoverFill : root.control
        border.width:root.st.activeCatalogue===modelData.catalogueKey?2:1
        border.color:root.st.activeCatalogue===modelData.catalogueKey?"#4A9EFF":root.glassStroke
        RoundedPreview {
         objectName:"effectThumbnail";anchors.top:parent.top;anchors.left:parent.left;anchors.right:parent.right
         anchors.margins:root.cardInset;height:92;radius:root.thumbnailRadius
         source:studio.assets+"thumbnails/"+modelData.key+".jpg"
         animationSource:studio.assets+"thumbnails/"+modelData.key+".gif"
         playing:cardPointer.containsMouse
        }
        Column {x:12;y:104;spacing:4;width:parent.width-24;LabelText {text:modelData.name;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;font.pixelSize:12;font.weight:Font.Medium;elide:Text.ElideRight;width:parent.width}MutedText {text:(modelData.subtitle || modelData.duration+qsTr(" 秒"))+(modelData.checkedCount>1 ? qsTr(" · 已选 ")+modelData.checkedCount+qsTr(" 种") : "");elide:Text.ElideRight;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;width:parent.width;font.pixelSize:10}}
        activeFocusOnTab:true
        Keys.onReturnPressed:studio.setActive(modelData.id)
        Keys.onSpacePressed:studio.toggleCatalogue(modelData.catalogueKey)
        Accessible.role: Accessible.Button; Accessible.name:modelData.name; Accessible.onPressAction:studio.setActive(modelData.id)

        MouseArea {id:cardPointer;anchors.fill:parent;hoverEnabled:true;onClicked:studio.setActive(modelData.id);cursorShape:Qt.PointingHandCursor}
        Rectangle {anchors.top:parent.top;anchors.right:parent.right;anchors.margins:8;width:22;height:22;radius:height/2;color:modelData.checked?root.blue:"#B50A1728";border.color:modelData.checked?"#ACD7FF":"#7097AAC0"
         Accessible.role:Accessible.CheckBox;Accessible.name:qsTr("导出 ")+modelData.name;Accessible.checkable:true;Accessible.checked:modelData.checked;Accessible.onPressAction:studio.toggleCatalogue(modelData.catalogueKey);Accessible.onToggleAction:studio.toggleCatalogue(modelData.catalogueKey)
         Glyph {anchors.centerIn:parent;visible:modelData.checked;symbol:"check";ink:"white";width:13;height:13}
         MouseArea {anchors.fill:parent;anchors.margins:-5;onClicked:studio.toggleCatalogue(modelData.catalogueKey);cursorShape:Qt.PointingHandCursor}
        }
       }
      }
     }
     MutedText {text:qsTr("点按预览 · 勾选导出");font.pixelSize:10}
    }
   }
      // Preview stage.
   ColumnLayout {SplitView.fillWidth:true;SplitView.minimumWidth:340;spacing:8
    Item {Layout.fillWidth:true;Layout.preferredHeight:45
     GlassPlate {anchors.fill: parent; radius: 17}
     RowLayout {anchors.fill:parent;anchors.leftMargin:10;anchors.rightMargin:10;spacing:5
      SegmentBar {
       id: previewLanguageSegments
       objectName: "previewSegments"
       Layout.preferredWidth: root.st.language === "en" ? 288 : 235; Layout.preferredHeight: 34
       labels:[qsTr("效果"),qsTr("素材"),qsTr("时间图")]; icons:["spark","frame","waves"]
       currentIndex:root.st.viewMode; onSelected: index => studio.setView(index)
      }
      Item {Layout.fillWidth:true}
      Action {text:root.fullPreview?qsTr("收起"):qsTr("放大");symbol:"frame";quiet:true;implicitHeight:29;onClicked:root.fullPreview=!root.fullPreview}
     }
    }
    RowLayout {Layout.fillWidth:true;Layout.fillHeight:true;spacing:8
    Rectangle {
     id:stage; Layout.fillWidth:true; Layout.fillHeight:true
     radius: 20; color:"#090E18"; border.color: "#566580A2"; antialiasing: true
     Rectangle {
      anchors.fill: parent; anchors.margins: 1
      radius: 19; visible: !root.st.hasImage
      gradient: Gradient {
       GradientStop {position: 0; color: "#263652"}
       GradientStop {position: .55; color: "#172235"}
       GradientStop {position: 1; color: "#0E1728"}
      }
     }

     Timer {id:viewportTimer;interval:90;onTriggered:studio.setPreviewViewport(previewImage.width,previewImage.height,root.Screen.devicePixelRatio)}
     Image {id:previewImage;objectName:"mainPreview";onWidthChanged:viewportTimer.restart();onHeightChanged:viewportTimer.restart();Component.onCompleted:viewportTimer.start();anchors.fill:parent;anchors.margins:25;source:root.st.hasImage?"image://preview/frame/"+root.st.imageVersion:"";fillMode:Image.PreserveAspectFit;cache:false;asynchronous:false;visible:root.st.hasImage;smooth:true}
     Column {visible:!root.st.hasImage;anchors.centerIn:parent;spacing:19;width:Math.min(parent.width-64,460)
      Image {source:studio.assets+"app-icon-glass.png";width:112;height:112;anchors.horizontalCenter:parent.horizontalCenter;mipmap:true}
      LabelText {text:root.st.loading?qsTr("正在读取素材"):qsTr("导入素材");font.pixelSize:25;font.weight:Font.DemiBold;color:"#F5F7FD";anchors.horizontalCenter:parent.horizontalCenter}
      MutedText {text:root.st.loading?root.st.busyText:qsTr("拖入一段延时视频");font.pixelSize:12;color:"#BBC9DF";anchors.horizontalCenter:parent.horizontalCenter}
      Row {
       spacing: 9; anchors.horizontalCenter: parent.horizontalCenter; visible: !root.st.loading && !root.st.source
       Action {text:qsTr("选择视频");symbol:"import";primary:true;onClicked:sourceDialog.open()}
      }
     }
     Rectangle {visible:!!root.st.source;anchors.top:parent.top;anchors.left:parent.left;anchors.margins:14;radius:13;height:27;width:Math.min(parent.width-28,metaText.implicitWidth+20);color:"#C029384F";border.color:"#537393BA"
      MutedText {id:metaText;anchors.centerIn:parent;width:parent.width-20;horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight;text:root.st.source?root.st.source.width+" × "+root.st.source.height+"  ·  "+root.st.source.duration.toFixed(2)+qsTr(" 秒  ·  ")+root.st.source.fps.toFixed(0)+" fps":"";color:"#B8C7D8";font.pixelSize:10}
     }
     Rectangle {visible:root.st.processing;anchors.left:parent.left;anchors.bottom:parent.bottom;anchors.margins:14;width:Math.min(parent.width-90,320);height:70;radius:12;color:"#E029384F"
      ColumnLayout {anchors.fill:parent;anchors.margins:9;spacing:4
       MutedText {text:root.st.processingStage+" · "+Math.round(root.st.processingProgress*100)+"%";color:"#F0F5FF"}
       MutedText {text:root.st.processingEta;color:"#D0DCEF";Layout.fillWidth:true}
       ExportProgress {Layout.fillWidth:true;value:root.st.processingProgress}
      }
     }
     Rectangle {visible:root.st.hasImage;anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:14;width:58;height:23;radius:11;color:"#B029384F";border.color:"#537393BA";MutedText {anchors.centerIn:parent;text:qsTr("预览");font.pixelSize:9;color:"#D5DEEA"}}
    }
     SelectionQueue {visible:root.portraitSource && root.st.selectedCount>0;vertical:true;Layout.preferredWidth:116;Layout.minimumWidth:100;Layout.maximumWidth:116;Layout.fillHeight:true}
    }
    SelectionQueue {visible:!root.portraitSource && root.st.selectedCount>0;vertical:false;Layout.fillWidth:true;Layout.preferredHeight:root.height<760?96:116}
    Item {Layout.fillWidth:true;Layout.preferredHeight:83
     GlassPlate {anchors.fill: parent; radius: 18}
     ColumnLayout {anchors.fill:parent;anchors.leftMargin:24;anchors.rightMargin:24;anchors.topMargin:10;anchors.bottomMargin:12;spacing:6
      Knob {from:0;to:1;value:root.st.progress;enabled:root.st.hasImage;onMoved:studio.seek(value);Accessible.name:qsTr("预览时间")}
      RowLayout {Layout.fillWidth:true;spacing:12
       Action {symbol:root.st.playing?"pause":"play";enabled:root.st.hasImage;implicitWidth:38;implicitHeight:29;onClicked:studio.togglePlay();Accessible.name:root.st.playing?qsTr("暂停预览"):qsTr("播放预览")}
       LabelText {text:root.st.elapsed; font.pixelSize:12;font.family:studio.monoFont}
       MutedText {text:"/  "+root.st.total;font.pixelSize:12;font.family:studio.monoFont}
       Item {Layout.fillWidth:true}
       MutedText {text:root.st.effect.name+"  ·  "+(root.st.pixel?qsTr("按像素细分"):root.st.count+qsTr(" 片"));font.pixelSize:11}
      }
     }
    }
   }
   Item {
    visible: !root.fullPreview
    SplitView.preferredWidth: root.st.language === "en" ? 390 : 318
    SplitView.minimumWidth: root.st.language === "en" ? 360 : 278
    SplitView.maximumWidth: 520
    GlassPlate {anchors.fill: parent; radius: 20}

    ColumnLayout {
     anchors.fill: parent
     spacing: 0
     ColumnLayout {
      Layout.fillWidth: true
      Layout.margins: 16
      spacing: 7
      RowLayout {
       Layout.fillWidth: true
       MutedText {
        text: root.inspectorPage === 0 ? qsTr("全局素材") : [qsTr("冻结展开"), qsTr("时间切片"), qsTr("时间切片"), qsTr("创意实验")][root.st.effect.family]
        font.pixelSize: 11; font.weight: Font.Medium
       }
       Item {Layout.fillWidth: true}
       Action {
        visible: root.inspectorPage === 1 || root.inspectorPage === 2
        text: qsTr("重置"); quiet: true; implicitHeight: 24
        onClicked: studio.resetSettings()

       }
      }
      LabelText {text: root.inspectorPage === 0 ? qsTr("素材处理") : root.st.effect.name;Layout.fillWidth:true;wrapMode:Text.WordWrap;font.pixelSize:root.st.language === "en" ? 21 : 23;font.weight:Font.DemiBold}
      MutedText {
       text: root.inspectorPage === 0 ? qsTr("原素材先稳定、去闪和调色，再进入切片。") : root.st.effect.description; Layout.fillWidth: true
       wrapMode: Text.Wrap; lineHeight: 1.22
      }
      SegmentBar {
       id: inspectorTabs
       objectName: "inspectorSegments"
       Layout.fillWidth: true; Layout.topMargin: 5
       labels: [qsTr("素材"), qsTr("效果"), qsTr("阴影"), qsTr("导出")]
       icons: ["spark", "sliders", "shadow", "export"]
      }
     }
     Rule {}
     ScrollView {
      id: inspectorScroll
      objectName: "inspectorScroll"
      Layout.fillWidth: true; Layout.fillHeight: true
      leftPadding: 16; rightPadding: 18; topPadding: 13; bottomPadding: 12
      clip: true
      contentWidth: availableWidth
      contentHeight: inspectorForm.implicitHeight
      ScrollBar.vertical.policy: ScrollBar.AsNeeded
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

      ColumnLayout {
       id: inspectorForm; objectName: "inspectorForm"
       width: inspectorScroll.contentWidth
       spacing: 11

       ColumnLayout {
        visible: root.inspectorPage === 1
        Layout.fillWidth: true; spacing: 10
        ColumnLayout {
         visible:root.st.effect.family===0 && root.st.freezeSplit;Layout.fillWidth:true;spacing:8
         InspectorRow {caption:qsTr("跳过中段")
          Level {from:0;to:1;value:root.st.freezeDiscard;name:qsTr("跳过中段");onAdjusted:amount=>studio.setFreezeDiscard(amount)}
         }
         MutedText {text:root.st.freezeDiscard>=.9999 ? qsTr("仅保留首帧和末帧") : qsTr("首尾各保留 ")+((1-root.st.freezeDiscard)*50).toFixed(1)+"%";Layout.fillWidth:true;wrapMode:Text.WordWrap}
         MutedText {text:qsTr("底片连续播放，仅冻结片跳过中段。");Layout.fillWidth:true;wrapMode:Text.WordWrap}
         MutedText {text:qsTr("展开占满所设时长，最后一片完成即结束。");Layout.fillWidth:true;wrapMode:Text.WordWrap}
         Rule {}
        }
        InspectorRow {
         visible: root.st.effect.family === 1 || root.st.effect.family === 2
         caption: qsTr("运动")
         Choice {
          model: root.st.movementLabels || []
          currentIndex: root.st.movementIndex || 0
          enabled: count > 1 && !root.st.rendering
          onActivated: studio.setMovement(currentIndex)
          Accessible.name: qsTr("时间切片运动")
         }
        }
        InspectorRow {
         visible: !!root.st.orientationLabels && root.st.orientationLabels[0] !== ""
         caption: qsTr("排列")
         Choice {
          model: root.st.orientationLabels || []
          currentIndex: root.st.orientationIndex || 0
          enabled: count > 1 && !root.st.rendering
          onActivated: studio.setOrientation(currentIndex)
          Accessible.name: qsTr("条形排列方向")
         }
        }
        InspectorRow {
         caption: qsTr("导出")
         Toggle {
          checked: !!root.st.activeChecked
          enabled: !root.st.rendering
          Accessible.name: qsTr("导出当前形状与运动组合")
          onToggled: studio.toggleEffect(root.st.active)
         }
         MutedText {text: root.st.activeChecked ? qsTr("已加入所选") : qsTr("当前组合")}
        }
        ColumnLayout {
         enabled: !root.st.settings.reference
         Layout.fillWidth: true; spacing: 10
         InspectorRow {
          caption: qsTr("片数"); hint: qsTr("片数上限随输出分辨率和形状变化")
          Choice {
           model: [qsTr("推荐"), qsTr("自定义"), qsTr("逐像素")]
           currentIndex: root.st.settings.sliceMode
           enabled: root.st.effect.id !== 13
           onActivated: studio.setSetting("sliceMode", currentIndex)
           Accessible.name: qsTr("片数模式")
          }
          NumberInput {
           visible: root.st.settings.sliceMode === 1
           Layout.preferredWidth: 68; Layout.fillWidth: false
           text: root.st.settings.sliceCount
           validator: IntValidator {bottom: 2; top: root.st.limit}
           onEditingFinished: studio.setSetting("sliceCount", Number(text))
           Accessible.name: qsTr("片数")
          }
          MutedText {
           visible: root.st.settings.sliceMode !== 1
           text: root.st.effect.id === 13 ? qsTr("连续") : root.st.pixel ? qsTr("连续取样") : root.st.count + qsTr(" 片")
           Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight
          }
         }
         MutedText {
          visible: root.st.settings.sliceMode === 1
          text: qsTr("上限 ") + root.st.limit + qsTr(" 片"); Layout.alignment: Qt.AlignRight
         }
         InspectorRow {
          caption: root.st.effect.family===0 && root.st.freezeSplit ? qsTr("展开时长") : qsTr("时长")
          NumberInput {
           text: Number(root.st.duration.toFixed(2)).toString()
           validator: DoubleValidator {bottom: .2; top: 120; decimals: 2; locale: "C"}
           onEditingFinished: studio.setSetting("duration", Number(text))
           Accessible.name: qsTr("时长")
          }
          MutedText {text: qsTr("秒")}
         }
         InspectorRow {
          visible: root.st.effect.family === 0 && !root.st.freezeSplit
          caption: qsTr("展开"); hint: qsTr("逐片冻结所占的时长比例")
          Level {value: root.st.settings.build; from: .1; to: .9; name: qsTr("展开"); onAdjusted: amount => studio.setSetting("build", amount)}
         }
         InspectorRow {
          visible: root.st.effect.family === 0 && !root.st.freezeSplit
          caption: qsTr("完成后")
          Choice {
           model: [qsTr("定格"), qsTr("同步解冻"), qsTr("依次解冻"), qsTr("基础流动"), qsTr("时间波纹")]
           currentIndex: root.st.settings.ending
           onActivated: studio.setSetting("ending", currentIndex)
           Accessible.name: qsTr("展开完成后")
          }
         }
         InspectorRow {
          visible: root.st.effect.family !== 3 || root.st.effect.id >= 407
          caption: qsTr("方向")
          Choice {
           model: root.st.effect.id === 410 ? [qsTr("左 → 右"), qsTr("右 → 左")]
                  : root.st.effect.id === 408 ? [qsTr("顺向"), qsTr("反向"), qsTr("由中心"), qsTr("向中心")]
                  : root.directions(root.st.effect.shape)
           currentIndex: root.st.settings.direction
           onActivated: studio.setSetting("direction", currentIndex)
           Accessible.name: qsTr("方向")
          }
         }
         InspectorRow {
          visible:root.st.effect.id===0 || root.st.effect.id===104
          caption:qsTr("起始角度")
          Knob {from:0;to:360;stepSize:.1;value:root.st.settings.rotationStartAngle||0;onMoved:studio.setSetting("rotationStartAngle",value);Accessible.name:qsTr("起始角度")}
          NumberInput {objectName:"rotationStartInput";Layout.preferredWidth:66;Layout.fillWidth:false;text:Number((root.st.settings.rotationStartAngle||0).toFixed(1)).toString();validator:DoubleValidator{bottom:0;top:360;decimals:1;locale:"C"} onEditingFinished:studio.setSetting("rotationStartAngle",Number(text));Accessible.name:qsTr("起始角度数值")}
          MutedText {text:"°";verticalAlignment:Text.AlignVCenter}
         }
         MutedText {visible:root.st.effect.id===0 || root.st.effect.id===104;text:qsTr("0° 为正上方，角度沿顺时针增加。");Layout.fillWidth:true;wrapMode:Text.WordWrap}
         InspectorRow {
          visible: root.st.effect.family !== 3 && [3,5,6,7,9,13,14].includes(root.st.effect.shape)
          caption: qsTr("起点")
          Choice {
           model: [qsTr("随效果"), qsTr("底部"), qsTr("顶部"), qsTr("左侧"), qsTr("右侧"), qsTr("中心")]
           currentIndex: root.st.settings.origin + 1
           onActivated: studio.setSetting("origin", currentIndex - 1)
           Accessible.name: qsTr("起点")
          }
         }
        }
        Rule {}
        Action {
         text: (root.advanced ? "▾  " : "▸  ") + qsTr("高级")
         quiet: true; implicitHeight: 27
         onClicked: root.advanced = !root.advanced
        }
        ColumnLayout {
         visible: root.advanced
         Layout.fillWidth: true; spacing: 10
         ColumnLayout {
          Layout.fillWidth: true; spacing: 10
          enabled: !root.st.settings.reference
          InspectorRow {
           caption: qsTr("时间方向")
           Choice {model: [qsTr("从早到晚"), qsTr("从晚到早")]; currentIndex: root.st.settings.sourceReverse ? 1 : 0; onActivated: studio.setSetting("sourceReverse", currentIndex === 1)}
          }
          InspectorRow {
           caption: qsTr("循环"); hint: qsTr("采样抵达素材边缘时的处理")
           Choice {model: [qsTr("停在边缘"), qsTr("往返"), qsTr("循环")]; currentIndex: root.st.settings.playback; onActivated: studio.setSetting("playback", currentIndex)}
          }
          InspectorRow {
           caption: qsTr("频次"); hint: qsTr("单次效果内的时间循环次数")
           NumberInput {text: (root.st.settings.cycles || root.st.effect.cycles).toFixed(2); validator: DoubleValidator {bottom: .1; top: 100; locale: "C"} onEditingFinished: studio.setSetting("cycles", Number(text))}
          }
          InspectorRow {
           visible: [2,12].includes(root.st.effect.shape)
           caption: qsTr("角度")
           NumberInput {text: root.st.settings.angle; validator: DoubleValidator {bottom: -360; top: 360; locale: "C"} onEditingFinished: studio.setSetting("angle", Number(text))}
           MutedText {text: "°"}
          }
          InspectorRow {
           visible: root.st.effect.family !== 3 && [4,6,7].includes(root.st.effect.shape)
           caption: qsTr("自转"); hint: qsTr("形状本身在一次效果内转过的圈数")
           NumberInput {text: root.st.settings.turns < 0 ? root.st.effect.turns : root.st.settings.turns; validator: DoubleValidator {bottom: 0; top: 20; locale: "C"} onEditingFinished: studio.setSetting("turns", Number(text))}
           MutedText {text: qsTr("圈")}
          }
          InspectorRow {
           caption: qsTr("边缘")
           Level {value: root.st.settings.softness; name: qsTr("边缘柔和度"); onAdjusted: amount => studio.setSetting("softness", amount)}
          }
          InspectorRow {
           visible: root.st.effect.family === 2
           caption: qsTr("波密度")
           Level {value: root.st.settings.density; from: .01; to: 2; percent: false; name: qsTr("波纹密度"); onAdjusted: amount => studio.setSetting("density", amount)}
          }
          InspectorRow {
           caption: qsTr("时差"); hint: qsTr("相邻切片在素材中的取样间距")
           Level {value: root.st.settings.span || root.st.effect.span; from: .01; to: 2; percent: false; name: qsTr("时差"); onAdjusted: amount => studio.setSetting("span", amount)}
          }
          InspectorRow {
           caption: qsTr("中心 X")
           Level {value: root.st.settings.centerX; name: qsTr("中心水平位置"); onAdjusted: amount => studio.setSetting("centerX", amount)}
          }
          InspectorRow {
           caption: qsTr("中心 Y")
           Level {value: root.st.settings.centerY; name: qsTr("中心垂直位置"); onAdjusted: amount => studio.setSetting("centerY", amount)}
          }
          InspectorRow {
           caption: qsTr("入点")
           Level {value: root.st.settings.sourceStart; name: qsTr("素材入点"); onAdjusted: amount => studio.setSetting("sourceStart", amount)}
          }
          InspectorRow {
           caption: qsTr("出点")
           Level {value: root.st.settings.sourceEnd; name: qsTr("素材出点"); onAdjusted: amount => studio.setSetting("sourceEnd", amount)}
          }
          InspectorRow {
           visible: root.st.effect.id === 12
           caption: qsTr("波源")
           Choice {model: [qsTr("2 个"), qsTr("3 个"), qsTr("4 个")]; currentIndex: root.st.settings.waveSources - 2; onActivated: studio.setSetting("waveSources", currentIndex + 2)}
          }
          InspectorRow {
           visible: root.st.effect.family !== 3
           caption: qsTr("时间图")
           Action {text: root.st.settings.customMap ? qsTr("更换…") : qsTr("导入…"); Layout.fillWidth: true; onClicked: mapDialog.open()}
          }
          InspectorRow {
           visible: root.st.settings.customMap
           caption: qsTr("映射")
           Choice {model: [qsTr("黑白定时"), qsTr("中灰基准")]; currentIndex: root.st.settings.mapMode; onActivated: studio.setSetting("mapMode", currentIndex);  }
          }
          Action {visible: root.st.settings.customMap; text: qsTr("恢复内置形状"); onClicked: studio.setSetting("customMap", false)}
         }

        }
       }

       ColumnLayout {
        visible: root.inspectorPage === 2
        Layout.fillWidth: true; spacing: 12
        RowLayout {
         Layout.fillWidth: true
         LabelText {text: qsTr("切片阴影"); font.weight: Font.DemiBold}
         Item {Layout.fillWidth: true}
         Toggle {
          objectName: "shadowToggle"
          checked: root.st.settings.shadowEnabled
          Accessible.name: qsTr("切片阴影")
          onToggled: studio.setSetting("shadowEnabled", checked)
         }
        }
        MutedText {
         text: qsTr("在线上最浓，仅向选中一侧渐隐。")
         Layout.fillWidth: true; wrapMode: Text.Wrap
        }
        Rule {}
        ColumnLayout {
         enabled: root.st.settings.shadowEnabled
         opacity: enabled ? 1 : .48
         Layout.fillWidth: true; spacing: 10
         InspectorRow {
          caption: qsTr("强度")
          Level {value: root.st.settings.shadowStrength; name: qsTr("阴影强度"); onAdjusted: amount => studio.setSetting("shadowStrength", amount)}
         }
         InspectorRow {
          caption: qsTr("宽度"); hint: qsTr("阴影占单片宽度的比例")
          Level {value: root.st.settings.shadowWidth; from: .02; to: .75; name: qsTr("阴影宽度"); onAdjusted: amount => studio.setSetting("shadowWidth", amount)}
         }
         InspectorRow {
          caption: qsTr("羽化")
          Level {value: root.st.settings.shadowSoftness; name: qsTr("阴影羽化"); onAdjusted: amount => studio.setSetting("shadowSoftness", amount)}
         }
         InspectorRow {
          caption: qsTr("阴影方向"); hint: qsTr("沿切片排列方向选择阴影所在的边")
          Choice {
           model: root.shadowSides(root.st.effect, root.st.settings); currentIndex: root.st.settings.shadowSide
           onActivated: studio.setSetting("shadowSide", currentIndex)
           Accessible.name: qsTr("阴影边位")
          }
         }
        }
       }

       ColumnLayout {
        visible: root.inspectorPage === 0
        Layout.fillWidth: true; spacing: 11
        InspectorRow {
         caption:qsTr("稳定")
         Choice {model:[qsTr("关闭"),qsTr("固定机位锁定"),qsTr("极致锁定")];currentIndex:["off","lock","extreme"].indexOf(root.st.sourceOptions.stabilize);enabled:!root.st.rendering;onActivated:studio.setSourceOption("stabilize",["off","lock","extreme"][currentIndex])}
        }
        ColumnLayout {
         visible:root.st.sourceOptions.stabilize!=="off" && !!root.st.source
         Layout.fillWidth:true;spacing:4
         RowLayout {Layout.fillWidth:true;MutedText {text:root.st.stabilizeStatus;Layout.fillWidth:true}MutedText {text:root.st.processing ? Math.round(root.st.processingProgress*100)+"%" : root.st.processingError ? "" : qsTr("就绪")}}
         MutedText {visible:root.st.processing;text:root.st.processingEta;Layout.fillWidth:true;wrapMode:Text.WordWrap}
         ExportProgress {Layout.fillWidth:true;visible:root.st.processing;value:root.st.processingProgress}
        }
        InspectorRow {
         caption:qsTr("去闪")
         Choice {model:[qsTr("关闭"),qsTr("轻柔"),qsTr("标准"),qsTr("极致")];currentIndex:["off","light","standard","extreme"].indexOf(root.st.sourceOptions.deflicker);enabled:!root.st.rendering;onActivated:studio.setSourceOption("deflicker",["off","light","standard","extreme"][currentIndex])}
        }
        ColumnLayout {
         visible:root.st.sourceOptions.deflicker!=="off" && !!root.st.source
         Layout.fillWidth:true;spacing:4
         RowLayout {Layout.fillWidth:true;MutedText {text:root.st.deflickerStatus;Layout.fillWidth:true}MutedText {text:root.st.processing ? Math.round(root.st.processingProgress*100)+"%" : root.st.processingError ? "" : qsTr("就绪")}}
         MutedText {visible:root.st.processing;text:root.st.processingEta;Layout.fillWidth:true;wrapMode:Text.WordWrap}
         ExportProgress {Layout.fillWidth:true;visible:root.st.processing;value:root.st.processingProgress}
        }
        MutedText {text:qsTr("三档均保留自然昼夜变化，不混合相邻画面。");Layout.fillWidth:true;wrapMode:Text.Wrap}
        Rule {}
         InspectorRow {
          caption:qsTr("昼夜方向")
          enabled:!root.st.rendering
          Choice {model:[qsTr("自动识别"),qsTr("日转夜"),qsTr("夜转日")];currentIndex:["auto","day_to_night","night_to_day"].indexOf(root.st.sourceOptions.dayNight);onActivated:studio.setSourceOption("dayNight",["auto","day_to_night","night_to_day"][currentIndex])}
         }
         MutedText {
          text:root.st.sourceOptions.dayNight!=="auto" ? qsTr("已手动指定")+" · "+(root.st.sourceOptions.dayNight==="day_to_night"?qsTr("日转夜"):qsTr("夜转日")) : !root.st.dayNightDetected ? qsTr("导入素材后识别昼夜方向") : root.st.dayNightConfidence<.2 ? qsTr("变化不明显，可手动指定") : qsTr("识别结果")+" · "+(root.st.dayNightDetected==="day_to_night" ? qsTr("日转夜") : qsTr("夜转日"))
          Layout.fillWidth:true;wrapMode:Text.Wrap
         }
        InspectorRow {
         caption:qsTr("风格调色")
         Toggle {checked:root.st.sourceOptions.grade;enabled:!root.st.rendering;onToggled:studio.setSourceOption("grade",checked)}
        }
        ColumnLayout {
         enabled:root.st.sourceOptions.grade && !root.st.rendering
         opacity:enabled?1:.55
         Layout.fillWidth:true;spacing:10
         InspectorRow {
          caption:qsTr("预设")
          Choice {model:[qsTr("昼暖夜青"),qsTr("自然过渡"),qsTr("琥珀夜蓝"),qsTr("手动调整")];currentIndex:["cinematic","natural","amber","custom"].indexOf(root.st.sourceOptions.look);onActivated:studio.setSourceOption("look",["cinematic","natural","amber","custom"][currentIndex])}
         }
         SegmentBar {id:gradeLanguageSegments;Layout.fillWidth:true;labels:[qsTr("首帧"),qsTr("末帧")];currentIndex:root.colorEndpoint;onSelected:index=>root.colorEndpoint=index}
         InspectorRow {
          caption:qsTr("色温")
          Level {value:root.st.sourceOptions[(root.colorEndpoint===0?"start":"end")+"Temperature"];from:-100;to:100;percent:false;name:qsTr("色温");onAdjusted:amount=>studio.setSourceOption((root.colorEndpoint===0?"start":"end")+"Temperature",amount)}
         }
         InspectorRow {
          caption:qsTr("色调")
          Level {value:root.st.sourceOptions[(root.colorEndpoint===0?"start":"end")+"Tint"];from:-100;to:100;percent:false;name:qsTr("色调");onAdjusted:amount=>studio.setSourceOption((root.colorEndpoint===0?"start":"end")+"Tint",amount)}
         }
         InspectorRow {
          caption:qsTr("饱和度")
          Level {value:root.st.sourceOptions[(root.colorEndpoint===0?"start":"end")+"Saturation"];from:0;to:2;name:qsTr("饱和度");onAdjusted:amount=>studio.setSourceOption((root.colorEndpoint===0?"start":"end")+"Saturation",amount)}
         }
         InspectorRow {
          caption:qsTr("曝光")
          Level {value:root.st.sourceOptions[(root.colorEndpoint===0?"start":"end")+"Exposure"];from:-2;to:2;percent:false;name:qsTr("曝光");onAdjusted:amount=>studio.setSourceOption((root.colorEndpoint===0?"start":"end")+"Exposure",amount)}
         }
         InspectorRow {
          caption:qsTr("对比度")
          Level {value:root.st.sourceOptions[(root.colorEndpoint===0?"start":"end")+"Contrast"];from:.6;to:1.5;name:qsTr("对比度");onAdjusted:amount=>studio.setSourceOption((root.colorEndpoint===0?"start":"end")+"Contrast",amount)}
         }
         MutedText {text:qsTr("首尾参数随原片时间平滑过渡。");Layout.fillWidth:true;wrapMode:Text.Wrap}
         Rule {}
         RowLayout {Layout.fillWidth:true;LabelText {text:"HSL";font.weight:Font.DemiBold}Item {Layout.fillWidth:true}Action {text:qsTr("重置颜色");quiet:true;onClicked:{studio.setHsl(root.hslBand,"hue",0);studio.setHsl(root.hslBand,"saturation",0);studio.setHsl(root.hslBand,"luminance",0)}}}
         InspectorRow {
          caption:qsTr("颜色")
          Choice {model:[qsTr("红"),qsTr("橙"),qsTr("黄"),qsTr("绿"),qsTr("青"),qsTr("蓝"),qsTr("紫"),qsTr("洋红")];currentIndex:root.hslBand;onActivated:root.hslBand=currentIndex;Accessible.name:"HSL"}
         }
         InspectorRow {
          caption:qsTr("色相")
          Level {from:-60;to:60;percent:false;value:root.st.sourceOptions.hsl[root.hslBand].hue;name:qsTr("色相");onAdjusted:amount=>studio.setHsl(root.hslBand,"hue",amount)}
         }
         InspectorRow {
          caption:qsTr("颜色饱和度")
          Level {from:-100;to:100;percent:false;value:root.st.sourceOptions.hsl[root.hslBand].saturation;name:qsTr("颜色饱和度");onAdjusted:amount=>studio.setHsl(root.hslBand,"saturation",amount)}
         }
         InspectorRow {
          caption:qsTr("明度")
          Level {from:-100;to:100;percent:false;value:root.st.sourceOptions.hsl[root.hslBand].luminance;name:qsTr("明度");onAdjusted:amount=>studio.setHsl(root.hslBand,"luminance",amount)}
         }
         MutedText {text:qsTr("按颜色独立调整，实时应用到预览与导出。");Layout.fillWidth:true;wrapMode:Text.Wrap}

        }
        MutedText {visible:root.st.preparedReady;text:qsTr("正式素材已就绪，导出复用处理结果。");Layout.fillWidth:true;wrapMode:Text.WordWrap}
        ColumnLayout {
         visible:root.st.processing
         Layout.fillWidth:true
         MutedText {text:root.st.processingStage;Layout.fillWidth:true;wrapMode:Text.WordWrap}
         MutedText {text:root.st.processingEta;Layout.fillWidth:true;wrapMode:Text.WordWrap}
         ExportProgress {Layout.fillWidth:true;value:root.st.processingProgress}
        }
        MutedText {visible:!!root.st.processingError;text:root.st.processingError;color:"#D65C64";Layout.fillWidth:true;wrapMode:Text.Wrap}
       }

       ColumnLayout {
        visible: root.inspectorPage === 3
        Layout.fillWidth: true; spacing: 10
        InspectorRow {
         caption: qsTr("分辨率")
         Choice {
          model: ["1080p", "2K", "4K", qsTr("跟随原片")]
          currentIndex: [1920,2560,3840,0].indexOf(root.st.settings.longEdge)
          onActivated: studio.setSetting("longEdge", [1920,2560,3840,0][currentIndex])
         }
        }
        MutedText {text: root.st.width + " × " + root.st.height; Layout.alignment: Qt.AlignRight}
        InspectorRow {
         caption: qsTr("帧率")
         Choice {model: ["24 fps", "25 fps", "30 fps", "50 fps", "60 fps"]; currentIndex: [24,25,30,50,60].indexOf(root.st.settings.fps); onActivated: studio.setSetting("fps", [24,25,30,50,60][currentIndex])}
        }
        InspectorRow {
         caption: qsTr("码率")
         Choice {objectName:"exportBitrateMode";model:[qsTr("推荐"),qsTr("自定义")];currentIndex:root.st.settings.bitrateMbps>0?1:0;onActivated:studio.setSetting("bitrateMbps",currentIndex===0?0:root.st.recommendedBitrateMbps)}
        }
        InspectorRow {
         visible:root.st.settings.bitrateMbps>0
         caption:"Mbps"
         NumberInput {
          objectName:"exportBitrateInput"
          text:String(root.st.settings.bitrateMbps)
          validator:DoubleValidator {bottom:1;top:500;decimals:1;locale:"C"}
          inputMethodHints:Qt.ImhFormattedNumbersOnly
          onEditingFinished:{let n=Number(text);if(isFinite(n)&&n>=1&&n<=500)studio.setSetting("bitrateMbps",n);text=Qt.binding(function(){return String(root.st.settings.bitrateMbps)})}
         }
        }
        MutedText {objectName:"exportBitrateSummary";text:qsTr("目标码率")+" · "+root.st.exportBitrateMbps+" Mbps";Layout.fillWidth:true;wrapMode:Text.WordWrap}
        MutedText {text:qsTr("码率越高，文件越大。实际码率随画面变化。");Layout.fillWidth:true;wrapMode:Text.WordWrap}
        InspectorRow {
         caption: qsTr("渲染")
         Choice {model: [qsTr("自动"), "Metal GPU", qsTr("多核 CPU")]; currentIndex: ["auto","gpu","cpu"].indexOf(root.st.settings.engine); onActivated: studio.setSetting("engine", ["auto","gpu","cpu"][currentIndex])}
        }
        MutedText {
         text: root.st.device; Layout.alignment: Qt.AlignRight
         Layout.maximumWidth: inspectorForm.width; elide: Text.ElideRight
        }
        Rule {}
        Action {
         text: (root.exportAdvanced ? "▾  " : "▸  ") + qsTr("高级")
         quiet: true; implicitHeight: 27
         onClicked: root.exportAdvanced = !root.exportAdvanced
        }
        ColumnLayout {
         visible: root.exportAdvanced
         Layout.fillWidth: true; spacing: 10
         InspectorRow {
          caption:qsTr("平滑渐变")
          Toggle {checked:root.st.settings.gradientDither;onToggled:studio.setSetting("gradientDither",checked)}
         }
         InspectorRow {
          caption: qsTr("采样"); hint: qsTr("精细按素材帧率取样，标准最高 30 fps")
          Choice {model: [qsTr("原片精度"), qsTr("标准 · 30 fps")]; currentIndex: root.st.settings.quality === "full" ? 0 : 1; onActivated: studio.setSetting("quality", currentIndex === 0 ? "full" : "standard")}
         }
         InspectorRow {
          caption: qsTr("编码")
          Choice {model: [qsTr("优先硬件"), "CPU"]; currentIndex: root.st.settings.encoder === "cpu" ? 1 : 0; onActivated: studio.setSetting("encoder", currentIndex === 0 ? "auto" : "cpu")}
         }
         InspectorRow {
          caption: qsTr("保留音频")
          Toggle {checked: root.st.settings.keepAudio; Accessible.name: qsTr("保留音频"); onToggled: studio.setSetting("keepAudio", checked)}
         }
        }
       }
      }
     }
    }
   }
  }
  Item {
   Layout.fillWidth: true
   Layout.preferredHeight: visible ? (root.showQueue ? 197 : 86) : 0
   visible: root.st.queue.length > 0
   GlassPlate {anchors.fill: parent; radius: 18; tint: root.sidebar}
   ColumnLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 5
    RowLayout {
     Layout.fillWidth: true
     LabelText {text: root.st.batchStage || qsTr("导出进度"); font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight}
     MutedText {text: root.st.finishedCount + " / " + root.st.queue.length + qsTr(" 项")}
     LabelText {text: Math.round(root.st.batchProgress * 100) + "%"; font.weight: Font.DemiBold; font.family: studio.monoFont; Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight}
     Action {text: root.showQueue ? qsTr("收起队列") : qsTr("显示队列"); quiet: true; implicitHeight: 25; onClicked: root.showQueue = !root.showQueue}
    }
    MutedText {visible:root.st.rendering;text:root.st.exportEta;Layout.fillWidth:true;wrapMode:Text.WordWrap}
    ExportProgress {value: root.st.batchProgress; Layout.fillWidth: true; Layout.preferredHeight: 7; Accessible.name: qsTr("总导出进度")}
    ListView {
     id: jobs
     objectName: "exportJobs"
     visible: root.showQueue
     Layout.fillWidth: true
     Layout.fillHeight: true
     orientation: ListView.Horizontal
     boundsBehavior: Flickable.StopAtBounds
     spacing: 8
     clip: true
     model: queueRows
     ScrollBar.horizontal: ScrollBar {policy: ScrollBar.AsNeeded; interactive: true}
     delegate: Rectangle {
      required property string effectName
      required property real amount
      required property string stageName
      width: 218; height: 83; radius: 13
      color: root.control; border.color: root.glassStroke
      ColumnLayout {
       anchors.fill: parent; anchors.margins: 9; spacing: 5
       RowLayout {
        Layout.fillWidth: true
        LabelText {text: effectName; Layout.fillWidth: true; elide: Text.ElideRight}
        MutedText {text: Math.round(amount * 100) + "%"}
       }
       ExportProgress {value: amount; Layout.fillWidth: true; Layout.preferredHeight: 6; Accessible.name: effectName + qsTr("进度")}
       MutedText {text: stageName; Layout.fillWidth: true}
      }
     }
    }
   }
  }
  Item {
   Layout.fillWidth: true
   Layout.preferredHeight: 20
   RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    MutedText {text: root.st.status; Layout.fillWidth: true; elide: Text.ElideRight}
    MutedText {text: qsTr("免费开源 · AlphaStar · ") + root.st.version}
   }
  }
 }
}
