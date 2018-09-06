unit FMX.frmhexmgrlicense;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, FMX.Edit, FMX.Ani,
  FMX.Colors;

type
  TfrmLicenseProperties = class(TForm)
    pnlHeader: TPanel;
    pnlMainContainer: TPanel;
    lblHeaderCaption: TLabel;
    MainLayout: TLayout;
    pnlRight: TPanel;
    pnlCodeBox: TPanel;
    lbSerial: TLabel;
    edKeyCode: TEdit;
    btnBack: TSpeedButton;
    pnlTopContainer: TPanel;
    pnlInfoContainer: TPanel;
    pnlProviderBox: TPanel;
    lbl1: TLabel;
    lbProvider: TLabel;
    pnlSoftwareBox: TPanel;
    lbl2: TLabel;
    lbSoftware: TLabel;
    pnlCreatedBox: TPanel;
    lbl3: TLabel;
    lbCreated: TLabel;
    pnlDurationBox: TPanel;
    lbl4: TLabel;
    lbDuration: TLabel;
    pnlExpiresBox: TPanel;
    lbl5: TLabel;
    lbExpires: TLabel;
    pnlProgressBox: TPanel;
    nProgress: TProgressBar;
    lbLeft: TLabel;
    pnlBottomBar: TPanel;
    btnRegister: TButton;
    imgAppLogo: TImage;
    tbMain: TToolBar;
    clBoxToolBar: TColorBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

//var
//  frmLicenseProperties: TfrmLicenseProperties;

implementation

{$R *.fmx}

procedure TfrmLicenseProperties.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

end.
