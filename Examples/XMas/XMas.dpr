program XMas;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  XM_Main in 'XM_Main.pas',
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
