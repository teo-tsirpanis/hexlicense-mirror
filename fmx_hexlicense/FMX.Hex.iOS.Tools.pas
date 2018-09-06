unit FMX.Hex.iOS.Tools;

(* Notes:
   Parts of this code is based on Sebastian Z's code. It was commited to
   StackOverflow here:
   http://stackoverflow.com/questions/30536457/ip-address-of-ios-device *)

interface

uses
  (* Standard units *)
  System.SysUtils, System.Classes,

  (* Indy units *)
  idCTypes, idException, IdStack, IdStackConsts, IdGlobal,
  IdStackBSDBase, IdStackVCLPosix,

  (* Posix *)
  Posix.Base, Posix.NetIf, Posix.NetinetIn;

type
  TIdStackLocalAddressIPv4Ex = class(TIdStackLocalAddressIPv4)
  protected
    FFlags: Cardinal;
    FIfaName: string;
  public
    function IsWifi: Boolean;
    function IsPPP: Boolean;
    property IfaName: string read FIfaName;
    constructor Create(ACollection: TCollection;
      const AIPAddress, ASubNetMask: string;
      AName: MarshaledAString; AFlags: Cardinal); reintroduce;
  end;

  TIdStackLocalAddressIPv6Ex = class(TIdStackLocalAddressIPv6)
  protected
    FFlags: Cardinal;
    FIfaName: string;
  public
    function IsWifi: Boolean;
    function IsPPP: Boolean;
    property IfaName: string read FIfaName;
    constructor Create(ACollection: TCollection; const AIPAddress: string;
      AName: MarshaledAString; AFlags: Cardinal); reintroduce;
  end;

  TIdStackVCLPosixEx = class(TIdStackVCLPosix)
  public
    procedure GetLocalAddressList(AAddresses: TIdStackLocalAddressList); override;
  end;

implementation

uses System.Types, FMX.Types;


function getifaddrs(ifap: pifaddrs): Integer;
cdecl; external libc name _PU + 'getifaddrs'; {do not localize}

procedure freeifaddrs(ifap: pifaddrs);
cdecl; external libc name _PU + 'freeifaddrs'; {do not localize}


const
  IFF_UP = $1;
  IFF_BROADCAST = $2;
  IFF_LOOPBACK = $8;
  IFF_POINTOPOINT = $10;
  IFF_MULTICAST = $8000;

procedure TIdStackVCLPosixEx.GetLocalAddressList(AAddresses: TIdStackLocalAddressList);
var
  LAddrList, LAddrInfo: pifaddrs;
  LSubNetStr: String;
begin
  if getifaddrs(@LAddrList) = 0 then
  try
    AAddresses.BeginUpdate;
    try
      LAddrInfo := LAddrList;
      repeat
        if (LAddrInfo^.ifa_addr <> nil) and ((LAddrInfo^.ifa_flags and IFF_LOOPBACK) = 0) then
        begin
          case LAddrInfo^.ifa_addr^.sa_family of
          Id_PF_INET4:
            begin
              if LAddrInfo^.ifa_netmask <> nil then
              begin
                LSubNetStr := TranslateTInAddrToString( PSockAddr_In(LAddrInfo^.ifa_netmask)^.sin_addr, Id_IPv4);
              end else
              begin
                LSubNetStr := '';
              end;

              TIdStackLocalAddressIPv4Ex.Create(AAddresses,
              TranslateTInAddrToString( PSockAddr_In(LAddrInfo^.ifa_addr)^.sin_addr,
              Id_IPv4), LSubNetStr, LAddrInfo^.ifa_name, LAddrInfo^.ifa_flags);
            end;
          Id_PF_INET6:
            begin
              TIdStackLocalAddressIPv6Ex.Create(AAddresses,
              TranslateTInAddrToString( PSockAddr_In6(LAddrInfo^.ifa_addr)^.sin6_addr,
              Id_IPv6), LAddrInfo^.ifa_name, LAddrInfo^.ifa_flags);
            end;
          end;
        end;
        LAddrInfo := LAddrInfo^.ifa_next;
      until LAddrInfo = nil;
    finally
      AAddresses.EndUpdate;
    end;
  finally
    freeifaddrs(LAddrList);
  end;
end;


{ TIdStackLocalAddressIPv4Ex }

constructor TIdStackLocalAddressIPv4Ex.Create(ACollection: TCollection;
  const AIPAddress, ASubNetMask: string; AName: MarshaledAString; AFlags: Cardinal);
begin
  inherited Create(ACollection, AIPAddress, ASubnetMask);
  FFlags := AFlags;
  if Assigned(AName) then
    FIfaName := AName;
end;

function TIdStackLocalAddressIPv4Ex.IsPPP: Boolean;
// The network connection to the carrier is established via PPP
// so GPRS, EDGE, UMTS connections have the flag IFF_POINTOPOINT set
begin
  Result := (FFlags and (IFF_UP or IFF_POINTOPOINT) = (IFF_UP or IFF_POINTOPOINT))
            and (FFlags and (IFF_LOOPBACK) = 0);
end;

function TIdStackLocalAddressIPv4Ex.IsWifi: Boolean;
// WLAN connections support Multicast
// WLAN connections do not use PPP
// Filter out the loopback interface (just for completeness, in case the
//  network enumeration is changed so that loopback is also included)
begin
  Result := ((FFlags and (IFF_UP or IFF_MULTICAST)) = (IFF_UP or IFF_MULTICAST))
         and (FFlags and (IFF_LOOPBACK or IFF_POINTOPOINT) = 0);
end;

{ TIdStackLocalAddressIPv6Ex }

constructor TIdStackLocalAddressIPv6Ex.Create(ACollection: TCollection;
  const AIPAddress: string; AName: MarshaledAString; AFlags: Cardinal);
begin
  inherited Create(ACollection, AIPAddress);
  FFlags := AFlags;
  if Assigned(AName) then
    FIfaName := AName;
end;

function TIdStackLocalAddressIPv6Ex.IsPPP: Boolean;
begin
  Result := (FFlags and (IFF_UP or IFF_POINTOPOINT) = (IFF_UP or IFF_POINTOPOINT))
            and (FFlags and (IFF_LOOPBACK) = 0);
end;

function TIdStackLocalAddressIPv6Ex.IsWifi: Boolean;
begin
  Result := ((FFlags and (IFF_UP or IFF_MULTICAST)) = (IFF_UP or IFF_MULTICAST))
         and (FFlags and (IFF_LOOPBACK or IFF_POINTOPOINT) = 0);
end;

initialization
begin
  SetStackClass(TIdStackVCLPosixEx);
end;

end.

