unit formaddroom;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, CheckLst,
  EditBtn, StdCtrls, ExtCtrls, sqldb, dateutils, LCLType;

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
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure DateEdit1AcceptDate(Sender: TObject; var ADate: TDateTime;
      var AcceptDate: Boolean);
    procedure DateEdit1Change(Sender: TObject);
    procedure DateEdit1KeyPress(Sender: TObject; var Key: char);
    procedure DateEdit2AcceptDate(Sender: TObject; var ADate: TDateTime;
      var AcceptDate: Boolean);
    procedure DateEdit2KeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
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

uses
  FormMain, FormAddCustomer, lib.database, FormLogin, lib.logger, lib.common;

var
  valid: boolean;

procedure TfrmAddRoom.DateEdit2KeyPress(Sender: TObject; var Key: char);
begin
  key := #0;
end;

procedure TfrmAddRoom.DateEdit1AcceptDate(Sender: TObject;
  var ADate: TDateTime; var AcceptDate: Boolean);
begin
  AcceptDate := (CompareDate(ADate, Now) >= 0);

  if (not AcceptDate) then
    Application.MessageBox('Tanggal check-in harus sama atau lebih dari tanggal sekarang', 'Data Salah', MB_ICONEXCLAMATION);
end;

procedure TfrmAddRoom.Button1Click(Sender: TObject);
var
  i, j, cnt, sz, price: integer;
  query, lookup: TSQLQuery;
  A, B, X, Y: TDateTime;

  OK: boolean;
begin
  cnt := 0;
  for i := 0 to CheckListBox1.Count -1 do
    if (CheckListBox1.Checked[i]) then
      inc(cnt);

  if (cnt = 0) then
  begin
    Application.MessageBox('Tidak ada ruangan yang di pilih', 'Data Salah', MB_ICONEXCLAMATION);
    exit;
  end;

  if (not valid) then
  begin
    Application.MessageBox('Tanggal check-in atau check-in tidak valid.', 'Data Salah', MB_ICONEXCLAMATION);
    exit;
  end;

  //check bentrok ngga
  query := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
  query.SQL.Text := 'SELECT `checkin`,`checkout` FROM `orders` WHERE';

  cnt := 0;
  for i := 0 to Length(frmAddCustomer.tmp_id)-1 do
  begin
    if (CheckListBox1.Checked[i]) then
    begin
      if (cnt > 0) then
        query.SQL.Text := query.SQL.Text + ' OR';
      query.SQL.Text := query.SQL.Text + Format('`room_id` = %d', [frmAddCustomer.tmp_id[i]]);
      inc(cnt);
    end;
  end;

  query.open;

  A := DateEdit1.Date;
  B := IncDay(DateEdit2.Date, -1);

  OK := true;
  //check segment intersection
  while (not query.EOF) do
  begin
    X := StrToDate(query.FieldByName('checkin').AsString);
    Y := IncDay(StrToDate(query.FieldByName('checkout').AsString), -1);

    if (isDateIntersect(A, B, X, Y)) then
    begin
      OK := false;
      break;
    end;

    query.Next;
  end;

  query.close;
  query.Free;

  if (not OK) then
  begin
    Application.MessageBox('Ada ruangan telah dipakai dalam rentang waktu yang diinginkan.', 'Reservasi Gagal',
    MB_ICONEXCLAMATION);
    exit;
  end;

  lookup := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  lookup.SQL.Text := 'SELECT `price` FROM `product_type` WHERE `name` = :name';

  //cek intersect sama yang udah -> O(N*M)
  for i := 0 to Length(frmAddCustomer.tmp_id)-1 do
  begin
    if not CheckListBox1.Checked[i] then
      continue;

    for j := 0 to Length(frmAddCustomer.tmpOrder)-1 do
    begin
      if frmAddCustomer.tmpOrder[j].id = frmAddCustomer.tmp_id[i] then
      begin
        X := StrToDate(frmAddCustomer.tmpOrder[j].checkin);
        Y := IncDay(StrToDate(frmAddCustomer.tmpOrder[j].checkout), -1);

        if (isDateIntersect(A, B, X, Y)) then
        begin
          OK := false;
          break;
        end;
			end;
		end;
	end;

  if (not OK) then
  begin
    Application.MessageBox('Ada ruangan telah dipakai dalam rentang waktu yang diinginkan.', 'Reservasi Gagal',
    MB_ICONEXCLAMATION);
    exit;
  end;

	//masukin ke temporary dulu
  for i := 0 to Length(frmAddCustomer.tmp_id)-1 do
  begin
    if (CheckListBox1.Checked[i]) then
    begin
      sz := Length(frmAddCustomer.tmpOrder);
      SetLength(frmAddCustomer.tmpOrder, sz+1);

      lookup.ParamByName('name').AsString := frmAddCustomer.tmp_jenis[i];
      lookup.Open;
      frmAddCustomer.tmpOrder[sz].Harga := Lookup.FieldByName('price').AsInteger;
      Lookup.Close;

      frmAddCustomer.tmpOrder[sz].id := frmAddCustomer.tmp_id[i];
      frmAddCustomer.tmpOrder[sz].name := frmAddCustomer.tmp_nama[i];
      frmAddCustomer.tmpOrder[sz].jenis := frmAddCustomer.tmp_jenis[i];
      frmAddCustomer.tmpOrder[sz].Days := DaysBetween(DateEdit1.Date, DateEdit2.Date);
      frmAddCustomer.tmpOrder[sz].sum := frmAddCustomer.tmpOrder[sz].Harga*frmAddCustomer.tmpOrder[sz].Days;
      frmAddCustomer.tmpOrder[sz].checkin := DateEdit1.Text;
      frmAddCustomer.tmpOrder[sz].checkout:= DateEdit2.Text;
    end;
  end;

  lookup.free;
  frmAddCustomer.UpdateOrders;
  close;
end;

procedure TfrmAddRoom.Button2Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmAddRoom.DateEdit1Change(Sender: TObject);
begin
  if (DateEdit1.Text <> '') then
    DateEdit2.Enabled := true;
end;

procedure TfrmAddRoom.DateEdit1KeyPress(Sender: TObject; var Key: char);
begin
  Key := #0;
end;

procedure TfrmAddRoom.DateEdit2AcceptDate(Sender: TObject;
  var ADate: TDateTime; var AcceptDate: Boolean);
begin
  AcceptDate := (CompareDate(ADate, DateEdit1.Date) > 0);

  if (not AcceptDate) then
    Application.MessageBox('Tanggal check-out harus lebih dari tanggal check-in', 'Data Salah', MB_ICONEXCLAMATION)
  else begin
    Label4.Caption := Format('Total Hari: %d', [DaysBetween(DateEdit1.Date, ADate)]);
    valid := true;
  end;
end;

procedure TfrmAddRoom.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  frmAddCustomer.Enabled := true;
end;

procedure TfrmAddRoom.FormCreate(Sender: TObject);
begin

end;

procedure TfrmAddRoom.FormShow(Sender: TObject);
var
  i: integer;
begin
  CheckListBox1.Clear;
  for i := 0 to Length(frmAddCustomer.tmp_id)-1 do
  	CheckListBox1.Items.Add(Format('%s (%s)', [frmAddCustomer.tmp_nama[i], frmAddCustomer.tmp_jenis[i]]));

  DateEdit1.Clear;
  DateEdit2.Clear;
  Label4.Caption := 'Total Hari: 0';
  DateEdit2.Enabled := false;

  valid := false;
end;

end.

