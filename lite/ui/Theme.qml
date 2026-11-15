pragma Singleton
import QtQuick
QtObject {
 property bool dark: false
 property string font: studio.interfaceFont
 property color canvas: dark ? "#14191F" : "#EFF2F7"
 property color panel: dark ? "#EE222932" : "#EAFBFCFE"
 property color control: dark ? "#553B4450" : "#BCFFFFFF"
 property color ink: dark ? "#EDF1F6" : "#202A37"
 property color muted: dark ? "#A5AFBF" : "#687587"
 property color line: dark ? "#25FFFFFF" : "#1A2B425D"
 property color blue: dark ? "#529CFF" : "#087DF3"
 property color selected: dark ? "#434D80B9" : "#DBEBFC"
 property color hover: dark ? "#35414E" : "#E5EDF7"
}
