import QtQuick
import QtQuick.Layouts
import "."
RowLayout {
 property string caption
 default property alias fields:holder.data
 Layout.fillWidth:true;spacing:10
 Label {text:parent.caption;Layout.preferredWidth:studio.language==="en"?88:62;font.pixelSize:12;wrapMode:Text.WordWrap}
 RowLayout {id:holder;Layout.fillWidth:true;Layout.minimumWidth:0;spacing:7}
}
