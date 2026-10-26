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
    readonly property string armText:    !hasVehicle ? root.t("未连接", "OFFLINE") : (vehicle.armed ? root.t("已解锁", "ARMED") : root.t("已加锁", "DISARMED"))
    readonly property string linkText:   !hasVehicle ? root.t("无信号", "NO LINK") : (vehicle.communicationLost ? root.t("通信中断", "LINK LOST") : root.t("正常", "OK"))

    // ======== 主题（深色 / 浅色）========
    property bool darkMode: true
    property bool englishMode: false

    readonly property var theme: darkMode ? __darkTheme : __lightTheme

    readonly property var __darkTheme: ({
        bg:         "#000000",
        panel:      "#050A0D",
        cyan:       "#25D6EA",
        cyanDim:    "#0F6E7A",
        label:      "#7E8A93",
        value:      "#F2F7F9",
        divider:    "#163038",
        btnBg:      "#08131A",
        btnBd:      "#1D3B45",
        active:     "#12A395",
        red:        "#E23B3B",
        launcherBg: "#0A1A20",
        barTrack:   "#0C2229",
        radar:      "#1B4550",
        radarDot:   "#123942",
        cellOn:     "#35C759",
        cellOff:    "#12262E",
        tickLong:   "#9FB3BC",
        tickShort:  "#3A4E57",
        tickMain:   "#E8F4F8",
        ringStroke: "#2A3D46",
        innerRing:  "#DDE9EF",
        heading:    "#FFFFFF",
        onActive:   "#04241F"
    })

    readonly property var __lightTheme: ({
        bg:         "#EEF2F5",
        panel:      "#FFFFFF",
        cyan:       "#0B7C90",
        cyanDim:    "#63A7B4",
        label:      "#5B6B75",
        value:      "#0E1A21",
        divider:    "#C9D6DE",
        btnBg:      "#FFFFFF",
        btnBd:      "#B7C7D1",
        active:     "#0B7C90",
        red:        "#C62828",
        launcherBg: "#FFFFFF",
        barTrack:   "#DCE6EC",
        radar:      "#B9CBD5",
        radarDot:   "#8FA9B6",
        cellOn:     "#1E9E4A",
        cellOff:    "#D3DFE6",
        tickLong:   "#3C4E58",
        tickShort:  "#8FA2AC",
        tickMain:   "#101A20",
        ringStroke: "#A8BAC4",
        innerRing:  "#37474F",
        heading:    "#101A20",
        onActive:   "#FFFFFF"
    })

    // ======== 双语 ========
    function t(zh, en) { return englishMode ? en : zh }

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
        color:        launcherMouse.pressed ? root.theme.active : root.theme.launcherBg
        border.color: root.theme.cyan
        border.width: 1

        QGCLabel {
            id: launcherText
            anchors.centerIn: parent
            text:  root.t("F9 仪表", "F9 PANEL")
            color: root.theme.cyan
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
        color: root.theme.bg
        focus: true

        // 字号基准：横屏取高度；竖屏取宽度折算，避免字号随高度爆炸
        readonly property real vUnit:   Math.min(height, width * 0.62)
        readonly property real topH:    height * 0.078
        readonly property real bottomH: height * 0.135
        readonly property real sidePad: width * 0.022
        readonly property real dialDia: Math.min((height - topH - bottomH) * 0.82, width * 0.40)
        readonly property real bigFont: vUnit * 0.115
        readonly property real midFont: vUnit * 0.038
        readonly property real smlFont: vUnit * 0.026

        // ============ 顶栏 ============
        Item {
            id: topBar
            anchors.top: parent.top
            width: parent.width
            height: panel.topH

            readonly property real chipH: ScreenTools.defaultFontPixelHeight * 1.95

            Row {
                anchors.left: parent.left
                anchors.leftMargin: panel.sidePad
                anchors.verticalCenter: parent.verticalCenter
                spacing: ScreenTools.defaultFontPixelWidth * 1.6
                // 竖屏宽度不足时隐藏这排状态文字，避免与右侧页签/开关重叠
                visible: panel.width >= panel.height * 1.15

                Repeater {
                    model: [
                        { k: root.t("控制权", "CTRL"), v: "—" },
                        { k: root.t("飞控", "FC"),   v: root.armText },
                        { k: root.t("当前模式", "MODE"), v: root.flightModeText },
                        { k: root.t("触屏操纵", "TOUCH"), v: root.t("关闭", "OFF") }
                    ]
                    delegate: Row {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.5
                        QGCLabel {
                            text: modelData.k + ":"
                            color: root.theme.label
                            font.pixelSize: panel.smlFont
                        }
                        QGCLabel {
                            text: modelData.v
                            color: root.theme.value
                            font.pixelSize: panel.smlFont
                            font.bold: true
                        }
                    }
                }
            }

            // 主题 / 语言切换
            Row {
                id: toggles
                anchors.right: parent.right
                anchors.rightMargin: panel.sidePad
                anchors.verticalCenter: parent.verticalCenter
                spacing: ScreenTools.defaultFontPixelWidth * 0.6

                Rectangle {
                    id: themeChip
                    width:  themeLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 1.6
                    height: topBar.chipH
                    radius: 3
                    color:        root.darkMode ? root.theme.cyan : "transparent"
                    border.color: root.theme.cyan
                    border.width: 1

                    QGCLabel {
                        id: themeLabel
                        anchors.centerIn: parent
                        text:  root.darkMode ? root.t("深色", "DARK") : root.t("浅色", "LIGHT")
                        color: root.darkMode ? root.theme.onActive : root.theme.cyan
                        font.pixelSize: panel.smlFont
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.darkMode = !root.darkMode
                    }
                }

                Rectangle {
                    id: langChip
                    width:  langLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 1.6
                    height: topBar.chipH
                    radius: 3
                    color:        root.englishMode ? root.theme.cyan : "transparent"
                    border.color: root.theme.cyan
                    border.width: 1

                    QGCLabel {
                        id: langLabel
                        anchors.centerIn: parent
                        text:  root.englishMode ? "EN" : "中"
                        color: root.englishMode ? root.theme.onActive : root.theme.cyan
                        font.pixelSize: panel.smlFont
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.englishMode = !root.englishMode
                    }
                }
            }

            // 右上角页签
            Row {
                anchors.right: toggles.left
                anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 1.2
                anchors.verticalCenter: parent.verticalCenter
                spacing: ScreenTools.defaultFontPixelWidth * 0.8

                Repeater {
                    model: [ root.t("仪表", "PANEL"), root.t("导航", "MAP"), root.t("专业模式", "PRO") ]
                    delegate: Rectangle {
                        width:  tabLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 2.2
                        height: tabLabel.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.9
                        radius: 3
                        color:        index === 0 ? root.theme.btnBg : "transparent"
                        border.color: index === 0 ? root.theme.cyan : root.theme.btnBd
                        border.width: 1

                        QGCLabel {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: index === 0 ? root.theme.cyan : root.theme.label
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
                color: root.theme.divider
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
                    ctx.strokeStyle = root.theme.radar
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
                color: root.theme.radarDot
                border.color: root.theme.cyanDim
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
                color: root.theme.cyan
                font.bold: true
                font.pixelSize: panel.bigFont
            }
            QGCLabel {
                anchors.left: gsValue.right
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.6
                anchors.baseline: gsValue.bottom
                text: "km/h"
                color: root.theme.value
                font.pixelSize: panel.midFont
                font.italic: true
            }
            QGCLabel {
                anchors.left: gsValue.left
                anchors.top: gsValue.bottom
                anchors.topMargin: -panel.smlFont * 0.2
                text: root.t("地速", "Ground") + "\n" + root.t("地面速度", "speed")
                color: root.theme.label
                font.pixelSize: panel.smlFont
            }
            QGCLabel {
                anchors.left: gsValue.right
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 4.2
                anchors.top: gsValue.top
                anchors.topMargin: panel.smlFont * 1.0
                text: "GS " + root.fmt(root.gsKmh, 0) + " km/h"
                color: root.theme.label
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
                    color: root.theme.barTrack
                    border.color: root.theme.divider
                    border.width: 1

                    Rectangle {
                        width: parent.width * Math.min(root.gsKmh / 65, 1)
                        height: parent.height
                        color: root.theme.cyan
                        opacity: 0.55
                    }
                }
                // 65 红线
                Rectangle {
                    x: parent.width * 0.94
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: parent.height * 0.8
                    color: root.theme.red
                }
                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    QGCLabel { text: "0";  color: root.theme.label; font.pixelSize: panel.smlFont * 0.85 }
                    Item { width: parent.width * 0.55 - 30; height: 1 }
                    QGCLabel { text: "40"; color: root.theme.label; font.pixelSize: panel.smlFont * 0.85 }
                    Item { width: parent.width * 0.30; height: 1 }
                    QGCLabel { text: "65"; color: root.theme.red;   font.pixelSize: panel.smlFont * 0.85 }
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
                    text: root.t("升降速度", "Climb") + "\n" + root.t("油门/俯仰", "rate")
                    color: root.theme.label
                    font.pixelSize: panel.smlFont
                }
                QGCLabel {
                    id: climbValue
                    anchors.left: climbLabel.right
                    anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                    anchors.bottom: climbLabel.bottom
                    text: root.fmt(root.climbMs, 1)
                    color: root.theme.cyan
                    font.bold: true
                    font.pixelSize: panel.bigFont * 0.62
                }
                QGCLabel {
                    anchors.left: climbValue.right
                    anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.4
                    anchors.baseline: climbValue.baseline
                    text: "m/s"
                    color: root.theme.value
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
                        ctx.strokeStyle = long ? root.theme.tickLong : root.theme.tickShort
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
                        ctx.fillStyle = (d === 0 || d === 90 || d === 180 || d === 270) ? root.theme.tickMain : root.theme.tickLong
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
                    ctx.fillStyle = root.theme.heading
                    ctx.beginPath()
                    ctx.moveTo(cx, cy - ringR + r * 0.02)
                    ctx.lineTo(cx - r * 0.035, cy - ringR + r * 0.075)
                    ctx.lineTo(cx + r * 0.035, cy - ringR + r * 0.075)
                    ctx.closePath()
                    ctx.fill()

                    // ---- 内圆描边 ----
                    ctx.beginPath()
                    ctx.arc(cx, cy, pr, 0, Math.PI * 2)
                    ctx.strokeStyle = root.theme.innerRing
                    ctx.lineWidth = Math.max(2, r * 0.008)
                    ctx.stroke()

                    // 外圈细描边
                    ctx.beginPath()
                    ctx.arc(cx, cy, ringR, 0, Math.PI * 2)
                    ctx.strokeStyle = root.theme.ringStroke
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
                color: root.theme.value
                font.pixelSize: panel.midFont * 1.1
                font.bold: true
            }
            // 滚转读数
            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -ScreenTools.defaultFontPixelHeight * 1.9
                text: root.t("横滚", "Roll") + " " + root.fmt(root.rollDeg, 1) + "°   " + root.t("俯仰", "Pitch") + " " + root.fmt(root.pitchDeg, 1) + "°"
                color: root.theme.label
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
                    color: root.theme.cyan
                    font.bold: true
                    font.pixelSize: panel.bigFont
                    anchors.baseline: altUnit.baseline
                }
                QGCLabel {
                    id: altUnit
                    text: "m"
                    color: root.theme.value
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
                    text: root.t("相对起飞点高度", "Relative alt")
                    color: root.theme.label
                    font.pixelSize: panel.smlFont * 0.95
                }
                QGCLabel {
                    anchors.right: parent.right
                    text: root.t("离地高度", "Height") + " AGL " + root.fmt(root.altRel, 1) + " m"
                    color: root.theme.label
                    font.pixelSize: panel.smlFont * 0.95
                }
            }

            Column {
                width: parent.width
                spacing: panel.smlFont * 0.35

                Repeater {
                    model: [
                        { k: root.t("至储备线", "To reserve"), v: "-- min" },
                        { k: root.t("电压", "Volt"),     v: root.fmt(root.battVolt, 1) + " V" },
                        { k: root.t("电流", "Curr"),     v: root.fmt(root.battAmp, 1) + " A" },
                        { k: root.t("电池温度", "Batt temp"), v: isNaN(root.battTemp) ? "-- °C" : root.fmt(root.battTemp, 1) + " °C" }
                    ]
                    delegate: Row {
                        anchors.right: parent.right
                        spacing: ScreenTools.defaultFontPixelWidth * 0.6
                        QGCLabel {
                            text: modelData.k
                            color: root.theme.label
                            font.pixelSize: panel.smlFont * 0.95
                        }
                        QGCLabel {
                            text: modelData.v
                            color: root.theme.value
                            font.pixelSize: panel.smlFont * 0.95
                            font.bold: true
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: ScreenTools.defaultFontPixelWidth * 0.4
                    QGCLabel {
                        text: root.t("电量", "Batt")
                        color: root.theme.label
                        font.pixelSize: panel.smlFont * 0.95
                    }
                    QGCLabel {
                        text: root.battPct < 0 ? "-- %" : Math.round(root.battPct) + " %"
                        color: root.battPct >= 0 && root.battPct < 25 ? root.theme.red : root.theme.cyan
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
                                color: (root.battPct / 12.5 > index) ? (root.battPct < 25 ? root.theme.red : root.theme.cellOn) : root.theme.cellOff
                            }
                        }
                    }
                }

                QGCLabel {
                    anchors.right: parent.right
                    text: root.t("卫星", "SAT") + " " + root.sats + "   " + root.t("通信", "LINK") + " " + root.linkText
                    color: root.theme.label
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
                color: root.theme.divider
            }

            // 飞控解锁状态徽标
            Rectangle {
                id: unlockBadge
                anchors.left: parent.left
                anchors.leftMargin: panel.sidePad
                anchors.verticalCenter: parent.verticalCenter
                width:  Math.min(unlockLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 2,
                                 parent.width * 0.28)
                height: unlockLabel.implicitHeight + ScreenTools.defaultFontPixelHeight * 1.1
                color: "transparent"
                border.color: root.theme.divider
                border.width: 1

                QGCLabel {
                    id: unlockLabel
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.t("飞控", "FC") + (root.hasVehicle && root.vehicle.armed ? root.t("解锁", " ARMED") : root.t("锁定", " DISARMED"))
                    color: root.hasVehicle && root.vehicle.armed ? root.theme.red : root.theme.label
                    font.pixelSize: panel.smlFont
                }
            }

            // 功能按钮
            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin:  unlockBadge.x + unlockBadge.width + ScreenTools.defaultFontPixelWidth * 2
                anchors.rightMargin: panel.sidePad
                anchors.verticalCenter: parent.verticalCenter
                spacing: ScreenTools.defaultFontPixelWidth * 0.5

                Repeater {
                    model: [
                        { t: root.t("姿态", "Stab"),       on: true  },
                        { t: root.t("定点", "Loiter"),       on: false },
                        { t: root.t("定高", "AltHold"),       on: false },
                        { t: root.t("起飞", "Takeoff"),       on: false },
                        { t: root.t("降落", "Land"),       on: false },
                        { t: root.t("返航", "RTL"),       on: false },
                        { t: root.t("保持待定义", "HOLD"), on: false },
                        { t: root.t("触屏接管", "Touch"),   on: false },
                        { t: root.t("更多", "More"),       on: false }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: btnText.implicitHeight + ScreenTools.defaultFontPixelHeight * 1.5
                        radius: 3
                        color:        modelData.on ? root.theme.active : root.theme.btnBg
                        border.color: modelData.on ? root.theme.active : root.theme.btnBd
                        border.width: 1

                        QGCLabel {
                            id: btnText
                            anchors.centerIn: parent
                            width: parent.width * 0.92
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text:  modelData.t
                            color: modelData.on ? root.theme.onActive : root.theme.value
                            font.pixelSize: panel.smlFont
                            font.bold: modelData.on
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (index === 8)            // 更多
                                    root.expanded = false
                            }
                        }
                    }
                }
            }
        }
    }
}
