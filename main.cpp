#include <QApplication>
#include <QQmlApplicationEngine>
#include <QSystemTrayIcon>
#include <QPainter>
#include <QQuickWindow>
#include <QQmlContext>
#include <QMenu>
#include <QtWebEngine>

#include "systemtrayicon.h"

QSystemTrayIcon* createSystemTray(QAction*& showAction)
{
    QPixmap px(64,64);
    px.fill(Qt::transparent);

    QPainter p(&px);
    p.setPen(Qt::white);
    QFont font = p.font();
    font.setPixelSize(48);
    p.setFont(font);
    p.drawText(QRect(0, 0, 64,64), Qt::AlignCenter, "W");

    QIcon icon(px);

    QSystemTrayIcon* systemTrayIcon = new SystemTrayIcon();
    systemTrayIcon->setIcon(icon);

    showAction = new QAction();

    /*	QMenu* systemTrayContextMenu = new QMenu();

    showAction = systemTrayContextMenu->addAction("Show");
    QAction* quitAction = systemTrayContextMenu->addAction("Quit");

    QObject::connect(quitAction, &QAction::triggered, qApp, &QCoreApplication::quit);

    systemTrayIcon->setContextMenu(systemTrayContextMenu);*/

    systemTrayIcon->show();

    return systemTrayIcon;
}

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);
    QtWebEngine::initialize();

    qRegisterMetaType<QSystemTrayIcon::ActivationReason>("QSystemTrayIcon::ActivationReason");

    QAction* showAction;
    QSystemTrayIcon* systemTrayIcon = createSystemTray(showAction);

    QObject::connect(systemTrayIcon, &QSystemTrayIcon::activated, showAction, &QAction::trigger);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("ShowAction", showAction);
    engine.rootContext()->setContextProperty("SystemTray", systemTrayIcon);

    engine.load(QUrl(QLatin1String("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    QQuickWindow* appWindow = qobject_cast<QQuickWindow*>(engine.rootObjects().first());

    if(!appWindow)
        return -1;

    return app.exec();
}
