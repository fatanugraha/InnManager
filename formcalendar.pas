unit formCalendar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids, sqldb, StdCtrls, ExtCtrls, LCLIntf, LCLType,
  DateUtils;

type

  { TfrmCalendar }

  TfrmCalendar = class(TForm)
    btnPrev: TButton;
    btnNext: TButton;
    lblNow: TLabel;
    Grid: TStringGrid;
    procedure btnPrevClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
    procedure GridSelection(Sender: TObject; aCol, aRow: Integer);
  private
    CurrentMonth: integer;
    CurrentYear: integer;
    CellsID: array of integer;
    //simpan orderid setiap cell
    BoardData: array of array of integer;
    //simpen nih sel itu statusnya apa (ORDER)
    StatusData: array of array of integer;
    //tulis ulang yang di fixed row sama kolom
    procedure UpdateFixed;
    //change current calendar to prefered month/yr (0-based month)
    procedure ChangeDate(month, year: integer);
    //load from orders to string grid
    procedure LoadData(month, year: integer);
  public
    //floodfill ganti warna
    procedure UpdateStatus(aCol, aRow, toStatus: integer);
  public
    { public declarations }
  end;

var
  frmCalendar: TfrmCalendar;

implementation

{$R *.lfm}

uses
  lib.logger, lib.database, FormLogin, lib.Common, FormMain, FormOrderCard, FormAddCustomer;

{ TfrmCalendar }

procedure TfrmCalendar.UpdateStatus(aCol, aRow, toStatus: integer);
begin
  StatusData[acol, arow] := toStatus;

  if aCol+1 < grid.ColCount then
    if (StatusData[acol+1, arow] <> toStatus) and (BoardData[acol+1, arow] = BoardData[acol, arow]) then
      UpdateStatus(acol+1, aRow, toStatus);

  if aCol-1 >= 1 then
    if (StatusData[acol-1, arow] <> toStatus) and (BoardData[acol-1, arow] = BoardData[acol, arow]) then
      UpdateStatus(acol-1, aRow, toStatus);
end;

procedure TfrmCalendar.LoadData(month, year: integer);
var
  fi, se, x, y, a, b: TDateTime;
  Status, i, l, r, mid, idx, OwnerID, RoomID: integer;
  StatusStr, OwnerName, OwnerIns: string;
  lookup: TSQLQuery;
begin
  x := StrToDate(Format('1/%d/%d', [month + 1, Year]));
  y := StrToDate(Format('%d/%d/%d', [MONTH_SIZE[month], month + 1, Year]));

  lookup := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  lookup.sql.Text := 'SELECT `name`,`instance` FROM `data` WHERE `id` = :id';

  with frmMain do
  begin
    dbOrdersQuery.Refresh;
    dbOrdersQuery.First;

    while (not dbOrdersQuery.EOF) do
    begin
      fi := StrToDate(dbOrdersQuery.FieldByName('checkin').AsString);
      se := IncDay(StrToDate(dbOrdersQuery.FieldByName('checkout').AsString), -1);
      OwnerID := dbOrdersQuery.FieldByName('owner_id').AsInteger;
      RoomID := dbOrdersQuery.FieldByName('room_id').AsInteger;
      Status := dbOrdersQuery.FieldByName('status').AsInteger;

      if (isDateIntersect(fi, se, x, y)) then
      begin
        if (CompareDate(fi, x) < 0) then
          a := x
        else
          a := fi;

        if (CompareDate(y, se) < 0) then
          b := y
        else
          b := se;

        l := 0;
        r := Length(CellsID) - 1;
        idx := -1;

        while (l <= r) and (idx = -1) do
        begin
          mid := (l + r) div 2;

          if (RoomID < CellsID[mid]) then
            r := mid - 1
          else if (RoomID > CellsID[mid]) then
            l := mid + 1
          else
            idx := mid;
				end;

        lookup.ParamByName('id').AsInteger := OwnerID;
        lookup.Open;
        OwnerName := lookup.FieldByName('name').AsString;
        OwnerIns := lookup.FieldByName('instance').AsString;
        Lookup.Close;

        mid := frmMain.dbOrdersQuery.fieldByName('id').AsInteger;
        for i := DayOf(a) to DayOf(b) do
        begin
          grid.Cells[i, idx + 1] := OwnerName + LineEnding + OwnerIns;
          BoardData[i, idx + 1] := mid;
          StatusData[i, idx + 1] := status;
        end;
      end;

      dbOrdersQuery.Next;
    end;
  end;
  lookup.Free;
end;

procedure TfrmCalendar.UpdateFixed;
const
  FIXED_COL_CNT = 1;
  FIXED_COL_SIZE = 120;
var
  query: TSQLQuery;
  cnt, x, i: integer;
begin
  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);

  //hitung banyanknya kamar yang tersedia
  query.SQL.Text := 'SELECT COUNT(*) FROM PRODUCT';
  query.Open;
  Grid.RowCount := query.FieldByName('COUNT(*)').AsInteger + FIXED_COL_CNT;
  Grid.ColWidths[0] := FIXED_COL_SIZE;
  query.Close;

  //print nama kamar sama jenisnya
  query.SQL.Text := 'SELECT `id`, `name`, `typename` FROM PRODUCT';
  query.Open;
  cnt := FIXED_COL_CNT;

  SetLength(CellsID, 0);
  x := 0;

  while (not query.EOF) do
  begin
    SetLength(CellsID, x + 1);
    CellsID[x] := query.FieldByName('id').AsInteger;
    Inc(x);

    Grid.Cells[0, cnt] := Format('%s' + LineEnding + '%s', [query.FieldByName('name').AsString, query.FieldByName('typename').AsString]);
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
  i, j, cur, size, user: integer;
  exists: boolean;
begin
  size := FIXED_COL + MONTH_SIZE[month];

  //if leap year add 1 additional day
  if (month = FEBRUARY) and IsLeapYear(year) then
    Inc(size);

  //erase existing contentes
  Grid.Clean(FIXED_COL, FIXED_ROW, Grid.ColCount - 1, Grid.RowCount - 1, [gzNormal]);
  Grid.ColCount := size;

  //get the first day in current month
  tmp := DefaultFormatSettings.DateSeparator;
  cur := TokenizeDay(FormatDateTime('dddd', StrToDate(Format('01/%d/%d', [month + 1, year]))));

  //tulis ke grid
  for i := 1 to size - 1 do
  begin
    Grid.Cells[i, 0] := Format('%s' + LineEnding + '%d', [DAY_IDN[cur], i]);
    cur := (cur + 1) mod DAY_IN_MONTH;
  end;

  //update title
  lblNow.Caption := Format('%s %d', [MONTH_IDN[month], year]);

  SetLength(BoardData, Grid.ColCount, Grid.RowCount);
  SetLength(StatusData, Grid.ColCount, Grid.RowCount);

  for i := 0 to grid.ColCount-1 do
    for j := 0 to grid.RowCount-1 do
    begin
      BoardData[i,j] := 0;
      StatusData[i,j] := 0;
    end;

  LoadData(month, year);
end;

procedure TfrmCalendar.FormShow(Sender: TObject);
begin
  //open current month
  CurrentMonth := StrToInt(FormatDateTime('mm', now)) - 1;
  CurrentYear := StrToInt(FormatDateTime('yyyy', now));

  UpdateFixed;
  ChangeDate(CurrentMonth, CurrentYear);
end;

procedure TfrmCalendar.GridDblClick(Sender: TObject);
begin
end;

procedure TfrmCalendar.GridDrawCell(Sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
const
  COLOR_BOOKED = $7226F9;
  COLOR_CHECKIN = $EFD966;
  COLOR_CHECKOUT = $2EE2A6;
var
  h, sz: integer;
  tmp: integer;
  cl : TColor;
begin
	with TStringGrid(Sender) do
  begin
    if (acol = 0) or (arow = 0) then //kalau dia fixed rows
    begin
      tmp := Font.Size;
      Font.Size := 0;
      Font.Bold := true;

      if (aRow = 0) and (Copy(Cells[ACol, ARow], 1, 6) = 'Minggu') then // kalau minggu, warnai merah
        font.color := clRed;
  	end;

    cl := Canvas.Brush.Color;
    if not ((aCol = 0) or (aRow = 0)) then
      if StatusData[acol, arow] = 1 then //booked
        canvas.Brush.color := COLOR_BOOKED
      else if StatusData[acol, arow] = 2 then //check-in
        canvas.Brush.color := COLOR_CHECKIN
      else if StatusData[acol, arow] = 3 then //check-out
        canvas.Brush.color := COLOR_CHECKOUT;

    h := DrawText(Canvas.Handle, PChar(Cells[ACol, ARow]), -1, aRect, DT_NOPREFIX or DT_WORDBREAK or DT_CENTER);

    Canvas.FillRect(aRect);
    sz := aRect.Bottom-aRect.Top+1;

    if (sz >= h) then
      Inc(aRect.Top, sz div 2 - h div 2)
		else
      Inc(aRect.Top, 1);

    DrawText(Canvas.Handle, PChar(Cells[ACol, ARow]), -1, aRect, DT_NOPREFIX or DT_WORDBREAK or DT_CENTER);

    if (acol = 0) or (arow = 0) then //normalize
		begin
		  grid.Font.size := tmp;
		  grid.Font.Bold := false;
		  if (aRow = 0) and (Copy(Cells[ACol, ARow], 1, 6) = 'Minggu') then
		    font.color := clDefault;
    end;

    Canvas.Brush.Color := cl;
	end;
end;

procedure TfrmCalendar.GridSelection(Sender: TObject; aCol, aRow: Integer);
begin
  if (aCol = 0) or (aRow = 0) then
    exit;

  if BoardData[aCol, aRow] = 0 then
  begin
    frmAddCustomer.EditID := 0;
    frmAddCustomer.Show;
    frmMain.Enabled := false;
  end else begin
    frmOrderCard.ID := BoardData[aCol, aRow];
    frmOrderCard.Col := aCol;
    frmOrderCard.Row := aRow;
    frmOrderCard.Show;
    frmMain.Enabled := false;
  end;
end;

procedure TfrmCalendar.FormResize(Sender: TObject);
begin
  //cosmetics
  lblNow.Left := Width div 2 - LblNow.Width div 2;
  LblNow.Top := Grid.Top div 2 - LblNow.Height div 2;

  btnNext.Top := Grid.Top div 2 - btnNext.Height div 2;
  btnPrev.Top := btnNext.Top;
end;


procedure TfrmCalendar.btnPrevClick(Sender: TObject);
begin
  Dec(CurrentMonth);

  if (CurrentMonth < 0) then
  begin
    Inc(CurrentMonth, MONTH_IN_YEAR);
    Dec(CurrentYear);
  end;

  ChangeDate(CurrentMonth, CurrentYear);
  FormResize(nil);
end;

procedure TfrmCalendar.btnNextClick(Sender: TObject);
begin
  Inc(CurrentMonth);

  if (CurrentMonth = MONTH_IN_YEAR) then
  begin
    CurrentMonth := 0;
    Inc(Currentyear);
  end;

  ChangeDate(CurrentMonth, Currentyear);
  FormResize(nil);
end;

procedure TfrmCalendar.Button1Click(Sender: TObject);
begin

end;

procedure TfrmCalendar.FormCreate(Sender: TObject);
begin
end;

end.
