unit formmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    imgUsers: TImage;
    imgProduct: TImage;
    imgCalendar: TImage;
    imgCustomer: TImage;
    lblUserName: TLabel;
    pnlHeader: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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
  FormUser, FormLogin, lib.common;

procedure TfrmMain.FormCreate(Sender: TObject);
begin

end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  CurrentSession.Authority := StrToInt(edit1.text);
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

