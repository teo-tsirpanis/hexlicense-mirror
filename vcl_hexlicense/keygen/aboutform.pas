
unit aboutform;

interface

uses
  pngimage,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ActnList,
  Vcl.ExtActns, Vcl.ExtCtrls, System.Actions;

type
  TfrmAbout = class(TForm)
    GroupBox1: TGroupBox;
    lbTitle: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ActionList1: TActionList;
    acToWebsite: TBrowseURL;
    Label5: TLabel;
    Label6: TLabel;
    Button1: TButton;
    Image1: TImage;
    procedure LinkLabel1Click(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmAbout: TfrmAbout;

implementation

{$R *.dfm}
uses hexmgrlicense;

procedure TfrmAbout.Button1Click(Sender: TObject);
begin
  modalresult:=mrOK;
end;

procedure TfrmAbout.FormCreate(Sender: TObject);
var
  mtext:  String;
begin
  mtext:=lbTitle.Caption;
  lbTitle.Caption:=mText + ' -  version' + THexLicense.getVersionText;
end;

procedure TfrmAbout.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if key=#27 then
  modalresult:=mrOK;
end;

procedure TfrmAbout.LinkLabel1Click(Sender: TObject);
begin
  acToWebsite.Execute;
end;

end.
