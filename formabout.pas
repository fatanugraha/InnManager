unit formAbout;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;

type

  { TfrmAbout }

  TfrmAbout = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lblDate: TLabel;
    lblVer: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    Panel1: TPanel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Memo2Change(Sender: TObject);
    procedure Panel1Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmAbout: TfrmAbout;

implementation

{$R *.lfm}

{ TfrmAbout }

uses
  lib.common, FormMain;

procedure TfrmAbout.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  frmMain.Enabled := true;
end;

procedure TfrmAbout.FormCreate(Sender: TObject);
begin

end;

procedure TfrmAbout.FormShow(Sender: TObject);
begin
  frmMain.Enabled := false;
  lblVer.Caption:= 'Built for ' + APP_NAME + ' with hardcoded id-ID interface language';
  lblDate.Caption:= APP_VER + ' - ' + APP_DATE ;
end;

procedure TfrmAbout.Memo2Change(Sender: TObject);
begin

end;

procedure TfrmAbout.Panel1Click(Sender: TObject);
begin

end;

end.

