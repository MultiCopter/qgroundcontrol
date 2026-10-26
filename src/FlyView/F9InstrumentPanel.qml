// F9-EVTOL 风格仪表盘（仿制）
// 说明：界面布局与配色参照 F9-EVTOL 发布的 APK 截图重绘，QML 为独立实现。
// 集成方式：FlyView 内的全屏覆盖层，左下角小按钮打开，面板内「导航」返回地图。

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

Item {
    id: root

    // ======== 状态 ========
    property bool expanded: false
    property var  vehicle: globals.activeVehicle
    readonly property bool hasVehicle: vehicle !== null && vehicle !== undefined

    // ======== 遥测（无飞控时全部回退到 0 / 占位符）========
    readonly property real pitchDeg:    hasVehicle ? vehicle.pitch.value : 0
    readonly property real rollDeg:     hasVehicle ? vehicle.roll.value : 0
    readonly property real headingDeg:  hasVehicle ? vehicle.heading.value : 0
    readonly property real gsKmh:       hasVehicle ? vehicle.groundSpeed.value * 3.6 : 0
    readonly property real altRel:      hasVehicle ? vehicle.altitudeRelative.value : 0
    readonly property real altAmsl:     hasVehicle ? vehicle.altitudeAMSL.value : 0
    readonly property real climbMs:     hasVehicle ? vehicle.climbRate.value : 0
    readonly property real battPct:     hasVehicle && vehicle.battery ? vehicle.battery.percentRemaining.value : -1
    readonly property real battVolt:    hasVehicle && vehicle.battery ? vehicle.battery.voltage.value : 0
    readonly property real battAmp:     hasVehicle && vehicle.battery ? vehicle.battery.current.value : 0
    readonly property real battTemp:    hasVehicle && vehicle.battery ? vehicle.battery.temperature.value : NaN
    readonly property int  sats:        hasVehicle && vehicle.gps ? vehicle.gps.satelliteCount.value : 0
    readonly property string flightModeText: hasVehicle ? vehicle.flightMode : "—"
    readonly property string armText:    !hasVehicle ? "未连接" : (vehicle.armed ? "已解锁" : "已加锁")
    readonly property string linkText:   !hasVehicle ? "无信号" : (vehicle.communicationLost ? "通信中断" : "正常")

    // ======== 配色 ========
    readonly property color cBg:      "#000000"
    readonly property color cPanel:   "#050A0D"
    readonly property color cCyan:    "#25D6EA"
    readonly property color cCyanDim: "#0F6E7A"
    readonly property color cLabel:   "#7E8A93"
    readonly property color cValue:   "#F2F7F9"
    readonly property color cDivider: "#163038"
    readonly property color cBtnBg:   "#08131A"
    readonly property color cBtnBd:   "#1D3B45"
    readonly property color cActive:  "#12A395"
    readonly property color cRed:     "#E23B3B"

    function fmt(v, digits) {
        if (v === undefined || v === null || isNaN(v)) return "—"
        return Number(v).toFixed(digits === undefined ? 1 : digits)
    }

    // ======== 打开入口（收起状态）========
    Rectangle {
        id: launcher
        visible: !root.expanded
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 1.2
        anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 4.2
        width:  launcherText.implicitWidth + ScreenTools.defaultFontPixelWidth * 2.4
        height: launcherText.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.8
        radius: height / 2
        color:        launcherMouse.pressed ? root.cActive : "#0A1A20"
        border.color: root.cCyan
        border.width: 1

        QGCLabel {
            id: launcherText
            anchors.centerIn: parent
            text:  qsTr("F9 仪表")
            color: root.cCyan
            font.bold: true
            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.85
        }

        MouseArea {
            id: launcherMouse
            anchors.fill: parent
            onClicked: root.expanded = true
        }
    }

    // ======== 主面板（展开状态）========
    Rectangle {
        id: panel
        visible: root.expanded
        anchors.fill: parent
        color: root.cBg
        focus: true

        readonly property real topH:    height * 0.078
        readonly property real bottomH: height * 0.135
        readonly property real sidePad: width * 0.022
        readonly property real dialDia: Math.min((height - topH - bottomH) * 0.82, width * 0.40)
        readonly property real bigFont: height * 0.115
        readonly property real midFont: height * 0.038
        readonly property real smlFont: height * 0.026

        // ============ 顶栏 ============
        Item {
            id: topBar
            anchors.top: parent.top
            width: parent.width
            height: panel.topH

            Row {
                anchors.left: parent.left
                anchors.leftMargin: panel.sidePad
                anchors.verticalCenter: parent.verticalCenter
                spacing: ScreenTools.defaultFontPixelWidth * 1.6

                Repeater {
                    model: [
                        { k: qsTr("控制权"), v: "—" },
                        { k: qsTr("飞控"),   v: root.armText },
                        { k: qsTr("当前模式"), v: root.flightModeText },
                        { k: qsTr("触屏操纵"), v: qsTr("关闭") }
                    ]
                    delegate: Row {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.5
                        QGCLabel {
                            text: modelData.k + ":"
                            color: root.cLabel
                            font.pixelSize: panel.smlFont
                        }
                        QGCLabel {
                            text: modelData.v
                            color: root.cValue
                            font.pixelSize: panel.smlFont
                            font.bold: true
                        }
                    }
                }
            }

            // 右上角页签
            Row {
                anchors.right: parent.right
                anchors.rightMargin: panel.sidePad
                anchors.verticalCenter: parent.verticalCenter
                spacing: ScreenTools.defaultFontPixelWidth * 0.8

                Repeater {
                    model: [ qsTr("仪表"), qsTr("导航"), qsTr("专业模式") ]
                    delegate: Rectangle {
                        width:  tabLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 2.2
                        height: tabLabel.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.9
                        radius: 3
                        color:        index === 0 ? root.cBtnBg : "transparent"
                        border.color: index === 0 ? root.cCyan : root.cBtnBd
                        border.width: 1

                        QGCLabel {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: index === 0 ? root.cCyan : root.cLabel
                            font.pixelSize: panel.smlFont
                            font.bold: index === 0
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: index === 1
                            onClicked: root.expanded = false   // 导航 = 回到地图
                        }
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: root.cDivider
            }
        }


        // ============ 装饰：左下雷达圈 ============
        Item {
            width:  parent.width * 0.13
            height: width
            anchors.left: parent.left
            anchors.leftMargin: parent.width * 0.008
            anchors.bottom: bottomBar.top
            anchors.bottomMargin: parent.height * 0.005
            opacity: 0.40

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    var cx = width / 2, cy = height / 2, r = width / 2
                    ctx.reset()
                    ctx.strokeStyle = "#1B4550"
                    ctx.lineWidth = 1
                    for (var i = 1; i <= 3; i++) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r * i / 3, 0, Math.PI * 2)
                        ctx.stroke()
                    }
                    ctx.beginPath()
                    ctx.moveTo(cx - r, cy); ctx.lineTo(cx + r, cy)
                    ctx.moveTo(cx, cy - r); ctx.lineTo(cx, cy + r)
                    ctx.stroke()
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width:  parent.width * 0.16
                height: width
                radius: width / 2
                color: "#123942"
                border.color: root.cCyanDim
                border.width: 1
            }
        }

        // ============ 左：地速 / 升降速度 ============
        Item {
            id: leftCluster
            anchors.left: parent.left
            anchors.leftMargin: panel.sidePad
            anchors.verticalCenter: parent.verticalCenter
            width:  parent.width * 0.24
            height: parent.height * 0.52

            QGCLabel {
                id: gsValue
                anchors.left: parent.left
                anchors.top: parent.top
                text:  Math.round(root.gsKmh)
                color: root.cCyan
                font.bold: true
                font.pixelSize: panel.bigFont
            }
            QGCLabel {
                anchors.left: gsValue.right
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.6
                anchors.baseline: gsValue.bottom
                text: "km/h"
                color: root.cValue
                font.pixelSize: panel.midFont
                font.italic: true
            }
            QGCLabel {
                anchors.left: gsValue.left
                anchors.top: gsValue.bottom
                anchors.topMargin: -panel.smlFont * 0.2
                text: qsTr("地速") + "\n" + qsTr("地面速度")
                color: root.cLabel
                font.pixelSize: panel.smlFont
            }
            QGCLabel {
                anchors.left: gsValue.right
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 4.2
                anchors.top: gsValue.top
                anchors.topMargin: panel.smlFont * 1.0
                text: "GS " + root.fmt(root.gsKmh, 0) + " km/h"
                color: root.cLabel
                font.pixelSize: panel.smlFont * 0.9
            }

            // 速度刻度条
            Item {
                id: gsBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: gsValue.bottom
                anchors.topMargin: panel.smlFont * 2.4
                height: panel.smlFont * 3.2

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: parent.height * 0.26
                    color: "#0C2229"
                    border.color: root.cDivider
                    border.width: 1

                    Rectangle {
                        width: parent.width * Math.min(root.gsKmh / 65, 1)
                        height: parent.height
                        color: root.cCyan
                        opacity: 0.55
                    }
                }
                // 65 红线
                Rectangle {
                    x: parent.width * 0.94
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: parent.height * 0.8
                    color: root.cRed
                }
                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    QGCLabel { text: "0";  color: root.cLabel; font.pixelSize: panel.smlFont * 0.85 }
                    Item { width: parent.width * 0.55 - 30; height: 1 }
                    QGCLabel { text: "40"; color: root.cLabel; font.pixelSize: panel.smlFont * 0.85 }
                    Item { width: parent.width * 0.30; height: 1 }
                    QGCLabel { text: "65"; color: root.cRed;   font.pixelSize: panel.smlFont * 0.85 }
                }
            }

            // 升降速度
            Item {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width
                height: panel.bigFont * 0.72

                QGCLabel {
                    id: climbLabel
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: qsTr("升降速度") + "\n" + qsTr("油门/俯仰")
                    color: root.cLabel
                    font.pixelSize: panel.smlFont
                }
                QGCLabel {
                    anchors.left: climbLabel.right
                    anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                    anchors.bottom: climbLabel.bottom
                    text: root.fmt(root.climbMs, 1)
                    color: root.cCyan
                    font.bold: true
                    font.pixelSize: panel.bigFont * 0.62
                }
                QGCLabel {
                    anchors.left: climbLabel.right
                    anchors.leftMargin: climbLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 4
                    anchors.bottom: climbLabel.bottom
                    text: "m/s"
                    color: root.cValue
                    font.pixelSize: panel.midFont * 0.9
                }
            }
        }

        // ============ 中：圆形姿态仪 ============
        Item {
            id: dialWrap
            width:  panel.dialDia
            height: panel.dialDia
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            readonly property real radius: width / 2

            Canvas {
                id: dial
                anchors.fill: parent
                renderStrategy: Canvas.Cooperative

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width / 2
                    var cy = height / 2
                    var r  = Math.min(width, height) / 2

                    // ---- 外圈罗盘刻度 ----
                    var ringR = r * 0.995
                    ctx.lineWidth = 1
                    for (var a = 0; a < 360; a += 5) {
                        var rad = (a - 90) * Math.PI / 180
                        var long = (a % 30 === 0)
                        var r1 = ringR - (long ? r * 0.075 : r * 0.04)
                        ctx.beginPath()
                        ctx.strokeStyle = long ? "#9FB3BC" : "#3A4E57"
                        ctx.moveTo(cx + Math.cos(rad) * ringR, cy + Math.sin(rad) * ringR)
                        ctx.lineTo(cx + Math.cos(rad) * r1,   cy + Math.sin(rad) * r1)
                        ctx.stroke()
                    }
                    // 罗盘数字/方位
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.font = "bold " + Math.round(r * 0.085) + "px sans-serif"
                    for (var d = 0; d < 360; d += 30) {
                        var rr = (d - 90) * Math.PI / 180
                        var lr = ringR - r * 0.155
                        var lbl
                        if (d === 0)        lbl = "N"
                        else if (d === 90)  lbl = "E"
                        else if (d === 180) lbl = "S"
                        else if (d === 270) lbl = "W"
                        else                lbl = ("00" + d).slice(-3)
                        ctx.fillStyle = (d === 0 || d === 90 || d === 180 || d === 270) ? "#E8F4F8" : "#9FB3BC"
                        ctx.fillText(lbl, cx + Math.cos(rr) * lr, cy + Math.sin(rr) * lr)
                    }

                    // ---- 姿态球（裁切到内圆）----
                    var pr = r * 0.635
                    ctx.save()
                    ctx.beginPath()
                    ctx.arc(cx, cy, pr, 0, Math.PI * 2)
                    ctx.clip()

                    var pitchPx = Math.max(-1, Math.min(1, root.pitchDeg / 45)) * pr * 1.15
                    ctx.translate(cx, cy + pitchPx)
                    ctx.rotate(-root.rollDeg * Math.PI / 180)

                    var span = pr * 2.6
                    // 天
                    var sky = ctx.createLinearGradient(0, -span, 0, 0)
                    sky.addColorStop(0, "#1B4F7A")
                    sky.addColorStop(1, "#2E8CC4")
                    ctx.fillStyle = sky
                    ctx.fillRect(-span, -span, span * 2, span)
                    // 地
                    var gnd = ctx.createLinearGradient(0, 0, 0, span)
                    gnd.addColorStop(0, "#8A4A12")
                    gnd.addColorStop(1, "#C8781A")
                    ctx.fillStyle = gnd
                    ctx.fillRect(-span, 0, span * 2, span)

                    // 地平线
                    ctx.strokeStyle = "#FFFFFF"
                    ctx.lineWidth = Math.max(2, r * 0.008)
                    ctx.beginPath()
                    ctx.moveTo(-span, 0)
                    ctx.lineTo(span, 0)
                    ctx.stroke()

                    // 俯仰梯
                    ctx.font = "bold " + Math.round(r * 0.062) + "px sans-serif"
                    ctx.textBaseline = "middle"
                    for (var p = -60; p <= 60; p += 10) {
                        if (p === 0) continue
                        var y = -p * (pr / 22)
                        var w = (p % 20 === 0) ? pr * 0.62 : pr * 0.34
                        var gap = pr * 0.10
                        ctx.strokeStyle = "#EAF3F7"
                        ctx.lineWidth = Math.max(1, r * 0.004)
                        ctx.beginPath()
                        ctx.moveTo(-w / 2 - gap, y); ctx.lineTo(-gap, y)
                        ctx.moveTo(gap, y);          ctx.lineTo(w / 2 + gap, y)
                        ctx.stroke()
                        ctx.fillStyle = "#EAF3F7"
                        ctx.fillText(Math.abs(p), -w / 2 - gap - pr * 0.1, y)
                        ctx.fillText(Math.abs(p),  w / 2 + gap + pr * 0.1, y)
                    }
                    ctx.restore()

                    // ---- 固定飞机符号 ----
                    ctx.strokeStyle = "#FFD24A"
                    ctx.lineWidth = Math.max(2, r * 0.012)
                    ctx.beginPath()
                    ctx.moveTo(cx - pr * 0.42, cy); ctx.lineTo(cx - pr * 0.14, cy)
                    ctx.moveTo(cx + pr * 0.14, cy); ctx.lineTo(cx + pr * 0.42, cy)
                    ctx.moveTo(cx, cy - pr * 0.05); ctx.lineTo(cx, cy + pr * 0.05)
                    ctx.stroke()

                    // ---- 顶部航向指针（三角）----
                    ctx.fillStyle = "#FFFFFF"
                    ctx.beginPath()
                    ctx.moveTo(cx, cy - ringR + r * 0.02)
                    ctx.lineTo(cx - r * 0.035, cy - ringR + r * 0.075)
                    ctx.lineTo(cx + r * 0.035, cy - ringR + r * 0.075)
                    ctx.closePath()
                    ctx.fill()

                    // ---- 内圆描边 ----
                    ctx.beginPath()
                    ctx.arc(cx, cy, pr, 0, Math.PI * 2)
                    ctx.strokeStyle = "#DDE9EF"
                    ctx.lineWidth = Math.max(2, r * 0.008)
                    ctx.stroke()

                    // 外圈细描边
                    ctx.beginPath()
                    ctx.arc(cx, cy, ringR, 0, Math.PI * 2)
                    ctx.strokeStyle = "#2A3D46"
                    ctx.lineWidth = 1
                    ctx.stroke()
                }
            }

            // 航向读数（圆盘上方）
            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: -ScreenTools.defaultFontPixelHeight * 0.2
                text: "HDG " + ("00" + Math.round(root.headingDeg)).slice(-3) + "°"
                color: root.cValue
                font.pixelSize: panel.midFont * 1.1
                font.bold: true
            }
            // 滚转读数
            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -ScreenTools.defaultFontPixelHeight * 1.9
                text: qsTr("横滚") + " " + root.fmt(root.rollDeg, 1) + "°   " + qsTr("俯仰") + " " + root.fmt(root.pitchDeg, 1) + "°"
                color: root.cLabel
                font.pixelSize: panel.smlFont * 1.1
            }

            Timer {
                interval: 50
                running: panel.visible
                repeat: true
                onTriggered: dial.requestPaint()
            }
        }

        // ============ 右：高度 / 电源 ============
        Column {
            id: rightCluster
            width: parent.width * 0.26
            anchors.right: parent.right
            anchors.rightMargin: panel.sidePad
            anchors.verticalCenter: parent.verticalCenter
            spacing: panel.smlFont * 1.6

            Row {
                anchors.right: parent.right
                spacing: ScreenTools.defaultFontPixelWidth * 0.4

                QGCLabel {
                    text:  root.fmt(root.altRel, 1)
                    color: root.cCyan
                    font.bold: true
                    font.pixelSize: panel.bigFont
                    anchors.baseline: altUnit.baseline
                }
                QGCLabel {
                    id: altUnit
                    text: "m"
                    color: root.cValue
                    font.pixelSize: panel.midFont
                    font.italic: true
                    anchors.bottom: parent.bottom
                }
            }

            Column {
                width: parent.width
                spacing: panel.smlFont * 0.15
                QGCLabel {
                    anchors.right: parent.right
                    text: qsTr("相对起飞点高度")
                    color: root.cLabel
                    font.pixelSize: panel.smlFont * 0.95
                }
                QGCLabel {
                    anchors.right: parent.right
                    text: qsTr("离地高度") + " AGL " + root.fmt(root.altRel, 1) + " m"
                    color: root.cLabel
                    font.pixelSize: panel.smlFont * 0.95
                }
            }

            Column {
                width: parent.width
                spacing: panel.smlFont * 0.35

                Repeater {
                    model: [
                        { k: qsTr("至储备线"), v: "-- min" },
                        { k: qsTr("电压"),     v: root.fmt(root.battVolt, 1) + " V" },
                        { k: qsTr("电流"),     v: root.fmt(root.battAmp, 1) + " A" },
                        { k: qsTr("电池温度"), v: isNaN(root.battTemp) ? "-- °C" : root.fmt(root.battTemp, 1) + " °C" }
                    ]
                    delegate: Row {
                        anchors.right: parent.right
                        spacing: ScreenTools.defaultFontPixelWidth * 0.6
                        QGCLabel {
                            text: modelData.k
                            color: root.cLabel
                            font.pixelSize: panel.smlFont * 0.95
                        }
                        QGCLabel {
                            text: modelData.v
                            color: root.cValue
                            font.pixelSize: panel.smlFont * 0.95
                            font.bold: true
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: ScreenTools.defaultFontPixelWidth * 0.4
                    QGCLabel {
                        text: qsTr("电量")
                        color: root.cLabel
                        font.pixelSize: panel.smlFont * 0.95
                    }
                    QGCLabel {
                        text: root.battPct < 0 ? "-- %" : Math.round(root.battPct) + " %"
                        color: root.battPct >= 0 && root.battPct < 25 ? root.cRed : root.cCyan
                        font.pixelSize: panel.smlFont * 0.95
                        font.bold: true
                    }
                    Row {
                        spacing: 2
                        Repeater {
                            model: 8
                            delegate: Rectangle {
                                width:  panel.smlFont * 0.40
                                height: panel.smlFont * 0.60
                                color: (root.battPct / 12.5 > index) ? (root.battPct < 25 ? root.cRed : "#35C759") : "#12262E"
                            }
                        }
                    }
                }

                QGCLabel {
                    anchors.right: parent.right
                    text: qsTr("卫星") + " " + root.sats + "   " + qsTr("通信") + " " + root.linkText
                    color: root.cLabel
                    font.pixelSize: panel.smlFont * 0.9
                }
            }
        }

        // ============ 底栏 ============
        Item {
            id: bottomBar
            anchors.bottom: parent.bottom
            width: parent.width
            height: panel.bottomH

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: root.cDivider
            }

            // 飞控解锁状态徽标
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: panel.sidePad
                anchors.verticalCenter: parent.verticalCenter
                width:  unlockLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 2
                height: unlockLabel.implicitHeight + ScreenTools.defaultFontPixelHeight * 1.1
                color: "transparent"
                border.color: root.cDivider
                border.width: 1

                QGCLabel {
                    id: unlockLabel
                    anchors.centerIn: parent
                    text: qsTr("飞控") + (root.hasVehicle && root.vehicle.armed ? qsTr("解锁") : qsTr("锁定"))
                    color: root.hasVehicle && root.vehicle.armed ? root.cRed : root.cLabel
                    font.pixelSize: panel.smlFont
                }
            }

            // 功能按钮
            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin:  panel.sidePad + unlockLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 4
                anchors.rightMargin: panel.sidePad
                anchors.verticalCenter: parent.verticalCenter
                spacing: ScreenTools.defaultFontPixelWidth * 0.5

                Repeater {
                    model: [
                        { t: qsTr("姿态"),       on: true  },
                        { t: qsTr("定点"),       on: false },
                        { t: qsTr("定高"),       on: false },
                        { t: qsTr("起飞"),       on: false },
                        { t: qsTr("降落"),       on: false },
                        { t: qsTr("返航"),       on: false },
                        { t: qsTr("保持待定义"), on: false },
                        { t: qsTr("触屏接管"),   on: false },
                        { t: qsTr("更多"),       on: false }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: btnText.implicitHeight + ScreenTools.defaultFontPixelHeight * 1.5
                        radius: 3
                        color:        modelData.on ? root.cActive : root.cBtnBg
                        border.color: modelData.on ? root.cActive : root.cBtnBd
                        border.width: 1

                        QGCLabel {
                            id: btnText
                            anchors.centerIn: parent
                            text:  modelData.t
                            color: modelData.on ? "#04241F" : root.cValue
                            font.pixelSize: panel.smlFont
                            font.bold: modelData.on
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (modelData.t === qsTr("更多"))
                                    root.expanded = false
                            }
                        }
                    }
                }
            }
        }
    }
}
