unit Form1;

interface

uses
  System.Types,
  System.Time,
  System.Colors,

  System.Stream.Writer,

  hex.types,
  hex.modulators,
  hex.obfuscation,
  hex.serialmatrix,
  hex.serialnumber,
  hex.ironwood,

  SmartCL.Controls.Header,
  SmartCL.Dialogs,
  SMartCL.Controls.Listbox,
  SmartCL.System, SmartCL.Graphics, SmartCL.Components, SmartCL.Forms, 
  SmartCL.Fonts, SmartCL.Borders, SmartCL.Application, SmartCL.Controls.Button,
  SmartCL.Controls.Label, SmartCL.Controls.EditBox, SmartCL.Controls.ComboBox,
  SmartCL.Controls.Memo, SmartCL.Controls.Listbox, SmartCL.Controls.ScrollBox,
  SmartCL.Controls.ToggleSwitch, SmartCL.Controls.Image;

type


  TForm1 = class(TW3Form)
    procedure W3Button1Click(Sender: TObject);
  private
    {$I 'Form1:intf'}
    FHeader: TW3HeaderControl;
  protected
    procedure InitializeForm; override;
    procedure InitializeObject; override;
    procedure Resize; override;
  end;

implementation

//############################################################################
// THexLucasModulator
//############################################################################


{ TForm1 }

procedure TForm1.W3Button1Click(Sender: TObject);
var
  LItems: integer;
  LRoot: THexKeyMatrix;
  x: integer;
  LContent: string;
begin

  for var LByte in LRoot do
  begin
    LByte := 0;
  end;

  // Get the root-key
  var QText := edRootKey.text.trim();
  if QText.length>0 then
  begin
    var temp := QText.Split(',');

    if temp.length <> 12 then
    begin
      showmessage("Invalid root-key, invalid partition seeds error");
      exit;
    end;

    x:=0;
    for var LByte in temp do
    begin
      if not LByte.ContainsHex then
      begin
        writeln("Here:" + LByte);
        showmessage("Invalid root-key, expected hexadecimal seed error");
        exit;
      end;

      LRoot[x] := Copy(LByte,2,2).HexToInteger();
      inc(x);
    end;
  end else
  begin
    showmessage('Invalid root key error');
    exit;
  end;

  // Get the number of items
  try
    LItems := edItems.Text.ToInteger();
  except
    on e: exception do
    begin
      Showmessage('Invalid value, expected normal number');
      edItems.SetFocus;
      exit;
    end;
  end;

  //edGates.enabled := false;
  //cbAlloc.enabled := false;
  edItems.enabled := false;
  edRootKey.enabled := false;
  cbModulators.Enabled := false;
  cbMethod.Enabled := false;
  btnGenerate.Cursor := crWait;
          //edGates.enabled := true;
          //cbAlloc.enabled := true;
  TW3Dispatch.Execute( procedure ()
    begin
      w3Scrollbox1.Content.InnerHTML:='';
      w3Scrollbox1.Update();

      var LGenerator := THexIronwoodGenerator.Create;
      // set the modulation
      case cbModulators.SelectedIndex of
      0: LGenerator.Modulator := THexLeonardoModulator.Create;
      1: LGenerator.Modulator := THexFibonacciModulator.Create;
      2: LGenerator.Modulator := THexLucasModulator.Create;
      end;

      // build parition tables
      try
        LGenerator.Build(LRoot);
      except
        on e: exception do
        begin
          showmessage(e.message);
          edItems.enabled := true;
          edRootKey.enabled := true;
          cbModulators.Enabled := true;
          cbMethod.enabled := true;
          btnGenerate.Cursor := crDefault;
          exit;
        end;
      end;

      LGenerator.OnAcceptSerialNumber := lambda (sender: TObject; serial: string; var OK: boolean)
          LContent += '<p>' + Serial + '</p>' + #13;
          ok := true;
        end;
      LGenerator.OnAfterMinting := lambda (sender: TObject)
          w3Scrollbox1.Content.InnerHTML := LContent;
          w3Scrollbox1.Update;
          LContent := "";

          edItems.enabled := true;
          edRootKey.enabled := true;
          cbModulators.Enabled := true;
          cbMethod.enabled := true;
          btnGenerate.Cursor := crDefault;


        end;

      // set method & mint
      case cbMethod.SelectedIndex of
      0:  LGenerator.Mint(LItems, gmDispersed);
      1:  LGenerator.Mint(LItems, gmCanonical);
      end;

    end,
    300);
end;

procedure TForm1.InitializeForm;
begin
  inherited;
  FHeader.Title.Caption :='Ironwood';

  cbModulators.Add('Leonardo');
  cbModulators.Add('Fibonacci');
  cbModulators.Add('Lucas');
  cbModulators.SelectedIndex := 0;

  cbGematria.add('Sepsephos');
  cbGematria.add('Beatus');
  cbGematria.add('Latin');
  cbGematria.add('Hebrew');
  cbGematria.add('Sanskrit');
  cbGematria.add('Amun');
  cbGematria.SelectedIndex := 0;

  cbMethod.Add('Dispersed');
  cbMethod.Add('Canonical');
  cbMethod.SelectedIndex := 0;

  cbAlloc.TextOn.Container.Font.Color :=clBlack;
  cbAlloc.TextOff.Container.Font.Color := clBlack;

  Fheader.BackButton.Visible := false;
  Fheader.NextButton.Visible := false;
  FHeader.Invalidate;

  btnInfo.OnClick := procedure (sender: TObject)
    begin

        Showmessage(
          #"This demo have a couple of features hardcoded:
            -Gates
            -Obfuscation
            -Range allocation

            These are available in the full product.
            Just click anywhere to close this dialog");

    end;

  w3scrollbox1.Content.Handle.style['color']:='#000000';
end;

procedure TForm1.InitializeObject;
begin
  inherited;
  {$I 'Form1:impl'}
  w3image1.LoadFromURL('res/Ironwood2.png');
  w3Image1.ImageFit := fsFill;

  w3label1.Font.Color := clWhite;
  w3label5.font.color := clWhite;

  FHeader := TW3HeaderControl.Create(Application.Display);
  Fheader.Height := 32;

  Application.Display.LayoutChildren();

end;
 
procedure TForm1.Resize;
begin
  inherited;
end;
 
initialization
  Forms.RegisterForm({$I %FILE%}, TForm1);
end.