
unit numberform;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls;

type
  TfrmNumber = class(TForm)
    Label1: TLabel;
    Edit1: TEdit;
    Button1: TButton;
    TrackBar1: TTrackBar;
    procedure Button1Click(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure TrackBar1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmNumber: TfrmNumber;

implementation

{$R *.dfm}

procedure TfrmNumber.Button1Click(Sender: TObject);
begin
  modalresult:=mrOK;
end;

procedure TfrmNumber.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if key=#27 then
  modalresult:=mrCancel;
end;

procedure TfrmNumber.TrackBar1Change(Sender: TObject);
begin
  edit1.Text:=IntToStr(trackbar1.Position);
end;

end.
