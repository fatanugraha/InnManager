unit formmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    Image1: TImage;
    imgUsers: TImage;
    imgProduct: TImage;
    imgCalendar: TImage;
    imgCustomer: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lblUserName: TLabel;
    pnlContainer: TPanel;
    pnlHeader: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure imgCustomerClick(Sender: TObject);
    procedure imgUsersClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

uses
  FormUser, FormLogin, lib.common, FormType;

procedure TfrmMain.FormCreate(Sender: TObject);
begin

end;

procedure TfrmMain.Image1Click(Sender: TObject);
begin
  frmType.Show;
end;

procedure TfrmMain.imgCustomerClick(Sender: TObject);
begin

end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin

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

