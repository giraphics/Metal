#ifndef UITESTDIALOGIMP_H
#define UITESTDIALOGIMP_H

#include <QDialog>

namespace Ui {
//class UiTestDialogImp;
class MetalDialogUI;
}

class QMacCocoaViewContainer;
class MetalDialog : public QDialog
{
    Q_OBJECT

public:
    explicit MetalDialog(QWidget *parent = 0);
    ~MetalDialog();

protected:
    void paintEvent(QPaintEvent* p_Event);

private:
    Ui::MetalDialogUI *ui;
    QMacCocoaViewContainer* m_Container;
};

#endif // UITESTDIALOGIMP_H
