unit R_Main;
{
 ****************************************************************************
 * Copyright (c) 2002 Free Software Foundation, Inc.                        *
 *                                                                          *
 * Permission is hereby granted, free of charge, to any person obtaining a  *
 * copy of this software and associated documentation files (the            *
 * "Software"), to deal in the Software without restriction, including      *
 * without limitation the rights to use, copy, modify, merge, publish,      *
 * distribute, distribute with modifications, sublicense, and/or sell       *
 * copies of the Software, and to permit persons to whom the Software is    *
 * furnished to do so, subject to the following conditions:                 *
 *                                                                          *
 * The above copyright notice and this permission notice shall be included  *
 * in all copies or substantial portions of the Software.                   *
 *                                                                          *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS  *
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF               *
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.   *
 * IN NO EVENT SHALL THE ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,   *
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR    *
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR    *
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.                               *
 *                                                                          *
 * Except as contained in this notice, the name(s) of the above copyright   *
 * holders shall not be used in advertising or otherwise to promote the     *
 * sale, use or other dealings in this Software without prior written       *
 * authorization.                                                           *
 ****************************************************************************

 rain 11/3/1980 EPS/CITHEP
}

interface
uses
  SysUtils, PDCurses;

type
  TMain = class(TObject)
  private
    function next_j(aJ: LongInt): LongInt;
  public
    procedure main;
  end;

implementation

procedure TMain.main;
var
  x, y, j, r, c: LongInt;
  xpos, ypos:    array[0..4] of LongInt;
  bg:            SmallInt;
begin
  Randomize;
  pdcInitLib;
  pdcInitScr;

  if pdcHasColors = PDC_TRUE then
  begin
    bg := COLOR_BLACK;

    pdcStartColor;

    {
    if (use_default_colors() == OK)
      bg = -1;
    }

    pdcInitPair(1, COLOR_BLUE, bg);
    pdcInitPair(2, COLOR_CYAN, bg);
  end;

  pdcNL;
  pdcNoEcho;
  pdcCursSet(0);
  pdcTimeout(0);
  pdcKeyPad(pdcSValStdScr, PDC_TRUE);

  r := pdcSValLines - 4;
  c := pdcSValCols  - 4;

  for j := 5 downto 0 do
  begin
    xpos[j] := (Random(MaxLongInt) mod c) + 2;
    ypos[j] := (Random(MaxLongInt) mod r) + 2;
  end;

  j := 0;

  while True do
  begin
    x := (Random(MaxLongInt) mod c) + 2;
    y := (Random(MaxLongInt) mod r) + 2;

    pdcMvAddCh(y, x, TChType('.'));

    pdcMvAddCh(ypos[j], xpos[j], TChType('o'));

    j := next_j(j);
    pdcMvAddCh(ypos[j], xpos[j], TChType('O'));

    j := next_j(j);
    pdcMvAddCh(ypos[j] - 1, xpos[j],   TChType('-'));
    pdcMvAddStr(ypos[j], xpos[j] - 1, '|.|');
    pdcMvAddCh(ypos[j] + 1, xpos[j],   TChType('-'));

    j := next_j(j);
    pdcMvAddCh(ypos[j]  - 2, xpos[j],       TChType('-'));
    pdcMvAddStr(ypos[j] - 1, xpos[j] - 1,  '/ \');
    pdcMvAddStr(ypos[j],     xpos[j] - 2, '| O |');
    pdcMvAddStr(ypos[j] + 1, xpos[j] - 1,  '\ /');
    pdcMvAddCh(ypos[j]  + 2, xpos[j],       TChType('-'));

    j := next_j(j);
    pdcMvAddCh(ypos[j]  - 2, xpos[j],       TChType(' '));
    pdcMvAddStr(ypos[j] - 1, xpos[j] - 1,  '   ');
    pdcMvAddStr(ypos[j],     xpos[j] - 2, '     ');
    pdcMvAddStr(ypos[j] + 1, xpos[j] - 1,  '   ');
    pdcMvAddCh(ypos[j]  + 2, xpos[j],       TChType(' '));

    xpos[j] := x;
    ypos[j] := y;

    case pdcGetCh of
      TChType('q'), TChType('Q'):
      begin
        pdcCursSet(1);
        pdcEndWin;
        pdcFreeLib;
        Exit;
      end;
      TChType('s'):
        pdcNoDelay(pdcSValStdScr, PDC_FALSE);
      TChType(' '):
        pdcNoDelay(pdcSValStdScr, PDC_TRUE);
    end;

    pdcNapMS(100);
  end;

  pdcFreeLib;
end;

function TMain.next_j(aJ: LongInt): LongInt;
var
  z:     LongInt;
  color: TChType;
begin
  if aJ = 0 then
    aJ := 4
  else
    Dec(aJ);

  if pdcHasColors = PDC_TRUE then
  begin
    z     := Random(MaxLongInt) mod 3;
    color := pdcColorPair(z);

    if z > 0 then
      color := color OR A_BOLD;

    pdcAttrSet(color);
  end;

  Result := aJ;
end;

end.
