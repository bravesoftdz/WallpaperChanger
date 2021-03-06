unit OSUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TOSFamily = (F_WINDOWS, F_LINUX, F_MAC, F_UNKNOWN);

const
  // TODO add preprocessor
  PATH_SEPARATOR = '/';
  OS_FAMILY = F_LINUX;

function IsAbsolutePath(Path : String) : Boolean;
function GetAbsolutePath(Path : String) : String;

implementation

function IsAbsolutePath(Path: String): Boolean;
const
  ALPHA_CHARS = ['A'..'Z', 'a'..'z'];
begin
  case OS_FAMILY of
    F_LINUX,
    F_MAC:
      Result := Path[1] = '/';
    F_WINDOWS:
      begin
        if (Length(Path) >=3) then
          Result := (Path[1] in ALPHA_CHARS) and (Path[2] = ':') and (Path[3] = PATH_SEPARATOR)
        else
          Result := False;
      end
    else
      Result := False;
  end;
end;

function GetAbsolutePath(Path: String): String;
begin
  if (not IsAbsolutePath(Path)) then
    Result := GetCurrentDir() + PATH_SEPARATOR + Path
  else
    Result := Path;
end;

end.

