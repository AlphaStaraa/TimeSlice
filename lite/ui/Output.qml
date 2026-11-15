import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."
ColumnLayout {
 id:panel
 property var st:studio.uiState
 property bool advanced:false
 spacing:16;enabled:!st.rendering
 Label {text:qsTr("输出");font.pixelSize:22;font.weight:Font.DemiBold}
 Label {text:qsTr("H.264 · SDR · MP4");color:Theme.muted;font.pixelSize:11}
 FieldRow {caption:qsTr("尺寸");Choice {model:[qsTr("原始尺寸"),"4K","1440p","1080p","720p"];currentIndex:Math.max(0,[0,3840,2560,1920,1280].indexOf(panel.st.settings.longEdge));onActivated:studio.setSetting("longEdge",[0,3840,2560,1920,1280][currentIndex])}}
 FieldRow {caption:qsTr("帧率");Choice {model:["24","25","30","50","60","120"];currentIndex:Math.max(0,[24,25,30,50,60,120].indexOf(panel.st.settings.fps));onActivated:studio.setSetting("fps",[24,25,30,50,60,120][currentIndex])}}
 Label {text:panel.st.width+" × "+panel.st.height+"  ·  "+panel.st.settings.fps+" fps";color:Theme.muted;font.pixelSize:12;Layout.alignment:Qt.AlignHCenter}
 Rectangle {Layout.fillWidth:true;height:1;color:Theme.line}
 Label {text:qsTr("保存到");font.weight:Font.Medium}
 Action {objectName:"chooseOutputAction";text:panel.st.output?qsTr("更换文件夹…"):qsTr("选择文件夹…");Layout.fillWidth:true;onClicked:studio.chooseOutput()}
 Label {text:panel.st.output||qsTr("首次导出前选择位置");color:Theme.muted;font.pixelSize:11;Layout.fillWidth:true;wrapMode:Text.WrapAnywhere;elide:Text.ElideNone}
 Rectangle {Layout.fillWidth:true;height:1;color:Theme.line}
 Action {text:(panel.advanced?"⌄  ":"›  ")+qsTr("更多选项");quiet:true;onClicked:panel.advanced=!panel.advanced}
 ColumnLayout {visible:panel.advanced;Layout.fillWidth:true;spacing:12
  FieldRow {caption:qsTr("合成");Choice {model:[qsTr("自动"),"GPU","CPU"];currentIndex:["auto","gpu","cpu"].indexOf(panel.st.settings.engine);onActivated:studio.setSetting("engine",["auto","gpu","cpu"][currentIndex])}}
  FieldRow {caption:qsTr("编码");Choice {model:[qsTr("优先硬件"),"CPU"];currentIndex:panel.st.settings.encoder==="cpu"?1:0;onActivated:studio.setSetting("encoder",currentIndex===1?"cpu":"auto")}}
  FieldRow {caption:qsTr("时间精度");Choice {model:[qsTr("原片精度"),qsTr("标准 · 30 fps")];currentIndex:panel.st.settings.quality==="full"?0:1;onActivated:studio.setSetting("quality",currentIndex===0?"full":"standard")}}
  FieldRow {caption:qsTr("保留音频");Toggle {checked:panel.st.settings.keepAudio;onToggled:studio.setSetting("keepAudio",checked)}}
 }
 Label {text:panel.st.device;font.pixelSize:10;color:Theme.muted;Layout.fillWidth:true;wrapMode:Text.WordWrap;elide:Text.ElideNone}
}
