import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: configPage
    property alias cfg_displayDuration: durationSlider.value
    property alias cfg_caringLevel: caringSlider.value
    property alias cfg_aiWindowTracking: aiTrackSwitch.checked
    property alias cfg_proactiveInterventions: proactiveSwitch.checked
    property alias cfg_escalationTimeout: timeoutSlider.value
    property alias cfg_activeMonitoring: activeMonitoringSwitch.checked
    
    spacing: 16
    Layout.fillWidth: true

    Label { text: "Quote visibility scale (Seconds)"; font.bold: true }
    RowLayout {
        spacing: 12
        Slider { id: durationSlider; from: 5; to: 90; stepSize: 1; Layout.fillWidth: true }
        Label { text: durationSlider.value + "s"; font.pointSize: 10 }
    }

    Label { text: "Raphael Advisor Caring Level (1 = Strict, 5 = Highly Caring)"; font.bold: true }
    RowLayout {
        spacing: 12
        Slider { id: caringSlider; from: 1; to: 5; stepSize: 1; Layout.fillWidth: true }
        Label { text: caringSlider.value; font.pointSize: 10 }
    }

    Label { text: "Anger Escalation Timeout (Seconds)"; font.bold: true }
    RowLayout {
        spacing: 12
        Slider { id: timeoutSlider; from: 30; to: 300; stepSize: 10; Layout.fillWidth: true }
        Label { text: timeoutSlider.value + "s"; font.pointSize: 10 }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: "#313244" }

    Switch {
        id: aiTrackSwitch
        text: "Enable AI Window Classification"
        Layout.fillWidth: true
    }

    Switch {
        id: proactiveSwitch
        text: "Enable Proactive Advice & Concept Explanations"
        Layout.fillWidth: true
    }

    Switch {
        id: activeMonitoringSwitch
        text: "Enable Focus/Distraction Tracking & Popups"
        Layout.fillWidth: true
    }
}
