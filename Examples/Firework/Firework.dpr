program Firework;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  PDCurses_OLD in '..\..\PDCurses_OLD.pas',
  PDPanel_OLD in '..\..\PDPanel_OLD.pas',
  PDTerm_OLD in '..\..\PDTerm_OLD.pas',
  PDVarArgCaller in '..\..\PDVarArgCaller.pas',
  PDCurses in '..\..\PDCurses.pas',
  FW_Main in 'FW_Main.pas';

var
  main: TMain;

begin
  try
    main := TMain.Create;
    main.main;
    FreeAndNil(main);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
