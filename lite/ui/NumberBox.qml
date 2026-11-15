import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."
TextField {
 id:box
 property real number:0
 property real minimum:0
 property real maximum:100
 property int decimals:1
 signal edited(real amount)
 Layout.fillWidth:true;Layout.minimumWidth:40;implicitHeight:34
 text:Number(number.toFixed(decimals)).toString();color:Theme.ink;font.family:Theme.font;font.pixelSize:12
 selectByMouse:true;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
 validator:DoubleValidator {bottom:box.minimum;top:box.maximum;decimals:box.decimals;locale:"C"}
 background:Glass {radius:11;color:Theme.control;border.color:box.activeFocus?Theme.blue:Theme.line}
 onEditingFinished:{let n=Number(text);if(isFinite(n))edited(Math.max(minimum,Math.min(maximum,n)))}
}
