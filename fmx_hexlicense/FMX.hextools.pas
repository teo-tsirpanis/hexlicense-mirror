unit FMX.hextools;

{$I FMX.hexlicense.inc}

interface

uses
  {$IFDEF VCL_TARGET}
    {$IFDEF USE_NEW_UNITNAMES}
    System.SysUtils, System.classes, System.Variants, WinAPI.Windows;
    {$ELSE}
    Sysutils, Classes, Variants, Windows;
    {$ENDIF}
  {$ENDIF}

  {$IFDEF FMX_TARGET}
    System.SysUtils, System.classes, System.Variants
    {$IFDEF MSWINDOWS} ,WinAPI.Windows {$ENDIF}
    ,System.dateutils;
  {$ENDIF}

type

// Note: Prior to Delphi 2008, NativeInt was treated as Int64 [8 bytes].
// This was actually done by mistake at Borland. NativeInt should reflect
// the size of the CPU's data and addresse registers. A 64-bit CPU moves
// an UInt64 faster than it does Uint32
{$IFDEF PATCH_NATIVE_INT}
NativeInt = Integer;
{$ENDIF}

THexTools = class(TInterfacedObject)
private
  FLastError: string;
protected
  procedure SetLastError(const ErrorText: string); virtual;
  procedure ClearLastError; virtual;
  function GetFailed: boolean; virtual;
public
  property LastError: string read FLastError;
  property Failed: boolean read GetFailed;

  class function CalcCRC(const Stream: TStream): longword; virtual;
  function DiskSerial: string; virtual; abstract;
  function MacAddress: string; virtual; abstract;
  function IPAddress: string; virtual; abstract;
end;

{$IFDEF MSWINDOWS}
THexToolsWindows = class(THexTools)
private
  FSWbemLocator : OLEVariant;
  FWMIService   : OLEVariant;
protected
  function GetWMIstring(const WMIclass, WMIproperty: string): string;
public
  function DebuggerRunning: boolean; virtual;
  function RunningFromIDE: boolean; virtual;
  function DiskSerial: string; override;
  function MacAddress: string; override;
  function IPAddress: string; override;
end;
{$ENDIF}

{$IFDEF IOS}
THexToolsIOS = class(THexTools)
public
  function DiskSerial: string; override;
  function MacAddress: string; override;
  function IPAddress: string; override;
end;
{$ENDIF}

{$IFDEF ANDROID}
THexToolsAndroid = class(THexTools)
public
  function DiskSerial: string; override;
  function MacAddress: string; override;
  function IPAddress: string; override;
end;
{$ENDIF}

{$IFDEF OSX}
THexToolsOSX = class(THexTools)
public
  function DiskSerial: string; override;
  function MacAddress: string; override;
  function IPAddress: string; override;
end;
{$ENDIF}

function GetHexTools(var Access: THexTools): boolean;

implementation

{$IFDEF MSWINDOWS}
uses ActiveX, Winsock, ComObj, nb30;
{$ENDIF}

{$IFDEF ANDROID}
uses  Androidapi.Helpers,
      Androidapi.JNI,
      Androidapi.JNIBridge,
      Androidapi.JNI.GraphicsContentViewText,
      Androidapi.JNI.JavaTypes,
      Androidapi.JNI.Provider,
      FMX.Helpers.Android,
      FMX.Hex.Android.Tools;
{$ENDIF}

{$IFDEF IOS}
uses iOSApi.UIKit, FMX.Hex.iOS.Tools, idStack;
{$ENDIF}

{$IFDEF OSX}
uses  Macapi.IOKit,
      Macapi.CoreFoundation,
      Macapi.Mach,
      Macapi.Helpers,

      Posix.Base,
      Posix.SysSocket,
      Posix.NetIf,
      Posix.NetinetIn,
      Posix.ArpaInet
      ;
{$ENDIF}

resourcestring
CNT_UNKNOWN = 'unknown';

function GetHexTools(var Access: THexTools): boolean;
begin
  result := false;
  Access := nil;

  try
    {$IFDEF MSWINDOWS}
    Access := THexToolsWindows.Create;
    result := true;
    {$ENDIF}

    {$IFDEF OSX}
    Access := THexToolsOSX.Create;
    result := true;
    {$ENDIF}

    {$IFDEF ANDROID}
    Access := THexToolsAndroid.Create;
    result := true;
    {$ENDIF}

    {$IFDEF IOS}
    Access := THexToolsIOS.Create;
    result := true;
    {$ENDIF}
  except
    on exception do;
  end;
end;

//###########################################################################
// THexToolsOSX
//###########################################################################
{$IFDEF OSX}
type
  u_char = UInt8;
  u_short = UInt16;

  sockaddr_dl = record
    sdl_len: u_char;    //* Total length of sockaddr */
    sdl_family: u_char; //* AF_LINK */
    sdl_index: u_short; //* if != 0, system given index for interface */
    sdl_type: u_char;   //* interface type */
    sdl_nlen: u_char;   //* interface name length, no trailing 0 reqd. */
    sdl_alen: u_char;   //* link level address length */
    sdl_slen: u_char;   //* link layer selector length */
    sdl_data: array[0..11] of AnsiChar; //* minimum work area, can be larger;
  end;
  psockaddr_dl = ^sockaddr_dl;

const
  IFT_ETHER = $6;  //if_types.h

function getifaddrs(var ifap: pifaddrs): Integer; cdecl;
   external libc name _PU + 'getifaddrs';{$EXTERNALSYM getifaddrs}


procedure freeifaddrs(ifp: pifaddrs); cdecl;
   external libc name _PU + 'freeifaddrs';{$EXTERNALSYM freeifaddrs}


function THexToolsOSX.DiskSerial: string;
var
  PlatformExpert: io_service_t;
  LRef: CFMutableDictionaryRef;
  LSerial: CFTypeRef;
  LBuffer: PAnsiChar;
begin
  result := CNT_UNKNOWN;
  try
    LRef := IOServiceMatching('IOPlatformExpertDevice');
    if (LRef <> nil) then
    begin
      PlatformExpert := IOServiceGetMatchingService(kIOMasterPortDefault,CFDictionaryRef(LRef));
      if (PlatformExpert <> 0) then
      begin
        try
          LSerial := IORegistryEntryCreateCFProperty
            (PlatformExpert, CFSTR('IOPlatformSerialNumber'),kCFAllocatorDefault,0);

          LBuffer := CFStringGetCStringPtr( LSerial, 0);

          result := String(AnsiString(LBuffer));
        finally
          IOObjectRelease(PlatformExpert);
        end;
      end;
    end;
  except
    on e: exception do
      SetLastError(e.message);
  end;
end;

function THexToolsOSX.MacAddress: string;
var
  ifap, Next: pifaddrs;
  sdp : psockaddr_dl;
  MacAddr : array[0..5] of Byte;
  LCurrentName: AnsiString;
  ip: AnsiString;
begin
  result := CNT_UNKNOWN;
  ClearLastError();
  try
    try
      if getifaddrs(ifap) <> 0 then
      exit;

      SetLength(ip, INET6_ADDRSTRLEN);
      Next := ifap;
      while (Next <> nil) do
      begin
        if LCurrentName <> AnsiString(Next.ifa_name) then
        LCurrentName := AnsiString(Next.ifa_name);

        case Next.ifa_addr.sa_family of
        AF_LINK :
          begin
            sdp := psockaddr_dl(Next.ifa_addr);
            if sdp.sdl_type = IFT_ETHER then
            begin
              Move(Pointer(PAnsiChar(@sdp^.sdl_data[0]) + sdp.sdl_nlen)^, MacAddr, 6);
              result := format('%x:%x:%x:%x:%x:%x',
                [ MacAddr[0],
                  MacAddr[1],
                  MacAddr[2],
                  MacAddr[3],
                  MacAddr[4],
                  MacAddr[5]]);
              break;
            end;
          end;
        end;
        Next := Next.ifa_next;
      end;
    finally
      freeifaddrs(ifap);
    end;
  except
    on e: exception do
      SetLastError(e.message);
  end;
end;

function THexToolsOSX.IPAddress: string;
var
  ifap, Next: pifaddrs;
  LCurrentName: AnsiString;
  ip: AnsiString;
  LTemp: string;
begin
  result := '';
  ClearLastError();
  try
    try
      if getifaddrs(ifap) <> 0 then
      begin
        SetLastError('Failed to get interface address, call to getifaddrs() failed error');
        exit;
      end;

      SetLength(ip, INET6_ADDRSTRLEN);
      Next := ifap;
      while (Next <> nil) do
      begin
        if LCurrentName <> AnsiString(Next.ifa_name) then
          LCurrentName := AnsiString(Next.ifa_name);

        case Next.ifa_addr.sa_family of
        AF_INET, AF_INET6:
          begin
            FillChar(Pointer(ip)^, INET6_ADDRSTRLEN, #0);
            inet_ntop(Next.ifa_addr.sa_family,
            @psockaddr_in(Next.ifa_addr)^.sin_addr, PAnsiChar(IP), INET6_ADDRSTRLEN);

            LTemp := IP;
            LTemp := LTemp.Trim();

            if (LTemp <> '127.0.0.1')
            and ( pos(':',LTemp)<1 )
            and ( LTemp.length >= 9)
            begin
              result := LTemp;
              break;
            end;

          end;
        end;
        Next := Next.ifa_next;
      end;
    finally
      freeifaddrs(ifap);
    end;
  except
    on e: exception do
      SetLastError(e.message);
  end;
end;

{$ENDIF}

//###########################################################################
// THexToolsAndroid
//###########################################################################

{$IFDEF ANDROID}
function THexToolsAndroid.DiskSerial: string;
begin
  result := CNT_UNKNOWN;
  ClearLastError();
  try
    result := JStringToString(TJSettings_SECURE.JavaClass.getString
    (SharedActivity.getContentResolver, TJSettings_SECURE.JavaClass.ANDROID_ID));
  except
    on e: exception do
      SetLastError(e.message);
  end;
end;

function THexToolsAndroid.MacAddress: string;
var
  WifiManagerObj: JObject;
  WifiManager: JWifiManager;
  WifiInfo: JWifiInfo;
begin
  result := CNT_UNKNOWN;
  ClearLastError();
  try
    WifiManagerObj := SharedActivityContext.getSystemService(TJContext.JavaClass.WIFI_SERVICE);
    WifiManager := TJWifiManager.Wrap((WifiManagerObj as ILocalObject).GetObjectID);
    WifiInfo := WifiManager.getConnectionInfo();
    //if WifiManager.isWifiEnabled then
    result := JStringToString(WifiInfo.getMacAddress);
  except
    on e: exception do
    SetLastError(e.Message);
  end;
end;

function THexToolsAndroid.IPAddress: string;
var
  WifiManagerObj: JObject;
  WifiManager: JWifiManager;
  WifiInfo: JWifiInfo;
  LIp: integer;
begin
  result := CNT_UNKNOWN;
  ClearLastError();
  try
    WifiManagerObj := SharedActivityContext.getSystemService(TJContext.JavaClass.WIFI_SERVICE);
    WifiManager := TJWifiManager.Wrap((WifiManagerObj as ILocalObject).GetObjectID);
    WifiInfo := WifiManager.getConnectionInfo();
    if WifiManager.isWifiEnabled then
    begin
      (* For some reason they pack the IP into a longword. Which makes you
         wonder: they use java which is bloated beyond belief.. yet they want
         to save a few bytes on a string. Go figure *)
      LIp := WifiInfo.getIpAddress();

      result := IntToStr( $FF and byte(LIP) ) + '.' +
                IntToStr( $FF and byte(LIP shr 8) ) + '.' +
                IntToStr( $FF and byte(LIP shr 16) ) + '.' +
                IntToStr( $FF and byte(LIP shr 24) );
    end;
  except
    on e: exception do
      SetLastError(e.Message);
  end;
end;
{$ENDIF}

//###########################################################################
// THexToolsIOS
//###########################################################################

{$IFDEF IOS}
function THexToolsIOS.DiskSerial: string;
var
  LDevice: UIDevice;
begin
  result := CNT_UNKNOWN;
  ClearLastError();
  try
    if TOSVersion.Major < 6 then
    begin
      LDevice := TUIDevice.Wrap(TUIDevice.OCClass.currentDevice);
      result := UTF8ToString( LDevice.uniqueIdentifier.UTF8String );
    end else
    begin
      LDevice := TUIDevice.Wrap(TUIDevice.OCClass.currentDevice);
      result := UTF8ToString( LDevice.identifierForVendor.UUIDString.UTF8String );
    end;
  except
    on e: exception do
    SetLastError(e.Message);
  end;
end;

function THexToolsIOS.MacAddress: string;
begin
  (* In iOS 7 and later, if you ask for the MAC address of an iOS device,
     the system returns the value 02:00:00:00:00:00. If you need to identify
     the device, use the identifierForVendor property of UIDevice instead.

     Source: https://developer.apple.com/library/content/releasenotes/General/WhatsNewIniOS/Articles/iOS7.html#//apple_ref/doc/uid/TP40013162-SW34 *)
  result := DiskSerial;
end;

function THexToolsIOS.IPAddress: string;
var
  LocalIPs: TIdStackLocalAddressList;
  x: integer;
  LIsWifi: boolean;
begin
  result := CNT_UNKNOWN;
  ClearLastError();
  try
    TIdStack.IncUsage;
    try
      LocalIPs := TIdStackLocalAddressList.Create;
      try
        GStack.GetLocalAddressList(LocalIPs);
        for x := 0 to LocalIPs.Count - 1 do
        begin
          if (LocalIPs[x] is TIdStackLocalAddressIPv4Ex) then
          begin
            LIsWifi := TIdStackLocalAddressIPv4Ex(LocalIPs[x]).IsWifi;
            if LIsWifi then
            begin
              result := LocalIPs[x].IPAddress;
              break;
            end;
          end;
        end;
      finally
        LocalIPs.Free;
      end;
    finally
      TIdStack.DecUsage;
    end;
  except
    on e: exception do
    SetLastError(e.Message);
  end;
end;
{$ENDIF}

//###########################################################################
// THexToolsWindows
//###########################################################################

{$IFDEF MSWINDOWS}
function THexToolsWindows.GetWMIString(const WMIclass, WMIproperty: string): string;
const
  wbemFlagForwardOnly = $00000020;
var
  LWbemObjectSet: OLEVariant;
  LWbemObject: OLEVariant;
  LEnum: IEnumvariant;
  LValue: longWord;
  LQuery: string;
begin;
  result:='';

  LQuery:=Format('Select %s from %s', [WMIproperty, WMIClass]);
  LWbemObjectSet:= FWMIService.ExecQuery(LQuery,'WQL',wbemFlagForwardOnly);

  LEnum := IUnknown(LWbemObjectSet._NewEnum) as IEnumVariant;
  if assigned(LEnum) then
  begin
    if LEnum.Next(1, LWbemObject, LValue) = 0 then
    begin
      if not VarIsNull(LWbemObject.Properties_.Item(WMIproperty).Value) then
        result := LWbemObject.Properties_.Item(WMIproperty).Value;
    end;
  end;
  LWbemObject := unassigned;
end;

function THexToolsWindows.DiskSerial: string;
begin
  ClearLastError;
  result := CNT_UNKNOWN;
  try
    FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    FWMIService := FSWbemLocator.ConnectServer('localhost', 'root\CIMV2', '', '');
    result := GetWMIstring('Win32_BIOS','SerialNumber');
  except
    on e: exception do
    begin
      SetLastError(e.Message);
    end;
  end;
end;

function THexToolsWindows.MacAddress: string;
const
  CNT_MAC_BLANK = '00-00-00-00-00-00';   // DO NOT CHANGE
  CNT_MAC_MASK  = '%s-%s-%s-%s-%s-%s';   // DO NOT CHANGE
var
  NCB: PNCB;
  Adapter: PAdapterStatus;
  RetCode: Ansichar;
  I: integer;
  Lenum: PlanaEnum;
  _SystemID: string;

  function CompileMac(const aAdapter: PAdapterStatus): string;
  begin
    result := format(CNT_MAC_MASK,
      [ IntToHex(Ord(aAdapter.adapter_address[0]),2),
        IntToHex(Ord(aAdapter.adapter_address[1]),2),
        IntToHex(Ord(aAdapter.adapter_address[2]),2),
        IntToHex(Ord(aAdapter.adapter_address[3]),2),
        IntToHex(Ord(aAdapter.adapter_address[4]),2),
        IntToHex(Ord(aAdapter.adapter_address[5]),2)
      ]);
  end;

begin
  result := CNT_UNKNOWN;
  ClearLastError;
  try
    _SystemID := '';
    Getmem(NCB, SizeOf(TNCB));
    Fillchar(NCB^, SizeOf(TNCB), 0);

    Getmem(Lenum, SizeOf(TLanaEnum));
    Fillchar(Lenum^, SizeOf(TLanaEnum), 0);

    Getmem(Adapter, SizeOf(TAdapterStatus));
    Fillchar(Adapter^, SizeOf(TAdapterStatus), 0);

    Lenum.Length    := chr(0);
    NCB.ncb_command := chr(NCBENUM);
    NCB.ncb_buffer  := Pointer(Lenum);
    NCB.ncb_length  := SizeOf(Lenum);
    Netbios(NCB);

    i := 0;
    repeat
      Fillchar(NCB^, SizeOf(TNCB), 0);
      Ncb.ncb_command  := chr(NCBRESET);
      Ncb.ncb_lana_num := lenum.lana[I];
      Netbios(Ncb);

      Fillchar(NCB^, SizeOf(TNCB), 0);
      Ncb.ncb_command  := chr(NCBASTAT);
      Ncb.ncb_lana_num := lenum.lana[I];
      Ncb.ncb_callname := '*               ';

      Ncb.ncb_buffer := Pointer(Adapter);

      Ncb.ncb_length := SizeOf(TAdapterStatus);
      RetCode        := Netbios(Ncb);

      if (RetCode = chr(0)) or (RetCode = chr(6)) then
      begin
        _SystemId := CompileMac(Adapter);
      end;
      Inc(i);
    until (I >= Ord(Lenum.Length)) or (_SystemID <> '00-00-00-00-00-00');
    FreeMem(NCB);
    FreeMem(Adapter);
    FreeMem(Lenum);
    result := _SystemID;
  except
    on e: exception do
      SetLastError(e.Message);
  end;
end;

function THexToolsWindows.IPAddress: string;
const
  CNT_IP_LOCALHOST = '127.0.0.1';
type
  pu_long = ^u_long;
var
  LTWSAData: TWSAData;
  LPHostEnt: PHostEnt;
  LInAddr: TInAddr;
  LNamebuf: packed Array[0..255] of ansichar;
  LRef: PAnsiChar;
begin
  result := CNT_UNKNOWN;
  ClearLastError;

  // Note: Windows supports WSA version 1.0, 1,1, 2.0, 2.1 and 2.2
  //       But in our case we are using functions that have been a part of
  //       WinSock since the late bronze age, so version 1.1 ($101)
  //       is equal to Windows 98. That should be safe enough.
  If WSAStartup($101,LTWSAData) = 0 Then
  Begin
    // Make sure our buffer is clear
    fillchar(LNameBuf,SizeOf(LNameBuf),0);

    try
      if GetHostName(LNamebuf,sizeof(LNamebuf)) <>  SOCKET_ERROR then
      begin
        LPHostEnt := GetHostByName(LNamebuf);
        if LPHostEnt <> nil then
        begin
          LInAddr.S_addr := u_long(pu_long(LPHostEnt^.h_addr_list^)^);
          LRef := inet_ntoa(LInAddr);
          if LRef <> nil then
          begin
            // success, return as proper string
            result := string(LRef);
          end else
          begin
            result := CNT_IP_LOCALHOST;
            SetLastError(SysErrorMessage(WSAGetLastError));
          end;
        end else
        begin
          result := CNT_IP_LOCALHOST;
          SetLastError(SysErrorMessage(WSAGetLastError));
        end;
      end else
      begin
        result := CNT_IP_LOCALHOST;
        SetLastError(SysErrorMessage(WSAGetLastError));
      end;
    finally
      WSACleanup;
    end;
  end;
end;

function THexToolsWindows.DebuggerRunning:boolean;
Begin
  result := IsDebuggerPresent;
end;

function THexToolsWindows.RunningFromIDE:boolean;

  // Reference: https://msdn.microsoft.com/en-us/library/windows/desktop/ms633499(v=vs.85).aspx
  function WindowIsOpen(AppWindowName, AppClassName: string): boolean;
  var
    LRes: HWND;
  begin
    LRes := FindWindow(PChar(AppWindowName), PChar(AppClassName));
    result := LRes <> 0;
  end;

Begin
  result := false;
  ClearLastError;
  try
    if system.DebugHook <> 0 then
    begin
      result := true;
      exit;
    end;

    result := WindowIsOpen('TPropertyInspector','Object Inspector')
    or WindowIsOpen('TMenuBuilder','Menu Designer')
    or WindowIsOpen('TAppBuilder','(AnyName)')
    or WindowIsOpen('TApplication', 'Delphi')
    or WindowIsOpen('TAlignPalette', 'Align');

    if not result then
    SetLastError( SysErrorMessage(GetLastError) );
  except
    on e: exception do
      SetLastError(e.message);
  end;
end;
{$ENDIF}

//###########################################################################
// THexTools
//###########################################################################

const
  CRC32Table:  ARRAY[0..255] OF LONGWORD =
   ($00000000, $77073096, $EE0E612C, $990951BA,
    $076DC419, $706AF48F, $E963A535, $9E6495A3,
    $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988,
    $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
    $1DB71064, $6AB020F2, $F3B97148, $84BE41DE,
    $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
    $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC,
    $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
    $3B6E20C8, $4C69105E, $D56041E4, $A2677172,
    $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
    $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940,
    $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
    $26D930AC, $51DE003A, $C8D75180, $BFD06116,
    $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
    $2802B89E, $5F058808, $C60CD9B2, $B10BE924,
    $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,
    $76DC4190, $01DB7106, $98D220BC, $EFD5102A,
    $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
    $7807C9A2, $0F00F934, $9609A88E, $E10E9818,
    $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
    $6B6B51F4, $1C6C6162, $856530D8, $F262004E,
    $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
    $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C,
    $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
    $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2,
    $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
    $4369E96A, $346ED9FC, $AD678846, $DA60B8D0,
    $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
    $5005713C, $270241AA, $BE0B1010, $C90C2086,
    $5768B525, $206F85B3, $B966D409, $CE61E49F,
    $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4,
    $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
    $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A,
    $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
    $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8,
    $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
    $F00F9344, $8708A3D2, $1E01F268, $6906C2FE,
    $F762575D, $806567CB, $196C3671, $6E6B06E7,
    $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC,
    $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
    $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252,
    $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
    $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60,
    $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
    $CB61B38C, $BC66831A, $256FD2A0, $5268E236,
    $CC0C7795, $BB0B4703, $220216B9, $5505262F,
    $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04,
    $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
    $9B64C2B0, $EC63F226, $756AA39C, $026D930A,
    $9C0906A9, $EB0E363F, $72076785, $05005713,
    $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38,
    $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
    $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E,
    $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
    $88085AE6, $FF0F6A70, $66063BCA, $11010B5C,
    $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
    $A00AE278, $D70DD2EE, $4E048354, $3903B3C2,
    $A7672661, $D06016F7, $4969474D, $3E6E77DB,
    $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0,
    $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
    $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6,
    $BAD03605, $CDD70693, $54DE5729, $23D967BF,
    $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94,
    $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);

procedure THexTools.SetLastError(const ErrorText: string);
begin
  FLastError := ErrorText;
end;

procedure THexTools.ClearLastError;
begin
  FLastError := '';
end;

function THexTools.GetFailed: boolean;
begin
  result := length(FLastError) > 0;
end;

class function THexTools.CalcCRC(const Stream: TStream): longword;
var
  aMemStream: TMemoryStream;
  aValue: Byte;
begin
  aMemStream := TMemoryStream.Create;
  try
    Result := $FFFFFFFF;
    while Stream.Position < Stream.Size do
    begin
      aMemStream.Seek(0, soFromBeginning);
      if (Stream.Size - Stream.Position) >= 1024*1024 then
      aMemStream.CopyFrom(Stream, 1024*1024) else
      begin
        aMemStream.Clear;
        aMemStream.CopyFrom(Stream, Stream.Size-Stream.Position);
      end;

      aMemStream.Seek(0, soFromBeginning);
      while (aMemStream.Position < aMemStream.Size) do
      begin
        aMemStream.ReadBuffer(aValue, 1);
        Result := (Result shr 8) xor CRC32Table[aValue xor (Result and $000000FF)];
      end;
    end;
    Result := not Result;
  finally
    aMemStream.Free;
  end;
end;

end.