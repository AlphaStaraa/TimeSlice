import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "."
ApplicationWindow {
 id:root
 visible:true;width:1220;height:790;minimumWidth:980;minimumHeight:620
 title:st.title;color:Theme.canvas;font.family:studio.interfaceFont;font.pixelSize:13
 property var st:studio.uiState
 property bool portrait:!!st.source&&st.source.height>st.source.width
 property alias inspectorPage:tabs.currentIndex
 readonly property bool outputFolderVisible: outputDialog.visible
 function dismissOutputDialog(){outputDialog.reject()}
 palette.highlight:Theme.blue
 FileDialog {id:sourceDialog;title:qsTr("选择延时视频");nameFilters:[qsTr("视频 (*.mp4 *.mov *.mkv *.m4v *.avi *.webm)")];onAccepted:studio.importSource(selectedFile.toString())}
 FileDialog {id:mapDialog;title:qsTr("选择黑白时间图");nameFilters:[qsTr("时间图 (*.png *.tif *.tiff *.jpg *.jpeg)")];onAccepted:studio.importMap(selectedFile.toString())}
 FileDialog {id:importPresetDialog;title:qsTr("导入切片参数");nameFilters:["JSON (*.json)"];onAccepted:studio.importPreset(selectedFile.toString())}
 FileDialog {id:exportPresetDialog;title:qsTr("保存切片参数");fileMode:FileDialog.SaveFile;defaultSuffix:"json";nameFilters:["JSON (*.json)"];onAccepted:studio.exportPreset(selectedFile.toString())}
 FileDialog {id:metricsDialog;title:qsTr("导出本地统计");fileMode:FileDialog.SaveFile;defaultSuffix:"json";nameFilters:["JSON (*.json)"];onAccepted:studio.exportMetrics(selectedFile.toString())}
 FolderDialog {id:outputDialog;objectName:"outputFolderDialog";title:qsTr("选择导出文件夹");onAccepted:studio.setOutput(selectedFolder.toString());onRejected:studio.rejectOutput()}
 Connections {target:studio
  function onOutputPickerRequested(initial){outputDialog.currentFolder=initial;outputDialog.open()}
  function onUiChanged(){if(root.st.error&&!errorDialog.visible)errorDialog.open()}
 }
 Shortcut {sequences:[StandardKey.Open];enabled:!root.st.rendering;onActivated:sourceDialog.open()}
 Shortcut {sequence:"Space";enabled:root.st.hasImage&&!root.st.rendering;onActivated:studio.togglePlay()}
 GlassDialog {id:errorDialog;objectName:"errorDialog";title:qsTr("这一步没有完成");anchors.centerIn:parent;modal:true;width:Math.min(480,root.width-80);standardButtons:Dialog.Ok
  Label {text:root.st.error;width:parent.width;wrapMode:Text.WrapAnywhere;elide:Text.ElideNone}
  onAccepted:studio.dismissError()
  onRejected:studio.dismissError()
  onClosed:studio.dismissError()
 }
 GlassDialog {id:quitDialog;objectName:"quitDialog";width:360;title:qsTr("取消任务并退出？");anchors.centerIn:parent;modal:true;standardButtons:Dialog.Yes|Dialog.No
  Label {text:qsTr("已完成的视频会保留。")}
  onAccepted:{studio.cancelRender();Qt.quit()}
 }
 onClosing:close=>{if(st.rendering||st.loading){close.accepted=false;quitDialog.open()}}
 GlassDialog {id:aboutDialog;objectName:"aboutDialog";title:qsTr("关于时刃 Lite");anchors.centerIn:parent;modal:true;width:Math.min(500,root.width-64);standardButtons:Dialog.Close
  contentItem:ScrollView {implicitHeight:300;TextArea {text:studio.localizedLicense;readOnly:true;wrapMode:TextEdit.Wrap;selectByMouse:true;color:Theme.ink;font.family:Theme.font;background:null}}
 }
 Menu {id:appMenu;background:Glass{radius:15}
  MenuItem {text:qsTr("使用示例视频");enabled:!root.st.rendering;onTriggered:studio.importExample()}
  MenuSeparator{}
  MenuItem {text:qsTr("导入切片参数…");enabled:!root.st.rendering;onTriggered:importPresetDialog.open()}
  MenuItem {text:qsTr("保存切片参数…");enabled:root.st.selectedCount>0;onTriggered:exportPresetDialog.open()}
  MenuSeparator{}
  MenuItem {text:qsTr("本地统计（可选）");checkable:true;checked:!!root.st.metricsEnabled;onTriggered:studio.setMetricsEnabled(checked)}
  MenuItem {text:qsTr("导出本地统计…");onTriggered:metricsDialog.open()}
  MenuSeparator{}
  MenuItem {text:Theme.dark?qsTr("浅色界面"):qsTr("深色界面");onTriggered:Theme.dark=!Theme.dark}
  MenuItem {text:studio.language==="zh"?"English":"简体中文";onTriggered:studio.setLanguage(studio.language==="zh"?"en":"zh")}
  MenuSeparator{}
  MenuItem {text:qsTr("关于");onTriggered:aboutDialog.open()}
 }
 DropArea {anchors.fill:parent;enabled:!root.st.rendering;onDropped:drop=>{if(drop.urls.length)studio.importSource(drop.urls[0].toString())}}
 ColumnLayout {
  anchors.fill:parent;anchors.margins:14;spacing:12
  RowLayout {Layout.fillWidth:true;spacing:10
   Image {source:studio.assets+"app-icon-glass.png";Layout.preferredWidth:36;Layout.preferredHeight:36;mipmap:true}
   Label {text:root.st.title;font.pixelSize:20;font.weight:Font.DemiBold}
   Label {text:root.st.source?root.st.source.name:"";color:Theme.muted;font.pixelSize:11;Layout.fillWidth:true;Layout.maximumWidth:500;elide:Text.ElideMiddle}
   Item {Layout.fillWidth:true}
   Action {objectName:"importVideoAction";text:root.st.source?qsTr("更换视频"):qsTr("导入视频");primary:!root.st.source;enabled:!root.st.rendering&&!root.st.loading;onClicked:sourceDialog.open()}
   Action {objectName:"exportVideoAction";text:root.st.rendering?qsTr("取消导出"):root.st.batch?qsTr("导出 ")+root.st.selectedCount+qsTr(" 项"):qsTr("导出视频");primary:enabled&&!root.st.rendering;enabled:root.st.rendering||!!root.st.source&&!root.st.loading&&root.st.selectedCount>0;onClicked:root.st.rendering?studio.cancelRender():studio.startRender()}
   Action {text:"···";implicitWidth:36;onClicked:appMenu.popup()}
  }
  RowLayout {Layout.fillWidth:true;Layout.fillHeight:true;spacing:12
   Glass {Layout.preferredWidth:226;Layout.fillHeight:true
    ColumnLayout {anchors.fill:parent;anchors.margins:10;spacing:10
     RowLayout {Layout.fillWidth:true;Label {text:qsTr("效果");font.weight:Font.DemiBold;Layout.fillWidth:true}
      Action {objectName:"batchToggle";text:root.st.batch?qsTr("完成多选"):qsTr("多选");quiet:!root.st.batch;implicitHeight:27;onClicked:studio.setBatch(!root.st.batch)}
     }
     RowLayout {Layout.fillWidth:true;spacing:3
      Repeater {model:[qsTr("冻结"),qsTr("切片"),qsTr("创意")]
       Action {required property string modelData;required property int index;text:modelData;Layout.fillWidth:true;implicitWidth:45;implicitHeight:30;leftPadding:5;rightPadding:5;font.pixelSize:11;primary:root.st.family===[0,1,3][index];onClicked:studio.setFamily([0,1,3][index])}
      }
     }
     GridView {id:library;objectName:"effectLibrary";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;cellWidth:width/2;cellHeight:116;model:studio.effectModel
      ScrollBar.vertical:ScrollBar{policy:ScrollBar.AsNeeded}
      delegate:Item {required property var entry;width:library.cellWidth;height:library.cellHeight
       EffectCard {objectName:"effectCard_"+entry.id;width:parent.width-6;entry:parent.entry;batch:root.st.batch;selected:entry.checked;active:root.st.active===entry.id;busy:root.st.rendering}
      }
     }
    }
   }
   ColumnLayout {Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumWidth:280;spacing:10
    RowLayout {Layout.fillWidth:true;Layout.fillHeight:true;spacing:10
     Glass {id:previewBox;objectName:"mainPreview";Layout.fillWidth:true;Layout.fillHeight:true;color:Theme.dark?"#0F141A":"#DDE4EC";clip:true
      Image {id:video;anchors.fill:parent;anchors.margins:6;fillMode:Image.PreserveAspectFit;cache:false;source:root.st.hasImage?"image://preview/frame/"+root.st.imageVersion:"";opacity:root.st.loading?.3:1
       onWidthChanged:sizeTimer.restart();onHeightChanged:sizeTimer.restart()
      }
      Timer {id:sizeTimer;interval:80;onTriggered:studio.setPreviewViewport(video.width,video.height,Screen.devicePixelRatio)}
      ColumnLayout {visible:!root.st.hasImage&&!root.st.loading;anchors.centerIn:parent;spacing:14;width:Math.min(330,parent.width-36)
       Label {text:qsTr("让时间展开");font.pixelSize:30;font.weight:Font.DemiBold;Layout.alignment:Qt.AlignHCenter}
       Label {text:qsTr("导入一段延时，选择切片，即可出片。");color:Theme.muted;font.pixelSize:12;Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter;wrapMode:Text.WordWrap;elide:Text.ElideNone}
       Action {text:qsTr("选择视频");primary:true;Layout.alignment:Qt.AlignHCenter;onClicked:sourceDialog.open()}
       Action {objectName:"exampleAction";text:qsTr("先试试示例");quiet:true;Layout.alignment:Qt.AlignHCenter;onClicked:studio.importExample()}
      }
      ColumnLayout {visible:root.st.loading;anchors.centerIn:parent;width:parent.width-32;spacing:10
       BusyIndicator {running:root.st.loading;Layout.alignment:Qt.AlignHCenter}
       Label {text:root.st.busyText;Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter;wrapMode:Text.WordWrap;elide:Text.ElideNone}
      }
     }
     SelectionQueue {visible:root.st.batch&&root.portrait;vertical:true;Layout.preferredWidth:132;Layout.fillHeight:true}
    }
    RowLayout {Layout.fillWidth:true;spacing:10;enabled:root.st.hasImage&&!root.st.rendering
     Action {text:root.st.playing?"Ⅱ":"▶";implicitWidth:36;implicitHeight:30;onClicked:studio.togglePlay()}
     Slider {id:seekBar;Layout.fillWidth:true;from:0;to:1;value:root.st.progress;onMoved:studio.seek(value)
      background:Rectangle {x:seekBar.leftPadding;y:seekBar.topPadding+(seekBar.availableHeight-height)/2;width:seekBar.availableWidth;height:4;radius:2;color:Theme.line
       Rectangle {width:seekBar.visualPosition*parent.width;height:4;radius:2;color:Theme.blue}
      }
      handle:Rectangle {x:seekBar.leftPadding+seekBar.visualPosition*(seekBar.availableWidth-width);y:seekBar.topPadding+(seekBar.availableHeight-height)/2;width:16;height:16;radius:8;color:Theme.dark?"#DCE7F5":"white";border.color:Theme.line}
     }
     Label {text:root.st.elapsed+" / "+root.st.total;font.family:studio.monoFont;font.pixelSize:10;color:Theme.muted}
    }
    SelectionQueue {visible:root.st.batch&&!root.portrait;Layout.fillWidth:true;Layout.preferredHeight:132}
   }
   Glass {Layout.preferredWidth:studio.language==="en"?306:286;Layout.fillHeight:true
    ColumnLayout {anchors.fill:parent;anchors.margins:14;spacing:12
     TabBar {id:tabs;objectName:"inspectorSegments";Layout.fillWidth:true;background:Glass{color:Theme.control;radius:11}
      Repeater {model:[qsTr("切片"),qsTr("输出")]
       TabButton {required property string modelData;text:modelData;implicitHeight:32;font.family:Theme.font;font.pixelSize:12
        background:Glass {radius:10;color:parent.checked?Theme.selected:"transparent";border.color:"transparent"}
        contentItem:Label {text:parent.text;horizontalAlignment:Text.AlignHCenter;font.pixelSize:12}
       }
      }
     }
     Flickable {id:inspector;objectName:"inspectorScroll";Layout.fillWidth:true;Layout.fillHeight:true;contentHeight:form.implicitHeight;clip:true;boundsBehavior:Flickable.StopAtBounds;ScrollBar.vertical:ScrollBar{}
      Connections {target:tabs;function onCurrentIndexChanged(){inspector.contentY=0}}
      ColumnLayout {id:form;width:inspector.width-5
       Parameters {visible:tabs.currentIndex===0;Layout.fillWidth:true;onRequestMap:mapDialog.open()}
       Output {visible:tabs.currentIndex===1;Layout.fillWidth:true}
      }
     }
    }
   }
  }
  ColumnLayout {Layout.fillWidth:true;spacing:6
   RowLayout {Layout.fillWidth:true
    Label {text:root.st.rendering?root.st.batchStage:root.st.status;Layout.fillWidth:true;color:Theme.muted;font.pixelSize:11}
    Label {visible:root.st.rendering;text:root.st.exportEta;font.pixelSize:11;color:Theme.muted}
    Label {visible:root.st.rendering;text:Math.round(root.st.batchProgress*100)+"%";font.family:studio.monoFont;font.pixelSize:11}
    Action {visible:!!root.st.result&&!root.st.rendering;text:qsTr("显示文件");quiet:true;implicitHeight:26;onClicked:studio.openOutput()}
   }
   Progress {visible:root.st.rendering;Layout.fillWidth:true;value:root.st.batchProgress}
  }
 }
}
