unit formproduct;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls;

type

  { TfrmProduct }

  TfrmProduct = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ListView1: TListView;
    procedure FormCreate(Sender: TObject);
    procedure ListView1Compare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmProduct: TfrmProduct;

implementation

{$R *.lfm}

{ TfrmProduct }

procedure TfrmProduct.FormCreate(Sender: TObject);
begin

end;

procedure TfrmProduct.ListView1Compare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
begin

end;

end.

