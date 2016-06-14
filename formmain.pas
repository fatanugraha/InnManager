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
    Image2: TImage;
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
    Label7: TLabel;
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
    procedure imgTypeClick(Sender: TObject);
    procedure imgCalendarClick(Sender: TObject);
    procedure imgCustomerClick(Sender: TObject);
    procedure imgProductClick(Sender: TObject);
    procedure imgUsersClick(Sender: TObject);
    procedure pnlContainerClick(Sender: TObject);
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
  FormUser, FormLogin, lib.common, FormType, FormProduct, formCalendar, lib.logger, FormCustomer
  ,formAddroom;

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
  lblUserName.Caption := CurrentSession.Username;
  WindowState := wsMaximized;
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //let's hope i sober when coding and always commit everything
  dbCustomersConnection.Connected := false;
  dbOrdersConnection.Connected := false;
  Application.Terminate;
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
  if (CurrentSession.Authority and AUTH_EDIT_USER) > 0 then
    frmUsers.Caption := 'Atur Pengguna'
  else
    frmUsers.Caption := 'Ganti Password';

  Enabled := false;
  frmUsers.Show;
end;

procedure TfrmMain.pnlContainerClick(Sender: TObject);
begin

end;

end.

