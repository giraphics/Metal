#include <QApplication>
#include <QWindow.h>
#include <QMainWIndow>
#include <QFrame>
#include <QPushButton>
#include <QHBoxLayout>
#include <QMacCocoaViewContainer>
#include <QDialog>

extern "C" {
    QWindow* DefferredLighting();
    QWidget* DefferredLightingQMacCocoaViewContainer(QWidget* p_Parent = NULL);
    QMacCocoaViewContainer* DefferredLightingCocoaView();
    void CleanUpMetal();
}

int main(int argc, char **argv)
{

    QApplication app(argc, argv);
    QWindow* metalWindow = DefferredLighting();
    //metalWindow->setFlags(Qt::Dialog);
    metalWindow->setTitle("Qt Deffered Lighting");
    metalWindow->resize(800, 600);
    metalWindow->show();

//    QDialog* dlg = new QDialog(NULL, Qt::Dialog);
//    QHBoxLayout* HLayout = new QHBoxLayout(NULL);
//    HLayout->addWidget (QWidget::createWindowContainer(DefferredLighting()));
//    dlg->setLayout (HLayout);
//    dlg->resize(800, 600);
//    dlg->show();

//    QDialog* dlg = new QDialog(NULL, Qt::Dialog);
//    QHBoxLayout* HLayout = new QHBoxLayout(NULL);
//    HLayout->addWidget (DefferredLightingCocoaView());
//    dlg->setLayout (HLayout);
//    dlg->resize(800, 600);
//    dlg->show();

//    for (int i = 0; i < 2; ++i)
//    {
//        DefferredLightingQMacCocoaViewContainer()->show();
//    }
//    QMainWindow* mainWindow = new QMainWindow();
//    QWidget* centralWidget = new QWidget(mainWindow);
//    mainWindow->setCentralWidget(centralWidget);

//    QLayout* centralWidgetLayout = new QHBoxLayout(centralWidget);

//    QWidget* normalWidget = new QWidget();
//    //centralWidgetLayout->addWidget(new QPushButton("sss"));

//    centralWidgetLayout->addWidget(QWidget::createWindowContainer(metalWindow)); // Add newly created NSView as a child of toplevel window(mainWindow)’s NSView.
//    mainWindow->show();

    int status = app.exec();
    CleanUpMetal();
    return status;
}
