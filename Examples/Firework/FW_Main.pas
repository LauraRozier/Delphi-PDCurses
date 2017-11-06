unit FW_Main;

interface

uses
  SysUtils, Math, StrUtils, PDCurses;

const
  COLOR_TABLE: array[0..7] of SmallInt = (
    COLOR_RED, COLOR_BLUE, COLOR_GREEN, COLOR_CYAN,
    COLOR_RED, COLOR_MAGENTA, COLOR_YELLOW, COLOR_WHITE
  );
  DELAYSIZE = 100;

type
  TMain = class(TObject)
  private
    fInitialRows, fInitialCols: LongInt;
    procedure myrefresh;
    procedure get_color;
    procedure explode(aRow, aCol: LongInt);
  public
    procedure main;
  end;

implementation

procedure TMain.main;
var
  i:              SmallInt;
  startVal,
  endVal,
  row,
  diff,
  direction,
  endRow:         LongInt;
  arrowDirection: AnsiString;
  flag:           LongInt;
  aAStr:    AnsiString;
  aVersion: TVersionInfo;
  c:        Char;
begin
  Randomize;
  pdcInitLib;
  pdcInitScr;
  pdcNoDelay(pdcSValStdScr, PDC_TRUE);
  pdcNoEcho;

  if pdcHasColors = PDC_TRUE then
    pdcStartColor;


  for i := Low(COLOR_TABLE) to High(COLOR_TABLE) do
    pdcInitPair(i, COLOR_TABLE[i], COLOR_BLACK);

  aAStr    := pdcSValTtyType;
  aVersion := pdcSValVersion;
  pdcMvAddStr(2, 3, PAnsiChar(aAStr));
  aAStr := 'Version: ' + IntToStr(aVersion.ver_major) +
           '.' + IntToStr(aVersion.ver_minor) +
           '.' + IntToStr(aVersion.ver_change);
  pdcMvAddStr(3, 3, PAnsiChar(aAStr));
  aAStr := 'Port: ' + pdcPortToStr(aVersion.port);
  pdcMvAddStr(4, 3, PAnsiChar(aAStr));
  pdcMvAddStr(6, 3, 'Press any key to continue ...');
  pdcRefresh;
  pdcBeep;
  Read(c);

  pdcErase;
  flag := 0;

  while True do
  begin
    fInitialRows := pdcSValLines;
    fInitialCols := pdcSValCols;
    startVal     := 0;
    diff         := 0;
    direction    := 0;
    endRow       := 0;

    while ((diff < 2) or (diff >= fInitialRows - 2)) do
    begin
      startVal := Random(MaxLongInt) mod (fInitialCols - 5) + 2;
      endVal   := Random(MaxLongInt) mod (fInitialCols - 5) + 2;

      direction := IfThen(startVal > endVal, -1, 1);
      diff      := abs(startVal - endVal);
    end;

    pdcAttrSet(A_NORMAL);

    for row := 0 to diff - 1 do
    begin
      arrowDirection := AnsiString(IfThen(direction < 0, '\', '/'));
      pdcMVAddStr(fInitialRows - row,
                  row * direction + startVal,
                  PAnsiChar(arrowDirection));

      if flag > 0 then
      begin
        myrefresh;
        pdcErase;

        flag := 0;
      end else
        flag := 1;

      endRow := row;
    end;

    if flag > 0 then
    begin
      myrefresh;
      flag := 0;
    end else
      flag := 1;

    explode(fInitialRows - endRow, diff * direction + startVal);

    pdcErase;
    myrefresh;
  end;

  pdcEndwin;
  pdcFreeLib;
end;

procedure TMain.myrefresh;
begin
  pdcNapMS(DELAYSIZE);
  pdcMove(pdcSValLines - 1, pdcSValCols - 1);
  pdcRefresh;
end;

procedure TMain.get_color;
var
  bold: TChType;
begin
  bold := IfThen((Random(MaxLongInt) mod 2) = PDC_TRUE, A_BOLD, A_NORMAL);
  pdcAttrSet(pdcColorPair(Random(MaxLongInt) mod 8) OR bold);
end;

procedure TMain.explode(aRow, aCol: Int32);
begin
  pdcErase;
  pdcMVAddStr(aRow, aCol, '-');
  myrefresh;

  Dec(aCol);

  get_color;
  pdcMVAddStr(aRow - 1, aCol, ' - ');
  pdcMVAddStr(aRow,     aCol, '-+-');
  pdcMVAddStr(aRow + 1, aCol, ' - ');
  myrefresh;

  Dec(aCol);

  get_color;
  pdcMVAddStr(aRow - 2, aCol, ' --- ');
  pdcMVAddStr(aRow - 1, aCol, '-+++-');
  pdcMVAddStr(aRow,     aCol, '-+#+-');
  pdcMVAddStr(aRow + 1, aCol, '-+++-');
  pdcMVAddStr(aRow + 2, aCol, ' --- ');
  myrefresh;

  get_color;
  pdcMVAddStr(aRow - 2, aCol, ' +++ ');
  pdcMVAddStr(aRow - 1, aCol, '++#++');
  pdcMVAddStr(aRow,     aCol, '+# #+');
  pdcMVAddStr(aRow + 1, aCol, '++#++');
  pdcMVAddStr(aRow + 2, aCol, ' +++ ');
  myrefresh;

  get_color;
  pdcMVAddStr(aRow - 2, aCol, '  #  ');
  pdcMVAddStr(aRow - 1, aCol, '## ##');
  pdcMVAddStr(aRow,     aCol, '#   #');
  pdcMVAddStr(aRow + 1, aCol, '## ##');
  pdcMVAddStr(aRow + 2, aCol, '  #  ');
  myrefresh;

  get_color;
  pdcMVAddStr(aRow - 2, aCol, ' # # ');
  pdcMVAddStr(aRow - 1, aCol, '#   #');
  pdcMVAddStr(aRow,     aCol, '     ');
  pdcMVAddStr(aRow + 1, aCol, '#   #');
  pdcMVAddStr(aRow + 2, aCol, ' # # ');
  myrefresh;
end;

end.
