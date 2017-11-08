program NewDemo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  ND_Main in 'ND_Main.pas',
  PDCurses in '..\..\PDCurses.pas',
  PDVarArgCaller in '..\..\PDVarArgCaller.pas';

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
