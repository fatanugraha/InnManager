unit formaddroom;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, CheckLst,
  EditBtn, StdCtrls, ExtCtrls;

type

  { TfrmAddRoom }

  TfrmAddRoom = class(TForm)
    Bevel1: TBevel;
    Button1: TButton;
    Button2: TButton;
    CheckListBox1: TCheckListBox;
    DateEdit1: TDateEdit;
    DateEdit2: TDateEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure DateEdit2KeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmAddRoom: TfrmAddRoom;

implementation

{$R *.lfm}

{ TfrmAddRoom }

procedure TfrmAddRoom.DateEdit2KeyPress(Sender: TObject; var Key: char);
begin
  key := #0;
end;

procedure TfrmAddRoom.FormCreate(Sender: TObject);
begin

end;

end.

