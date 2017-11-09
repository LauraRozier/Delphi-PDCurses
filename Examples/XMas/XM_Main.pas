unit XM_Main;
{
  ******************************************************************************
  * asciixmas                                                                  *
  * December 1989             Larry Bartz           Indianapolis, IN           *
  *                                                                            *
  *                                                                            *
  * I'm dreaming of an ascii character-based monochrome Christmas,             *
  * Just like the one's I used to know!                                        *
  * Via a full duplex communications channel,                                  *
  * At 9600 bits per second,                                                   *
  * Even though it's kinda slow.                                               *
  *                                                                            *
  * I'm dreaming of an ascii character-based monochrome Christmas,             *
  * With ev'ry C program I write!                                              *
  * May your screen be merry and bright!                                       *
  * And may all your Christmases be amber or green,                            *
  * (for reduced eyestrain and improved visibility)!                           *
  *                                                                            *
  *                                                                            *
  *                                                                            *
  * IMPLEMENTATION                                                             *
  *                                                                            *
  * Feel free to modify the defined string FROMWHO to reflect you, your        *
  * organization, your site, whatever.                                         *
  *                                                                            *
  * This looks a lot better if you can turn off your cursor before execution.  *
  * The cursor is distracting but it doesn't really ruin the show.             *
  *                                                                            *
  * At our site, we invoke this for our users just after login and the         *
  * determination of terminal type.                                            *
  *                                                                            *
  *                                                                            *
  * PORTABILITY                                                                *
  *                                                                            *
  * I wrote this using only the very simplest curses functions so that it      *
  * might be the most portable. I was personally able to test on five          *
  * different cpu/UNIX combinations.                                           *
  *                                                                            *
  *                                                                            *
  * COMPILE                                                                    *
  *                                                                            *
  * usually this:                                                              *
  *                                                                            *
  * cc -O xmas.c -lcurses -o xmas -s                                           *
  *                                                                            *
  ******************************************************************************
}
{$I ..\..\PDCurses.inc}

interface

uses
  SysUtils, PDCurses;

const
  FROM_WHO: PAnsiChar = 'From Larry Bartz, Mark Hessling and William McBrine';

type
  TPAnsiCharArray = array of PAnsiChar;

  TMain = class(TObject)
  private
    y_pos, x_pos, cycle: LongInt;
    treescrn,  treescrn2, treescrn3, treescrn4, treescrn5,
    treescrn6, treescrn7, treescrn8, dotdeer0,  stardeer0,
    lildeer0,  lildeer1,  lildeer2,  lildeer3,  middeer0,
    middeer1,  middeer2,  middeer3,  bigdeer0,  bigdeer1,
    bigdeer2,  bigdeer3,  bigdeer4,  lookdeer0, lookdeer1,
    lookdeer2, lookdeer3, lookdeer4, w_holiday, w_del_msg: PWindow;
    procedure lil(aWindow: PWindow);
    procedure midtop(aWindow: PWindow);
    procedure bigtop(aWindow: PWindow);
    procedure bigface(aWindow: PWindow; aNoseAttr: TChType);
    procedure legs1(aWindow: PWindow);
    procedure legs2(aWindow: PWindow);
    procedure legs3(aWindow: PWindow);
    procedure legs4(aWindow: PWindow);
    procedure initdeer;
    procedure boxit;
    procedure seas;
    procedure greet;
    procedure fromwho;
    procedure del_msg;
    procedure tree;
    procedure balls;
    procedure star;
    procedure strng1;
    procedure strng2;
    procedure strng3;
    procedure strng4;
    procedure strng5;
    procedure blinkit;
    procedure reindeer;
{$IFDEF XCURSES}
    function ParamsToPPAnsiChar: TPAnsiCharArray;
{$ENDIF XCURSES}
    procedure tshow(aWindow: PWindow; aTime: LongInt);
    procedure show(aWindow: PWindow; aTime: LongInt);
  public
    procedure main;
  end;

implementation

{$IFDEF XCURSES} // Needs translation to proper Linux, can't do that from Starter. :(
function TMain.ParamsToPPAnsiChar: TPAnsiCharArray;
var
  tmpStr: AnsiString;
  i:      Integer;
begin
  for i := 1 to ParamCount do
  begin
    SetLength(Result, Length(Result) + 1);
    tmpStr               := AnsiString(ParamStr(i));
    Result[High(Result)] := PAnsiChar(tmpStr);
  end;
end;
{$ENDIF XCURSES}

procedure TMain.main;
var
  loopy: LongInt;
{$IFDEF XCURSES}
  argV:  TPAnsiCharArray;
begin
  pdcInitLib;
  argV := ParamsToPPAnsiChar;
  pdcXInitScr(ParamCount, @argV[0]);
{$ELSE XCURSES}
begin
  pdcInitLib;
  pdcInitScr;
{$ENDIF XCURSES}

  pdcNoDelay(pdcSValStdScr, PDC_TRUE);
  pdcNoEcho;
  pdcNoNL;
  pdcRefresh;

  if pdcHasColors = PDC_TRUE then
    pdcStartColor;

  pdcCursSet(0);

  treescrn  := pdcNewWin(16, 27, 3, 53);
  treescrn2 := pdcNewWin(16, 27, 3, 53);
  treescrn3 := pdcNewWin(16, 27, 3, 53);
  treescrn4 := pdcNewWin(16, 27, 3, 53);
  treescrn5 := pdcNewWin(16, 27, 3, 53);
  treescrn6 := pdcNewWin(16, 27, 3, 53);
  treescrn7 := pdcNewWin(16, 27, 3, 53);
  treescrn8 := pdcNewWin(16, 27, 3, 53);

  w_holiday := pdcNewWin(1, 26, 3, 27);

  w_del_msg := pdcNewWin(1, 12, 23, 60);

  pdcMvWAddStr(w_holiday, 0, 0, 'H A P P Y  H O L I D A Y S');

  initdeer;

  pdcClear;
  pdcWErase(treescrn);
  pdcTouchWin(treescrn);
  pdcWErase(treescrn2);
  pdcTouchWin(treescrn2);
  pdcWErase(treescrn8);
  pdcTouchWin(treescrn8);
  pdcRefresh;
  pdcNapMS(1000);

  boxit;
  del_msg;
  pdcNapMS(1000);

  seas;
  del_msg;
  pdcNapMS(1000);

  greet;
  del_msg;
  pdcNapMS(1000);

  fromwho;
  del_msg;
  pdcNapMS(1000);

  tree;
  del_msg;
  pdcNapMS(1000);

  balls;
  del_msg;
  pdcNapMS(1000);

  star;
  del_msg;
  pdcNapMS(1000);

  strng1;
  strng2;
  strng3;
  strng4;
  strng5;

  {
    set up the windows for our blinking trees
    *****************************************
  }
  // treescrn3
  pdcOverlay(treescrn, treescrn3);

  // balls
  pdcMvWAddCh(treescrn3, 4, 18, TChType(' '));
  pdcMvWAddCh(treescrn3, 7, 6, TChType(' '));
  pdcMvWAddCh(treescrn3, 8, 19, TChType(' '));
  pdcMvWAddCh(treescrn3, 11, 12, TChType(' '));

  // star
  pdcMvWAddCh(treescrn3, 0, 12, TChType('*'));

  // strng1
  pdcMvWAddCh(treescrn3, 3, 11, TChType(' '));

  // strng2
  pdcMvWAddCh(treescrn3, 5, 13, TChType(' '));
  pdcMvWAddCh(treescrn3, 6, 10, TChType(' '));

  // strng3
  pdcMvWAddCh(treescrn3, 7, 16, TChType(' '));
  pdcMvWAddCh(treescrn3, 7, 14, TChType(' '));

  // strng4
  pdcMvWAddCh(treescrn3, 10, 13, TChType(' '));
  pdcMvWAddCh(treescrn3, 10, 10, TChType(' '));
  pdcMvWAddCh(treescrn3, 11, 8, TChType(' '));

  // strng5
  pdcMvWAddCh(treescrn3, 11, 18, TChType(' '));
  pdcMvWAddCh(treescrn3, 12, 13, TChType(' '));

  // treescrn4
  pdcOverlay(treescrn, treescrn4);

  // balls
  pdcMvWAddCh(treescrn4, 3, 9, TChType(' '));
  pdcMvWAddCh(treescrn4, 4, 16, TChType(' '));
  pdcMvWAddCh(treescrn4, 7, 6, TChType(' '));
  pdcMvWAddCh(treescrn4, 8, 19, TChType(' '));
  pdcMvWAddCh(treescrn4, 11, 2, TChType(' '));
  pdcMvWAddCh(treescrn4, 12, 23, TChType(' '));

  // star
  pdcMvWAddCh(treescrn4, 0, 12, TChType('*') OR A_STANDOUT);

  // strng1
  pdcMvWAddCh(treescrn4, 3, 13, TChType(' '));

  // strng2

  // strng3
  pdcMvWAddCh(treescrn4, 7, 15, TChType(' '));
  pdcMvWAddCh(treescrn4, 8, 11, TChType(' '));

  // strng4
  pdcMvWAddCh(treescrn4, 9, 16, TChType(' '));
  pdcMvWAddCh(treescrn4, 10, 12, TChType(' '));
  pdcMvWAddCh(treescrn4, 11, 8, TChType(' '));

  // strng5
  pdcMvWAddCh(treescrn4, 11, 18, TChType(' '));
  pdcMvWAddCh(treescrn4, 12, 14, TChType(' '));

  // treescrn5
  pdcOverlay(treescrn, treescrn5);

  // balls
  pdcMvWAddCh(treescrn5, 3, 15, TChType(' '));
  pdcMvWAddCh(treescrn5, 10, 20, TChType(' '));
  pdcMvWAddCh(treescrn5, 12, 1, TChType(' '));

  // star
  pdcMvWAddCh(treescrn5, 0, 12, TChType('*'));

  // strng1
  pdcMvWAddCh(treescrn5, 3, 11, TChType(' '));

  // strng2
  pdcMvWAddCh(treescrn5, 5, 12, TChType(' '));

  // strng3
  pdcMvWAddCh(treescrn5, 7, 14, TChType(' '));
  pdcMvWAddCh(treescrn5, 8, 10, TChType(' '));

  // strng4
  pdcMvWAddCh(treescrn5, 9, 15, TChType(' '));
  pdcMvWAddCh(treescrn5, 10, 11, TChType(' '));
  pdcMvWAddCh(treescrn5, 11, 7, TChType(' '));

  // strng5
  pdcMvWAddCh(treescrn5, 11, 17, TChType(' '));
  pdcMvWAddCh(treescrn5, 12, 13, TChType(' '));

  // treescrn6
  pdcOverlay(treescrn, treescrn6);

  // balls
  pdcMvWAddCh(treescrn6, 6, 7, TChType(' '));
  pdcMvWAddCh(treescrn6, 7, 18, TChType(' '));
  pdcMvWAddCh(treescrn6, 10, 4, TChType(' '));
  pdcMvWAddCh(treescrn6, 11, 23, TChType(' '));

  // star
  pdcMvWAddCh(treescrn6, 0, 12, TChType('*') OR A_STANDOUT);

  // strng1

  // strng2
  pdcMvWAddCh(treescrn6, 5, 11, TChType(' '));

  // strng3
  pdcMvWAddCh(treescrn6, 7, 13, TChType(' '));
  pdcMvWAddCh(treescrn6, 8, 9, TChType(' '));

  // strng4
  pdcMvWAddCh(treescrn6, 9, 14, TChType(' '));
  pdcMvWAddCh(treescrn6, 10, 10, TChType(' '));
  pdcMvWAddCh(treescrn6, 11, 6, TChType(' '));

  // strng5
  pdcMvWAddCh(treescrn6, 11, 16, TChType(' '));
  pdcMvWAddCh(treescrn6, 12, 12, TChType(' '));

  // treescrn7
  pdcOverlay(treescrn, treescrn7);

  // balls
  pdcMvWAddCh(treescrn7, 3, 15, TChType(' '));
  pdcMvWAddCh(treescrn7, 6, 7, TChType(' '));
  pdcMvWAddCh(treescrn7, 7, 18, TChType(' '));
  pdcMvWAddCh(treescrn7, 10, 4, TChType(' '));
  pdcMvWAddCh(treescrn7, 11, 22, TChType(' '));

  // star
  pdcMvWAddCh(treescrn7, 0, 12, TChType('*'));

  // strng1
  pdcMvWAddCh(treescrn7, 3, 12, TChType(' '));

  // strng2
  pdcMvWAddCh(treescrn7, 5, 13, TChType(' '));
  pdcMvWAddCh(treescrn7, 6, 9, TChType(' '));

  // strng3
  pdcMvWAddCh(treescrn7, 7, 15, TChType(' '));
  pdcMvWAddCh(treescrn7, 8, 11, TChType(' '));

  // strng4
  pdcMvWAddCh(treescrn7, 9, 16, TChType(' '));
  pdcMvWAddCh(treescrn7, 10, 12, TChType(' '));
  pdcMvWAddCh(treescrn7, 11, 8, TChType(' '));

  // strng5
  pdcMvWAddCh(treescrn7, 11, 18, TChType(' '));
  pdcMvWAddCh(treescrn7, 12, 14, TChType(' '));

  pdcNapMS(1000);
  reindeer;

  pdcTouchWin(w_holiday);
  pdcWRefresh(w_holiday);
  pdcWRefresh(w_del_msg);

  pdcNapMS(1000);

  for loopy := 0 to 50 - 1 do
    blinkit;

  pdcClear;
  pdcRefresh;

  pdcCursSet(1);
  pdcEndWin;
  pdcFreeLib;
end;

procedure TMain.lil(aWindow: PWindow);
begin
  pdcMvWAddCh(aWindow, 0, 0, TChType('V'));
  pdcMvWAddCh(aWindow, 1, 0, TChType('@'));
  pdcMvWAddCh(aWindow, 1, 3, TChType('~'));
end;

procedure TMain.midtop(aWindow: PWindow);
begin
  pdcMvWAddStr(aWindow, 0, 2, 'yy');
  pdcMvWAddStr(aWindow, 1, 2, '0(=)~');
end;

procedure TMain.bigtop(aWindow: PWindow);
begin
  pdcMvWAddStr(aWindow, 0, 17, '\/');
  pdcMvWAddStr(aWindow, 0, 20, '\/');
  pdcMvWAddCh(aWindow, 1, 18, TChType('\'));
  pdcMvWAddCh(aWindow, 1, 20, TChType('/'));
  pdcMvWAddStr(aWindow, 2, 19, '|_');
  pdcMvWAddStr(aWindow, 3, 18, '/^0\');
  pdcMvWAddStr(aWindow, 4, 17, '//\');
  pdcMvWAddCh(aWindow, 4, 22, TChType('\'));
  pdcMvWAddStr(aWindow, 5, 7, '^~~~~~~~~//  ~~U');
end;

procedure TMain.bigface(aWindow: PWindow; aNoseAttr: TChType);
begin
  pdcMvWAddStr(aWindow, 0, 16, '\/     \/');
  pdcMvWAddStr(aWindow, 1, 17, '\Y/ \Y/');
  pdcMvWAddStr(aWindow, 2, 19, '\=/');
  pdcMvWAddStr(aWindow, 3, 17, '^\o o/^');
  pdcMvWAddStr(aWindow, 4, 17, '//( )');
  pdcMvWAddStr(aWindow, 5, 7, '^~~~~~~~~// \');
  pdcWAddCh(aWindow, TChType('O') OR aNoseAttr);
  pdcWAddStr(aWindow, '/');
end;

procedure TMain.legs1(aWindow: PWindow);
begin
  pdcMvWAddStr(aWindow, 6, 7, '( \_____( /');
  pdcMvWAddStr(aWindow, 7, 8, '( )    /');
  pdcMvWAddStr(aWindow, 8, 9, '\\   /');
  pdcMvWAddStr(aWindow, 9, 11, '\>/>');
end;

procedure TMain.legs2(aWindow: PWindow);
begin
  pdcMvWAddStr(aWindow, 6, 7, '(( )____( /');
  pdcMvWAddStr(aWindow, 7, 7, '( /      |');
  pdcMvWAddStr(aWindow, 8, 8, '\/      |');
  pdcMvWAddStr(aWindow, 9, 9, '|>     |>');
end;

procedure TMain.legs3(aWindow: PWindow);
begin
  pdcMvWAddStr(aWindow, 6, 6, '( ()_____( /');
  pdcMvWAddStr(aWindow, 7, 6, '/ /       /');
  pdcMvWAddStr(aWindow, 8, 5, '|/          \');
  pdcMvWAddStr(aWindow, 9, 5, '/>           \>');
end;

procedure TMain.legs4(aWindow: PWindow);
begin
  pdcMvWAddStr(aWindow, 6, 6, '( )______( /');
  pdcMvWAddStr(aWindow, 7, 5, '(/          \');
  pdcMvWAddStr(aWindow, 8, 0, 'v___=             ----^');
end;

procedure TMain.initdeer;
var
  noseattr: TChType;
begin
  if pdcHasColors = PDC_TRUE then
  begin
    pdcInitPair(31, COLOR_RED, COLOR_BLACK);
    noseattr := pdcColorPair(31);
  end else
    noseattr := A_NORMAL;

  // set up the windows for our various reindeer
  dotdeer0  := pdcNewWin(3, 71, 0, 8);
  stardeer0 := pdcNewWin(4, 56, 0, 8);
  lildeer0  := pdcNewWin(7, 54, 0, 8);
  middeer0  := pdcNewWin(15, 42, 0, 8);
  bigdeer0  := pdcNewWin(10, 23, 0, 0);
  lookdeer0 := pdcNewWin(10, 25, 0, 0);

  // lildeer1
  lildeer1 := pdcNewWin(2, 4, 0, 0);
  lil(lildeer1);
  pdcMvWAddStr(lildeer1, 1, 1, '<>');

  // lildeer2
  lildeer2 := pdcNewWin(2, 4, 0, 0);
  lil(lildeer2);
  pdcMvWAddStr(lildeer2, 1, 1, '||');

  // lildeer3
  lildeer3 := pdcNewWin(2, 4, 0, 0);
  lil(lildeer3);
  pdcMvWAddStr(lildeer3, 1, 1, '><');

  // middeer1
  middeer1 := pdcNewWin(3, 7, 0, 0);
  midtop(middeer1);
  pdcMvWAddStr(middeer1, 2, 3, '\/');

  // middeer2
  middeer2 := pdcNewWin(3, 7, 0, 0);
  midtop(middeer2);
  pdcMvWAddCh(middeer2, 2, 3, TChType('|'));
  pdcMvWAddCh(middeer2, 2, 5, TChType('|'));

  // middeer3
  middeer3 := pdcNewWin(3, 7, 0, 0);
  midtop(middeer3);
  pdcMvWAddCh(middeer3, 2, 2, TChType('/'));
  pdcMvWAddCh(middeer3, 2, 6, TChType('\'));

  // bigdeer1
  bigdeer1 := pdcNewWin(10, 23, 0, 0);
  bigtop(bigdeer1);
  legs1(bigdeer1);

  // bigdeer2
  bigdeer2 := pdcNewWin(10, 23, 0, 0);
  bigtop(bigdeer2);
  legs2(bigdeer2);

  // bigdeer3
  bigdeer3 := pdcNewWin(10, 23, 0, 0);
  bigtop(bigdeer3);
  legs3(bigdeer3);

  // bigdeer4
  bigdeer4 := pdcNewWin(10, 23, 0, 0);
  bigtop(bigdeer4);
  legs4(bigdeer4);

  // lookdeer1
  lookdeer1 := pdcNewWin(10, 25, 0, 0);
  bigface(lookdeer1, noseattr);
  legs1(lookdeer1);

  // lookdeer2
  lookdeer2 := pdcNewWin(10, 25, 0, 0);
  bigface(lookdeer2, noseattr);
  legs2(lookdeer2);

  // lookdeer3
  lookdeer3 := pdcNewWin(10, 25, 0, 0);
  bigface(lookdeer3, noseattr);
  legs3(lookdeer3);

  // lookdeer4
  lookdeer4 := pdcNewWin(10, 25, 0, 0);
  bigface(lookdeer4, noseattr);
  legs4(lookdeer4);
end;

procedure TMain.boxit;
var
  x: LongInt;
begin
  for x := 0 to 20 - 1 do
    pdcMvAddCh(x, 7, TChType('|'));

  for x := 0 to 80 - 1 do
  begin
    if x > 7 then
      pdcMvAddCh(19, x, TChType('_'));

    pdcMvAddCh(22, x, TChType('_'));
  end;
end;

procedure TMain.seas;
begin
  pdcMvAddCh(4, 1, TChType('S'));
  pdcMvAddCh(6, 1, TChType('E'));
  pdcMvAddCh(8, 1, TChType('A'));
  pdcMvAddCh(10, 1, TChType('S'));
  pdcMvAddCh(12, 1, TChType('O'));
  pdcMvAddCh(14, 1, TChType('N'));
  pdcMvAddCh(16, 1, TChType('`'));
  pdcMvAddCh(18, 1, TChType('S'));
end;

procedure TMain.greet;
begin
  pdcMvAddCh(3, 5, TChType('G'));
  pdcMvAddCh(5, 5, TChType('R'));
  pdcMvAddCh(7, 5, TChType('E'));
  pdcMvAddCh(9, 5, TChType('E'));
  pdcMvAddCh(11, 5, TChType('T'));
  pdcMvAddCh(13, 5, TChType('I'));
  pdcMvAddCh(15, 5, TChType('N'));
  pdcMvAddCh(17, 5, TChType('G'));
  pdcMvAddCh(19, 5, TChType('S'));
end;

procedure TMain.fromwho;
begin
  pdcMvAddStr(21, 13, FROM_WHO);
end;

procedure TMain.del_msg;
begin
  pdcRefresh;
end;

procedure TMain.tree;
begin
  if pdcHasColors = PDC_TRUE then
  begin
    pdcInitPair(30, COLOR_GREEN, COLOR_BLACK);
    pdcWAttrSet(treescrn, pdcColorPair(30));
  end;

  pdcMvWAddCh(treescrn, 1, 11, TChType('/'));
  pdcMvWAddCh(treescrn, 2, 11, TChType('/'));
  pdcMvWAddCh(treescrn, 3, 10, TChType('/'));
  pdcMvWAddCh(treescrn, 4, 9, TChType('/'));
  pdcMvWAddCh(treescrn, 5, 9, TChType('/'));
  pdcMvWAddCh(treescrn, 6, 8, TChType('/'));
  pdcMvWAddCh(treescrn, 7, 7, TChType('/'));
  pdcMvWAddCh(treescrn, 8, 6, TChType('/'));
  pdcMvWAddCh(treescrn, 9, 6, TChType('/'));
  pdcMvWAddCh(treescrn, 10, 5, TChType('/'));
  pdcMvWAddCh(treescrn, 11, 3, TChType('/'));
  pdcMvWAddCh(treescrn, 12, 2, TChType('/'));

  pdcMvWAddCh(treescrn, 1, 13, TChType('\'));
  pdcMvWAddCh(treescrn, 2, 13, TChType('\'));
  pdcMvWAddCh(treescrn, 3, 14, TChType('\'));
  pdcMvWAddCh(treescrn, 4, 15, TChType('\'));
  pdcMvWAddCh(treescrn, 5, 15, TChType('\'));
  pdcMvWAddCh(treescrn, 6, 16, TChType('\'));
  pdcMvWAddCh(treescrn, 7, 17, TChType('\'));
  pdcMvWAddCh(treescrn, 8, 18, TChType('\'));
  pdcMvWAddCh(treescrn, 9, 18, TChType('\'));
  pdcMvWAddCh(treescrn, 10, 19, TChType('\'));
  pdcMvWAddCh(treescrn, 11, 21, TChType('\'));
  pdcMvWAddCh(treescrn, 12, 22, TChType('\'));

  pdcMvWAddCh(treescrn, 4, 10, TChType('_'));
  pdcMvWAddCh(treescrn, 4, 14, TChType('_'));
  pdcMvWAddCh(treescrn, 8, 7, TChType('_'));
  pdcMvWAddCh(treescrn, 8, 17, TChType('_'));

  pdcMvWAddStr(treescrn, 13, 0, '//////////// \\\\\\\\\\\\');

  if pdcHasColors = PDC_TRUE then
  begin
    pdcInitPair(20, COLOR_YELLOW, COLOR_BLACK);
    pdcWAttrSet(treescrn, pdcColorPair(20));
  end;

  pdcMvWAddStr(treescrn, 14, 11, '| |');
  pdcMvWAddStr(treescrn, 15, 11, '|_|');

  pdcWRefresh(treescrn);
  pdcWRefresh(w_del_msg);
end;

procedure TMain.balls;
var
  ball1, ball2, ball3, ball4, ball5, ball6: TChType;
begin
  pdcOverlay(treescrn, treescrn2);

  if pdcHasColors = PDC_TRUE then
  begin
    pdcInitPair(1, COLOR_BLUE, COLOR_BLACK);
    pdcInitPair(2, COLOR_RED, COLOR_BLACK);
    pdcInitPair(3, COLOR_MAGENTA, COLOR_BLACK);
    pdcInitPair(4, COLOR_CYAN, COLOR_BLACK);
    pdcInitPair(5, COLOR_YELLOW, COLOR_BLACK);
    pdcInitPair(6, COLOR_WHITE, COLOR_BLACK);

    ball1 := pdcColorPair(1) OR TChType('@');
    ball2 := pdcColorPair(2) OR TChType('@');
    ball3 := pdcColorPair(3) OR TChType('@');
    ball4 := pdcColorPair(4) OR TChType('@');
    ball5 := pdcColorPair(5) OR TChType('@');
    ball6 := pdcColorPair(6) OR TChType('@');
  end else
  begin
    ball1 := TChType('@');
    ball2 := TChType('@');
    ball3 := TChType('@');
    ball4 := TChType('@');
    ball5 := TChType('@');
    ball6 := TChType('@');
  end;

  pdcMvWAddCh(treescrn2, 3, 9, ball1);
  pdcMvWAddCh(treescrn2, 3, 15, ball2);
  pdcMvWAddCh(treescrn2, 4, 8, ball3);
  pdcMvWAddCh(treescrn2, 4, 16, ball4);
  pdcMvWAddCh(treescrn2, 5, 7, ball5);
  pdcMvWAddCh(treescrn2, 5, 17, ball6);
  pdcMvWAddCh(treescrn2, 7, 6, ball1 OR A_BOLD);
  pdcMvWAddCh(treescrn2, 7, 18, ball2 OR A_BOLD);
  pdcMvWAddCh(treescrn2, 8, 5, ball3 OR A_BOLD);
  pdcMvWAddCh(treescrn2, 8, 19, ball4 OR A_BOLD);
  pdcMvWAddCh(treescrn2, 10, 4, ball5 OR A_BOLD);
  pdcMvWAddCh(treescrn2, 10, 20, ball6 OR A_BOLD);
  pdcMvWAddCh(treescrn2, 11, 2, ball1);
  pdcMvWAddCh(treescrn2, 11, 22, ball2);
  pdcMvWAddCh(treescrn2, 12, 1, ball3);
  pdcMvWAddCh(treescrn2, 12, 23, ball4);

  pdcWRefresh(treescrn2);
  pdcWRefresh(w_del_msg);
end;

procedure TMain.star;
begin
  pdcMvWAddCh(treescrn2, 0, 12, TChType('*') OR A_STANDOUT);

  pdcWRefresh(treescrn2);
  pdcWRefresh(w_del_msg);
end;

procedure TMain.strng1;
begin
  if pdcHasColors = PDC_TRUE then
  begin
    pdcInitPair(10, COLOR_YELLOW, COLOR_BLACK);
    pdcWAttrSet(treescrn2, pdcColorPair(10) OR A_BOLD);
  end;

  pdcMvWAddStr(treescrn2, 3, 11, '.:''');

  pdcWRefresh(treescrn2);
  pdcWRefresh(w_del_msg);
end;

procedure TMain.strng2;
begin
  if pdcHasColors = PDC_TRUE then
  begin
    pdcInitPair(11, COLOR_RED, COLOR_BLACK);
    pdcWAttrSet(treescrn2, pdcColorPair(11) OR A_BOLD);
  end;

  pdcMvWAddStr(treescrn2, 5, 11, ',.:''');
  pdcMvWAddStr(treescrn2, 6, 9, ':''');

  pdcWRefresh(treescrn2);
  pdcWRefresh(w_del_msg);
end;

procedure TMain.strng3;
begin
  if pdcHasColors = PDC_TRUE then
  begin
    pdcInitPair(12, COLOR_GREEN, COLOR_BLACK);
    pdcWAttrSet(treescrn2, pdcColorPair(12) OR A_BOLD);
  end;

  pdcMvWAddStr(treescrn2, 7, 13, ',.:''');
  pdcMvWAddStr(treescrn2, 8, 9, ',.:''');

  pdcWRefresh(treescrn2);
  pdcWRefresh(w_del_msg);
end;

procedure TMain.strng4;
begin
  if pdcHasColors = PDC_TRUE then
  begin
    pdcInitPair(13, COLOR_WHITE, COLOR_BLACK);
    pdcWAttrSet(treescrn2, pdcColorPair(13) OR A_BOLD);
  end;

  pdcMvWAddStr(treescrn2, 9, 14, ',.:''');
  pdcMvWAddStr(treescrn2, 10, 10, ',.:''');
  pdcMvWAddStr(treescrn2, 11, 6, ',.:''');
  pdcMvWAddCh(treescrn2, 12, 5, $27); // $27 = '

  pdcWRefresh(treescrn2);
  pdcWRefresh(w_del_msg);
end;

procedure TMain.strng5;
begin
  if pdcHasColors = PDC_TRUE then
  begin
    pdcInitPair(14, COLOR_CYAN, COLOR_BLACK);
    pdcWAttrSet(treescrn2, pdcColorPair(14) OR A_BOLD);
  end;

  pdcMvWAddStr(treescrn2, 11, 16, ',.:''');
  pdcMvWAddStr(treescrn2, 12, 12, ',.:''');

  // save a fully lit tree
  pdcOverlay(treescrn2, treescrn);

  pdcWRefresh(treescrn2);
  pdcWRefresh(w_del_msg);
end;

procedure TMain.blinkit;
begin
  if cycle > 4 then
    cycle := 0;

  pdcTouchWin(treescrn3);

  case cycle of
    0: begin pdcOverlay(treescrn3, treescrn8); end;
    1: begin pdcOverlay(treescrn4, treescrn8); end;
    2: begin pdcOverlay(treescrn5, treescrn8); end;
    3: begin pdcOverlay(treescrn6, treescrn8); end;
    4: begin pdcOverlay(treescrn7, treescrn8); end;
  end;

  pdcWRefresh(treescrn8);
  pdcWRefresh(w_del_msg);

  pdcNapMS(75);
  pdcTouchWin(treescrn8);

  // ALL ON**************************************************
  pdcOverlay(treescrn, treescrn8);
  pdcWRefresh(treescrn8);
  pdcWRefresh(w_del_msg);

  Inc(cycle);
end;

procedure TMain.reindeer;
var
  looper: LongInt;
  i, j: LongInt;
begin
  y_pos := 0;

  // Needs testing; Orig: for (x_pos = 70; x_pos > 62; x_pos--)
  for i := 70 downto 62 do
  begin
    x_pos := i;

    if x_pos < 62 then
      y_pos := 1;

    for looper := 0 to 4 - 1 do
    begin
      pdcMvWAddCh(dotdeer0, y_pos, x_pos, TChType('.'));
      pdcWRefresh(dotdeer0);
      pdcWRefresh(w_del_msg);
      pdcWErase(dotdeer0);
      pdcWRefresh(dotdeer0);
      pdcWRefresh(w_del_msg);
    end;
  end;

  y_pos := 2;

  for i := 62 downto 50 do
  begin
    x_pos := i;

    for looper := 0 to 4 - 1 do
    begin
      if x_pos < 56 then
      begin
        y_pos := 3;

        pdcMvWAddCh(stardeer0, y_pos, x_pos, TChType('*'));
        pdcWRefresh(stardeer0);
        pdcWRefresh(w_del_msg);
        pdcWErase(stardeer0);
        pdcWRefresh(stardeer0);
      end else
      begin
        pdcMvWAddCh(dotdeer0, y_pos, x_pos, TChType('*'));
        pdcWRefresh(dotdeer0);
        pdcWRefresh(w_del_msg);
        pdcWErase(dotdeer0);
        pdcWRefresh(dotdeer0);
      end;

      pdcWRefresh(w_del_msg);
    end;
  end;

  x_pos := 58;

  for j := 2 to 5 - 1 do
  begin
    y_pos := j;
    tshow(lildeer0, 50);

    for looper := 0 to 4 - 1 do
    begin
      show(lildeer3, 50);
      show(lildeer2, 50);
      show(lildeer1, 50);
      show(lildeer2, 50);
      show(lildeer3, 50);

      tshow(lildeer0, 50);

      Dec(x_pos, 2);
    end;
  end;

  x_pos := 35;

  for j := 5 to 10 - 1 do
  begin
    y_pos := j;
    pdcTouchWin(middeer0);
    pdcWRefresh(middeer0);
    pdcWRefresh(w_del_msg);

    for looper := 0 to 2 - 1 do
    begin
      show(middeer3, 50);
      show(middeer2, 50);
      show(middeer1, 50);
      show(middeer2, 50);
      show(middeer3, 50);

      tshow(middeer0, 50);

      Dec(x_pos, 3);
    end;
  end;

  pdcNapMS(2000);
  y_pos := 1;

  for i := 8 to 16 - 1 do
  begin
    x_pos := i;

    show(bigdeer4, 30);
    show(bigdeer3, 30);
    show(bigdeer2, 30);
    show(bigdeer1, 30);
    show(bigdeer2, 30);
    show(bigdeer3, 30);
    show(bigdeer4, 30);
    show(bigdeer0, 30);
  end;

  x_pos := 15;

  for looper := 0 to 6 - 1 do
  begin
    show(lookdeer4, 40);
    show(lookdeer3, 40);
    show(lookdeer2, 40);
    show(lookdeer1, 40);
    show(lookdeer2, 40);
    show(lookdeer3, 40);
    show(lookdeer4, 40);
  end;

  show(lookdeer0, 40);

  for j := y_pos to 10 - 1 do
  begin
    y_pos := j;

    for looper := 0 to 2 - 1 do
    begin
      show(bigdeer4, 30);
      show(bigdeer3, 30);
      show(bigdeer2, 30);
      show(bigdeer1, 30);
      show(bigdeer2, 30);
      show(bigdeer3, 30);
      show(bigdeer4, 30);
    end;

    show(bigdeer0, 30);
  end;

  y_pos := 9;

  pdcMvWin(lookdeer3, y_pos, x_pos);
  pdcWRefresh(lookdeer3);
  pdcWRefresh(w_del_msg);
end;

procedure TMain.tshow(aWindow: PWindow; aTime: LongInt);
begin
  pdcTouchWin(aWindow);
  pdcWRefresh(aWindow);
  pdcWRefresh(w_del_msg);
  pdcNapMS(aTime);
end;

procedure TMain.show(aWindow: PWindow; aTime: LongInt);
begin
  pdcMvWin(aWindow, y_pos, x_pos);
  pdcWRefresh(aWindow);
  pdcWRefresh(w_del_msg);
  pdcNapMS(aTime);
end;

end.
