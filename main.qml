import QtQuick 2.7
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtWebEngine 1.7

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    visibility: ApplicationWindow.Hidden
    flags: Qt.Window | Qt.FramelessWindowHint

    signal trayActivation()

    onActiveChanged: {
        if(!active)
            hide();
    }

    Connections {
        target: ShowAction
        onTriggered: {
            if(!active) {
                show()
                raise()
                requestActivate()

                window.x = SystemTray.x - width
                window.y = SystemTray.y + SystemTray.height
            } else {
                hide()
            }
        }
    }

    onClosing: {
        hide()
        close.accepted = false
    }

    Item {
        focus: true

        Keys.onEscapePressed: {
            hide()
        }

        Component.onCompleted: forceActiveFocus()
    }

    UserSettings {
        id: settings
    }

    TabBar {
        id: bar
        anchors.right: addButton.left
        anchors.left: parent.left

        onCurrentIndexChanged: {
            if(bar.count > 0 && currentIndex === -1) {
                currentIndex = 0
            }
            if(bar.editIndex != -1 && currentIndex != bar.editIndex) {
                bar.editIndex = -1
            }
        }

        property int editIndex: -1

        Repeater {
            model: settings.viewModel
            TabButton {
                id: tabBtn
                text: itemTitle.length > 0 ? itemTitle : "<New>"
                hoverEnabled: true
            }
        }
    }

    RoundButton {
        id: addButton
        anchors.right: parent.right
        anchors.top: parent.top
        text: "+"
        flat: true

        onClicked: {
            settings.add('', '')
            bar.currentIndex = bar.count-1
        }
    }

    StackLayout {
        width: parent.width
        anchors.top: bar.bottom
        anchors.bottom: parent.bottom
        currentIndex: bar.currentIndex
        Repeater {
            model: settings.viewModel
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                property bool editMode: bar.editIndex == index || itemUrl.length === 0

                onVisibleChanged: {
                    webView.forceActiveFocus()
                }

                WebEngineView {
                    id: webView
                    anchors.fill: parent
                    url: itemUrl
                    visible: !editMode
                    onNewViewRequested:  Qt.openUrlExternally(request.requestedUrl)
                }

                Item {
                    visible: editMode
                    anchors.fill: parent
                    ColumnLayout {
                        width: 500
                        anchors.centerIn: parent
                        TextField {
                            id: titleEdit
                            Layout.fillWidth: true
                            text: itemTitle
                            selectByMouse: true
                            placeholderText: "Title"
                        }
                        TextField {
                            id: urlEdit
                            Layout.fillWidth: true
                            text: itemUrl
                            selectByMouse: true
                            placeholderText: "http://..."
                        }

                        RowLayout {
                            Button {
                                text: "Apply"
                                onClicked: {
                                    settings.set(dbId, titleEdit.text, urlEdit.text)
                                    bar.editIndex = -1
                                }
                            }
                            Button {
                                visible: itemUrl.length > 0
                                text: "Cancel"
                                onClicked: bar.editIndex = -1
                            }
                        }
                    }
                }

                RowLayout {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right

                    RoundButton {
                        id: refreshButton
                        icon.source: "refresh.svg"
                        icon.width: 16
                        icon.height: 16
                        onClicked: {
                            webView.reload();
                        }
                    }

                    RoundButton {
                        icon.source: "link.svg"
                        icon.width: 16
                        icon.height: 16
                        onClicked: {
                            Qt.openUrlExternally(itemUrl)
                        }
                    }
                    RoundButton {
                        icon.source: "edit.svg"
                        icon.width: 16
                        icon.height: 16
                        onClicked: {
                            bar.currentIndex = index
                            bar.editIndex = index
                        }
                    }
                    RoundButton {
                        icon.source: "trash-can.svg"
                        icon.width: 16
                        icon.height: 16
                        onClicked: {
                            settings.remove(dbId)
                        }
                    }
                }

                ProgressBar {
                    anchors.bottom: parent.bottom
                    height: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    value: webView.loadProgress / 100.0
                    opacity: webView.loading && webView.loadProgress < 100 ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 1000
                        }
                    }
                }

            }
        }
    }
}
