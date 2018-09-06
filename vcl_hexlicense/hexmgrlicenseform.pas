  unit hexmgrlicenseform;

  interface

  {$I 'hexlicense.inc'}

  uses
  {$IFDEF USE_MODERN_UNITNAMES}
  System.SysUtils, System.Classes, WinAPI.Windows, WinAPI.Messages,
  VCL.Graphics, VCL.Controls, VCL.Forms, VCL.Dialogs, VCL.StdCtrls,
  VCL.ExtCtrls, VCL.ComCtrls;
  {$ELSE}
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls;
  {$ENDIF}

  Type TfrmLicenseProperties = class(TForm)
    Panel1: TPanel;
    btnCancel: TButton;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    lbCreated: TLabel;
    Label2: TLabel;
    lbDuration: TLabel;
    Label3: TLabel;
    lbProvider: TLabel;
    Label4: TLabel;
    lbSoftware: TLabel;
    Label6: TLabel;
    lbExpires: TLabel;
    Panel2: TPanel;
    Image1: TImage;
    PageControl1: TPageControl;
    Panel3: TPanel;
    TabSheet1: TTabSheet;
    lbSerial: TLabel;
    edKeyCode: TEdit;
    btnRegister: TButton;
    nProgress: TProgressBar;
    Label8: TLabel;
    lbLeft: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    Procedure BrukerKlikkerRegistrere(Sender:TObject);
    Procedure BrukerKlikkerAvbryt(Sender:TObject);
  public
    { Public declarations }
  end;

  implementation

  {$R *.DFM}

  procedure TfrmLicenseProperties.FormCreate(Sender: TObject);
  begin
    btnRegister.OnClick:=BrukerKlikkerRegistrere;
    btnCancel.OnClick:=BrukerKlikkerAvbryt;
    tabsheet1.Caption:='Register';
    lbserial.Caption:='Serial number:';
    label3.Caption:='Provider: ';
    label4.Caption:='Software: ';
    label1.Caption:='Created: ';
    label2.Caption:='Duration: ';
    label6.Caption:='Expires: ';
    label8.Caption:='License state: ';
  end;

  Procedure TfrmlicenseProperties.BrukerKlikkerRegistrere(Sender:TObject);
  var
    FText:  String;
  begin
    { validate holder information }
    FText:=trim(edKeyCode.Text);
    If Length(FText)<>27 then
    begin
      edKeyCode.SetFocus;
      exit;
    end;
    ModalResult:=mrOK;
  End;

  Procedure TfrmlicenseProperties.BrukerKlikkerAvbryt(Sender:TObject);
  Begin
    ModalResult:=mrCancel;
  End;

  procedure TfrmLicenseProperties.FormShow(Sender: TObject);
  begin
    If edKeyCode.Enabled then
    edKeyCode.SetFocus;
  end;

end.
