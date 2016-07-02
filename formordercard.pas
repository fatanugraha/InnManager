unit FormOrderCard;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, sqldb, dateUtils, LCLType,
  ExtCtrls;

type

  { TfrmOrderCard }

  TfrmOrderCard = class(TForm)
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    btnAddCharge: TButton;
    btnSwitch: TButton;
    btnBooked: TButton;
    btnCheckIn: TButton;
    btnCheckOut: TButton;
    btnMemoSave: TButton;
    btnMemoRevert: TButton;
    Button1: TButton;
    Button2: TButton;
    edtAddFood: TLabeledEdit;
    edtAddMisc: TLabeledEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    lblByWho: TLabel;
    lblDate: TLabel;
    lblStatRoom: TLabel;
    lblContact: TLabel;
    lblCheckIn: TLabel;
    lblCheckOut: TLabel;
    lblDuration: TLabel;
    lblNama: TLabel;
    Label5: TLabel;
    edtAddCharge: TLabeledEdit;
    lblInst: TLabel;
    lblStatBill: TLabel;
    lblStatTrans: TLabel;
    Memo1: TMemo;
    Panel1: TPanel;
    procedure btnAddChargeClick(Sender: TObject);
    procedure btnBookedClick(Sender: TObject);
    procedure btnCheckInClick(Sender: TObject);
    procedure btnCheckOutClick(Sender: TObject);
    procedure btnMemoRevertClick(Sender: TObject);
    procedure btnMemoSaveClick(Sender: TObject);
    procedure btnSwitchClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure edtAddChargeChange(Sender: TObject);
    procedure edtAddChargeKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GroupBox1Click(Sender: TObject);
    procedure GroupBox2Click(Sender: TObject);
  private
    final: boolean;
  public
    Col, Row: integer;
    ID: integer;
  end;

var
  frmOrderCard: TfrmOrderCard;

implementation

{$R *.lfm}

{ TfrmOrderCard }

uses
  lib.common, lib.logger, lib.database, FormMain, FormAddCustomer, FormLogin, FormCalendar;

var
  OwnerID, RoomID, status, price, cStatus, cDue, cPaid, cExtra, cFood, cMisc: integer;
  notes, checkin, checkout, RoomName, RoomType, cName, cInst, cContact1, cContact2, cByWho, cDate: string;

procedure TfrmOrderCard.FormCreate(Sender: TObject);
begin

end;

procedure TfrmOrderCard.btnBookedClick(Sender: TObject);
var
  query: TSQLQuery;
begin
  frmMain.dbOrdersQuery.Close;

  lblStatRoom.Caption := 'dipesan (belum ditempati)';
  btnBooked.Enabled   := false;
  btnCheckIn.Enabled  := true;
  btnCheckOut.Enabled := true;

  query := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
  query.SQL.Text := 'UPDATE `orders` SET `status` = 1 WHERE `id` = :id';
  query.ParamByName('id').AsInteger := ID;
  query.ExecSQL;
  frmMain.dbOrdersTransaction.Commit;
  query.Free;

  frmMain.dbOrdersQuery.Open;
  frmCalendar.UpdateStatus(Col, Row, ORDERS_BOOKED);
end;

procedure TfrmOrderCard.btnAddChargeClick(Sender: TObject);
var
  query: TSQLQuery;
  ret: integer;
begin
  ret := Application.MessageBox(PChar(Format('Tambahkan %s ke total biaya pelanggan?', [edtAddCharge.Text])),
                               'Konfirmasi', MB_ICONQUESTION or MB_YESNOCANCEL);

  if ret <> ID_YES then
    exit;

  Inc(cDue, UnGroupDigits(edtAddCharge.Text));
  Inc(cExtra, UnGroupDigits(edtAddCharge.Text));

  query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  query.SQL.Text := 'UPDATE `data` SET `bill_add` = :bill_add WHERE `id` = :owner_id';
  query.ParamByName('bill_add').AsInteger := cExtra;
  Notes := Memo1.Text;
  query.ParamByName('owner_id').AsInteger := ownerID;
  query.ExecSQL;
  frmMain.dbCustomersTransaction.Commit;
  query.Free;

  if (cPaid = cDue) or (cStatus = 1) then
    lblStatBill.Caption := 'Lunas'
  else if cPaid < cDue then
    lblStatBill.Caption := 'Parsial (DP)'
  else
    lblStatBill.Caption := 'Belum Bayar';

  edtAddCharge.Text := '0';
end;

procedure TfrmOrderCard.btnCheckInClick(Sender: TObject);
var
  query: TSQLQuery;
begin
  frmMain.dbOrdersQuery.Close;

  lblStatRoom.Caption := 'telah check-in';
  btnBooked.Enabled   := true;
  btnCheckIn.Enabled  := false;
  btnCheckOut.Enabled := true;

  query := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
  query.SQL.Text := 'UPDATE `orders` SET `status` = 2 WHERE `id` = :id';
  query.ParamByName('id').AsInteger := ID;
  query.ExecSQL;
  frmMain.dbOrdersTransaction.Commit;
  query.Free;

  frmMain.dbOrdersQuery.Open;
  frmCalendar.UpdateStatus(Col, Row, ORDERS_CHECKIN);
end;

procedure TfrmOrderCard.btnCheckOutClick(Sender: TObject);
var
  query: TSQLQuery;
begin
  frmMain.dbOrdersQuery.Close;

  lblStatRoom.Caption := 'telah check-out';
  btnBooked.Enabled   := true;
  btnCheckIn.Enabled  := true;
  btnCheckOut.Enabled := false;

  query := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
  query.SQL.Text := 'UPDATE `orders` SET `status` = 3 WHERE `id` = :id';
  query.ParamByName('id').AsInteger := ID;
  query.ExecSQL;
  frmMain.dbOrdersTransaction.Commit;
  query.Free;

  frmMain.dbOrdersQuery.Open;
  frmCalendar.UpdateStatus(Col, Row, ORDERS_CHECKOUT);
end;

procedure TfrmOrderCard.btnMemoRevertClick(Sender: TObject);
begin
  Memo1.Text := Notes;
end;

procedure TfrmOrderCard.btnMemoSaveClick(Sender: TObject);
var
  query: TSQLQuery;
begin
  query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  query.SQL.Text := 'UPDATE `data` SET `note` = :note WHERE `id` = :owner_id';
  query.ParamByName('note').AsString := Memo1.Text;
  Notes := Memo1.Text;
  query.ParamByName('owner_id').AsInteger := ownerID;
  query.ExecSQL;
  frmMain.dbCustomersTransaction.Commit;
  query.Free;
end;

procedure TfrmOrderCard.btnSwitchClick(Sender: TObject);
begin
  Close;
  frmMain.Enabled := false;
  frmAddCustomer.EditID := OwnerID;
  frmAddCustomer.Show;;
end;

procedure TfrmOrderCard.Button1Click(Sender: TObject);
var
  query: TSQLQuery;
  ret: integer;
begin
  ret := Application.MessageBox(PChar(Format('Tambahkan %s ke biaya makan pelanggan?', [edtAddFood.Text])),
                               'Konfirmasi', MB_ICONQUESTION or MB_YESNOCANCEL);

  if ret <> ID_YES then
    exit;

  Inc(cDue, UnGroupDigits(edtAddFood.Text));
  Inc(cFood, UnGroupDigits(edtAddFood.Text));

  query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  query.SQL.Text := 'UPDATE `data` SET `bill_food` = :bill_food WHERE `id` = :owner_id';
  query.ParamByName('bill_food').AsInteger := cFood;
  Notes := Memo1.Text;
  query.ParamByName('owner_id').AsInteger := ownerID;
  query.ExecSQL;
  frmMain.dbCustomersTransaction.Commit;
  query.Free;

  if (cPaid = cDue) or (cStatus = 1) then
    lblStatBill.Caption := 'Lunas'
  else if cPaid < cDue then
    lblStatBill.Caption := 'Parsial (DP)'
  else
    lblStatBill.Caption := 'Belum Bayar';

  edtAddFood.Text := '0';
end;

procedure TfrmOrderCard.Button2Click(Sender: TObject);
var
  query: TSQLQuery;
  ret: integer;
begin
  ret := Application.MessageBox(PChar(Format('Tambahkan %s ke biaya lain lain pelanggan?', [edtAddMisc.Text])),
                               'Konfirmasi', MB_ICONQUESTION or MB_YESNOCANCEL);

  if ret <> ID_YES then
    exit;

  Inc(cDue, UnGroupDigits(edtAddMisc.Text));
  Inc(cMisc, UnGroupDigits(edtAddMisc.Text));

  query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  query.SQL.Text := 'UPDATE `data` SET `bill_misc` = :bill_misc WHERE `id` = :owner_id';
  query.ParamByName('bill_misc').AsInteger := cMisc;
  Notes := Memo1.Text;
  query.ParamByName('owner_id').AsInteger := ownerID;
  query.ExecSQL;
  frmMain.dbCustomersTransaction.Commit;
  query.Free;

  if (cPaid = cDue) or (cStatus = 1) then
    lblStatBill.Caption := 'Lunas'
  else if cPaid < cDue then
    lblStatBill.Caption := 'Parsial (DP)'
  else
    lblStatBill.Caption := 'Belum Bayar';

  edtAddMisc.Text := '0';
end;

procedure TfrmOrderCard.edtAddChargeChange(Sender: TObject);
begin
  TEdit(Sender).Text     := GroupDigits(UnGroupDigits(TEdit(Sender).Text));
  TEdit(sender).SelStart := Length(TEdit(Sender).Text);
end;

procedure TfrmOrderCard.edtAddChargeKeyPress(Sender: TObject; var Key: char);
begin
  //restrict selain angka sama backspace
  if not(('0' <= key) and (key <= '9') or (key = #8)) then
    key := #0
end;

procedure TfrmOrderCard.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  frmMain.Enabled := true;
end;

procedure TfrmOrderCard.FormShow(Sender: TObject);
var
  query: TSQLQuery;
begin
  edtAddFood.Text := '0';
  edtAddMisc.Text := '0';
  edtAddCharge.Text := '0';

  query := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
  query.SQL.Text := 'SELECT * FROM `orders` WHERE `id` = :id';
  query.ParamByName('id').AsInteger := ID;
  query.Open;
  OwnerID  := query.FieldByName('owner_id').AsInteger;
  RoomID   := query.FieldByName('room_id').AsInteger;
  status   := query.FieldByName('status').AsInteger;
  price    := query.FieldByName('price').AsInteger;
  checkin  := query.FieldByName('checkin').AsString;
  checkout := query.FieldByName('checkout').AsString;
  query.Close;
  query.Free;

  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT `name`,`typename` FROM `product` WHERE `id` = :id';
  query.ParamByName('id').AsInteger := RoomID;
  query.Open;
  RoomName := query.FieldByName('name').AsString;
  RoomType := query.FieldByName('typename').AsString;
  query.Close;
  query.Free;

  query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  query.SQL.Text := 'SELECT * FROM `data` WHERE `id` = :id';
  query.ParamByName('id').AsInteger := OwnerID;
  query.Open;
  cStatus := query.FieldByName('done').AsInteger;
  notes   := query.FieldByName('note').AsString;
  cInst   := query.FieldByName('instance').AsString;
  cName   := query.FieldByName('name').AsString;
  cContact1 := query.FieldByName('contact1').AsString;
  cContact2 := query.FieldByName('contact2').AsString;
  cDue := 0;
  Inc(cDue, query.FieldByName('bill_room').AsInteger);
  Inc(cDue, query.FieldByName('bill_food').AsInteger);
  cFood := query.FieldByName('bill_food').AsInteger;
  Inc(cDue, query.FieldByName('bill_misc').AsInteger);
  cMisc := query.FieldByName('bill_misc').AsInteger;
  Inc(cDue, query.FieldByName('bill_add').AsInteger);
  cExtra := query.FieldByName('bill_add').AsInteger;
  Dec(cDue, query.FieldByName('bill_rem').AsInteger);
  cPaid := query.FieldByName('bill_front').AsInteger;

  cByWho := query.FieldByName('by_who').AsString;
  cDate := query.FieldByName('date_created').AsString;
  final := query.FieldByName('done').AsInteger = 1;
  query.Close;
  Query.Free;

  if cInst = '' then
    cInst := '-';
  if ccontact2 = '' then
    cContact2 := '-';

  //load ke form
  btnBooked.Enabled := true;
  btnCheckIn.Enabled := true;
  btnCheckOut.Enabled := true;

  Label1.Caption := Format('%s (%s)', [RoomName, RoomType]);
  Label2.Caption := Format('Rp%s /hari', [GroupDigits(price)]);
  if status = ORDERS_BOOKED then
  begin
    lblStatRoom.Caption := 'dipesan (belum ditempati)';
    btnBooked.Enabled := false;
  end
  else if status = ORDERS_CHECKIN then
  begin
    lblStatRoom.Caption := 'telah check-in';
    btnCheckIn.Enabled := false;
  end
  else if status = ORDERS_CHECKOUT then
  begin
    lblStatRoom.Caption := 'telah check-out';
    btnCheckOut.Enabled := false;
  end
  else
    lblStatRoom.Caption := 'undefined';

  lblNama.Caption := cName;
  lblInst.Caption := cInst;
  lblContact.Caption := Format('%s / %s', [cContact1, cContact2]);
  lblCheckIn.Caption := checkin;
  lblCheckOut.Caption := checkout;
  lblDuration.Caption := IntToStr(DaysBetween(StrToDate(checkin), StrToDate(checkout))) + ' hari';
  lblDate.Caption     := cDate;

  if (cPaid = cDue) or (cStatus = 1) then
    lblStatBill.Caption := 'Lunas'
  else if cPaid < cDue then
    lblStatBill.Caption := 'Parsial (DP)'
  else
    lblStatBill.Caption := 'Belum Bayar';

  lblByWho.Caption := cbyWho;
  if cStatus = 1 then
    lblStatTrans.caption := 'Transaksi Selesai'
  else
    lblStatTrans.caption := 'Transaksi Berlangsung';

  Memo1.Text := Notes;

  groupbox2.visible := not final;
  btnMemoRevert.Enabled:=not final;
  btnMemoSave.Enabled:=not final;

  if final then
    GroupBox1.Width := Bevel1.Width
  else
    GroupBox1.Width := groupbox2.left-5-groupbox1.left;
end;

procedure TfrmOrderCard.GroupBox1Click(Sender: TObject);
begin

end;

procedure TfrmOrderCard.GroupBox2Click(Sender: TObject);
begin

end;

end.

