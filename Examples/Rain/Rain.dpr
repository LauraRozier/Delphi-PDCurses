program Rain;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  PDCurses in '..\..\PDCurses.pas',
  PDVarArgCaller in '..\..\PDVarArgCaller.pas',
  R_Main in 'R_Main.pas';

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
