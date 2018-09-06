
unit exportform;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmExport = class(TForm)
    RadioGroup1: TRadioGroup;
    Button1: TButton;
    Button2: TButton;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmExport: TfrmExport;

implementation

{$R *.dfm}

procedure TfrmExport.Button1Click(Sender: TObject);
begin
  modalresult:=mrCancel;
end;

procedure TfrmExport.Button2Click(Sender: TObject);
begin
  modalresult:=mrOK;
end;

procedure TfrmExport.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if key=#27 then
  modalresult:=mrCancel;
end;

end.
