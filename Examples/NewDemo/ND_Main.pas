unit ND_Main;

{
 * A demo program using PDCurses.
 * The program illustrates the use of colors for text output.
 *
 *  Hacks by jbuhler@cs.washington.edu on 12/29/96
}

interface
uses
  Vcl.Forms, Windows, SysUtils, Math, AnsiStrings, PDCurses;

const
  // An ASCII map of Australia
  AusMap: array[0..16] of PAnsiChar = (
    '                       A ',
    '           AA         AA ',
    '    N.T. AAAAA       AAAA ',
    '     AAAAAAAAAAA  AAAAAAAA ',
    '   AAAAAAAAAAAAAAAAAAAAAAAAA Qld.',
    ' AAAAAAAAAAAAAAAAAAAAAAAAAAAA ',
    ' AAAAAAAAAAAAAAAAAAAAAAAAAAAAA ',
    ' AAAAAAAAAAAAAAAAAAAAAAAAAAAA ',
    '   AAAAAAAAAAAAAAAAAAAAAAAAA N.S.W.',
    'W.A. AAAAAAAAA      AAAAAA Vic.',
    '       AAA   S.A.     AA',
    '                       A  Tas.',
    '',
    '',
    '',
    '',
    ''
  );
  // "Funny" messages for the scroller
  messages: array[0..5] of PAnsiChar = (
    'Hello from the Land Down Under',
    'The Land of crocs, and a big Red Rock',
    'Where the sunflower runs along the highways',
    'The dusty red roads lead one to loneliness',
    'Blue sky in the morning and',
    'Freezing nights and twinkling stars'
  );

type
  TMain = class(TObject)
  private
    function WaitForUser: LongInt;
    function SubWinTest(aWindow: PWindow): LongInt;
    procedure BouncingBalls(aWindow: PWindow);
  public
    procedure main;
  end;

function trap(aSignal: DWORD): BOOL; stdcall;

implementation

function trap(aSignal: DWORD): BOOL; stdcall;
begin
  if aSignal = CTRL_C_EVENT then
  begin
    Result := True;
    pdcCursSet(1);
    pdcEndWin;
    pdcFreeLib;
    Application.Terminate;
  end;

  Result := False;
end;

procedure TMain.main;
var
  win: PWindow;
  save: array[0..79] of TChType;
  ch: TChType;
  width, height, w, x, y, i, j: LongInt;
  msg, visbuff: PAnsiChar;
  msgLen, scrollLen, stop, k: LongInt;
  version: TVersionInfo;
  versionStr: AnsiString;
begin
  pdcInitLib;
  pdcInitScr;
  Randomize;

  if pdcHasColors = PDC_TRUE then
    pdcStartColor;

  pdcUseDefaultColors;
  pdcCBreak;
  pdcNoEcho;

  pdcCursSet(0);
  SetConsoleCtrlHandler(@trap, True);
  pdcNoEcho;

  version    := pdcSValVersion;
  versionStr := AnsiString('PDCurses ' + IntToStr(version.ver_major) +
                '.' + IntToStr(version.ver_minor) +
                '.' + IntToStr(version.ver_change) +
                ' - ' + pdcPortToStr(version.port));

  {
    refresh stdscr so that reading from it will not cause it to
    overwrite the other windows that are being created
  }
  pdcRefresh;

  // Create a drawing window
  width  := 48;
  height := 15;

  win := pdcNewWin(height, width,
                   (pdcSValLines - height) div 2,
                   (pdcSValCols  - width)  div 2);

  if win = nil then
  begin
    pdcCursSet(1);
    pdcEndWin;
    pdcFreeLib;
    Application.Terminate;
  end;

  while True do
  begin
    pdcInitPair(1, COLOR_WHITE, COLOR_BLUE);
    pdcWBkgd(win, pdcColorPair(1));
    pdcWErase(win);

    pdcInitPair(2, COLOR_RED, COLOR_RED);
    pdcWAttrSet(win, pdcColorPair(2));
    pdcBox(win, TChType(' '), TChType(' '));
    pdcWRefresh(win);

    pdcWAttrSet(win, A_NORMAL);

    // Do random output of a character
    ch := TChType('a');
    pdcNoDelay(pdcSValStdScr, PDC_TRUE);

    for i := 0 to 5000 - 1 do
    begin
      x := Random(MaxLongInt) mod (width - 2) + 1;
      y := Random(MaxLongInt) mod (height - 2) + 1;

      pdcMvWAddCh(win, y, x, ch);
      pdcWRefresh(win);

      if pdcGetCh <> PDC_ERR then
        break;

      if i = 2000 then
      begin
        ch := TChType('b');
        pdcInitPair(3, COLOR_CYAN, COLOR_YELLOW);
        pdcWAttrSet(win, pdcColorPair(3));
      end;
    end;

    pdcNoDelay(pdcSValStdScr, PDC_FALSE);
    SubWinTest(win);

    // Erase and draw green window
    pdcInitPair(4, COLOR_YELLOW, COLOR_GREEN);
    pdcWBkgd(win, pdcColorPair(4));
    pdcWAttrSet(win, A_BOLD);
    pdcWErase(win);
    pdcWRefresh(win);

    // Draw RED bounding box
    pdcWAttrSet(win, pdcColorPair(2));
    pdcBox(win, TChType(' '), TChType(' '));
    pdcWRefresh(win);

    // Display Australia map
    pdcWAttrSet(win, A_BOLD);

    for i := 0 to Length(AusMap) - 1 do
    begin
      pdcMvWAddStr(win, i + 1, 8, AusMap[i]);
      pdcWRefresh(win);
      pdcNapMS(100);
    end;

    pdcInitPair(5, COLOR_BLUE, COLOR_WHITE);
    pdcWAttrSet(win, pdcColorPair(5) OR A_BLINK);
    pdcMvWAddStr(win, height - 2,
                 1 * ((width div 2) - (Length(versionStr) div 2)),
                 PAnsiChar(versionStr));
    pdcWRefresh(win);

    // Draw running messages
    pdcInitPair(6, COLOR_BLACK, COLOR_WHITE);
    pdcWAttrSet(win, pdcColorPair(6));
    w := width - 2;
    pdcNoDelay(win, PDC_TRUE);

    // Thibmo's re-hack of jbuhler's re-hacked scrolling messages
    for j := 0 to Length(messages) - 1 do
    begin
      msg       := messages[j];
      msgLen    := AnsiStrings.StrLen(msg);
      scrollLen := w + msgLen;
      stop      := 0;
      pdcFlushInp;

      for k := scrollLen downto 0 do
      begin
        GetMem(visbuff, scrollLen);
        FillChar(visbuff[0], scrollLen, ' ');
        Move(msg[0], visbuff[k - msgLen], msgLen);

        pdcMvWAddNStr(win, height div 2, 1, PAnsiChar(visbuff), w);
        pdcWRefresh(win);

        if pdcWGetCh(win) <> PDC_ERR then
        begin
          pdcFlushInp;
          stop := 1;
          break;
        end;

        pdcNapMS(100);
      end;

      if stop = 1 then
        break;
    end;

    j := 0;

    // Draw running 'A's across in RED
    pdcInitPair(7, COLOR_RED, COLOR_GREEN);
    pdcWAttrOn(win, pdcColorPair(7));

    for i := 2 to width - 5 do
    begin
      ch := pdcMvWInCh(win, 5, i);
      save[j] := ch;
      Inc(j);
      ch := ch AND $7F;
      pdcMvWAddCh(win, 5, i, ch);
    end;

    pdcWRefresh(win);

    // Put a message up; wait for a key
    i := height - 2;
    pdcWAttrSet(win, pdcColorPair(5));
    pdcMvWAddStr(win, i, 3, '   Type a key to continue or ESC to quit  ');
    pdcWRefresh(win);

    pdcFlushInp;
    if WaitForUser = $1B then break;

    // Restore the old line
    pdcWAttrSet(win, 0);
    j := 0;

    for i := 2 to width - 5 do
    begin
      pdcMvWAddCh(win, 5, i, save[j]);
      Inc(j);
    end;

    pdcWRefresh(win);
    BouncingBalls(win);

    // BouncingBalls() leaves a keystroke in the queue
    if WaitForUser = $1B then break;
  end;

  pdcCursSet(1);
  pdcEndWin;
  pdcFreeLib;
end;

function TMain.WaitForUser: LongInt;
var
  ch: TChType;
begin
  pdcNoDelay(pdcSValStdScr, PDC_TRUE);
  pdcHalfDelay(50);

  ch := pdcGetCh;

  pdcNoDelay(pdcSValStdScr, PDC_FALSE);
  pdcNoCBreak; // Reset the pdcHalfDelay() value
  pdcCBreak;

  Result := IfThen(ch = $1B { = \033 = KEY_ESC }, $1B, 0);
end;

function TMain.SubWinTest(aWindow: PWindow): LongInt;
var
  sWin1P, sWin2P, sWin3P: PWindow;
  maxPoint, begPoint: TPoint;
  sW, sH: LongInt;
begin
  Result := 1;

  pdcWAttrSet(aWindow, A_NORMAL);
  maxPoint := pdcGetMaxYX(aWindow);
  begPoint := pdcGetBegYX(aWindow);

  sW := maxPoint.X div 3;
  sH := maxPoint.Y div 3;

  sWin1P := pdcDerWin(aWindow, sH, sW, 3,              5);
  sWin2P := pdcSubWin(aWindow, sH, sW, begPoint.Y + 4, begPoint.X + 8);
  sWin3P := pdcSubWin(aWindow, sH, sW, begPoint.Y + 5, begPoint.X + 11);

  if (sWin1P = nil) or (sWin2P = nil) or (sWin3P = nil) then
    Exit;

  pdcInitPair(8, COLOR_RED, COLOR_BLUE);
  pdcWBkgd(sWin1P, pdcColorPair(8));
  pdcWErase(sWin1P);
  pdcMvWAddStr(sWin1P, 0, 3, 'Sub-window 1');
  pdcWRefresh(sWin1P);

  pdcInitPair(9, COLOR_CYAN, COLOR_MAGENTA);
  pdcWBkgd(sWin2P, pdcColorPair(9));
  pdcWErase(sWin2P);
  pdcMvWAddStr(sWin2P, 0, 3, 'Sub-window 2');
  pdcWRefresh(sWin2P);

  pdcInitPair(10, COLOR_YELLOW, COLOR_GREEN);
  pdcWBkgd(sWin3P, pdcColorPair(10));
  pdcWErase(sWin3P);
  pdcMvWAddStr(sWin3P, 0, 3, 'Sub-window 3');
  pdcWRefresh(sWin3P);

  WaitForUser;

  pdcDelWin(sWin1P);
  pdcDelWin(sWin2P);
  pdcDelWin(sWin3P);

  Result := 0;
end;

procedure TMain.BouncingBalls(aWindow: PWindow);
var
  c1, c2, c3, ball1, ball2, ball3: TChType;
  x1, y1, xd1, yd1, x2, y2, xd2, yd2, x3, y3, xd3, yd3, c: LongInt;
  maxPoint: TPoint;
begin
  pdcCursSet(0);

  pdcWBkgd(aWindow, pdcColorPair(1));
  pdcWRefresh(aWindow);
  pdcWAttrSet(aWindow, A_NORMAL);

  pdcInitPair(11, COLOR_RED,    COLOR_GREEN);
  pdcInitPair(12, COLOR_BLUE,   COLOR_RED);
  pdcInitPair(13, COLOR_YELLOW, COLOR_WHITE);

  ball1 := TChType('O') OR pdcColorPair(11);
  ball2 := TChType('*') OR pdcColorPair(12);
  ball3 := TChType('@') OR pdcColorPair(13);

  maxPoint := pdcGetMaxYX(aWindow);

  x1 := 2 + Random(MaxLongInt) mod (maxPoint.X - 4);
  y1 := 2 + Random(MaxLongInt) mod (maxPoint.Y - 4);
  x2 := 2 + Random(MaxLongInt) mod (maxPoint.X - 4);
  y2 := 2 + Random(MaxLongInt) mod (maxPoint.Y - 4);
  x3 := 2 + Random(MaxLongInt) mod (maxPoint.X - 4);
  y3 := 2 + Random(MaxLongInt) mod (maxPoint.Y - 4);

  xd1 := 1;
  yd1 := 1;
  xd2 := 1;
  yd2 := -1;
  xd3 := -1;
  yd3 := 1;

  pdcNoDelay(pdcSValStdScr, PDC_TRUE);
  c := pdcGetCh;

  while c = PDC_ERR do
  begin
    Inc(x1, xd1);
    if (x1 <= 1) or (x1 >= maxPoint.X - 2) then
      xd1 := xd1 * -1;

    Inc(y1, yd1);
    if (y1 <= 1) or (y1 >= maxPoint.Y - 2) then
      yd1 := yd1 * -1;

    Inc(x2, xd2);
    if (x2 <= 1) or (x2 >= maxPoint.X - 2) then
      xd2 := xd2 * -1;

    Inc(y2, yd2);
    if (y2 <= 1) or (y2 >= maxPoint.Y - 2) then
      yd2 := yd2 * -1;

    Inc(x3, xd3);
    if (x3 <= 1) or (x3 >= maxPoint.X - 2) then
      xd3 := xd3 * -1;

    Inc(y3, yd3);
    if (y3 <= 1) or (y3 >= maxPoint.Y - 2) then
      yd3 := yd3 * -1;

    c1 := pdcMvWInCh(aWindow, y1, x1);
    c2 := pdcMvWInCh(aWindow, y2, x2);
    c3 := pdcMvWInCh(aWindow, y3, x3);

    pdcMvWAddCh(aWindow, y1, x1, ball1);
    pdcMvWAddCh(aWindow, y2, x2, ball2);
    pdcMvWAddCh(aWindow, y3, x3, ball3);

    pdcWMove(aWindow, 0, 0);
    pdcWRefresh(aWindow);

    pdcMvWAddCh(aWindow, y1, x1, c1);
    pdcMvWAddCh(aWindow, y2, x2, c2);
    pdcMvWAddCh(aWindow, y3, x3, c3);

    pdcNapMS(150);
    c := pdcGetCh;
  end;

  pdcNoDelay(pdcSValStdScr, PDC_FALSE);
  pdcUnGetCh(c);
end;

end.
