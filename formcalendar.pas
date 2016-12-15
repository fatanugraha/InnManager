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
    dummy: TPaintBox;
    pbHeader: TPaintBox;
    procedure btnPrevClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
    procedure GridTopLeftChanged(Sender: TObject);
    procedure pbHeaderPaint(Sender: TObject);
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
    procedure ReloadData;
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

var
  header_days: array [0..40] of string;

procedure TfrmCalendar.ReloadData;
begin
  ChangeDate(CurrentMonth, CurrentYear)
end;

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
  x := IncDay(EncodeDate(Year, month+1, 1), -1);
  y := EncodeDate(Year, month+1, DaysInMonth(EncodeDate(Year, Month+1, 1)));

  lookup := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  lookup.sql.Text := 'SELECT `name`,`instance` FROM `data` WHERE `id` = :id';

  with frmMain do
  begin
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

        if idx <> -1 then
        begin
          lookup.ParamByName('id').AsInteger := OwnerID;
          lookup.Open;
          OwnerName := lookup.FieldByName('name').AsString;
          OwnerIns := lookup.FieldByName('instance').AsString;
          Lookup.Close;

          mid := frmMain.dbOrdersQuery.fieldByName('id').AsInteger;
          if a = x then
          begin
            grid.Cells[1, idx] := OwnerName + LineEnding + OwnerIns;
            BoardData[1, idx] := mid;
            StatusData[1, idx] := status;
            a := incDay(a, 1);
          end;

          for i := DayOf(a) to DayOf(b) do
          begin
            grid.Cells[i+1, idx] := OwnerName + LineEnding + OwnerIns;
            BoardData[i+1, idx] := mid;
            StatusData[i+1, idx] := status;
          end;
        end;
      end;
      dbOrdersQuery.Next;
    end;
  end;
  lookup.Free;
end;

procedure TfrmCalendar.UpdateFixed;
const
  FIXED_COL_SIZE = 120;
var
  query: TSQLQuery;
  y, i: integer;
begin
  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);

  //hitung banyanknya kamar yang tersedia
  query.SQL.Text := 'SELECT COUNT(*) FROM `product` WHERE `active` = 1';
  query.Open;
  Grid.RowCount := query.FieldByName('COUNT(*)').AsInteger;
  Grid.ColWidths[0] := FIXED_COL_SIZE;
  query.Close;

  //print nama kamar sama jenisnya
  query.SQL.Text := 'SELECT `id`, `name`, `typename` FROM `product` WHERE `active` = 1';
  query.Open;

  SetLength(CellsID, 0);
  y := 0;

  while (not query.EOF) do
  begin
    SetLength(CellsID, y + 1);
    CellsID[y] := query.FieldByName('id').AsInteger;
    Grid.Cells[0, y] := Format('%s' + LineEnding + '%s', [query.FieldByName('name').AsString, query.FieldByName('typename').AsString]);
    Inc(y);

    query.Next;
  end;

  query.Close;
  query.Free;
end;

procedure TfrmCalendar.ChangeDate(month, year: integer);
const
  FEBRUARY = 1;
  FIXED_COL = 1;
  FIXED_ROW = 0;
var
  tmp: char;
  i, j, cur, size, user: integer;
  exists: boolean;
begin
  size := FIXED_COL + DaysInMonth(EncodeDate(year, month+1, 1)) + 1; //extra 1 day from previous month

  //erase existing contentes
  Grid.Clean(FIXED_COL, FIXED_ROW, Grid.ColCount - 1, Grid.RowCount - 1, [gzNormal]);
  Grid.ColCount := size;

  //get the first day in current month
  tmp := DefaultFormatSettings.DateSeparator;
  cur := TokenizeDay(FormatDateTime('dddd', StrToDate(Format('01/%d/%d', [month + 1, year]))));

  for i := 0 to size-1 do
  begin
    j := i;

    if i = 0 then
      j := DaysInMonth(IncDay(EncodeDate(Year, month+1, 1), -1))
    else if i = size-1 then
      j := 1;

    header_days[i] := Format('%s' + LineEnding + '%d', [DAY_IDN[cur], j]);
    cur := (cur + 1) mod 7;
  end;

  //tulis ke grid
  //todo

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

  //cek kalau di bulan dan tahun sekarnag
  //todo
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
   if (grid.col = 0) then
    exit;

  if BoardData[grid.col, grid.row] = 0 then
  begin
    frmAddCustomer.EditID := 0;
    frmAddCustomer.FromCalendar := true;
    frmAddCustomer.Show;
    frmMain.Enabled := false;
  end else begin
    frmOrderCard.ID := BoardData[grid.col, grid.row];
    frmOrderCard.Col := grid.col;
    frmOrderCard.Row := grid.row;
    frmOrderCard.Show;
    frmMain.Enabled := false;
  end;
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
    if (acol = 0) then //kalau dia fixed rows
    begin
      tmp := Font.Size;
      Font.Size := 0;
      Font.Bold := true;
    end;

    cl := Canvas.Brush.Color;

    canvas.Pen.color := clBlack;
    if aCol <> 0 then
      if StatusData[acol, arow] = 1 then //booked
        canvas.Brush.color := COLOR_BOOKED
      else if StatusData[acol, arow] = 2 then //check-in
        canvas.Brush.color := COLOR_CHECKIN
      else if StatusData[acol, arow] = 3 then //check-out
        canvas.Brush.color := COLOR_CHECKOUT;

    h := DrawText(Canvas.Handle, PChar(Cells[ACol, ARow]), -1, aRect,
      DT_NOPREFIX or DT_WORDBREAK or DT_CENTER);

    Canvas.FillRect(aRect);
    sz := aRect.Bottom-aRect.Top+1;

    if (sz >= h) then
      Inc(aRect.Top, sz div 2 - h div 2)
    else
      Inc(aRect.Top, 1);

    DrawText(Canvas.Handle, PChar(Cells[ACol, ARow]), -1, aRect,
      DT_NOPREFIX or DT_WORDBREAK or DT_CENTER);

    if (acol = 0) then //normalize
    begin
      grid.Font.size := tmp;
      grid.Font.Bold := false;
    end;

    Canvas.Brush.Color := cl;
  end;
end;

procedure TfrmCalendar.GridTopLeftChanged(Sender: TObject);
begin
  pbHeader.Invalidate;
end;

procedure TfrmCalendar.pbHeaderPaint(Sender: TObject);
const
  nw_color = $B0B0B0;
  bg_color = $F0F0F0;
  fixed_wd = 120;
  normal_wd = 100;
var
  h, i, size, sz, pref, aCol, aRow, wd: integer;

  tmp_d, tmp_m: integer;
  aRect: TRect;
begin
  //hapus sebelumnya
  pbHeader.canvas.fillrect(0, 0, pbHeader.width, pbHeader.height);

  wd := grid.DefaultColWidth;
  pref := fixed_wd - wd div 2;

  for i := grid.LeftCol-1 to grid.ColCount-1 do
  begin
    size := normal_wd;

    if pref > pbHeader.width then
       break;

    aRect := Rect(pref, 0, pref+size+1, pbHeader.Height);

    inc(pref, size);

    h := DrawText(dummy.canvas.Handle, PChar(header_days[i]), -1, aRect, DT_NOPREFIX or DT_WORDBREAK or DT_CENTER);
    sz := aRect.Bottom-aRect.Top+1;

    pbHeader.Canvas.Brush.Color := bg_color;

    //tandai hari ini
    if (currentmonth = monthOf(now)-1) and (currentyear = YearOf(now)) and (i = dayof(now)) then
      pbHeader.Canvas.Brush.Color := nw_color;

    if (i = 0) and (currentmonth <> monthof(now)-1) and (monthof(IncDay(now, 1))-1 = currentmonth) then
      pbHeader.Canvas.Brush.Color := nw_color;

    if (i = grid.ColCount-1) and (currentmonth <> monthof(now)-1) and (monthof(IncDay(now, -1))-1 = currentmonth) then
      pbHeader.Canvas.Brush.Color := nw_color;

    pbHeader.Canvas.Pen.Color := clBlack;
    pbHeader.canvas.Rectangle(aRect);


    if (sz >= h) then
      Inc(aRect.Top, sz div 2 - h div 2)
    else
      Inc(aRect.Top, 1);

    DrawText(pbHeader.Canvas.Handle, PChar(header_days[i]), -1, aRect, DT_NOPREFIX or DT_WORDBREAK or DT_CENTER);
  end;
end;

procedure TfrmCalendar.FormResize(Sender: TObject);
begin
  //cosmetics
  lblNow.Left := Width div 2 - LblNow.Width div 2;
  LblNow.Top := pbHeader.Top div 2 - LblNow.Height div 2;

  btnNext.Top := pbHeader.Top div 2 - btnNext.Height div 2;
  btnPrev.Top := btnNext.Top;
end;

procedure TfrmCalendar.btnPrevClick(Sender: TObject);
begin
  Dec(CurrentMonth);

  if (CurrentMonth < 0) then
  begin
    Inc(CurrentMonth, 12);
    Dec(CurrentYear);
  end;

  ChangeDate(CurrentMonth, CurrentYear);
  FormResize(nil);
end;

procedure TfrmCalendar.btnNextClick(Sender: TObject);
begin
  Inc(CurrentMonth);

  if (CurrentMonth = 12) then
  begin
    CurrentMonth := 0;
    Inc(Currentyear);
  end;

  ChangeDate(CurrentMonth, Currentyear);
  FormResize(nil);
end;

end.
