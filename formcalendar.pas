unit formCalendar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids, sqldb, StdCtrls, ExtCtrls;

type

  { TfrmCalendar }

  TfrmCalendar = class(TForm)
    Button1: TButton;
    Button2: TButton;
    lblNow: TLabel;
    lblTime: TLabel;
    Grid: TStringGrid;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    CurrentMonth: integer;
    CurrentYear: integer;

    procedure UpdateFixed;
    procedure ChangeDate(month, year: integer);
  public
    { public declarations }
  end;

var
  frmCalendar: TfrmCalendar;

implementation

{$R *.lfm}

uses
  lib.logger, lib.database, FormLogin, lib.Common;

{ TfrmCalendar }

procedure TfrmCalendar.UpdateFixed;
const
  FIXED_COL_CNT = 1;
  FIXED_COL_SIZE = 140;
var
  query: TSQLQuery;
  cnt: integer;
begin
  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT COUNT(*) FROM PRODUCT';
  query.Open;
  Grid.RowCount := query.FieldByName('COUNT(*)').AsInteger + FIXED_COL_CNT;
  Grid.ColWidths[0] := FIXED_COL_SIZE;
  query.Close;

  query.SQL.Text := 'SELECT `name`, `typename` FROM PRODUCT';
  query.Open;
  cnt := FIXED_COL_CNT;
  while (not query.EOF) do
  begin
    Grid.Cells[0, cnt] := Format('%s [%s]', [query.FieldByName('name').AsString,
      query.FieldByName('typename').AsString]);
    Inc(cnt);
    query.Next;
  end;
  query.Close;
  query.Free;
end;

procedure TfrmCalendar.ChangeDate(month, year: integer);
const
  FEBRUARY = 1;
  FIXED_COL = 1;
  FIXED_ROW = 1;
var
  tmp: char;
  i, cur: integer;
  size: integer;
begin
  size := FIXED_COL + MONTH_SIZE[month];

  if (month = FEBRUARY) and IsLeapYear(year) then
    inc(size);

  Grid.Clean(FIXED_COL, FIXED_ROW, Grid.ColCount-1, Grid.RowCount-1, [gzNormal]);
  Grid.ColCount := size;

  DefaultFormatSettings.ShortDateFormat := 'dd/MM/yyyy';
  tmp := DefaultFormatSettings.DateSeparator;
  cur := TokenizeDay(FormatDateTime('dddd', StrToDate(Format('01/%d/%d', [month+1, year]))));
  for i := 1 to size-1 do
  begin
    Grid.Cells[i, 0] := Format('%d - %s', [i, DAY_IDN[cur]]);
    cur := (cur+1) mod 7;
  end;

  lblNow.Caption := Format('%s %d', [MONTH_IDN[month], year]);
end;

procedure TfrmCalendar.FormShow(Sender: TObject);
begin
  CurrentMonth := StrToInt(FormatDateTime('mm', now))-1;
  CurrentYear := StrToInt(FormatDateTime('yyyy', now));

  UpdateFixed;
  ChangeDate(CurrentMonth, CurrentYear);
end;

procedure TfrmCalendar.Timer1Timer(Sender: TObject);
begin
  lblTime.Caption := FormatDateTime('hh:nn:ss - dddd, dd mmmm yyyy', now);
end;

procedure TfrmCalendar.FormCreate(Sender: TObject);
begin

end;

procedure TfrmCalendar.Button3Click(Sender: TObject);
begin

end;

procedure TfrmCalendar.Button1Click(Sender: TObject);
begin
  dec(CurrentMonth);
  if (CurrentMonth < 0) then begin
    inc(CurrentMonth, 12);
    dec(CurrentYear);
  end;
  ChangeDate(CurrentMonth, CurrentYear);
end;

procedure TfrmCalendar.Button2Click(Sender: TObject);
begin
  inc(CurrentMonth);
  if (CurrentMonth = 12) then
  begin
    CurrentMonth := 0;
    inc(Currentyear);
  end;
  ChangeDate(CurrentMonth, Currentyear);
end;

end.
