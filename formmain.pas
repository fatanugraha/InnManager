unit formmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqlite3conn, sqldb, FileUtil, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, Grids;

type

  { TfrmMain }
  PForm = ^TForm;

  TfrmMain = class(TForm)
    Image1: TImage;
    Image3: TImage;
    imgType: TImage;
    imgUsers: TImage;
    imgProduct: TImage;
    imgCalendar: TImage;
    imgCustomer: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lblSelected: TLabel;
    lblUserName: TLabel;
    pnlContainer: TPanel;
    pnlHeader: TPanel;
    dbOrdersConnection: TSQLite3Connection;
    dbOrdersTransaction: TSQLTransaction;
    dbCustomersConnection: TSQLite3Connection;
    dbCustomersTransaction: TSQLTransaction;
    dbOrdersQuery: TSQLQuery;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Image3Click(Sender: TObject);
    procedure imgTypeClick(Sender: TObject);
    procedure imgCalendarClick(Sender: TObject);
    procedure imgCustomerClick(Sender: TObject);
    procedure imgProductClick(Sender: TObject);
    procedure imgUsersClick(Sender: TObject);
    procedure Label9Click(Sender: TObject);
  private
    prev: PForm;
  public
    //embed form to pnlContainer and select current tab
    procedure OpenTab(Form: PForm; Sender: TObject);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

uses
  FormUser, FormLogin, lib.common, FormType, FormProduct, formCalendar, lib.logger, FormCustomer, formAddroom,
  FormAbout, FormReport;

procedure TfrmMain.OpenTab(Form: PForm; Sender: TObject);
begin
  if (lblSelected.Left = Tlabel(Sender).Left-2) then
    exit;

  if (prev <> nil) then
    prev^.close;

  with Form^ do
  begin
    prev := Form;
    Align := alClient;
    BorderStyle := bsNone;
    Parent := pnlContainer;
    Show;
  end;

  lblSelected.Left := TLabel(Sender).left-2;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  //connect to database keep-alive until form closed
  dbOrdersConnection.DatabaseName := CurrentDir + FILE_ORDERS;
  dbOrdersConnection.Connected := true;
  dbCustomersConnection.DatabaseName := CurrentDir + FILE_CUSTOMERS;
  dbCustomersConnection.Connected := true;
  dbOrdersQuery.Open;

  //cosmetics
  lblSelected.left := 0;
  imgCalendarClick(imgCalendar);
  frmMain.lblUserName.Caption := Format('%s (%s)', [CurrentSession.FullName,
    CurrentSession.Username]);
  WindowState := wsMaximized;

  Caption := APP_NAME + ' | Sistem Reservasi';
end;

procedure TfrmMain.Image1Click(Sender: TObject);
begin
  OpenTab(@frmReport, Sender);
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Hide;
  frmLogin.Show;
end;

procedure TfrmMain.Image3Click(Sender: TObject);
begin
  frmAbout.Show;
end;

procedure TfrmMain.imgTypeClick(Sender: TObject);
begin
  OpenTab(@frmType, Sender);
end;

procedure TfrmMain.imgCalendarClick(Sender: TObject);
begin
  OpenTab(@frmCalendar, Sender);
end;

procedure TfrmMain.imgCustomerClick(Sender: TObject);
begin
  OpenTab(@frmCustomer, Sender);
end;

procedure TfrmMain.imgProductClick(Sender: TObject);
begin
  OpenTab(@frmProduct, Sender);
end;

procedure TfrmMain.imgUsersClick(Sender: TObject);
begin
  frmUsers.Show;
end;

procedure TfrmMain.Label9Click(Sender: TObject);
begin

end;

end.

