import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: plasmoidRoot
    width: 240
    height: 40
    Layout.preferredWidth: width
    Layout.preferredHeight: height

    compactRepresentation: Item {
        width: 36; height: 36
        Rectangle {
            anchors.fill: parent; color: "transparent"
            Text {
                anchors.centerIn: parent; text: "Σ"; font.pointSize: 14; font.bold: true
                color: rightInsightPanel.visible || leftQuotePanel.visible ? "#89b4fa" : "#6c7086"
            }
            MouseArea { anchors.fill: parent; onClicked: plasmoidRoot.expanded = !plasmoidRoot.expanded }
        }
    }

    fullRepresentation: Rectangle {
        implicitWidth: 300
        implicitHeight: controlColumn.implicitHeight + 24
        color: Qt.rgba(0.09, 0.09, 0.15, 0.88)
        border.color: "#cba6f7"
        border.width: 1
        radius: 6

        ColumnLayout {
            id: controlColumn
            anchors.fill: parent; anchors.margins: 12; spacing: 10

            Label {
                text: "RAPHAEL // FLOW MATRIX"
                font.family: "Monospace"
                font.pointSize: 7.5
                font.bold: true
                color: "#cba6f7"
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#313244" }

            // Custom Toggles instead of basic Switches
            Repeater {
                model: [
                    { name: "LEFT QUOTE STREAM", getter: () => leftQuotePanel.visible, setter: (val) => leftQuotePanel.visible = val },
                    { name: "RIGHT INSIGHT CARD", getter: () => rightInsightPanel.visible, setter: (val) => rightInsightPanel.visible = val },
                    { name: "CHAT CONSOLE", getter: () => rightInsightPanel.chatConsoleVisible, setter: (val) => rightInsightPanel.chatConsoleVisible = val }
                ]

                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    color: Qt.rgba(0.07, 0.07, 0.11, 0.6)
                    radius: 3
                    border.color: "#313244"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        Label {
                            text: modelData.name + " //"
                            font.family: "Monospace"
                            font.pointSize: 7
                            font.bold: true
                            color: "#bac2de"
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 36
                            height: 16
                            color: modelData.getter() ? "#a6e3a1" : "#313244"
                            radius: 8
                            border.color: "#45475a"

                            Rectangle {
                                width: 12; height: 12; radius: 6; color: "#11111b"
                                x: modelData.getter() ? 22 : 2
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on x { NumberAnimation { duration: 120 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.setter(!modelData.getter())
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#313244" }

            // --- CHRONOS TIMING CONFIGURATION MATRIX ---
            ColumnLayout {
                id: chronosRatioProtocolsLayout
                Layout.fillWidth: true; spacing: 6
                Label {
                    text: "CHRONOS RATIO PROTOCOLS"
                    font.family: "Monospace"
                    font.bold: true
                    font.pointSize: 7.5
                    color: "#ca9ee6"
                }

                function syncDelayMatrix() {
                    var doc = new XMLHttpRequest();
                    doc.open("POST", "http://127.0.0.1:5757/update_delays", true);
                    doc.setRequestHeader("Content-Type", "application/json");
                    doc.send(JSON.stringify({
                        "quotes": quotesSlider.value, "sarcasm": sarcasmSlider.value,
                        "anger": angerSlider.value, "replies": repliesSlider.value, "proactive_comments": proactiveSlider.value
                    }));
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Quotes Slider Row
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "QUOTES:"; font.family: "Monospace"; color: "#cdd6f4"; font.pointSize: 7.5; Layout.preferredWidth: 80 }
                        Slider {
                            id: quotesSlider
                            Layout.fillWidth: true; from: 0.0; to: 5.0; stepSize: 0.5; value: 0.0
                            onMoved: chronosRatioProtocolsLayout.syncDelayMatrix()
                            background: Rectangle { x: quotesSlider.leftPadding; y: quotesSlider.topPadding + quotesSlider.availableHeight / 2 - height / 2; width: quotesSlider.availableWidth; height: 4; radius: 2; color: "#313244"; Rectangle { width: quotesSlider.visualPosition * parent.width; height: parent.height; color: "#cba6f7"; radius: 2 } }
                            handle: Rectangle { x: quotesSlider.leftPadding + quotesSlider.visualPosition * (quotesSlider.availableWidth - width); y: quotesSlider.topPadding + quotesSlider.availableHeight / 2 - height / 2; width: 10; height: 10; radius: 5; color: "#cdd6f4"; border.color: "#cba6f7"; border.width: 1 }
                        }
                        Label { text: quotesSlider.value.toFixed(1) + "s"; font.family: "Monospace"; color: "#a6adc8"; font.pointSize: 7.5; Layout.preferredWidth: 26 }
                    }

                    // Sarcasm Slider Row
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "SARCASM:"; font.family: "Monospace"; color: "#cdd6f4"; font.pointSize: 7.5; Layout.preferredWidth: 80 }
                        Slider {
                            id: sarcasmSlider
                            Layout.fillWidth: true; from: 0.0; to: 5.0; stepSize: 0.5; value: 1.5
                            onMoved: chronosRatioProtocolsLayout.syncDelayMatrix()
                            background: Rectangle { x: sarcasmSlider.leftPadding; y: sarcasmSlider.topPadding + sarcasmSlider.availableHeight / 2 - height / 2; width: sarcasmSlider.availableWidth; height: 4; radius: 2; color: "#313244"; Rectangle { width: sarcasmSlider.visualPosition * parent.width; height: parent.height; color: "#cba6f7"; radius: 2 } }
                            handle: Rectangle { x: sarcasmSlider.leftPadding + sarcasmSlider.visualPosition * (sarcasmSlider.availableWidth - width); y: sarcasmSlider.topPadding + sarcasmSlider.availableHeight / 2 - height / 2; width: 10; height: 10; radius: 5; color: "#cdd6f4"; border.color: "#cba6f7"; border.width: 1 }
                        }
                        Label { text: sarcasmSlider.value.toFixed(1) + "s"; font.family: "Monospace"; color: "#a6adc8"; font.pointSize: 7.5; Layout.preferredWidth: 26 }
                    }

                    // Anger Slider Row
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "ANGER:"; font.family: "Monospace"; color: "#cdd6f4"; font.pointSize: 7.5; Layout.preferredWidth: 80 }
                        Slider {
                            id: angerSlider
                            Layout.fillWidth: true; from: 0.0; to: 5.0; stepSize: 0.5; value: 0.5
                            onMoved: chronosRatioProtocolsLayout.syncDelayMatrix()
                            background: Rectangle { x: angerSlider.leftPadding; y: angerSlider.topPadding + angerSlider.availableHeight / 2 - height / 2; width: angerSlider.availableWidth; height: 4; radius: 2; color: "#313244"; Rectangle { width: angerSlider.visualPosition * parent.width; height: parent.height; color: "#cba6f7"; radius: 2 } }
                            handle: Rectangle { x: angerSlider.leftPadding + angerSlider.visualPosition * (angerSlider.availableWidth - width); y: angerSlider.topPadding + angerSlider.availableHeight / 2 - height / 2; width: 10; height: 10; radius: 5; color: "#cdd6f4"; border.color: "#cba6f7"; border.width: 1 }
                        }
                        Label { text: angerSlider.value.toFixed(1) + "s"; font.family: "Monospace"; color: "#a6adc8"; font.pointSize: 7.5; Layout.preferredWidth: 26 }
                    }

                    // Replies Slider Row
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "REPLIES:"; font.family: "Monospace"; color: "#cdd6f4"; font.pointSize: 7.5; Layout.preferredWidth: 80 }
                        Slider {
                            id: repliesSlider
                            Layout.fillWidth: true; from: 0.0; to: 5.0; stepSize: 0.5; value: 1.0
                            onMoved: chronosRatioProtocolsLayout.syncDelayMatrix()
                            background: Rectangle { x: repliesSlider.leftPadding; y: repliesSlider.topPadding + repliesSlider.availableHeight / 2 - height / 2; width: repliesSlider.availableWidth; height: 4; radius: 2; color: "#313244"; Rectangle { width: repliesSlider.visualPosition * parent.width; height: parent.height; color: "#cba6f7"; radius: 2 } }
                            handle: Rectangle { x: repliesSlider.leftPadding + repliesSlider.visualPosition * (repliesSlider.availableWidth - width); y: repliesSlider.topPadding + repliesSlider.availableHeight / 2 - height / 2; width: 10; height: 10; radius: 5; color: "#cdd6f4"; border.color: "#cba6f7"; border.width: 1 }
                        }
                        Label { text: repliesSlider.value.toFixed(1) + "s"; font.family: "Monospace"; color: "#a6adc8"; font.pointSize: 7.5; Layout.preferredWidth: 26 }
                    }

                    // Proactive Slider Row
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "PROACTIVE:"; font.family: "Monospace"; color: "#cdd6f4"; font.pointSize: 7.5; Layout.preferredWidth: 80 }
                        Slider {
                            id: proactiveSlider
                            Layout.fillWidth: true; from: 0.0; to: 5.0; stepSize: 0.5; value: 2.0
                            onMoved: chronosRatioProtocolsLayout.syncDelayMatrix()
                            background: Rectangle { x: proactiveSlider.leftPadding; y: proactiveSlider.topPadding + proactiveSlider.availableHeight / 2 - height / 2; width: proactiveSlider.availableWidth; height: 4; radius: 2; color: "#313244"; Rectangle { width: proactiveSlider.visualPosition * parent.width; height: parent.height; color: "#cba6f7"; radius: 2 } }
                            handle: Rectangle { x: proactiveSlider.leftPadding + proactiveSlider.visualPosition * (proactiveSlider.availableWidth - width); y: proactiveSlider.topPadding + proactiveSlider.availableHeight / 2 - height / 2; width: 10; height: 10; radius: 5; color: "#cdd6f4"; border.color: "#cba6f7"; border.width: 1 }
                        }
                        Label { text: proactiveSlider.value.toFixed(1) + "s"; font.family: "Monospace"; color: "#a6adc8"; font.pointSize: 7.5; Layout.preferredWidth: 26 }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#313244" }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    color: "#313244"
                    radius: 3

                    Text {
                        anchors.centerIn: parent
                        text: "FORCE SYNC"
                        font.family: "Monospace"
                        font.bold: true
                        font.pointSize: 7.5
                        color: "#cdd6f4"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: syncNetworkPayload()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    color: "#313244"
                    radius: 3

                    Text {
                        anchors.centerIn: parent
                        text: "GET SUMMARY"
                        font.family: "Monospace"
                        font.bold: true
                        font.pointSize: 7.5
                        color: "#cdd6f4"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var xhr = new XMLHttpRequest();
                            xhr.open("GET", "http://127.0.0.1:5757/get_summary");
                            xhr.onreadystatechange = function() {
                                if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                                    var res = JSON.parse(xhr.responseText);
                                    chatHistoryModel.append({ isUser: false, messageText: "Summary: " + res.summary, isAngry: false });
                                }
                            }
                            xhr.send();
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    color: "#313244"
                    radius: 3

                    Text {
                        anchors.centerIn: parent
                        text: "DASHBOARD"
                        font.family: "Monospace"
                        font.bold: true
                        font.pointSize: 7.5
                        color: "#cdd6f4"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("http://127.0.0.1:5757/dashboard")
                    }
                }
            }
        }
    }


    // Configuration properties bound to main.xml
    property int displayDuration: plasmoid.configuration.displayDuration
    property int caringLevel: plasmoid.configuration.caringLevel
    property bool aiWindowTracking: plasmoid.configuration.aiWindowTracking
    property bool proactiveInterventions: plasmoid.configuration.proactiveInterventions
    property int escalationTimeout: plasmoid.configuration.escalationTimeout
    property bool activeMonitoring: plasmoid.configuration.activeMonitoring

    QtObject {
        id: sharedState
        property string currentBadge: "evaluating space..."
        property string currentQuote: "Consciousness initializing. Maintain execution discipline."
        property string currentAuthor: "Raphael"

        property string insightLabel: "workspace observation"
        property string insightSource: "live feed"
        property string insightBody: "Awaiting window context analytics streaming parameters..."
        property string insightTagText: "focus"
        property color insightTagColor: "#dcbc64"
        property color insightTagBorder: Qt.rgba(0.86, 0.73, 0.39, 0.25)
        
        property string sensorScreen: "System"
        property string sensorScreenClean: "Workspace"
        property string sensorMusic: "Muted"
        property string sensorTime: "0 min"

        property string liveFocusCounter: "0m 0s"
        property string liveDistractCounter: "0m 0s"
        property int rawDistractSeconds: 0
        property string currentMetricsStatus: "Neutral"
        
        property double focusEfficiencyRatio: 1.0
        property string focusEfficiencyText: "100% FOCUS"
        property color focusEfficiencyColor: "#a6e3a1"

        property string sessionSummaryText: "Resuming cognitive timeline parameters..."
        property string sessionGoalsText: "• Calibrating focus vectors\n• Loading milestones"
    }

    Timer {
        id: telemetryNetworkTimer
        interval: 1000 
        running: true
        repeat: true
        onTriggered: syncNetworkPayload()
    }

    function triggerWindowFlash() {
        flashAnim.start();
    }

    function formatTimeMetrics(totalSeconds) {
        var m = Math.floor(totalSeconds / 60);
        var s = totalSeconds % 60;
        return m + "m " + s + "s";
    }

    function syncNetworkPayload() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "http://127.0.0.1:5757/telemetry_v3?caring=" + caringLevel + "&ai_track=" + aiWindowTracking + "&proactive=" + proactiveInterventions + "&timeout=" + escalationTimeout + "&active_monitoring=" + activeMonitoring);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var res = JSON.parse(xhr.responseText);
                sharedState.currentBadge = res.quote.badge;
                sharedState.currentQuote = res.quote.text;
                sharedState.currentAuthor = res.quote.author;
                
                sharedState.insightLabel = res.insight.label;
                sharedState.insightSource = res.insight.src;
                sharedState.insightBody = res.insight.text;
                sharedState.insightTagText = res.insight.tag;
                
                if (sharedState.insightTagText === "screen") { sharedState.insightTagColor = "#64a0ff"; sharedState.insightTagBorder = Qt.rgba(0.39, 0.63, 1.0, 0.25); }
                else if (sharedState.insightTagText === "reading") { sharedState.insightTagColor = "#74c7ec"; sharedState.insightTagBorder = Qt.rgba(0.45, 0.78, 0.93, 0.25); } 
                else if (sharedState.insightTagText === "music") { sharedState.insightTagColor = "#64dc96"; sharedState.insightTagBorder = Qt.rgba(0.39, 0.86, 0.58, 0.25); }
                else if (sharedState.insightTagText === "pattern") { sharedState.insightTagColor = "#b482ff"; sharedState.insightTagBorder = Qt.rgba(0.7, 0.5, 1.0, 0.25); }
                else if (sharedState.insightTagText === "focus") { sharedState.insightTagColor = "#dcbc64"; sharedState.insightTagBorder = Qt.rgba(0.86, 0.73, 0.39, 0.25); }
                else { sharedState.insightTagColor = "#ff7864"; sharedState.insightTagBorder = Qt.rgba(1.0, 0.47, 0.39, 0.25); }
                
                sharedState.sensorScreen = res.sensors.screen;
                sharedState.sensorScreenClean = res.sensors.screen_clean || res.sensors.screen;
                sharedState.sensorMusic = res.sensors.music;
                sharedState.sensorTime = res.sensors.focus_time;

                if(res.metrics) {
                    sharedState.liveFocusCounter = formatTimeMetrics(res.metrics.focus_seconds);
                    sharedState.liveDistractCounter = formatTimeMetrics(res.metrics.distract_seconds);
                    sharedState.currentMetricsStatus = res.metrics.current_status;
                    sharedState.rawDistractSeconds = res.metrics.distract_seconds;

                    var f_secs = res.metrics.focus_seconds;
                    var d_secs = res.metrics.distract_seconds;
                    var total = f_secs + d_secs;
                    if (total > 0) {
                        var ratio = f_secs / total;
                        sharedState.focusEfficiencyRatio = ratio;
                        sharedState.focusEfficiencyText = Math.round(ratio * 100) + "% FOCUS";
                        if (ratio >= 0.8) {
                            sharedState.focusEfficiencyColor = "#a6e3a1"; // Catppuccin Green
                        } else if (ratio >= 0.5) {
                            sharedState.focusEfficiencyColor = "#f9e2af"; // Catppuccin Yellow
                        } else {
                            sharedState.focusEfficiencyColor = "#f38ba8"; // Catppuccin Red
                        }
                    } else {
                        sharedState.focusEfficiencyRatio = 1.0;
                        sharedState.focusEfficiencyText = "100% FOCUS";
                        sharedState.focusEfficiencyColor = "#a6e3a1";
                    }
                }

                if (res.pending_ui_messages && res.pending_ui_messages.length > 0) {
                    for (var i = 0; i < res.pending_ui_messages.length; i++) {
                        var packet = res.pending_ui_messages[i];
                        chatHistoryModel.append({ 
                            isUser: false, 
                            messageText: packet.text, 
                            isAngry: packet.is_angry || false 
                        });
                        if (packet.is_angry) {
                            triggerWindowFlash();
                        }
                    }
                    var flushXhr = new XMLHttpRequest();
                    flushXhr.open("POST", "http://127.0.0.1:5757/flush_proactive_msg");
                    flushXhr.send();
                }

                if (res.session_summary) {
                    sharedState.sessionSummaryText = res.session_summary;
                }
                if (res.session_goals && res.session_goals.length > 0) {
                    var goalsString = "";
                    for (var g = 0; g < res.session_goals.length; g++) {
                        goalsString += "• " + res.session_goals[g] + (g < res.session_goals.length - 1 ? "\n" : "");
                    }
                    sharedState.sessionGoalsText = goalsString;
                }

                if (res.delays) {
                    if (res.delays.quotes !== undefined && !quotesSlider.pressed) quotesSlider.value = res.delays.quotes;
                    if (res.delays.sarcasm !== undefined && !sarcasmSlider.pressed) sarcasmSlider.value = res.delays.sarcasm;
                    if (res.delays.anger !== undefined && !angerSlider.pressed) angerSlider.value = res.delays.anger;
                    if (res.delays.replies !== undefined && !repliesSlider.pressed) repliesSlider.value = res.delays.replies;
                    if (res.delays.proactive_comments !== undefined && !proactiveSlider.pressed) proactiveSlider.value = res.delays.proactive_comments;
                }
            }
        }
        xhr.send();
    }

    ListModel {
        id: chatHistoryModel
    }

    function dispatchBubblePayload(messageString) {
        var txt = messageString.trim();
        if (!txt) return;
        
        chatHistoryModel.append({ isUser: true, messageText: txt, isAngry: false });
        
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "http://127.0.0.1:5757/chat_v4");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var res = JSON.parse(xhr.responseText);
                chatHistoryModel.append({ isUser: false, messageText: res.response, isAngry: res.is_angry || false });
                if (res.is_angry) {
                    triggerWindowFlash();
                }
            }
        }
        xhr.send(JSON.stringify({ "message": txt }));
    }

    // =========================================================
    // WINDOW PANEL 1: DRAGGABLE QUOTE VIEWPORT LAYER (LEFT)
    // =========================================================
    Window {
        id: leftQuotePanel
        visible: true
        color: "transparent"
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.X11BypassWindowManagerHint
        
        x: 40
        y: 60
        width: 380
        height: quoteCol.implicitHeight + 36

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.09, 0.09, 0.15, 0.88)
            radius: 6
            border.color: "#cba6f7"
            border.width: 1

            MouseArea {
                anchors.fill: parent
                property point clickPos: "0,0"
                onPressed: (mouse) => { clickPos = Qt.point(mouse.x, mouse.y) }
                onPositionChanged: (mouse) => {
                    var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                    leftQuotePanel.x += delta.x
                    leftQuotePanel.y += delta.y
                }
            }
        }

        ColumnLayout {
            id: quoteCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    width: 6; height: 6; radius: 3; color: "#cba6f7"
                }
                Text {
                    text: "RAPHAEL // " + (sharedState.currentBadge ? sharedState.currentBadge.toUpperCase() : "QUOTE STREAM")
                    font.family: "Monospace"
                    font.pointSize: 7.5
                    font.bold: true
                    color: "#cba6f7"
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 20; height: 20; color: "transparent"
                    Label {
                        anchors.centerIn: parent; text: "×"; font.family: "Noto Sans"; font.pointSize: 11; color: "#9399b2"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: leftQuotePanel.visible = false
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "\"" + sharedState.currentQuote + "\""
                font.family: "Noto Sans"
                font.pointSize: 10.5
                color: "#cdd6f4"
                wrapMode: Text.WordWrap
                lineHeight: 1.3
            }

            Text {
                text: "— " + sharedState.currentAuthor.toUpperCase()
                font.family: "Monospace"
                font.pointSize: 8
                font.bold: true
                color: "#6c7086"
            }
        }
    }

    // =========================================================
    // WINDOW PANEL 2: RIGHT PANEL (FIXED CHAT & EXPANDABLE OBSERVATION)
    // =========================================================
    Window {
        id: rightInsightPanel
        visible: true
        color: "transparent"
        flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowActsLikeContextMenu
        
        property bool chatConsoleVisible: true
        property bool isTextExpanded: false 

        x: Screen.width - width - 40
        y: 60
        width: 360
        
        height: outerMainBackgroundColumn.implicitHeight + secureDragBar.height + 28

        Rectangle {
            id: innerMainBackground
            anchors.fill: parent
            color: Qt.rgba(0.09, 0.09, 0.15, 0.88)
            radius: 6
            border.color: innerMainBackground.isFlashed ? "#ff5555" : (sharedState.currentMetricsStatus === "Taking a break" ? "#f38ba8" : "#89b4fa")
            border.width: innerMainBackground.isFlashed ? 3 : 1
            property bool isFlashed: false

            Behavior on border.color { ColorAnimation { duration: 100 } }
            Behavior on border.width { NumberAnimation { duration: 100 } }

            SequentialAnimation {
                id: flashAnim
                PropertyAction { target: innerMainBackground; property: "isFlashed"; value: true }
                PauseAnimation { duration: 150 }
                PropertyAction { target: innerMainBackground; property: "isFlashed"; value: false }
                PauseAnimation { duration: 150 }
                PropertyAction { target: innerMainBackground; property: "isFlashed"; value: true }
                PauseAnimation { duration: 150 }
                PropertyAction { target: innerMainBackground; property: "isFlashed"; value: false }
                PauseAnimation { duration: 150 }
                PropertyAction { target: innerMainBackground; property: "isFlashed"; value: true }
                PauseAnimation { duration: 150 }
                PropertyAction { target: innerMainBackground; property: "isFlashed"; value: false }
            }

            Rectangle {
                id: secureDragBar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 40
                color: "#11111b"
                radius: 6

                // Top border line
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#313244"
                }

                // Bottom separator line
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#181825"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    // LED focus/distraction status indicator
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: sharedState.currentMetricsStatus === "Taking a break" ? "#f38ba8" : 
                               (sharedState.currentMetricsStatus === "Neutral" ? "#f9e2af" : "#a6e3a1")
                        
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutQuad }
                        }
                    }

                    Label {
                        text: "RAPHAEL // COGNITIVE HUD v4.8"
                        font.family: "Monospace"
                        font.pointSize: 7.5
                        font.bold: true
                        color: "#cdd6f4"
                        Layout.fillWidth: true

                        MouseArea {
                            anchors.fill: parent
                            property point clickPos: "0,0"
                            onPressed: (mouse) => { clickPos = Qt.point(mouse.x, mouse.y) }
                            onPositionChanged: (mouse) => {
                                var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                                rightInsightPanel.x += delta.x
                                rightInsightPanel.y += delta.y
                            }
                        }
                    }

                    // Cyberpunk mode toggle button
                    Rectangle {
                        width: 85
                        height: 22
                        color: rightInsightPanel.chatConsoleVisible ? "#313244" : "#1e1e2e"
                        radius: 3
                        border.color: "#45475a"
                        border.width: 1

                        Label {
                            anchors.centerIn: parent
                            text: rightInsightPanel.chatConsoleVisible ? "[ CHAT ACTIVE ]" : "[ HUD MODE ]"
                            font.family: "Monospace"
                            font.pointSize: 6.5
                            font.bold: true
                            color: rightInsightPanel.chatConsoleVisible ? "#f9e2af" : "#bac2de"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rightInsightPanel.chatConsoleVisible = !rightInsightPanel.chatConsoleVisible
                            }
                        }
                    }

                    // Close Button
                    Rectangle {
                        width: 22
                        height: 22
                        color: "transparent"

                        Label {
                            anchors.centerIn: parent
                            text: "×"
                            font.family: "Noto Sans"
                            font.pointSize: 12
                            color: "#9399b2"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rightInsightPanel.visible = false
                        }
                    }
                }
            }

            ColumnLayout {
                id: outerMainBackgroundColumn
                anchors.top: secureDragBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                anchors.topMargin: 8
                spacing: 12

                // --- WORKSPACE OBSERVATION HUD PANEL ---
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: observationCol.implicitHeight + 16
                    color: Qt.rgba(0.07, 0.07, 0.11, 0.4)
                    radius: 4
                    border.color: "#313244"
                    border.width: 1

                    ColumnLayout {
                        id: observationCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            // A pulsing scanner line or box
                            Rectangle {
                                width: 8; height: 8; color: "#89b4fa"
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.2; to: 1.0; duration: 600 }
                                    NumberAnimation { from: 1.0; to: 0.2; duration: 600 }
                                }
                            }
                            Label {
                                text: sharedState.insightLabel.toUpperCase() + " // " + sharedState.insightSource.toUpperCase()
                                font.family: "Monospace"
                                font.pointSize: 7.5
                                font.bold: true
                                color: "#89b4fa"
                            }
                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Label {
                                text: "TARGET //"
                                font.family: "Monospace"
                                font.pointSize: 7
                                font.bold: true
                                color: "#f9e2af"
                            }
                            Label {
                                text: sharedState.sensorScreenClean
                                font.family: "Noto Sans"
                                font.pointSize: 8.5
                                font.bold: true
                                color: "#cdd6f4"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            id: insightTextItem
                            Layout.fillWidth: true
                            text: sharedState.insightBody
                            font.family: "Noto Sans"
                            font.pointSize: 9.5
                            color: "#cdd6f4"
                            wrapMode: Text.WordWrap
                            lineHeight: 1.2
                            maximumLineCount: rightInsightPanel.isTextExpanded ? 20 : 2
                            elide: Text.ElideRight
                        }

                        Text {
                            text: rightInsightPanel.isTextExpanded ? "[ COLLAPSE TELEMETRY ▲ ]" : "[ EXPAND TELEMETRY ▼ ]"
                            font.family: "Monospace"
                            font.pointSize: 7.5
                            font.bold: true
                            color: "#89b4fa"
                            Layout.alignment: Qt.AlignLeft
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rightInsightPanel.isTextExpanded = !rightInsightPanel.isTextExpanded
                            }
                        }
                    }
                }

                // --- INSTRUMENTATION READOUT TAGS ---
                RowLayout {
                    id: insightTagBlock
                    Layout.fillWidth: true
                    spacing: 10

                    // System focus state tag
                    Rectangle {
                        width: tagTxt.implicitWidth + 16
                        height: 22
                        color: Qt.rgba(0.07, 0.07, 0.11, 0.6)
                        radius: 4
                        border.color: sharedState.insightTagBorder
                        border.width: 1
                        
                        Label {
                            id: tagTxt
                            anchors.centerIn: parent
                            text: "MODE: " + sharedState.insightTagText
                            font.family: "Monospace"
                            font.pointSize: 7.5
                            font.bold: true
                            color: sharedState.insightTagColor
                            font.capitalization: Font.AllUppercase
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 6

                        // Focus timer box
                        Rectangle {
                            width: 85; height: 22; color: Qt.rgba(0.07, 0.07, 0.11, 0.6); radius: 4; border.color: "#a6e3a1"; border.width: 1
                            Label {
                                anchors.centerIn: parent
                                text: "FOCUS: " + sharedState.liveFocusCounter
                                font.family: "Monospace"
                                font.pointSize: 7.5; font.bold: true; color: "#a6e3a1"
                            }
                        }

                        // Distraction timer box
                        Rectangle {
                            width: 85; height: 22; color: Qt.rgba(0.07, 0.07, 0.11, 0.6); radius: 4; border.color: "#f38ba8"; border.width: 1
                            Label {
                                anchors.centerIn: parent
                                text: "SLACK: " + sharedState.liveDistractCounter
                                font.family: "Monospace"
                                font.pointSize: 7.5; font.bold: true; color: "#f38ba8"
                            }
                        }
                    }
                }

                // --- COGNITIVE EFFICIENCY PROGRESS METERS ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "COGNITIVE EFFICIENCY"
                            font.family: "Monospace"
                            font.pointSize: 7.5
                            font.bold: true
                            color: "#89b4fa"
                            font.letterSpacing: 1
                        }
                        Item { Layout.fillWidth: true }
                        Label {
                            text: sharedState.focusEfficiencyText
                            font.family: "Monospace"
                            font.pointSize: 7.5
                            font.bold: true
                            color: sharedState.focusEfficiencyColor
                        }
                    }

                    // Progress Bar Container
                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        color: "#181825"
                        radius: 4
                        border.color: "#313244"
                        border.width: 1
                        clip: true

                        // Glowing fill bar
                        Rectangle {
                            id: efficiencyFillBar
                            height: parent.height - 2
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 1
                            width: Math.max(4, (parent.width - 2) * sharedState.focusEfficiencyRatio)
                            radius: 3
                            color: sharedState.focusEfficiencyColor
                            opacity: 0.85

                            Behavior on width {
                                NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }
                }

                // --- COLLAPSIBLE CHAT SECTION WRAPPER ---
                Rectangle {
                    id: chatSectionWrapper
                    Layout.fillWidth: true
                    implicitHeight: rightInsightPanel.chatConsoleVisible ? chatSectionInnerCol.implicitHeight : 0
                    clip: true
                    color: "transparent"

                    Behavior on implicitHeight {
                        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                    }

                    ColumnLayout {
                        id: chatSectionInnerCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8

                        Rectangle {
                            id: conversationFrameRect
                            Layout.fillWidth: true
                            Layout.preferredHeight: 320 
                            color: Qt.rgba(0.07, 0.07, 0.11, 0.5)
                            radius: 4
                            border.color: "#313244"
                            border.width: 1

                            ListView {
                                id: chatListView
                                anchors.fill: parent
                                anchors.margins: 10
                                clip: true
                                spacing: 8
                                model: chatHistoryModel
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

                                onCountChanged: Qt.callLater(() => chatListView.positionViewAtEnd())

                                header: Item {
                                    width: chatListView.width
                                    height: blueprintCol.implicitHeight + 16

                                    ColumnLayout {
                                        id: blueprintCol
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: 4
                                        spacing: 8

                                        // Historical Session Log Cockpit Panel
                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: summaryCol.implicitHeight + 20
                                            color: Qt.rgba(0.07, 0.07, 0.11, 0.5)
                                            radius: 4
                                            border.color: "#313244"
                                            border.width: 1

                                            ColumnLayout {
                                                id: summaryCol
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.margins: 10
                                                spacing: 4

                                                Label {
                                                    text: "LOG // HISTORICAL CONTEXT"
                                                    font.family: "Monospace"
                                                    font.pointSize: 7
                                                    font.bold: true
                                                    color: "#a6e3a1"
                                                }

                                                Text {
                                                    id: summaryText
                                                    Layout.fillWidth: true
                                                    text: sharedState.sessionSummaryText
                                                    font.family: "Noto Sans"
                                                    font.pointSize: 8.5
                                                    color: "#bac2de"
                                                    wrapMode: Text.WordWrap
                                                }
                                            }
                                        }

                                        // Tactical Session Targets Cockpit Panel
                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: targetCol.implicitHeight + 20
                                            color: Qt.rgba(0.07, 0.07, 0.11, 0.5)
                                            radius: 4
                                            border.color: "#b4befe"
                                            border.width: 1

                                            ColumnLayout {
                                                id: targetCol
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.margins: 10
                                                spacing: 4

                                                Label {
                                                    text: "DIR // TACTICAL SESSION TARGETS"
                                                    font.family: "Monospace"
                                                    font.pointSize: 7
                                                    font.bold: true
                                                    color: "#b4befe"
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: sharedState.sessionGoalsText
                                                    font.family: "Noto Sans"
                                                    font.pointSize: 8.5
                                                    color: "#cdd6f4"
                                                    wrapMode: Text.WordWrap
                                                    lineHeight: 1.3
                                                }
                                            }
                                        }
                                        
                                        Item { height: 6 } 
                                    }
                                }

                                delegate: Item {
                                    id: chatBubbleDelegateItem
                                    width: chatListView.width
                                    height: Math.max(messageOuterBubbleRect.height, bubbleLayoutContentColumn.implicitHeight + 20) + 8

                                    Rectangle {
                                        id: messageOuterBubbleRect
                                        width: chatListView.width * 0.75
                                        height: bubbleLayoutContentColumn.implicitHeight + 20
                                        
                                        anchors.right: model.isUser ? parent.right : undefined
                                        anchors.left:  model.isUser ? undefined   : parent.left
                                        anchors.rightMargin: model.isUser ? 6 : 0
                                        anchors.leftMargin:  model.isUser ? 0 : 6
                                        
                                        color: Qt.rgba(0.09, 0.09, 0.15, 0.8)
                                        radius: 3
                                        border.color: model.isUser ? "#89b4fa" : (model.isAngry ? "#ff5555" : "#cba6f7")
                                        border.width: 1
                                        scale: 0.2
                                        NumberAnimation on scale {
                                            from: 0.2
                                            to: model.isAngry ? 1.05 : 1.0
                                            duration: 250
                                            easing.type: Easing.OutBack
                                        }
                                        transform: Translate { id: translateTransform }

                                        Component.onCompleted: {
                                            if (model.isAngry) {
                                                shakeAnimation.start()
                                            }
                                        }

                                        SequentialAnimation {
                                            id: shakeAnimation
                                            loops: 2
                                            PropertyAnimation { target: translateTransform; property: "x"; from: 0; to: -8; duration: 40; easing.type: Easing.InOutQuad }
                                            PropertyAnimation { target: translateTransform; property: "x"; from: -8; to: 8; duration: 40; easing.type: Easing.InOutQuad }
                                            PropertyAnimation { target: translateTransform; property: "x"; from: 8; to: 0; duration: 40; easing.type: Easing.InOutQuad }
                                        }

                                        ColumnLayout {
                                            id: bubbleLayoutContentColumn
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 4

                                            Label {
                                                text: model.isUser ? "> YOU" : (model.isAngry ? "> RAPHAEL [ALERT]" : "> RAPHAEL")
                                                font.family: "Monospace"
                                                font.pointSize: 7.5
                                                font.bold: true
                                                color: model.isUser ? "#89b4fa" : (model.isAngry ? "#ff5555" : "#cba6f7")
                                                Layout.fillWidth: true
                                            }
                                            
                                            Text {
                                                text: model.messageText
                                                font.family: "Monospace"
                                                font.pointSize: 8.5
                                                color: model.isAngry ? "#ffcccc" : "#cdd6f4"
                                                wrapMode: Text.WordWrap
                                                lineHeight: 1.2
                                                
                                                Layout.fillWidth: true
                                                Layout.preferredWidth: messageOuterBubbleRect.width - 24
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            id: chatInputContainerRow
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: chatInputField
                                Layout.fillWidth: true
                                placeholderText: "ENTER COMMAND / COMMUNICATE..."
                                placeholderTextColor: "#585b70"
                                font.family: "Monospace"
                                font.pointSize: 9
                                color: "#cdd6f4"
                                
                                background: Rectangle { 
                                    color: Qt.rgba(0.07, 0.07, 0.11, 0.6)
                                    radius: 3
                                    border.color: chatInputField.activeFocus ? "#89b4fa" : "#313244"
                                    border.width: 1
                                }
                                
                                Keys.onReturnPressed: {
                                    plasmoidRoot.dispatchBubblePayload(chatInputField.text)
                                    chatInputField.text = ""
                                }
                            }

                            Rectangle {
                                id: sendButton
                                width: 45
                                height: chatInputField.height
                                color: chatInputField.activeFocus ? "#89b4fa" : "#313244"
                                radius: 3

                                Text {
                                    anchors.centerIn: parent
                                    text: "RUN"
                                    color: chatInputField.activeFocus ? "#11111b" : "#cdd6f4"
                                    font.family: "Monospace"
                                    font.bold: true
                                    font.pointSize: 7.5
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        plasmoidRoot.dispatchBubblePayload(chatInputField.text)
                                        chatInputField.text = ""
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: sensorFooterPanelRect
                    Layout.fillWidth: true
                    height: 28
                    color: Qt.rgba(0.07, 0.07, 0.11, 0.6)
                    radius: 4
                    border.color: "#313244"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        RowLayout {
                            spacing: 4
                            Rectangle { width: 4; height: 4; radius: 2; color: "#89b4fa" }
                            Label {
                                text: "SYS: " + sharedState.sensorScreen
                                font.family: "Monospace"
                                font.pointSize: 7.5
                                color: "#bac2de"
                                elide: Text.ElideRight; Layout.maximumWidth: 85
                            }
                        }
                        RowLayout {
                            spacing: 4
                            Rectangle { width: 4; height: 4; radius: 2; color: "#cba6f7" }
                            Label {
                                text: "MSC: " + sharedState.sensorMusic
                                font.family: "Monospace"
                                font.pointSize: 7.5
                                color: "#bac2de"
                                elide: Text.ElideRight; Layout.maximumWidth: 85
                            }
                        }
                        RowLayout {
                            spacing: 4
                            Rectangle { width: 4; height: 4; radius: 2; color: "#a6e3a1" }
                            Label {
                                text: "TME: " + sharedState.sensorTime
                                font.family: "Monospace"
                                font.pointSize: 7.5
                                color: "#bac2de"
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // WINDOW PANEL 3: CENTERED DISTRACTION OVERLAY
    // =========================================================
    Window {
        id: distractionOverlay
        visible: (sharedState.currentMetricsStatus === "Taking a break") && (sharedState.rawDistractSeconds > escalationTimeout)
        color: "transparent"
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.X11BypassWindowManagerHint
        
        width: 520
        height: 340
        x: (Screen.width - width) / 2
        y: (Screen.height - height) / 2

        Rectangle {
            id: overlayContainer
            anchors.fill: parent
            color: Qt.rgba(0.09, 0.09, 0.15, 0.96)
            radius: 4
            border.color: "#f38ba8"
            border.width: 2

            SequentialAnimation on border.color {
                loops: Animation.Infinite
                ColorAnimation { from: "#f38ba8"; to: "#ff5555"; duration: 1000 }
                ColorAnimation { from: "#ff5555"; to: "#f38ba8"; duration: 1000 }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "WARNING // COGNITIVE BREACH INTERCEPTED"
                        font.family: "Monospace"
                        font.pointSize: 9.5
                        font.bold: true
                        color: "#f38ba8"
                        font.letterSpacing: 1.5
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 110; height: 24; color: Qt.rgba(0.07, 0.07, 0.11, 0.6); radius: 3; border.color: "#f38ba8"; border.width: 1
                        Label {
                            anchors.centerIn: parent
                            text: "DIVERGENT: " + sharedState.liveDistractCounter
                            font.family: "Monospace"
                            font.pointSize: 7.5; font.bold: true; color: "#f38ba8"
                        }
                    }
                }

                Label {
                    text: "CRITICAL ALERT: Target shifted focus to '" + sharedState.sensorScreen + "'."
                    font.family: "Monospace"
                    font.pointSize: 9.5
                    color: "#a6adc8"
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: sharedState.insightBody
                    font.family: "Noto Sans"
                    font.pointSize: 12
                    font.bold: true
                    color: "#f38ba8"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    lineHeight: 1.3
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    TextField {
                        id: overlayInputField
                        Layout.fillWidth: true
                        placeholderText: "STATE JUSTIFICATION PROTOCOL..."
                        placeholderTextColor: "#585b70"
                        font.family: "Monospace"
                        font.pointSize: 10
                        color: "#cdd6f4"
                        
                        background: Rectangle { 
                            color: Qt.rgba(0.07, 0.07, 0.11, 0.6)
                            radius: 3
                            border.color: overlayInputField.activeFocus ? "#f38ba8" : "#313244"
                            border.width: 1
                        }
                        
                        Keys.onReturnPressed: {
                            var text = overlayInputField.text.trim();
                            if (text) {
                                plasmoidRoot.dispatchBubblePayload(text);
                                overlayInputField.text = "";
                            }
                        }
                    }

                    Rectangle {
                        width: 70
                        height: overlayInputField.height
                        color: "#f38ba8"
                        radius: 3

                        Text {
                            anchors.centerIn: parent
                            text: "SUBMIT"
                            color: "#11111b"
                            font.family: "Monospace"
                            font.bold: true
                            font.pointSize: 8
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var text = overlayInputField.text.trim();
                                if (text) {
                                    plasmoidRoot.dispatchBubblePayload(text);
                                    overlayInputField.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
