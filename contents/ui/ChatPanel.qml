import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 8
    
    Label {
        text: "Distraction detected. State your reason:"
        color: "#FF8888"
        font.bold: true
        font.pointSize: 9
    }

    RowLayout {
        spacing: 8
        TextField {
            id: inputReason
            Layout.fillWidth: true
            placeholderText: "Explain why you switched tasks..."
            color: "#FFFFFF"
            background: Rectangle { color: "#222222"; radius: 3 }
            onAccepted: submitReason()
        }
        Button {
            text: "Override"
            onClicked: submitReason()
        }
    }

    function submitReason() {
        if (inputReason.text.trim() === "") return;
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "http://localhost:5757/override");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var res = JSON.parse(xhr.responseText);
                if (res.approved) {
                    inputReason.text = "";
                }
            }
        }
        xhr.send(JSON.stringify({ "reason": inputReason.text }));
    }
}
