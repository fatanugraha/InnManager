unit formCustomer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls;

type

  { TfrmCustomer }

  TfrmCustomer = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    ListView1: TListView;
    ListView2: TListView;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmCustomer: TfrmCustomer;

implementation

{$R *.lfm}

end.

