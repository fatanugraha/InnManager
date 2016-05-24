unit formmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Grids;

type

  { TfrmMain }
  PForm = ^TForm;

  TfrmMain = class(TForm)
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
    lblSelected: TLabel;
    lblUserName: TLabel;
    pnlContainer: TPanel;
    pnlHeader: TPanel;
    procedure FormShow(Sender: TObject);
    procedure imgTypeClick(Sender: TObject);
    procedure imgCalendarClick(Sender: TObject);
    procedure imgCustomerClick(Sender: TObject);
    procedure imgProductClick(Sender: TObject);
    procedure imgUsersClick(Sender: TObject);
  private
    prev: PForm;
  public
    procedure OpenTab(Form: PForm; Sender: TObject);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

uses
  FormUser, FormLogin, lib.common, FormType, FormProduct, formCalendar, lib.logger;

procedure TfrmMain.OpenTab(Form: PForm; Sender: TObject);
begin
  if (lblSelected.Left = Tlabel(Sender).Left) then
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

  lblSelected.Left := TLabel(Sender).left;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  //cosmetics
  lblSelected.left := 0;
  imgCalendarClick(imgCalendar);

  //
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

end.

