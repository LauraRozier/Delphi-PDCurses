unit PDVarArgCaller;
// Public Domain Curses

{
  *----------------------------------------------------------------------*
  *                   Delphi VarArg Caller for PDCurses                  *
  *----------------------------------------------------------------------*


  Helper unit for calling a function with a va_list param from Delphi.

  Credits to: Barry Kelly
  Source: https://stackoverflow.com/a/2306776

  NOTE: This will only work if assembler syntax is supported.
}

{$I PDCurses.inc}

interface

{$IFDEF ASSEMBLER}
uses
  SysUtils;

type
  TVarArgCaller = record
  private
    fStack: array of Byte;
    fTop:   PByte;
    procedure LazyInit;
    procedure PushData(aLoc: Pointer; aSize: Integer);
  public
    procedure PushArg(aValue: Pointer); overload;
    procedure PushArg(aValue: Integer); overload;
    procedure PushArg(aValue: Double); overload;
    procedure PushArgList;
    function Invoke(aCodeAddress: Pointer): Pointer;
  end;

function CallVA_ListFunction(aMethod: Pointer;
                             const aArgs: array of const): Pointer; overload;
function CallVA_ListFunction(aMethod: Pointer;
                             const aText: PAnsiChar;
                             const aArgs: array of const): Pointer; overload;
function CallVA_ListFunction(aMethod: Pointer;
                             aPointer: Pointer;
                             const aText: PAnsiChar;
                             const aArgs: array of const): Pointer; overload;
{$ENDIF ASSEMBLER}

implementation

{$IFDEF ASSEMBLER}
procedure TVarArgCaller.LazyInit;
const
  ONE_MEG = 1048576;
begin
  if fStack = nil then
  begin
    {
      Warning: The stack size is based on the assumption that our call
      doesn't use more then 512 KB of stack space.
    }
    SetLength(fStack, ONE_MEG div 2);
    fTop := @fStack[Length(FStack)];
  end;
end;

procedure TVarArgCaller.PushData(aLoc: Pointer; aSize: Integer);
  function AlignUp(aValue: Integer): Integer;
  begin
    Result := (aValue + 3) and not 3;
  end;
begin
  LazyInit;

  // You might want more headroom than this
  Assert(fTop - aSize >= PByte(@fStack[0]));
  Dec(fTop, AlignUp(aSize));
  FillChar(fTop^, AlignUp(aSize), 0);
  Move(aLoc^, fTop^, aSize);
end;

procedure TVarArgCaller.PushArg(aValue: Pointer);
begin
  PushData(@aValue, SizeOf(aValue));
end;

procedure TVarArgCaller.PushArg(aValue: Integer);
begin
  PushData(@aValue, SizeOf(aValue));
end;

procedure TVarArgCaller.PushArg(aValue: Double);
begin
  PushData(@aValue, SizeOf(aValue));
end;

procedure TVarArgCaller.PushArgList;
var
  currTop: PByte;
begin
  currTop := fTop;
  PushArg(currTop);
end;

function TVarArgCaller.Invoke(aCodeAddress: Pointer): Pointer;
asm
{$IFDEF CPUX86}
  { Create a new stack frame }
  PUSH EBP                        { Save current stack frame }
  MOV EBP,ESP                     { Point EBP to top of the stack }

  { Going to do something unpleasant now... }
  MOV ESP, EAX.TVarArgCaller.fTop { Swap stack out }
  CALL aCodeAddress               { Perform the method call }
  MOV ESP,EBP                     { Return value is in EAX }

  POP EBP                         { Restore EBP }
{$ENDIF CPUX86}
{$IFDEF CPUX64}
  { Create a stack frame }
  PUSH RBP                        { Save current stack frame }
  MOV RBP,RSP                     { Point RBP to top of the stack }

  { Going to do something unpleasant now... }
  MOV RSP, RAX.TVarArgCaller.fTop { Swap stack out }
  CALL aCodeAddress               { Perform the method call }
  MOV RSP,RBP                     { Return value is in RAX }

  POP RBP                         { Restore RBP }
{$ENDIF CPUX64}
end;

function CallVA_ListFunction(aMethod: Pointer;
                             const aArgs: array of const): Pointer;
var
  i:      Integer;
  caller: TVarArgCaller;
begin
  for i := High(aArgs) downto Low(aArgs) do
  begin
    case aArgs[i].VType of
      vtInteger:       caller.PushArg(aArgs[i].VInteger);
      vtInt64:         caller.PushArg(aArgs[i].VInt64);
      vtPChar:         caller.PushArg(aArgs[i].VPChar);
      vtPWideChar:     caller.PushArg(aArgs[i].VPWideChar);
      vtExtended:      caller.PushArg(aArgs[i].VExtended^);
      vtAnsiString:    caller.PushArg(PAnsiChar(aArgs[i].VAnsiString));
      vtWideString:    caller.PushArg(PWideChar(aArgs[i].VWideString));
      vtUnicodeString: caller.PushArg(PWideChar(aArgs[i].VUnicodeString));
      vtPointer:       caller.PushArg(aArgs[i].VPointer);
    else
      raise Exception.Create('Unknown type'); // etc.
    end;
  end;

  caller.PushArgList;
  Result := caller.Invoke(aMethod);
end;

function CallVA_ListFunction(aMethod: Pointer;
                             const aText: PAnsiChar;
                             const aArgs: array of const): Pointer;
var
  i:      Integer;
  caller: TVarArgCaller;
begin
  for i := High(aArgs) downto Low(aArgs) do
  begin
    case aArgs[i].VType of
      vtInteger:       caller.PushArg(aArgs[i].VInteger);
      vtInt64:         caller.PushArg(aArgs[i].VInt64);
      vtPChar:         caller.PushArg(aArgs[i].VPChar);
      vtPWideChar:     caller.PushArg(aArgs[i].VPWideChar);
      vtExtended:      caller.PushArg(aArgs[i].VExtended^);
      vtAnsiString:    caller.PushArg(PAnsiChar(aArgs[i].VAnsiString));
      vtWideString:    caller.PushArg(PWideChar(aArgs[i].VWideString));
      vtUnicodeString: caller.PushArg(PWideChar(aArgs[i].VUnicodeString));
      vtPointer:       caller.PushArg(aArgs[i].VPointer);
    else
      raise Exception.Create('Unknown type'); // etc.
    end;
  end;

  caller.PushArgList;
  caller.PushArg(aText);
  Result := caller.Invoke(aMethod);
end;


function CallVA_ListFunction(aMethod: Pointer;
                             aPointer: Pointer;
                             const aText: PAnsiChar;
                             const aArgs: array of const): Pointer;
var
  i:      Integer;
  caller: TVarArgCaller;
begin
  for i := High(aArgs) downto Low(aArgs) do
  begin
    case aArgs[i].VType of
      vtInteger:       caller.PushArg(aArgs[i].VInteger);
      vtInt64:         caller.PushArg(aArgs[i].VInt64);
      vtPChar:         caller.PushArg(aArgs[i].VPChar);
      vtPWideChar:     caller.PushArg(aArgs[i].VPWideChar);
      vtExtended:      caller.PushArg(aArgs[i].VExtended^);
      vtAnsiString:    caller.PushArg(PAnsiChar(aArgs[i].VAnsiString));
      vtWideString:    caller.PushArg(PWideChar(aArgs[i].VWideString));
      vtUnicodeString: caller.PushArg(PWideChar(aArgs[i].VUnicodeString));
      vtPointer:       caller.PushArg(aArgs[i].VPointer);
    else
      raise Exception.Create('Unknown type'); // etc.
    end;
  end;

  caller.PushArgList;
  caller.PushArg(aText);
  caller.PushArg(aPointer);
  Result := caller.Invoke(aMethod);
end;
{$ENDIF ASSEMBLER}

end.
