unit formreport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, DateTimePicker, Forms, Controls, Graphics,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, DateUtils, sqldb;

type

  { TfrmReport }

  TfrmReport = class(TForm)
    _Bevel1: TBevel;
    _Button1: TButton;
    _ComboBox1: TComboBox;
    _picker: TDateTimePicker;
    _Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lblIncome: TLabel;
    ListView1: TListView;
    procedure _Button1Click(Sender: TObject);
    procedure _ComboBox1Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

  roomrec = record
    id: integer;
    Name: string;
    active, used, sum: integer;
  end;

var
  frmReport: TfrmReport;

implementation

{$R *.lfm}

{ TfrmReport }

uses
  lib.database, FormMain, lib.common, FormLogin, lib.logger;

var
  rooms_data: array of roomrec;

procedure TfrmReport._ComboBox1Change(Sender: TObject);
begin
  if _ComboBox1.ItemIndex = 0 then
    _picker.HideDateTimeParts := []
  else
    _picker.HideDateTimeParts := [dtpDay];
end;

procedure TfrmReport._Button1Click(Sender: TObject);
var
  x, y, tbegin, tend: TDateTime;
  query: TSQLQuery;
  sum, i, done, cnt: integer;
  owners: array of integer;
  tmp: TListItem;
begin
  for i := 0 to high(rooms_data) do
  begin
    rooms_data[i].sum := 0;
    rooms_data[i].used := 0;
  end;

  if _ComboBox1.ItemIndex = 0 then
  begin
    tbegin := _picker.Date;
    tend := IncDay(_picker.Date, 1);
  end
  else
  begin
    tbegin := EncodeDate(YearOf(_picker.Date), MonthOf(_picker.Date), 1);
    tend := IncDay(EncodeDate(YearOf(_picker.Date), MonthOf(_picker.Date),
      DaysInMonth(_picker.Date)), 1);
  end;

  query := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
  query.SQL.Text := 'SELECT * FROM `orders`';
  query.Open;

  sum := 0;
  cnt := 0;

  setlength(owners, 0);

  while (not query.EOF) do
  begin
    x := StrToDate(query.FieldByName('checkin').AsString);
    y := StrToDate(query.FieldByName('checkout').AsString);

    if isDateIntersect(x, y, tbegin, tend) then
    begin
      if tend < y then
        y := tend;

      if x < tbegin then
        x := tbegin;

      if daysBetween(x, y) > 0 then
      begin
        for i := 0 to high(rooms_Data) do
        begin
          if rooms_data[i].id <> query.FieldByName('room_id').AsInteger then
            continue;

          Inc(cnt, DaysBetween(x, y));
          Inc(rooms_data[i].used, DaysBetween(x, y));
          Inc(rooms_data[i].sum, query.FieldByName('price').AsInteger * DaysBetween(x, y));
          Inc(sum, query.FieldByName('price').AsInteger * DaysBetween(x, y));

          break;
        end;

        done := query.FieldByName('owner_id').AsInteger;
        for i := 0 to high(owners) do
        begin
          if owners[i] = done then
          begin
            done := 0;
            break;
          end;
        end;

        if done > 0 then
        begin
          SetLength(owners, Length(owners) + 1);
          owners[high(owners)] := done;
        end;
      end;
    end;

    query.Next;
  end;

  query.Close;
  query.Free;

  //tampilin
  listview1.Clear;
  for i := 0 to high(rooms_data) do
  begin
    if (rooms_data[i].sum = 0) then
      continue;

    tmp := TListItem.Create(listView1.Items);
    tmp.Caption := rooms_data[i].Name;
    tmp.SubItems.add(GroupDigits(rooms_data[i].used));
    tmp.SubItems.add('Rp' + GroupDigits(rooms_data[i].sum));
    listview1.Items.AddItem(tmp);
  end;


  Label5.Caption := ': ' + IntToStr(length(owners));
  Label6.Caption := ': ' + IntToStr(cnt);
  lblIncome.Caption := ': Rp' + GroupDigits(sum);

  for i := 0 to ComponentCount - 1 do
  begin
    TControl(Components[i]).Visible := True;
  end;
end;

procedure TfrmReport.FormShow(Sender: TObject);
var
  query: TSQLQuery;
  x: integer;
begin
  _picker.Date := Date;

  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT * FROM `product`';
  query.Open;

  setlength(rooms_data, 0);

  while (not Query.EOF) do
  begin
    x := Length(rooms_data);
    SetLength(rooms_data, x + 1);

    rooms_data[x].id := query.FieldByName('id').AsInteger;
    rooms_data[x].Name := query.FieldByName('name').AsString;
    rooms_data[x].active := query.FieldByName('active').AsInteger;

    query.Next;
  end;

  query.Close;
  query.Free;

  for x := 0 to ComponentCount - 1 do
  begin
    if Components[x].Name[1] <> '_' then
      TControl(Components[x]).Visible := False;
  end;

end;

end.
