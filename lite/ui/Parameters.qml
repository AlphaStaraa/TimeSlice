import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."
ColumnLayout {
 id:panel
 property var st:studio.uiState
 property bool advanced:false
 property bool shadowOpen:false
 signal requestMap()
 spacing:12;enabled:!st.rendering
 Label {text:panel.st.effect.name;font.pixelSize:22;font.weight:Font.DemiBold;Layout.fillWidth:true;wrapMode:Text.WordWrap;elide:Text.ElideNone}
 Label {text:panel.st.effect.description;font.pixelSize:11;color:Theme.muted;Layout.fillWidth:true;wrapMode:Text.WordWrap;elide:Text.ElideNone}
 Choice {visible:panel.st.effect.family===0;model:[qsTr("标准冻结"),qsTr("昼夜分割")];currentIndex:panel.st.freezeSplit?1:0;onActivated:studio.setFreezeSplit(currentIndex===1)}
 FieldRow {visible:panel.st.effect.family===0&&panel.st.freezeSplit;caption:qsTr("跳过中段");Level {value:panel.st.freezeDiscard;onAdjusted:amount=>studio.setFreezeDiscard(amount)}}
 Label {visible:panel.st.effect.family===0&&panel.st.freezeSplit;text:qsTr("展开完成即结束");font.pixelSize:11;color:Theme.muted}
 FieldRow {visible:panel.st.effect.family===1||panel.st.effect.family===2;caption:qsTr("运动");Choice {model:panel.st.movementLabels;currentIndex:panel.st.movementIndex;onActivated:studio.setMovement(currentIndex)}}
 FieldRow {visible:!!panel.st.orientationLabels&&panel.st.orientationLabels[0]!=="";caption:qsTr("排列");Choice {model:panel.st.orientationLabels;currentIndex:panel.st.orientationIndex;onActivated:studio.setOrientation(currentIndex)}}
 FieldRow {caption:qsTr("片数")
  NumberBox {objectName:"sliceCountInput";number:panel.st.count;minimum:2;maximum:panel.st.limit;decimals:0;enabled:!panel.st.pixel&&panel.st.effect.id!==13;onEdited:amount=>{studio.setSetting("sliceMode",1);studio.setSetting("sliceCount",amount)}}
  Action {text:qsTr("像素");primary:panel.st.pixel;implicitWidth:56;onClicked:studio.setSetting("sliceMode",panel.st.pixel?1:2)}
 }
 FieldRow {caption:qsTr("时长");NumberBox {number:panel.st.duration;minimum:.2;maximum:120;decimals:2;onEdited:amount=>studio.setSetting("duration",amount)}Label {text:qsTr("秒");color:Theme.muted}}
 FieldRow {caption:qsTr("方向");Choice {model:panel.st.effect.shape===1?[qsTr("上 → 下"),qsTr("下 → 上"),qsTr("向外"),qsTr("向内")]:[3,4].includes(panel.st.effect.shape)?[qsTr("顺时针"),qsTr("逆时针"),qsTr("向外"),qsTr("向内")]:[5,6,7,9,13,14].includes(panel.st.effect.shape)?[qsTr("向外"),qsTr("向内"),qsTr("正向"),qsTr("反向")]:[qsTr("左 → 右"),qsTr("右 → 左"),qsTr("向外"),qsTr("向内")];currentIndex:panel.st.settings.direction;onActivated:studio.setSetting("direction",currentIndex)}}
 FieldRow {visible:[0,104].includes(panel.st.effect.id);caption:qsTr("起始角度");NumberBox {objectName:"rotationStartInput";number:panel.st.settings.rotationStartAngle||0;maximum:360;onEdited:amount=>studio.setSetting("rotationStartAngle",amount)}Label{text:"°";color:Theme.muted}}
 FieldRow {visible:!([0,104].includes(panel.st.effect.id))&&[3,5,6,7,9,13,14].includes(panel.st.effect.shape);caption:qsTr("起点");Choice {model:[qsTr("随效果"),qsTr("底部"),qsTr("顶部"),qsTr("左侧"),qsTr("右侧"),qsTr("中心")];currentIndex:panel.st.settings.origin+1;onActivated:studio.setSetting("origin",currentIndex-1)}}
 FieldRow {visible:[2,12].includes(panel.st.effect.shape);caption:qsTr("倾角");NumberBox {number:panel.st.settings.angle;minimum:0;maximum:180;onEdited:amount=>studio.setSetting("angle",amount)}Label{text:"°";color:Theme.muted}}
 FieldRow {visible:panel.st.effect.family===0&&!panel.st.freezeSplit;caption:qsTr("完成后");Choice {model:[qsTr("定格"),qsTr("同步解冻"),qsTr("依次解冻"),qsTr("基础流动"),qsTr("时间波纹")];currentIndex:panel.st.settings.ending;onActivated:studio.setSetting("ending",currentIndex)}}
 Rectangle {Layout.fillWidth:true;height:1;color:Theme.line}
 RowLayout {Layout.fillWidth:true
  Action {text:(panel.shadowOpen?"⌄  ":"›  ")+qsTr("阴影");quiet:true;onClicked:panel.shadowOpen=!panel.shadowOpen}
  Item {Layout.fillWidth:true}
  Toggle {objectName:"shadowToggle";checked:panel.st.settings.shadowEnabled;onToggled:studio.setSetting("shadowEnabled",checked)}
 }
 ColumnLayout {visible:panel.shadowOpen;enabled:panel.st.settings.shadowEnabled;opacity:enabled?1:.4;Layout.fillWidth:true;spacing:9
  FieldRow {caption:qsTr("强度");Level {value:panel.st.settings.shadowStrength;onAdjusted:amount=>studio.setSetting("shadowStrength",amount)}}
  FieldRow {caption:qsTr("宽度");Level {from:.02;to:.75;value:panel.st.settings.shadowWidth;onAdjusted:amount=>studio.setSetting("shadowWidth",amount)}}
  FieldRow {caption:qsTr("羽化");Level {value:panel.st.settings.shadowSoftness;onAdjusted:amount=>studio.setSetting("shadowSoftness",amount)}}
  FieldRow {caption:qsTr("边位");Choice {model:[qsTr("默认侧"),qsTr("反向侧")];currentIndex:panel.st.settings.shadowSide;onActivated:studio.setSetting("shadowSide",currentIndex)}}
 }
 Rectangle {Layout.fillWidth:true;height:1;color:Theme.line}
 Action {text:(panel.advanced?"⌄  ":"›  ")+qsTr("更多参数");quiet:true;onClicked:panel.advanced=!panel.advanced}
 ColumnLayout {visible:panel.advanced;Layout.fillWidth:true;spacing:10
  FieldRow {visible:panel.st.effect.family===0&&!panel.st.freezeSplit;caption:qsTr("展开比例");Level {from:.1;to:.9;value:panel.st.settings.build;onAdjusted:amount=>studio.setSetting("build",amount)}}
  FieldRow {caption:qsTr("时间跨度");Level {from:.02;to:1;value:panel.st.settings.span||panel.st.effect.span;onAdjusted:amount=>studio.setSetting("span",amount)}}
  FieldRow {caption:qsTr("循环次数");NumberBox {number:panel.st.settings.cycles||panel.st.effect.cycles;minimum:1;maximum:30;onEdited:amount=>studio.setSetting("cycles",amount)}}
  FieldRow {visible:panel.st.effect.family===3;caption:qsTr("密度");Level {value:panel.st.settings.density;onAdjusted:amount=>studio.setSetting("density",amount)}}
  FieldRow {caption:qsTr("柔和度");Level {value:panel.st.settings.softness;onAdjusted:amount=>studio.setSetting("softness",amount)}}
  FieldRow {visible:[3,4].includes(panel.st.effect.shape);caption:qsTr("转数");NumberBox {number:panel.st.settings.turns<0?panel.st.effect.turns:panel.st.settings.turns;minimum:0;maximum:30;onEdited:amount=>studio.setSetting("turns",amount)}}
  FieldRow {caption:qsTr("时间方向");Choice {model:[qsTr("从早到晚"),qsTr("从晚到早")];currentIndex:panel.st.settings.sourceReverse?1:0;onActivated:studio.setSetting("sourceReverse",currentIndex===1)}}
  FieldRow {caption:qsTr("边缘取样");Choice {model:[qsTr("停在边缘"),qsTr("往返"),qsTr("循环")];currentIndex:panel.st.settings.playback;onActivated:studio.setSetting("playback",currentIndex)}}
  FieldRow {caption:qsTr("入点");Level {value:panel.st.settings.sourceStart;onAdjusted:amount=>studio.setSetting("sourceStart",amount)}}
  FieldRow {caption:qsTr("出点");Level {value:panel.st.settings.sourceEnd;onAdjusted:amount=>studio.setSetting("sourceEnd",amount)}}
  FieldRow {caption:qsTr("中心 X");Level {value:panel.st.settings.centerX;onAdjusted:amount=>studio.setSetting("centerX",amount)}}
  FieldRow {caption:qsTr("中心 Y");Level {value:panel.st.settings.centerY;onAdjusted:amount=>studio.setSetting("centerY",amount)}}
  FieldRow {visible:panel.st.effect.id===12;caption:qsTr("波源");Choice {model:["2","3","4"];currentIndex:panel.st.settings.waveSources-2;onActivated:studio.setSetting("waveSources",currentIndex+2)}}
  FieldRow {caption:qsTr("时间图");Action {text:qsTr("导入…");Layout.fillWidth:true;onClicked:panel.requestMap()}}
  FieldRow {visible:panel.st.settings.customMap;caption:qsTr("映射");Choice {model:[qsTr("黑白定时"),qsTr("中灰基准")];currentIndex:panel.st.settings.mapMode;onActivated:studio.setSetting("mapMode",currentIndex)}}
  Action {visible:panel.st.settings.customMap;text:qsTr("恢复内置形状");onClicked:studio.setSetting("customMap",false)}
 }
 Action {text:qsTr("恢复默认");quiet:true;Layout.alignment:Qt.AlignHCenter;onClicked:studio.resetSettings()}
}
