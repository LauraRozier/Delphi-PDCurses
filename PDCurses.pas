unit PDCurses;
// Public Domain Curses
{
  *----------------------------------------------------------------------*
  *                              PDCurses                                *
  *----------------------------------------------------------------------*
}
{$I PDCurses.inc}

interface
uses
  SysUtils,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF MSWINDOWS}
  {$IFDEF POSIX}
  Posix.Dlfcn,
  {$ENDIF POSIX}
  PDVarArgCaller;

const
{$IFDEF MSWINDOWS}
  {$IFDEF WIN32}
  LIBPDCURSES = 'pdcurses.dll';
  {$ELSE WIN32}
    {$IFDEF WIN64}
  LIBPDCURSES = 'pdcurses64.dll';
    {$ENDIF WIN64}
  {$ENDIF WIN32}
{$ELSE MSWINDOWS}
  {$IFDEF MACOS}
  // These could also be .a, depending on the compiler used for PDCurses
  LIBPDCURSES = 'pdcurses.lib';
  LIBPDCPANEL = 'panel.lib';
  {$ELSE MACOS}
    {$IFDEF LINUX}
  LIBPDCURSES = 'libXCurses';
    {$ENDIF LINUX}
  {$ENDIF MACOS}
{$ENDIF MSWINDOWS}

var
  PDCLibHandle: Pointer;
{$IFDEF MACOS}
  PDCPanelLibHandle: Pointer;
{$ENDIF MACOS}

{
  Compatability types
}
type
  EDLLLoadError = class(exception);
  TPoint        = record
    X, Y: LongInt;
  end;
  PPoint        = ^TPoint;
  PPPoint       = ^PPoint;
  PFile         = Pointer;
  PPFile        = ^PFile;
  TBool         = Byte; // PDCurses Boolean type
  PBool         = ^TBool;
  PPBool        = ^PBool;

{
  PDCurses Manifest Constants
}
const
  PDC_FALSE: TBool = 0;
  PDC_TRUE:  TBool = 1;
  PDC_NULL         = nil;
  PDC_ERR          = -1;
  PDC_OK           = 0;

{
  PDCurses Type Declarations
}
type
  {$IFDEF CHTYPE_EXTRA_LONG}
  TChType  = UInt64; // "non-standard" 64-bit chtypes
  {$ELSE CHTYPE_EXTRA_LONG}
    {$IFDEF CHTYPE_LONG}
  TChType  = LongWord; // Standard" CHTYPE_LONG case, 16-bit attr + 16-bit char
    {$ELSE CHTYPE_LONG}
  TChType  = SmallInt; // 8-bit attr + 8-bit char
    {$ENDIF CHTYPE_LONG}
  {$ENDIF CHTYPE_EXTRA_LONG}
  PChType  = ^TChType;
  PPChType = ^PChType;

  {$IFDEF PDC_WIDE}
  TCChar  = TChType;
  PCChar  = ^TCChar;
  PPCChar = ^PCChar;
  {$ENDIF PDC_WIDE}

  TAttr  = TChType; // must be at least as wide as chtype
  PAttr  = ^TAttr;
  PPAttr = ^PAttr;

{
  Version constants, available as of version 4.0 :
}
type
  TPort  = (
    PDC_PORT_X11     = 0,
    PDC_PORT_WIN32  {= 1},
    PDC_PORT_WIN32A {= 2},
    PDC_PORT_DOS    {= 3},
    PDC_PORT_OS2    {= 4},
    PDC_PORT_SDL1   {= 5},
    PDC_PORT_SDL2   {= 6}
  );
  PPort  = ^TPort;
  PPPort = ^PPort;

  TVersionInfo  = record
    port:           TPort;
    ver_major,
    ver_minor,
    ver_change:     LongInt;
    chtype_size:    NativeUInt;
    is_wide,
    is_forced_utf8: Bool;
  end;
  PVersionInfo  = ^TVersionInfo;
  PPVersionInfo = ^PVersionInfo;

{
  PDCurses Mouse Interface -- SYSVR4, with extensions

  Most flavors of PDCurses support three buttons.  Win32a supports
  these plus two "extended" buttons.  But we'll set this macro to
  six,  allowing future versions to support up to nine total buttons.
  (The button states are broken up into two arrays to allow for the
  possibility of backward compatibility to DLLs compiled with only
  three mouse buttons.)
}
const
  PDC_MAX_MOUSE_BUTTONS        = 9;
  PDC_N_EXTENDED_MOUSE_BUTTONS = 6;

type
  TMouseStatus  = record
    X:       LongInt;                // absolute column, 0 based, measured in characters
    Y:       LongInt;                // absolute row, 0 based, measured in characters
    button:  array[0..2] of SmallInt; // state of each button
    changes: LongInt;                // flags indicating what has changed with the mouse
    xbutton: array[0..PDC_N_EXTENDED_MOUSE_BUTTONS - 1] of SmallInt; // state of ext buttons
  end;
  PMouseStatus  = ^TMouseStatus;
  PPMouseStatus = ^PMouseStatus;

const
  BUTTON_RELEASED       = $0000;
  BUTTON_PRESSED        = $0001;
  BUTTON_CLICKED        = $0002;
  BUTTON_DOUBLE_CLICKED = $0003;
  BUTTON_TRIPLE_CLICKED = $0004;
  BUTTON_MOVED          = $0005; // PDCurses
  WHEEL_SCROLLED        = $0006; // PDCurses
  BUTTON_ACTION_MASK    = $0007; // PDCurses

  PDC_BUTTON_SHIFT      = $0008; // PDCurses
  PDC_BUTTON_CONTROL    = $0010; // PDCurses
  PDC_BUTTON_ALT        = $0020; // PDCurses
  BUTTON_MODIFIER_MASK  = $0038; // PDCurses

function MOUSE_X_POS: LongInt; inline;
function MOUSE_Y_POS: LongInt; inline;

{
   Bits associated with the .changes field:
     3         2         1         0
   210987654321098765432109876543210
                                   1 <- button 1 has changed   0
                                  10 <- button 2 has changed   1
                                 100 <- button 3 has changed   2
                                1000 <- mouse has moved        3
                               10000 <- mouse position report  4
                              100000 <- mouse wheel up         5
                             1000000 <- mouse wheel down       6
                            10000000 <- mouse wheel left       7
                           100000000 <- mouse wheel right      8
                          1000000000 <- button 4 has changed   9
   (NOTE: buttons 6 to   10000000000 <- button 5 has changed  10
   9 aren't implemented 100000000000 <- button 6 has changed  11
   in any flavor of    1000000000000 <- button 7 has changed  12
   PDCurses yet!)     10000000000000 <- button 8 has changed  13
                     100000000000000 <- button 9 has changed  14
}

const
  PDC_MOUSE_MOVED       = $0008;
  PDC_MOUSE_POSITION    = $0010;
  PDC_MOUSE_WHEEL_UP    = $0020;
  PDC_MOUSE_WHEEL_DOWN  = $0040;
  PDC_MOUSE_WHEEL_LEFT  = $0080;
  PDC_MOUSE_WHEEL_RIGHT = $0100;

function A_BUTTON_CHANGED:               LongInt; inline;
function MOUSE_MOVED:                    LongInt; inline;
function MOUSE_POS_REPORT:               LongInt; inline;
function BUTTON_CHANGED(aButton: Int32): LongInt; inline;
function BUTTON_STATUS(aButton: Int32):  LongInt; inline;
function MOUSE_WHEEL_UP:                 LongInt; inline;
function MOUSE_WHEEL_DOWN:               LongInt; inline;
function MOUSE_WHEEL_LEFT:               LongInt; inline;
function MOUSE_WHEEL_RIGHT:              LongInt; inline;

{
  mouse bit-masks
}
const
  BUTTON1_RELEASED:        LongInt = $00000001;
  BUTTON1_PRESSED:         LongInt = $00000002;
  BUTTON1_CLICKED:         LongInt = $00000004;
  BUTTON1_DOUBLE_CLICKED:  LongInt = $00000008;
  BUTTON1_TRIPLE_CLICKED:  LongInt = $00000010;
  BUTTON1_MOVED:           LongInt = $00000010; // PDCurses

  BUTTON2_RELEASED:        LongInt = $00000020;
  BUTTON2_PRESSED:         LongInt = $00000040;
  BUTTON2_CLICKED:         LongInt = $00000080;
  BUTTON2_DOUBLE_CLICKED:  LongInt = $00000100;
  BUTTON2_TRIPLE_CLICKED:  LongInt = $00000200;
  BUTTON2_MOVED:           LongInt = $00000200; // PDCurses

  BUTTON3_RELEASED:        LongInt = $00000400;
  BUTTON3_PRESSED:         LongInt = $00000800;
  BUTTON3_CLICKED:         LongInt = $00001000;
  BUTTON3_DOUBLE_CLICKED:  LongInt = $00002000;
  BUTTON3_TRIPLE_CLICKED:  LongInt = $00004000;
  BUTTON3_MOVED:           LongInt = $00004000; // PDCurses

{
  For the ncurses-compatible functions only, BUTTON4_PRESSED and
  BUTTON5_PRESSED are returned for mouse scroll wheel up and down;
  otherwise PDCurses doesn't support buttons 4 and 5
}
  BUTTON4_RELEASED:        LongInt = $00008000;
  BUTTON4_PRESSED:         LongInt = $00010000;
  BUTTON4_CLICKED:         LongInt = $00020000;
  BUTTON4_DOUBLE_CLICKED:  LongInt = $00040000;
  BUTTON4_TRIPLE_CLICKED:  LongInt = $00080000;

  BUTTON5_RELEASED:        LongInt = $00100000;
  BUTTON5_PRESSED:         LongInt = $00200000;
  BUTTON5_CLICKED:         LongInt = $00400000;
  BUTTON5_DOUBLE_CLICKED:  LongInt = $00800000;
  BUTTON5_TRIPLE_CLICKED:  LongInt = $01000000;

  MOUSE_WHEEL_SCROLL:      LongInt = $02000000; // PDCurses
  BUTTON_MODIFIER_SHIFT:   LongInt = $04000000; // PDCurses
  BUTTON_MODIFIER_CONTROL: LongInt = $08000000; // PDCurses
  BUTTON_MODIFIER_ALT:     LongInt = $10000000; // PDCurses

  ALL_MOUSE_EVENTS:        LongInt = $1FFFFFFF; // PDCurses
  REPORT_MOUSE_POSITION:   LongInt = $20000000; // PDCurses

{
  ncurses mouse interface
}
type
  TMMask  = LongWord;
  PMMask  = ^TMMask;
  PPMMask = ^PMMask;

  TMEvent  = record
    Id:      SmallInt;  // Unused, always 0
    X, Y, Z: LongInt;   // x, y same as MOUSE_STATUS; z unused
    BState:  TMMask; {  Equivalent to changes + button[],
                        but in the same format as used for mousemask() }
  end;
  PMEvent  = ^TMEvent;
  PPMEvent = ^PMEvent;

const
{$IFDEF NCURSES_MOUSE_VERSION}
  BUTTON_SHIFT   = BUTTON_MODIFIER_SHIFT;
  BUTTON_CONTROL = BUTTON_MODIFIER_CONTROL;
  BUTTON_CTRL    = BUTTON_MODIFIER_CONTROL;
  BUTTON_ALT     = BUTTON_MODIFIER_ALT;
{$ELSE NCURSES_MOUSE_VERSION}
  BUTTON_SHIFT   = PDC_BUTTON_SHIFT;
  BUTTON_CONTROL = PDC_BUTTON_CONTROL;
  BUTTON_ALT     = PDC_BUTTON_ALT;
{$ENDIF NCURSES_MOUSE_VERSION}

{
  PDCurses Structure Definitions
}
type
  PWindow  = ^TWindow;     // Putting this here, so it can be used in the record
  TWindow  = record        // definition of a window
    _cury,                 // current pseudo-cursor location
    _curx,
    _maxy,                 // max window coordinates
    _maxx,
    _begy,                 // origin on screen
    _begx,
    _flags:      LongInt;  // window properties
    _attrs,                // standard attributes and colors
    _bkgd:       TChType;  // background, normally blank
    _clear,                // causes clear at next refresh
    _leaveit,              // leaves cursor where it is
    _scroll,               // allows window scrolling
    _nodelay,              // input character wait flag
    _immed,                // immediate update flag
    _sync,                 // synchronise window ancestors
    _use_keypad: TBool;    // flags keypad key mode active
    _y:          PPChType; // pointer to line pointer array
    _firstch,              // first changed character in line
    _lastch:     PLongInt; // last changed character in line
    _tmarg,                // top of scrolling region
    _bmarg,                // bottom of scrolling region
    _delayms,              // milliseconds of delay for getch()
    _parx,                 // coords relative to parent (0, 0)
    _pary:       LongInt;
    _parent:     PWindow;  // subwin's pointer to parent win
  end;
  PPWindow = ^PWindow;

{
  Avoid using the SCREEN struct directly -- use the corresponding functions
  if possible. This record may eventually be made private.
}
  TScreen  = record
    alive,                          // if initscr() called, and not endwin()
    autocr,                         // if cr -> lf
    cbreak,                         // if terminal unbuffered
    echo,                           // if terminal echo
    raw_inp,                        // raw input mode (v. cooked input)
    raw_out,                        // raw output mode (7 v. 8 bits)
    audible,                        // FALSE if the bell is visual
    mono,                           // TRUE if current screen is mono
    resized,                        // TRUE if TERM has been resized
    orig_attr:            TBool;    // TRUE if we have the original colors
    orig_fore,                      // original screen foreground color
    orig_back:            SmallInt; // original screen foreground color
    cursrow,                        // position of physical cursor
    curscol,
    visibility,                     // visibility of cursor
    orig_cursor,                    // original cursor size
    lines,                          // new value for LINES
    cols:                 LongInt;  // new value for COLS
    _trap_mbe,                      // trap these mouse button events
    _map_mbe_to_key:      LongWord; // map mouse buttons to slk
    mouse_wait,                     {  time to wait (in ms) for a button release
                                       after a press, in order to count it as a
                                       click }
    slklines:             LongInt;  // lines in use by slk_init()
    slk_winptr:           PWindow;  // window for slk
    linesrippedoff,                 // lines ripped off via ripoffline()
    linesrippedoffontop,            // lines ripped off on top via ripoffline()
    delaytenths:          LongInt;  // 1/10ths second to wait block getch() for
    _preserve:            TBool;    // TRUE if screen background to be preserved
    _restore:             LongInt;  {  specifies if screen background to be
                                       restored, and how }
    save_key_modifiers,             {  TRUE if each key modifiers saved with
                                       each key press }
    return_key_modifiers,           {  TRUE if modifier keys are returned as
                                       "real" keys }
    key_code:             TBool;    {  TRUE if last key is a special key;
                                       used internally by get_wch() }
{$IFDEF XCURSES}
    XcurscrSize:          LongInt;  // size of Xcurscr shared memory block
    sb_on:                TBool;
    sb_viewport_y,
    sb_viewport_x,
    sb_total_y,
    sb_total_x,
    sb_cur_y,
    sb_cur_x:             LongInt;
{$ENDIF XCURSES}
    line_color:           SmallInt; // color of line attributes - default -1
  end;
  PScreen  = ^TScreen;
  PPScreen = ^PScreen;

{
  PDCurses External Variables
}
type
  TAcsMap  = array[Char] of TCChar;
  PAcsMap  = ^TAcsMap;
  PPAcsMap = ^PAcsMap;
  TPutC    = function(aArg: LongInt): LongInt; cdecl;
  TWinInit = function(aWindow: PWindow; aColCount: LongInt): LongInt; cdecl;

function pdcSValLines:       LongInt; inline;
function pdcSValCols:        LongInt; inline;
function pdcSValStdScr:      PWindow; inline;
function pdcSValCurScr:      PWindow; inline;
function pdcSValSP:          PScreen; inline;
function pdcSValMouseStatus: TMouseStatus; inline;
function pdcSValColors:      LongInt; inline;
function pdcSValColorPairs:  LongInt; inline;
function pdcSValTabSize:     LongInt; inline;
function pdcSValAcsMap:      TAcsMap; inline;
{$IFDEF MSWINDOWS}
function pdcSValTtyType:     AnsiString; inline;
{$ENDIF MSWINDOWS}
{$IFDEF LINUX}
function pdcSValTtyType:     string; inline;
{$ENDIF LINUX}
function pdcSValVersion:     TVersionInfo; inline;

{
man-start**************************************************************

PDCurses Text Attributes
========================

Originally, PDCurses used a short (16 bits) for its chtype. To include
color, a number of things had to be sacrificed from the strict Unix and
System V support. The main problem was fitting all character attributes
and color into an unsigned char (all 8 bits!).

Today, PDCurses by default uses a long (32 bits) for its chtype, as in
System V. The short chtype is still available, by undefining CHTYPE_LONG
and rebuilding the library.

The following is the structure of a win->_attrs chtype:

short form:

-------------------------------------------------
|15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0|
-------------------------------------------------
  color number |  attrs |   character eg 'a'

The available non-color attributes are bold, reverse and blink. Others
have no effect. The high order char is an index into an array of
physical colors (defined in color.c) -- 32 foreground/background color
pairs (5 bits) plus 3 bits for other attributes.

long form:

----------------------------------------------------------------------------
|31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|..| 3| 2| 1| 0|
----------------------------------------------------------------------------
      color number      |     modifiers         |      character eg 'a'

The available non-color attributes are bold, underline, invisible,
right-line, left-line, protect, reverse and blink. 256 color pairs (8
bits), 8 bits for other attributes, and 16 bits for character data.

Note that there is now a "super-long" 64-bit form, available by
defining CHTYPE_LONG to be 2:

-------------------------------------------------------------------------------
|63|62|61|60|59|..|34|33|32|31|30|29|28|..|22|21|20|19|18|17|16|..| 3| 2| 1| 0|
-------------------------------------------------------------------------------
         color number   |        modifiers      |         character eg 'a'


   We take five more bits for the character (thus allowing Unicode values
past 64K;  UTF-16 can go up to 0x10ffff,  requiring 21 bits total),  and
four more bits for attributes.  Three are currently used as A_OVERLINE, A_DIM,
and A_STRIKEOUT;  one more is reserved for future use.  31 bits are then used
for color.  These are usually just treated as the usual palette
indices,  and range from 0 to 255.   However,  if bit 63 is
set,  the remaining 30 bits are interpreted as foreground RGB (first
fifteen bits,  five bits for each of the three channels) and background RGB
(same scheme using the remaining 15 bits.)

man-end****************************************************************
}
{
  Video attribute macros
}
const
  A_NORMAL = $0;

{$IF Defined(CHTYPE_LONG) OR Defined(CHTYPE_EXTRA_LONG)}
  {$IFDEF CHTYPE_EXTRA_LONG} // 64-bit chtypes
  PDC_CHARTEXT_BITS = $15;
  A_CHARTEXT        = (TChType($1)  SHL PDC_CHARTEXT_BITS) - 1;
  A_ALTCHARSET      = TChType($001) SHL PDC_CHARTEXT_BITS;
  A_RIGHTLINE       = TChType($002) SHL PDC_CHARTEXT_BITS;
  A_LEFTLINE        = TChType($004) SHL PDC_CHARTEXT_BITS;
  A_INVIS           = TChType($008) SHL PDC_CHARTEXT_BITS;
  A_UNDERLINE       = TChType($010) SHL PDC_CHARTEXT_BITS;
  A_REVERSE         = TChType($020) SHL PDC_CHARTEXT_BITS;
  A_BLINK           = TChType($040) SHL PDC_CHARTEXT_BITS;
  A_BOLD            = TChType($080) SHL PDC_CHARTEXT_BITS;
  A_OVERLINE        = TChType($100) SHL PDC_CHARTEXT_BITS;
  A_STRIKEOUT       = TChType($200) SHL PDC_CHARTEXT_BITS;
  A_DIM             = TChType($400) SHL PDC_CHARTEXT_BITS;
{ May come up with a use for this bit someday; reserved for the future: }
//  A_FUTURE_2        = ChType(ChType($800)      shl PDC_CHARTEXT_BITS);
  PDC_COLOR_SHIFT   = PDC_CHARTEXT_BITS + $C;
  A_COLOR           = TChType($7FFFFFFF) SHL PDC_COLOR_SHIFT;
  A_RGB_COLOR       = TChType($40000000) SHL PDC_COLOR_SHIFT;
  A_ATTRIBUTES      = (TChType($FFF)     SHL PDC_CHARTEXT_BITS) OR A_COLOR;

function A_RGB(aRFore, aGFore, aBFore,
               aRBack, aGBack, aBBack: TChType): TChType; inline;

const
  {$ELSE CHTYPE_EXTRA_LONG} // plain ol' 32-bit chtypes
  A_ALTCHARSET    = TChType($00010000);
  A_RIGHTLINE     = TChType($00020000);
  A_LEFTLINE      = TChType($00040000);
  A_INVIS         = TChType($00080000);
  A_UNDERLINE     = TChType($00100000);
  A_REVERSE       = TChType($00200000);
  A_BLINK         = TChType($00400000);
  A_BOLD          = TChType($00800000);
  A_COLOR         = TChType($FF000000);
  A_RGB_COLOR     = A_NORMAL;
    {$IFDEF PDC_WIDE}
  A_CHARTEXT      = TChType($0000FFFF);
  A_ATTRIBUTES    = TChType($FFFF0000);
  A_DIM           = A_NORMAL;
  A_OVERLINE      = A_NORMAL;
  A_STRIKEOUT     = A_NORMAL;
    {$ELSE PDC_WIDE} // with 8-bit chars, we have bits for these attribs :
  A_CHARTEXT      = TChType($000000FF);
  A_ATTRIBUTES    = TChType($FFFFE000);
  A_DIM           = TChType($00008000);
  A_OVERLINE      = TChType($00004000);
  A_STRIKEOUT     = TChType($00002000);
    {$ENDIF PDC_WIDE}
  PDC_COLOR_SHIFT = $18;
  {$ENDIF CHTYPE_EXTRA_LONG}

  A_ITALIC        = A_INVIS;
  A_PROTECT       = A_UNDERLINE OR A_LEFTLINE OR A_RIGHTLINE;
{$ELSE Defined(CHTYPE_LONG) OR Defined(CHTYPE_EXTRA_LONG)} // 16-bit chtypes
  A_BOLD          = TChType($0100); // X/Open
  A_REVERSE       = TChType($0200); // X/Open
  A_BLINK         = TChType($0400); // X/Open

  A_ATTRIBUTES    = TChType($FF00); // X/Open
  A_CHARTEXT      = TChType($00FF); // X/Open
  A_COLOR         = TChType($F800); // System V

  A_ALTCHARSET    = A_NORMAL;      // X/Open
  A_PROTECT       = A_NORMAL;      // X/Open
  A_UNDERLINE     = A_NORMAL;      // X/Open
  A_OVERLINE      = A_NORMAL;      // X/Open
  A_STRIKEOUT     = A_NORMAL;      // X/Open

  A_LEFTLINE      = A_NORMAL;
  A_RIGHTLINE     = A_NORMAL;
  A_ITALIC        = A_NORMAL;
  A_INVIS         = A_NORMAL;
  A_RGB_COLOR     = A_NORMAL;
  A_DIM           = A_NORMAL;

  PDC_COLOR_SHIFT = $B;
{$IFEND Defined(CHTYPE_LONG) OR Defined(CHTYPE_EXTRA_LONG)}

  A_STANDOUT      = A_REVERSE OR A_BOLD; // X/Open
  CHR_MSK         = A_CHARTEXT;          // Obsolete
  ATR_MSK         = A_ATTRIBUTES;        // Obsolete
  ATR_NRM         = A_NORMAL;            // Obsolete

{
  For use with attr_t -- X/Open says, "these shall be distinct", so
  this is a non-conforming implementation.
}
const
  WA_NORMAL     = A_NORMAL;

  WA_ALTCHARSET = A_ALTCHARSET;
  WA_BLINK      = A_BLINK;
  WA_BOLD       = A_BOLD;
  WA_DIM        = A_DIM;
  WA_INVIS      = A_INVIS;
  WA_LEFT       = A_LEFTLINE;
  WA_PROTECT    = A_PROTECT;
  WA_REVERSE    = A_REVERSE;
  WA_RIGHT      = A_RIGHTLINE;
  WA_STANDOUT   = A_STANDOUT;
  WA_UNDERLINE  = A_UNDERLINE;

  WA_HORIZONTAL = A_NORMAL;
  WA_LOW        = A_NORMAL;
  WA_TOP        = A_NORMAL;
  WA_VERTICAL   = A_NORMAL;

  WA_ATTRIBUTES = A_ATTRIBUTES;

{
  Alternate character set macros

  'aWChar' = 32-bit chtype; acs_map[] index | A_ALTCHARSET
  'aNChar' = 16-bit chtype; it gets the fallback set because no bit is
             available for A_ALTCHARSET
}
function pdcAcsPick(aWChar, aNChar: AnsiChar): TChType; inline;

// VT100-compatible symbols -- box chars
function ACS_LRCORNER: TChType; inline; { lower right corner }
function ACS_URCORNER: TChType; inline; { upper right corner }
function ACS_ULCORNER: TChType; inline; { upper left corner }
function ACS_LLCORNER: TChType; inline; { lower left corner }
function ACS_PLUS: TChType; inline;     { large plus or crossover }
function ACS_LTEE: TChType; inline;     { tee pointing right }
function ACS_RTEE: TChType; inline;     { tee pointing left }
function ACS_BTEE: TChType; inline;     { tee pointing up }
function ACS_TTEE: TChType; inline;     { tee pointing down }
function ACS_HLINE: TChType; inline;    { horizontal line }
function ACS_VLINE: TChType; inline;    { vertical line }

// PDCurses-only ACS chars.  Don't use if ncurses compatibility matters.
// Some won't work in non-wide X11 builds (see 'acs_defs.h' for details).
function ACS_CENT: TChType; inline;
function ACS_YEN: TChType; inline;
function ACS_PESETA: TChType; inline;
function ACS_HALF: TChType; inline;
function ACS_QUARTER: TChType; inline;
function ACS_LEFT_ANG_QU: TChType; inline;
function ACS_RIGHT_ANG_QU: TChType; inline;
function ACS_D_HLINE: TChType; inline;
function ACS_D_VLINE: TChType; inline;
function ACS_CLUB: TChType; inline;
function ACS_HEART: TChType; inline;
function ACS_SPADE: TChType; inline;
function ACS_SMILE: TChType; inline;
function ACS_REV_SMILE: TChType; inline;
function ACS_MED_BULLET: TChType; inline;
function ACS_WHITE_BULLET: TChType; inline;
function ACS_PILCROW: TChType; inline;
function ACS_SECTION: TChType; inline;

function ACS_SUP2: TChType; inline;
function ACS_ALPHA: TChType; inline;
function ACS_BETA: TChType; inline;
function ACS_GAMMA: TChType; inline;
function ACS_UP_SIGMA: TChType; inline;
function ACS_LO_SIGMA: TChType; inline;
function ACS_MU: TChType; inline;
function ACS_TAU: TChType; inline;
function ACS_UP_PHI: TChType; inline;
function ACS_THETA: TChType; inline;
function ACS_OMEGA: TChType; inline;
function ACS_DELTA: TChType; inline;
function ACS_INFINITY: TChType; inline;
function ACS_LO_PHI: TChType; inline;
function ACS_EPSILON: TChType; inline;
function ACS_INTERSECT: TChType; inline;
function ACS_TRIPLE_BAR: TChType; inline;
function ACS_DIVISION: TChType; inline;
function ACS_APPROX_EQ: TChType; inline;
function ACS_SM_BULLET: TChType; inline;
function ACS_SQUARE_ROOT: TChType; inline;
function ACS_UBLOCK: TChType; inline;
function ACS_BBLOCK: TChType; inline;
function ACS_LBLOCK: TChType; inline;
function ACS_RBLOCK: TChType; inline;

function ACS_A_ORDINAL: TChType; inline;
function ACS_O_ORDINAL: TChType; inline;
function ACS_INV_QUERY: TChType; inline;
function ACS_REV_NOT: TChType; inline;
function ACS_NOT: TChType; inline;
function ACS_INV_BANG: TChType; inline;
function ACS_UP_INTEGRAL: TChType; inline;
function ACS_LO_INTEGRAL: TChType; inline;
function ACS_SUP_N: TChType; inline;
function ACS_CENTER_SQU: TChType; inline;
function ACS_F_WITH_HOOK: TChType; inline;

function ACS_SD_LRCORNER: TChType; inline;
function ACS_SD_URCORNER: TChType; inline;
function ACS_SD_ULCORNER: TChType; inline;
function ACS_SD_LLCORNER: TChType; inline;
function ACS_SD_PLUS: TChType; inline;
function ACS_SD_LTEE: TChType; inline;
function ACS_SD_RTEE: TChType; inline;
function ACS_SD_BTEE: TChType; inline;
function ACS_SD_TTEE: TChType; inline;

function ACS_D_LRCORNER: TChType; inline;
function ACS_D_URCORNER: TChType; inline;
function ACS_D_ULCORNER: TChType; inline;
function ACS_D_LLCORNER: TChType; inline;
function ACS_D_PLUS: TChType; inline;
function ACS_D_LTEE: TChType; inline;
function ACS_D_RTEE: TChType; inline;
function ACS_D_BTEE: TChType; inline;
function ACS_D_TTEE: TChType; inline;

function ACS_DS_LRCORNER: TChType; inline;
function ACS_DS_URCORNER: TChType; inline;
function ACS_DS_ULCORNER: TChType; inline;
function ACS_DS_LLCORNER: TChType; inline;
function ACS_DS_PLUS: TChType; inline;
function ACS_DS_LTEE: TChType; inline;
function ACS_DS_RTEE: TChType; inline;
function ACS_DS_BTEE: TChType; inline;
function ACS_DS_TTEE: TChType; inline;

// VT100-compatible symbols -- other
function ACS_S1: TChType; inline;
function ACS_S9: TChType; inline;
function ACS_DIAMOND: TChType; inline;
function ACS_CKBOARD: TChType; inline;
function ACS_DEGREE: TChType; inline;
function ACS_PLMINUS: TChType; inline;
function ACS_BULLET: TChType; inline;

// Teletype 5410v1 symbols -- these are defined in SysV curses, but
// are not well-supported by most terminals. Stick to VT100 characters
// for optimum portability.
function ACS_LARROW: TChType; inline;
function ACS_RARROW: TChType; inline;
function ACS_DARROW: TChType; inline;
function ACS_UARROW: TChType; inline;
function ACS_BOARD: TChType; inline;
function ACS_LTBOARD: TChType; inline;
function ACS_LANTERN: TChType; inline;
function ACS_BLOCK: TChType; inline;

// That goes double for these -- undocumented SysV symbols. Don't use them.
function ACS_S3: TChType; inline;
function ACS_S7: TChType; inline;
function ACS_LEQUAL: TChType; inline;
function ACS_GEQUAL: TChType; inline;
function ACS_PI: TChType; inline;
function ACS_NEQUAL: TChType; inline;
function ACS_STERLING: TChType; inline;

// Box char aliases
function ACS_BSSB: TChType; inline;
function ACS_SSBB: TChType; inline;
function ACS_BBSS: TChType; inline;
function ACS_SBBS: TChType; inline;
function ACS_SBSS: TChType; inline;
function ACS_SSSB: TChType; inline;
function ACS_SSBS: TChType; inline;
function ACS_BSSS: TChType; inline;
function ACS_BSBS: TChType; inline;
function ACS_SBSB: TChType; inline;
function ACS_SSSS: TChType; inline;

// cchar_t aliases
{$IFDEF PDC_WIDE}
function WACS_LRCORNER: TCChar; inline;
function WACS_URCORNER: TCChar; inline;
function WACS_ULCORNER: TCChar; inline;
function WACS_LLCORNER: TCChar; inline;
function WACS_PLUS: TCChar; inline;
function WACS_LTEE: TCChar; inline;
function WACS_RTEE: TCChar; inline;
function WACS_BTEE: TCChar; inline;
function WACS_TTEE: TCChar; inline;
function WACS_HLINE: TCChar; inline;
function WACS_VLINE: TCChar; inline;

function WACS_CENT: TCChar; inline;
function WACS_YEN: TCChar; inline;
function WACS_PESETA: TCChar; inline;
function WACS_HALF: TCChar; inline;
function WACS_QUARTER: TCChar; inline;
function WACS_LEFT_ANG_QU: TCChar; inline;
function WACS_RIGHT_ANG_QU: TCChar; inline;
function WACS_D_HLINE: TCChar; inline;
function WACS_D_VLINE: TCChar; inline;
function WACS_CLUB: TCChar; inline;
function WACS_HEART: TCChar; inline;
function WACS_SPADE: TCChar; inline;
function WACS_SMILE: TCChar; inline;
function WACS_REV_SMILE: TCChar; inline;
function WACS_MED_BULLET: TCChar; inline;
function WACS_WHITE_BULLET: TCChar; inline;
function WACS_PILCROW: TCChar; inline;
function WACS_SECTION: TCChar; inline;

function WACS_SUP2: TCChar; inline;
function WACS_ALPHA: TCChar; inline;
function WACS_BETA: TCChar; inline;
function WACS_GAMMA: TCChar; inline;
function WACS_UP_SIGMA: TCChar; inline;
function WACS_LO_SIGMA: TCChar; inline;
function WACS_MU: TCChar; inline;
function WACS_TAU: TCChar; inline;
function WACS_UP_PHI: TCChar; inline;
function WACS_THETA: TCChar; inline;
function WACS_OMEGA: TCChar; inline;
function WACS_DELTA: TCChar; inline;
function WACS_INFINITY: TCChar; inline;
function WACS_LO_PHI: TCChar; inline;
function WACS_EPSILON: TCChar; inline;
function WACS_INTERSECT: TCChar; inline;
function WACS_TRIPLE_BAR: TCChar; inline;
function WACS_DIVISION: TCChar; inline;
function WACS_APPROX_EQ: TCChar; inline;
function WACS_SM_BULLET: TCChar; inline;
function WACS_SQUARE_ROOT: TCChar; inline;
function WACS_UBLOCK: TCChar; inline;
function WACS_BBLOCK: TCChar; inline;
function WACS_LBLOCK: TCChar; inline;
function WACS_RBLOCK: TCChar; inline;

function WACS_A_ORDINAL: TCChar; inline;
function WACS_O_ORDINAL: TCChar; inline;
function WACS_INV_QUERY: TCChar; inline;
function WACS_REV_NOT: TCChar; inline;
function WACS_NOT: TCChar; inline;
function WACS_INV_BANG: TCChar; inline;
function WACS_UP_INTEGRAL: TCChar; inline;
function WACS_LO_INTEGRAL: TCChar; inline;
function WACS_SUP_N: TCChar; inline;
function WACS_CENTER_SQU: TCChar; inline;
function WACS_F_WITH_HOOK: TCChar; inline;

function WACS_SD_LRCORNER: TCChar; inline;
function WACS_SD_URCORNER: TCChar; inline;
function WACS_SD_ULCORNER: TCChar; inline;
function WACS_SD_LLCORNER: TCChar; inline;
function WACS_SD_PLUS: TCChar; inline;
function WACS_SD_LTEE: TCChar; inline;
function WACS_SD_RTEE: TCChar; inline;
function WACS_SD_BTEE: TCChar; inline;
function WACS_SD_TTEE: TCChar; inline;

function WACS_D_LRCORNER: TCChar; inline;
function WACS_D_URCORNER: TCChar; inline;
function WACS_D_ULCORNER: TCChar; inline;
function WACS_D_LLCORNER: TCChar; inline;
function WACS_D_PLUS: TCChar; inline;
function WACS_D_LTEE: TCChar; inline;
function WACS_D_RTEE: TCChar; inline;
function WACS_D_BTEE: TCChar; inline;
function WACS_D_TTEE: TCChar; inline;

function WACS_DS_LRCORNER: TCChar; inline;
function WACS_DS_URCORNER: TCChar; inline;
function WACS_DS_ULCORNER: TCChar; inline;
function WACS_DS_LLCORNER: TCChar; inline;
function WACS_DS_PLUS: TCChar; inline;
function WACS_DS_LTEE: TCChar; inline;
function WACS_DS_RTEE: TCChar; inline;
function WACS_DS_BTEE: TCChar; inline;
function WACS_DS_TTEE: TCChar; inline;

function WACS_S1: TCChar; inline;
function WACS_S9: TCChar; inline;
function WACS_DIAMOND: TCChar; inline;
function WACS_CKBOARD: TCChar; inline;
function WACS_DEGREE: TCChar; inline;
function WACS_PLMINUS: TCChar; inline;
function WACS_BULLET: TCChar; inline;

function WACS_LARROW: TCChar; inline;
function WACS_RARROW: TCChar; inline;
function WACS_DARROW: TCChar; inline;
function WACS_UARROW: TCChar; inline;
function WACS_BOARD: TCChar; inline;
function WACS_LTBOARD: TCChar; inline;
function WACS_LANTERN: TCChar; inline;
function WACS_BLOCK: TCChar; inline;

function WACS_S3: TCChar; inline;
function WACS_S7: TCChar; inline;
function WACS_LEQUAL: TCChar; inline;
function WACS_GEQUAL: TCChar; inline;
function WACS_PI: TCChar; inline;
function WACS_NEQUAL: TCChar; inline;
function WACS_STERLING: TCChar; inline;

function WACS_BSSB: TCChar; inline;
function WACS_SSBB: TCChar; inline;
function WACS_BBSS: TCChar; inline;
function WACS_SBBS: TCChar; inline;
function WACS_SBSS: TCChar; inline;
function WACS_SSSB: TCChar; inline;
function WACS_SSBS: TCChar; inline;
function WACS_BSSS: TCChar; inline;
function WACS_BSBS: TCChar; inline;
function WACS_SBSB: TCChar; inline;
function WACS_SSSS: TCChar; inline;
{$ENDIF PDC_WIDE}

{
  Color macros
}
const
  COLOR_BLACK   = 0;
{$IFDEF PDC_RGB}  // RGB
  COLOR_RED     = 1;
  COLOR_GREEN   = 2;
  COLOR_BLUE    = 4;
{$ELSE PDC_RGB}   // BGR
  COLOR_BLUE    = 1;
  COLOR_GREEN   = 2;
  COLOR_RED     = 4;
{$ENDIF PDC_RGB}
  COLOR_CYAN    = COLOR_BLUE OR COLOR_GREEN;
  COLOR_MAGENTA = COLOR_RED  OR COLOR_BLUE;
  COLOR_YELLOW  = COLOR_RED  OR COLOR_GREEN;
  COLOR_WHITE   = 7;

{
  Function and Keypad Key Definitions.
  Many are just for compatibility.
}
const
{$IFDEF PDC_WIDE}
  KEY_OFFSET = $EC00;
{$ELSE PDC_WIDE}
  KEY_OFFSET = $100;
{$ENDIF PDC_WIDE}

  KEY_CODE_YES     = KEY_OFFSET + $00; // If get_wch() gives a key code
  KEY_BREAK        = KEY_OFFSET + $01; // Not on PC KBD
  KEY_DOWN         = KEY_OFFSET + $02; // Down arrow key
  KEY_UP           = KEY_OFFSET + $03; // Up arrow key
  KEY_LEFT         = KEY_OFFSET + $04; // Left arrow key
  KEY_RIGHT        = KEY_OFFSET + $05; // Right arrow key
  KEY_HOME         = KEY_OFFSET + $06; // home key
  KEY_BACKSPACE    = KEY_OFFSET + $07; // not on pc
  KEY_F0           = KEY_OFFSET + $08; // function keys; 64 reserved

  KEY_DL           = KEY_OFFSET + $48; // delete line
  KEY_IL           = KEY_OFFSET + $49; // insert line
  KEY_DC           = KEY_OFFSET + $4a; // delete character
  KEY_IC           = KEY_OFFSET + $4b; // insert char or enter ins mode
  KEY_EIC          = KEY_OFFSET + $4c; // exit insert char mode
  KEY_CLEAR        = KEY_OFFSET + $4d; // clear screen
  KEY_EOS          = KEY_OFFSET + $4e; // clear to end of screen
  KEY_EOL          = KEY_OFFSET + $4f; // clear to end of line
  KEY_SF           = KEY_OFFSET + $50; // scroll 1 line forward
  KEY_SR           = KEY_OFFSET + $51; // scroll 1 line back = reverse;
  KEY_NPAGE        = KEY_OFFSET + $52; // next page
  KEY_PPAGE        = KEY_OFFSET + $53; // previous page
  KEY_STAB         = KEY_OFFSET + $54; // set tab
  KEY_CTAB         = KEY_OFFSET + $55; // clear tab
  KEY_CATAB        = KEY_OFFSET + $56; // clear all tabs
  KEY_ENTER        = KEY_OFFSET + $57; // enter or send = unreliable;
  KEY_SRESET       = KEY_OFFSET + $58; // soft/reset = partial/unreliable;
  KEY_RESET        = KEY_OFFSET + $59; // reset/hard reset = unreliable;
  KEY_PRINT        = KEY_OFFSET + $5a; // print/copy
  KEY_LL           = KEY_OFFSET + $5b; // home down/bottom = lower left;
  KEY_ABORT        = KEY_OFFSET + $5c; // abort/terminate key = any;
  KEY_SHELP        = KEY_OFFSET + $5d; // short help
  KEY_LHELP        = KEY_OFFSET + $5e; // long help
  KEY_BTAB         = KEY_OFFSET + $5f; // Back tab key
  KEY_BEG          = KEY_OFFSET + $60; // beg(inning;) key
  KEY_CANCEL       = KEY_OFFSET + $61; // cancel key
  KEY_CLOSE        = KEY_OFFSET + $62; // close key
  KEY_COMMAND      = KEY_OFFSET + $63; // cmd = command; key
  KEY_COPY         = KEY_OFFSET + $64; // copy key
  KEY_CREATE       = KEY_OFFSET + $65; // create key
  KEY_END          = KEY_OFFSET + $66; // end key
  KEY_EXIT         = KEY_OFFSET + $67; // exit key
  KEY_FIND         = KEY_OFFSET + $68; // find key
  KEY_HELP         = KEY_OFFSET + $69; // help key
  KEY_MARK         = KEY_OFFSET + $6a; // mark key
  KEY_MESSAGE      = KEY_OFFSET + $6b; // message key
  KEY_MOVE         = KEY_OFFSET + $6c; // move key
  KEY_NEXT         = KEY_OFFSET + $6d; // next object key
  KEY_OPEN         = KEY_OFFSET + $6e; // open key
  KEY_OPTIONS      = KEY_OFFSET + $6f; // options key
  KEY_PREVIOUS     = KEY_OFFSET + $70; // previous object key
  KEY_REDO         = KEY_OFFSET + $71; // redo key
  KEY_REFERENCE    = KEY_OFFSET + $72; // ref= erence; key
  KEY_REFRESH      = KEY_OFFSET + $73; // refresh key
  KEY_REPLACE      = KEY_OFFSET + $74; // replace key
  KEY_RESTART      = KEY_OFFSET + $75; // restart key
  KEY_RESUME       = KEY_OFFSET + $76; // resume key
  KEY_SAVE         = KEY_OFFSET + $77; // save key
  KEY_SBEG         = KEY_OFFSET + $78; // shifted beginning key
  KEY_SCANCEL      = KEY_OFFSET + $79; // shifted cancel key
  KEY_SCOMMAND     = KEY_OFFSET + $7a; // shifted command key
  KEY_SCOPY        = KEY_OFFSET + $7b; // shifted copy key
  KEY_SCREATE      = KEY_OFFSET + $7c; // shifted create key
  KEY_SDC          = KEY_OFFSET + $7d; // shifted delete char key
  KEY_SDL          = KEY_OFFSET + $7e; // shifted delete line key
  KEY_SELECT       = KEY_OFFSET + $7f; // select key
  KEY_SEND         = KEY_OFFSET + $80; // shifted end key
  KEY_SEOL         = KEY_OFFSET + $81; // shifted clear line key
  KEY_SEXIT        = KEY_OFFSET + $82; // shifted exit key
  KEY_SFIND        = KEY_OFFSET + $83; // shifted find key
  KEY_SHOME        = KEY_OFFSET + $84; // shifted home key
  KEY_SIC          = KEY_OFFSET + $85; // shifted input key

  KEY_SLEFT        = KEY_OFFSET + $87; // shifted left arrow key
  KEY_SMESSAGE     = KEY_OFFSET + $88; // shifted message key
  KEY_SMOVE        = KEY_OFFSET + $89; // shifted move key
  KEY_SNEXT        = KEY_OFFSET + $8a; // shifted next key
  KEY_SOPTIONS     = KEY_OFFSET + $8b; // shifted options key
  KEY_SPREVIOUS    = KEY_OFFSET + $8c; // shifted prev key
  KEY_SPRINT       = KEY_OFFSET + $8d; // shifted print key
  KEY_SREDO        = KEY_OFFSET + $8e; // shifted redo key
  KEY_SREPLACE     = KEY_OFFSET + $8f; // shifted replace key
  KEY_SRIGHT       = KEY_OFFSET + $90; // shifted right arrow
  KEY_SRSUME       = KEY_OFFSET + $91; // shifted resume key
  KEY_SSAVE        = KEY_OFFSET + $92; // shifted save key
  KEY_SSUSPEND     = KEY_OFFSET + $93; // shifted suspend key
  KEY_SUNDO        = KEY_OFFSET + $94; // shifted undo key
  KEY_SUSPEND      = KEY_OFFSET + $95; // suspend key
  KEY_UNDO         = KEY_OFFSET + $96; // undo key

// PDCurses-specific key definitions -- PC only
  ALT_0                 = KEY_OFFSET + $97;
  ALT_1                 = KEY_OFFSET + $98;
  ALT_2                 = KEY_OFFSET + $99;
  ALT_3                 = KEY_OFFSET + $9a;
  ALT_4                 = KEY_OFFSET + $9b;
  ALT_5                 = KEY_OFFSET + $9c;
  ALT_6                 = KEY_OFFSET + $9d;
  ALT_7                 = KEY_OFFSET + $9e;
  ALT_8                 = KEY_OFFSET + $9f;
  ALT_9                 = KEY_OFFSET + $a0;
  ALT_A                 = KEY_OFFSET + $a1;
  ALT_B                 = KEY_OFFSET + $a2;
  ALT_C                 = KEY_OFFSET + $a3;
  ALT_D                 = KEY_OFFSET + $a4;
  ALT_E                 = KEY_OFFSET + $a5;
  ALT_F                 = KEY_OFFSET + $a6;
  ALT_G                 = KEY_OFFSET + $a7;
  ALT_H                 = KEY_OFFSET + $a8;
  ALT_I                 = KEY_OFFSET + $a9;
  ALT_J                 = KEY_OFFSET + $aa;
  ALT_K                 = KEY_OFFSET + $ab;
  ALT_L                 = KEY_OFFSET + $ac;
  ALT_M                 = KEY_OFFSET + $ad;
  ALT_N                 = KEY_OFFSET + $ae;
  ALT_O                 = KEY_OFFSET + $af;
  ALT_P                 = KEY_OFFSET + $b0;
  ALT_Q                 = KEY_OFFSET + $b1;
  ALT_R                 = KEY_OFFSET + $b2;
  ALT_S                 = KEY_OFFSET + $b3;
  ALT_T                 = KEY_OFFSET + $b4;
  ALT_U                 = KEY_OFFSET + $b5;
  ALT_V                 = KEY_OFFSET + $b6;
  ALT_W                 = KEY_OFFSET + $b7;
  ALT_X                 = KEY_OFFSET + $b8;
  ALT_Y                 = KEY_OFFSET + $b9;
  ALT_Z                 = KEY_OFFSET + $ba;

  CTL_LEFT              = KEY_OFFSET + $bb; // Control-Left-Arrow
  CTL_RIGHT             = KEY_OFFSET + $bc;
  CTL_PGUP              = KEY_OFFSET + $bd;
  CTL_PGDN              = KEY_OFFSET + $be;
  CTL_HOME              = KEY_OFFSET + $bf;
  CTL_END               = KEY_OFFSET + $c0;

  KEY_A1                = KEY_OFFSET + $c1; // upper left on Virtual keypad
  KEY_A2                = KEY_OFFSET + $c2; // upper middle on Virt. keypad
  KEY_A3                = KEY_OFFSET + $c3; // upper right on Vir. keypad
  KEY_B1                = KEY_OFFSET + $c4; // middle left on Virt. keypad
  KEY_B2                = KEY_OFFSET + $c5; // center on Virt. keypad
  KEY_B3                = KEY_OFFSET + $c6; // middle right on Vir. keypad
  KEY_C1                = KEY_OFFSET + $c7; // lower left on Virt. keypad
  KEY_C2                = KEY_OFFSET + $c8; // lower middle on Virt. keypad
  KEY_C3                = KEY_OFFSET + $c9; // lower right on Vir. keypad

  PADSLASH              = KEY_OFFSET + $ca; // slash on keypad
  PADENTER              = KEY_OFFSET + $cb; // enter on keypad
  CTL_PADENTER          = KEY_OFFSET + $cc; // ctl-enter on keypad
  ALT_PADENTER          = KEY_OFFSET + $cd; // alt-enter on keypad
  PADSTOP               = KEY_OFFSET + $ce; // stop on keypad
  PADSTAR               = KEY_OFFSET + $cf; // star on keypad
  PADMINUS              = KEY_OFFSET + $d0; // minus on keypad
  PADPLUS               = KEY_OFFSET + $d1; // plus on keypad
  CTL_PADSTOP           = KEY_OFFSET + $d2; // ctl-stop on keypad
  CTL_PADCENTER         = KEY_OFFSET + $d3; // ctl-enter on keypad
  CTL_PADPLUS           = KEY_OFFSET + $d4; // ctl-plus on keypad
  CTL_PADMINUS          = KEY_OFFSET + $d5; // ctl-minus on keypad
  CTL_PADSLASH          = KEY_OFFSET + $d6; // ctl-slash on keypad
  CTL_PADSTAR           = KEY_OFFSET + $d7; // ctl-star on keypad
  ALT_PADPLUS           = KEY_OFFSET + $d8; // alt-plus on keypad
  ALT_PADMINUS          = KEY_OFFSET + $d9; // alt-minus on keypad
  ALT_PADSLASH          = KEY_OFFSET + $da; // alt-slash on keypad
  ALT_PADSTAR           = KEY_OFFSET + $db; // alt-star on keypad
  ALT_PADSTOP           = KEY_OFFSET + $dc; // alt-stop on keypad
  CTL_INS               = KEY_OFFSET + $dd; // ctl-insert
  ALT_DEL               = KEY_OFFSET + $de; // alt-delete
  ALT_INS               = KEY_OFFSET + $df; // alt-insert
  CTL_UP                = KEY_OFFSET + $e0; // ctl-up arrow
  CTL_DOWN              = KEY_OFFSET + $e1; // ctl-down arrow
  CTL_TAB               = KEY_OFFSET + $e2; // ctl-tab
  ALT_TAB               = KEY_OFFSET + $e3;
  ALT_MINUS             = KEY_OFFSET + $e4;
  ALT_EQUAL             = KEY_OFFSET + $e5;
  ALT_HOME              = KEY_OFFSET + $e6;
  ALT_PGUP              = KEY_OFFSET + $e7;
  ALT_PGDN              = KEY_OFFSET + $e8;
  ALT_END               = KEY_OFFSET + $e9;
  ALT_UP                = KEY_OFFSET + $ea; // alt-up arrow
  ALT_DOWN              = KEY_OFFSET + $eb; // alt-down arrow
  ALT_RIGHT             = KEY_OFFSET + $ec; // alt-right arrow
  ALT_LEFT              = KEY_OFFSET + $ed; // alt-left arrow
  ALT_ENTER             = KEY_OFFSET + $ee; // alt-enter
  ALT_ESC               = KEY_OFFSET + $ef; // alt-escape
  ALT_BQUOTE            = KEY_OFFSET + $f0; // alt-back quote
  ALT_LBRACKET          = KEY_OFFSET + $f1; // alt-left bracket
  ALT_RBRACKET          = KEY_OFFSET + $f2; // alt-right bracket
  ALT_SEMICOLON         = KEY_OFFSET + $f3; // alt-semi-colon
  ALT_FQUOTE            = KEY_OFFSET + $f4; // alt-forward quote
  ALT_COMMA             = KEY_OFFSET + $f5; // alt-comma
  ALT_STOP              = KEY_OFFSET + $f6; // alt-stop
  ALT_FSLASH            = KEY_OFFSET + $f7; // alt-forward slash
  ALT_BKSP              = KEY_OFFSET + $f8; // alt-backspace
  CTL_BKSP              = KEY_OFFSET + $f9; // ctl-backspace
  PAD0                  = KEY_OFFSET + $fa; // keypad 0

  CTL_PAD0              = KEY_OFFSET + $fb; // ctl-keypad 0
  CTL_PAD1              = KEY_OFFSET + $fc;
  CTL_PAD2              = KEY_OFFSET + $fd;
  CTL_PAD3              = KEY_OFFSET + $fe;
  CTL_PAD4              = KEY_OFFSET + $ff;
  CTL_PAD5              = KEY_OFFSET + $100;
  CTL_PAD6              = KEY_OFFSET + $101;
  CTL_PAD7              = KEY_OFFSET + $102;
  CTL_PAD8              = KEY_OFFSET + $103;
  CTL_PAD9              = KEY_OFFSET + $104;

  ALT_PAD0              = KEY_OFFSET + $105; // alt-keypad 0
  ALT_PAD1              = KEY_OFFSET + $106;
  ALT_PAD2              = KEY_OFFSET + $107;
  ALT_PAD3              = KEY_OFFSET + $108;
  ALT_PAD4              = KEY_OFFSET + $109;
  ALT_PAD5              = KEY_OFFSET + $10a;
  ALT_PAD6              = KEY_OFFSET + $10b;
  ALT_PAD7              = KEY_OFFSET + $10c;
  ALT_PAD8              = KEY_OFFSET + $10d;
  ALT_PAD9              = KEY_OFFSET + $10e;

  CTL_DEL               = KEY_OFFSET + $10f; // clt-delete
  ALT_BSLASH            = KEY_OFFSET + $110; // alt-back slash
  CTL_ENTER             = KEY_OFFSET + $111; // ctl-enter

  SHF_PADENTER          = KEY_OFFSET + $112; // shift-enter on keypad
  SHF_PADSLASH          = KEY_OFFSET + $113; // shift-slash on keypad
  SHF_PADSTAR           = KEY_OFFSET + $114; // shift-star  on keypad
  SHF_PADPLUS           = KEY_OFFSET + $115; // shift-plus  on keypad
  SHF_PADMINUS          = KEY_OFFSET + $116; // shift-minus on keypad
  SHF_UP                = KEY_OFFSET + $117; // shift-up on keypad
  SHF_DOWN              = KEY_OFFSET + $118; // shift-down on keypad
  SHF_IC                = KEY_OFFSET + $119; // shift-insert on keypad
  SHF_DC                = KEY_OFFSET + $11a; // shift-delete on keypad

  KEY_MOUSE             = KEY_OFFSET + $11b; // "mouse" key
  KEY_SHIFT_L           = KEY_OFFSET + $11c; // Left-shift
  KEY_SHIFT_R           = KEY_OFFSET + $11d; // Right-shift
  KEY_CONTROL_L         = KEY_OFFSET + $11e; // Left-control
  KEY_CONTROL_R         = KEY_OFFSET + $11f; // Right-control

  KEY_ALT_L             = KEY_OFFSET + $120; // Left-alt
  KEY_ALT_R             = KEY_OFFSET + $121; // Right-alt
  KEY_RESIZE            = KEY_OFFSET + $122; // Window resize
  KEY_SUP               = KEY_OFFSET + $123; // Shifted up arrow
  KEY_SDOWN             = KEY_OFFSET + $124; // Shifted down arrow

// The following were added 2011 Sep 14,  and are
// not returned by most flavors of PDCurses:
  CTL_SEMICOLON         = KEY_OFFSET + $125;
  CTL_EQUAL             = KEY_OFFSET + $126;
  CTL_COMMA             = KEY_OFFSET + $127;
  CTL_MINUS             = KEY_OFFSET + $128;

  CTL_STOP              = KEY_OFFSET + $129;
  CTL_FSLASH            = KEY_OFFSET + $12a;
  CTL_BQUOTE            = KEY_OFFSET + $12b;

  KEY_APPS              = KEY_OFFSET + $12c;
  KEY_SAPPS             = KEY_OFFSET + $12d;
  CTL_APPS              = KEY_OFFSET + $12e;
  ALT_APPS              = KEY_OFFSET + $12f;

  KEY_PAUSE             = KEY_OFFSET + $130;
  KEY_SPAUSE            = KEY_OFFSET + $131;
  CTL_PAUSE             = KEY_OFFSET + $132;

  KEY_PRINTSCREEN       = KEY_OFFSET + $133;
  ALT_PRINTSCREEN       = KEY_OFFSET + $134;
  KEY_SCROLLLOCK        = KEY_OFFSET + $135;
  ALT_SCROLLLOCK        = KEY_OFFSET + $136;

  CTL_0                 = KEY_OFFSET + $137;
  CTL_1                 = KEY_OFFSET + $138;
  CTL_2                 = KEY_OFFSET + $139;
  CTL_3                 = KEY_OFFSET + $13a;
  CTL_4                 = KEY_OFFSET + $13b;
  CTL_5                 = KEY_OFFSET + $13c;
  CTL_6                 = KEY_OFFSET + $13d;
  CTL_7                 = KEY_OFFSET + $13e;
  CTL_8                 = KEY_OFFSET + $13f;
  CTL_9                 = KEY_OFFSET + $140;

  KEY_BROWSER_BACK      = KEY_OFFSET + $141;
  KEY_SBROWSER_BACK     = KEY_OFFSET + $142;
  KEY_CBROWSER_BACK     = KEY_OFFSET + $143;
  KEY_ABROWSER_BACK     = KEY_OFFSET + $144;
  KEY_BROWSER_FWD       = KEY_OFFSET + $145;
  KEY_SBROWSER_FWD      = KEY_OFFSET + $146;
  KEY_CBROWSER_FWD      = KEY_OFFSET + $147;
  KEY_ABROWSER_FWD      = KEY_OFFSET + $148;
  KEY_BROWSER_REF       = KEY_OFFSET + $149;
  KEY_SBROWSER_REF      = KEY_OFFSET + $14A;
  KEY_CBROWSER_REF      = KEY_OFFSET + $14B;
  KEY_ABROWSER_REF      = KEY_OFFSET + $14C;
  KEY_BROWSER_STOP      = KEY_OFFSET + $14D;
  KEY_SBROWSER_STOP     = KEY_OFFSET + $14E;
  KEY_CBROWSER_STOP     = KEY_OFFSET + $14F;
  KEY_ABROWSER_STOP     = KEY_OFFSET + $150;
  KEY_SEARCH            = KEY_OFFSET + $151;
  KEY_SSEARCH           = KEY_OFFSET + $152;
  KEY_CSEARCH           = KEY_OFFSET + $153;
  KEY_ASEARCH           = KEY_OFFSET + $154;
  KEY_FAVORITES         = KEY_OFFSET + $155;
  KEY_SFAVORITES        = KEY_OFFSET + $156;
  KEY_CFAVORITES        = KEY_OFFSET + $157;
  KEY_AFAVORITES        = KEY_OFFSET + $158;
  KEY_BROWSER_HOME      = KEY_OFFSET + $159;
  KEY_SBROWSER_HOME     = KEY_OFFSET + $15A;
  KEY_CBROWSER_HOME     = KEY_OFFSET + $15B;
  KEY_ABROWSER_HOME     = KEY_OFFSET + $15C;
  KEY_VOLUME_MUTE       = KEY_OFFSET + $15D;
  KEY_SVOLUME_MUTE      = KEY_OFFSET + $15E;
  KEY_CVOLUME_MUTE      = KEY_OFFSET + $15F;
  KEY_AVOLUME_MUTE      = KEY_OFFSET + $160;
  KEY_VOLUME_DOWN       = KEY_OFFSET + $161;
  KEY_SVOLUME_DOWN      = KEY_OFFSET + $162;
  KEY_CVOLUME_DOWN      = KEY_OFFSET + $163;
  KEY_AVOLUME_DOWN      = KEY_OFFSET + $164;
  KEY_VOLUME_UP         = KEY_OFFSET + $165;
  KEY_SVOLUME_UP        = KEY_OFFSET + $166;
  KEY_CVOLUME_UP        = KEY_OFFSET + $167;
  KEY_AVOLUME_UP        = KEY_OFFSET + $168;
  KEY_NEXT_TRACK        = KEY_OFFSET + $169;
  KEY_SNEXT_TRACK       = KEY_OFFSET + $16A;
  KEY_CNEXT_TRACK       = KEY_OFFSET + $16B;
  KEY_ANEXT_TRACK       = KEY_OFFSET + $16C;
  KEY_PREV_TRACK        = KEY_OFFSET + $16D;
  KEY_SPREV_TRACK       = KEY_OFFSET + $16E;
  KEY_CPREV_TRACK       = KEY_OFFSET + $16F;
  KEY_APREV_TRACK       = KEY_OFFSET + $170;
  KEY_MEDIA_STOP        = KEY_OFFSET + $171;
  KEY_SMEDIA_STOP       = KEY_OFFSET + $172;
  KEY_CMEDIA_STOP       = KEY_OFFSET + $173;
  KEY_AMEDIA_STOP       = KEY_OFFSET + $174;
  KEY_PLAY_PAUSE        = KEY_OFFSET + $175;
  KEY_SPLAY_PAUSE       = KEY_OFFSET + $176;
  KEY_CPLAY_PAUSE       = KEY_OFFSET + $177;
  KEY_APLAY_PAUSE       = KEY_OFFSET + $178;
  KEY_LAUNCH_MAIL       = KEY_OFFSET + $179;
  KEY_SLAUNCH_MAIL      = KEY_OFFSET + $17A;
  KEY_CLAUNCH_MAIL      = KEY_OFFSET + $17B;
  KEY_ALAUNCH_MAIL      = KEY_OFFSET + $17C;
  KEY_MEDIA_SELECT      = KEY_OFFSET + $17D;
  KEY_SMEDIA_SELECT     = KEY_OFFSET + $17E;
  KEY_CMEDIA_SELECT     = KEY_OFFSET + $17F;
  KEY_AMEDIA_SELECT     = KEY_OFFSET + $180;
  KEY_LAUNCH_APP1       = KEY_OFFSET + $181;
  KEY_SLAUNCH_APP1      = KEY_OFFSET + $182;
  KEY_CLAUNCH_APP1      = KEY_OFFSET + $183;
  KEY_ALAUNCH_APP1      = KEY_OFFSET + $184;
  KEY_LAUNCH_APP2       = KEY_OFFSET + $185;
  KEY_SLAUNCH_APP2      = KEY_OFFSET + $186;
  KEY_CLAUNCH_APP2      = KEY_OFFSET + $187;
  KEY_ALAUNCH_APP2      = KEY_OFFSET + $188;

  KEY_MIN               = KEY_BREAK;        // Minimum curses key value
  KEY_MAX               = KEY_ALAUNCH_APP2; // Maximum curses key

function KEY_F(aNum: Byte): TChType; inline;

{
  PDCurses Function Declarations
}
// Standard
var
  pdcAddCh:          function(const aChar: TChType): LongInt; cdecl;
  pdcAddChNStr:      function(const aText: PChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcAddChStr:       function(const aText: PChType): LongInt; cdecl;
  pdcAddNStr:        function(const aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcAddStr:         function(const aText: PAnsiChar): LongInt; cdecl;
  pdcAttrOff:        function(aAttrs: TChType): LongInt; cdecl;
  pdcAttrOn:         function(aAttrs: TChType): LongInt; cdecl;
  pdcAttrSet:        function(aAttrs: TChType): LongInt; cdecl;
  pdcAttrOptsGet:    function(aAttrs: PAttr; aColorPair: PSmallInt;
                              aOpts: Pointer): LongInt; cdecl;
  pdcAttrOptsOff:    function(aAttrs: TAttr; aOpts: Pointer): LongInt; cdecl;
  pdcAttrOptsOn:     function(aAttrs: TAttr; aOpts: Pointer): LongInt; cdecl;
  pdcAttrOptsSet:    function(aAttrs: TAttr; aColorPair: SmallInt;
                              aOpts: Pointer): LongInt; cdecl;
  pdcBaudRate:       function: LongInt; cdecl;
  pdcBeep:           function: LongInt; cdecl;
  pdcBkgd:           function(aChar: TChType): LongInt; cdecl;
  pdcBkgdSet:        procedure(aChar: TChType); cdecl;
  pdcBorder:         function(aLS, aRS, aTS, aBS, aTL, aTR,
                              aBL, aBR: TChType): LongInt; cdecl;
  pdcBox:            function(aWindow: PWindow;
                              aVChar, aHChar: TChType): LongInt; cdecl;
  pdcCanChangeColor: function: TBool; cdecl;
  pdcCBreak:         function: LongInt; cdecl;
  pdcChgAt:          function(aCount: LongInt; aAttr: TAttr; aColor: SmallInt;
                              const aOpts: Pointer): LongInt; cdecl;
  pdcClearOk:        function(aWindow: PWindow; aFlag: TBool): LongInt; cdecl;
  pdcClear:          function: LongInt; cdecl;
  pdcClrToBot:       function: LongInt; cdecl;
  pdcClrToEOL:       function: LongInt; cdecl;
  pdcColorContent:   function(aColor: SmallInt;
                              aR, aG, aB: PSmallInt): LongInt; cdecl;
  pdcColorSet:       function(aColorPair: SmallInt;
                              aOpts: Pointer): LongInt; cdecl;
  pdcCopyWin:        function(const aSrcWin: PWindow; aDestWin: PWindow;
                              aSrcTR, aSrcTC, aDestTR, aDestTC, aDestBR,
                              aDestBC: LongInt; aOverlay: TBool): LongInt; cdecl;
  pdcCursSet:        function(aVisibility: LongInt): LongInt; cdecl;
  pdcDefProgMode:    function: LongInt; cdecl;
  pdcDefShellMode:   function: LongInt; cdecl;
  pdcDelayOutput:    function(aTime: LongInt): LongInt; cdecl;
  pdcDelCh:          function: LongInt; cdecl;
  pdcDeleteLn:       function: LongInt; cdecl;
  pdcDelScreen:      procedure(aScreen: PScreen); cdecl;
  pdcDelWin:         function(aWindow: PWindow): LongInt; cdecl;
  pdcDerWin:         function(aWindow: PWindow; aLineCount, aColCount,
                              aBegY, aBegX: LongInt): PWindow; cdecl;
  pdcDoUpdate:       function: LongInt; cdecl;
  pdcDupWin:         function(aWindow: PWindow): PWindow; cdecl;
  pdcEchoChar:       function(const aChar: TChType): LongInt; cdecl;
  pdcEcho:           function: LongInt; cdecl;
  pdcEndWin:         function: LongInt; cdecl;
  pdcEraseChar:      function: AnsiChar; cdecl;
  pdcErase:          function: LongInt; cdecl;
  pdcFilter:         procedure; cdecl;
  pdcFlash:          function: LongInt; cdecl;
  pdcFlushInp:       function: LongInt; cdecl;
  pdcGetBkgd:        function(aWindow: PWindow): TChType; cdecl;
  pdcGetNStr:        function(aText: PAnsiChar; aCount: LongInt): LongInt; cdecl;
  pdcGetStr:         function(aText: PAnsiChar): LongInt; cdecl;
  pdcGetWin:         function(aFile: PFile): PWindow; cdecl;
  pdcHalfDelay:      function(aTime: LongInt): LongInt; cdecl;
  pdcHasColors:      function: TBool; cdecl;
  pdcHasIC:          function: TBool; cdecl;
  pdcHasIL:          function: TBool; cdecl;
  pdcHLine:          function(aChar: TChType; aCount: LongInt): LongInt; cdecl;
  pdcIDCOk:          procedure(aWindow: PWindow; aFlag: TBool); cdecl;
  pdcIDLOk:          function(aWindow: PWindow; aFlag: TBool): LongInt; cdecl;
  pdcImmedOk:        procedure(aWindow: PWindow; aFlag: TBool); cdecl;
  pdcInChNStr:       function(aText: PChType; aCount: LongInt): LongInt; cdecl;
  pdcInChStr:        function(aText: PChType): LongInt; cdecl;
  pdcInCh:           function: TChType; cdecl;
  pdcInitColor:      function(aId, aRed, aGreen, aBlue: SmallInt): LongInt; cdecl;
  pdcInitPair:       function(aId, aForeColor,
                              aBackColor: SmallInt): LongInt; cdecl;
  pdcInitScr:        function: PWINDOW; cdecl;
  pdcInNStr:         function(aText: PAnsiChar; aCount: LongInt): LongInt; cdecl;
  pdcInsCh:          function(aChar: TChType): LongInt; cdecl;
  pdcInsDelLn:       function(aCount: LongInt): LongInt; cdecl;
  pdcInsertLn:       function: LongInt; cdecl;
  pdcInsNStr:        function(const aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcInsStr:         function(const aText: PAnsiChar): LongInt; cdecl;
  pdcInStr:          function(aText: PAnsiChar): LongInt; cdecl;
  pdcIntrFlush:      function(aWindow: PWindow; aFlag: TBool): LongInt; cdecl;
  pdcIsEndWin:       function: TBool; cdecl;
  pdcIsLineTouched:  function(aWindow: PWindow; aLine: LongInt): TBool; cdecl;
  pdcIsWinTouched:   function(aWindow: PWindow): TBool; cdecl;
  pdcKeyName:        function(aKey: LongInt): PAnsiChar; cdecl;
  pdcKeyPad:         function(aWindow: PWindow; aFlag: TBool): LongInt; cdecl;
  pdcKillChar:       function: AnsiChar; cdecl;
  pdcLeaveOk:        function(aWindow: PWindow; aFlag: TBool): LongInt; cdecl;
  pdcLongName:       function: PAnsiChar; cdecl;
  pdcMeta:           function(aWindow: PWindow; aFlag: TBool): LongInt; cdecl;
  pdcMove:           function(aY, aX: LongInt): LongInt; cdecl;
  pdcMvAddCh:        function(aY, aX: LongInt;
                              const aChar: TChType): LongInt; cdecl;
  pdcMvAddChNStr:    function(aY, aX: LongInt; const aChar: PChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvAddChStr:     function(aY, aX: LongInt;
                              const aChar: PChType): LongInt; cdecl;
  pdcMvAddNStr:      function(aY, aX: LongInt; const aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvAddStr:       function(aY, aX: LongInt;
                              const aText: PAnsiChar): LongInt; cdecl;
  pdcMvChgAt:        function(aY, aX, aCount: LongInt; aAttr: TAttr;
                              aColor: SmallInt;
                              const aOpts: Pointer): LongInt; cdecl;
  pdcMvCur:          function(aOldRow, aOldCol, aNewRow,
                              aNewCol: LongInt): LongInt; cdecl;
  pdcMvDelCh:        function(aY, aX: LongInt): LongInt; cdecl;
  pdcMvDerWin:       function(aWindow: PWindow;
                              aParY, aParX: LongInt): LongInt; cdecl;
  pdcMvGetCh:        function(aY, aX: LongInt): LongInt; cdecl;
  pdcMvGetNStr:      function(aY, aX: LongInt; aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvGetStr:       function(aY, aX: LongInt; aText: PAnsiChar): LongInt; cdecl;
  pdcMvHLine:        function(aY, aX: LongInt; aChar: TChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvInCh:         function(aY, aX: LongInt): TChType; cdecl;
  pdcMvInChNStr:     function(aY, aX: LongInt; aChar: PChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvInChStr:      function(aY, aX: LongInt; aChar: PChType): LongInt; cdecl;
  pdcMvInNStr:       function(aY, aX: LongInt; aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvInsCh:        function(aY, aX: LongInt; aChar: TChType): LongInt; cdecl;
  pdcMvInsNStr:      function(aY, aX: LongInt; const aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvInsStr:       function(aY, aX: LongInt;
                              const aText: PAnsiChar): LongInt; cdecl;
  pdcMvInStr:        function(aY, aX: LongInt; aText: PAnsiChar): LongInt; cdecl;
  pdcMvPrintW:       function(aY, aX: LongInt; const aFormat: PAnsiChar;
                              const aArgs: array of const): LongInt; cdecl;
  pdcMvScanW:        function(aY, aX: LongInt; const aFormat: PAnsiChar;
                              const aArgs: array of const): LongInt; cdecl;
  pdcMvVLine:        function(aY, aX: LongInt; aChar: TChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWAddChNStr:   function(aWindow: PWindow; aY, aX: LongInt;
                              const aChar: PChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWAddChStr:    function(aWindow: PWindow; aY, aX: LongInt;
                              const aChar: PChType): LongInt; cdecl;
  pdcMvWAddCh:       function(aWindow: PWindow; aY, aX: LongInt;
                              const aChar: TChType): LongInt; cdecl;
  pdcMvWAddNStr:     function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWAddStr:      function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PAnsiChar): LongInt; cdecl;
  pdcMvWChgAt:       function(aWindow: PWindow; aY, aX, aCount: LongInt;
                              aAttr: TAttr; aColor: SmallInt;
                              const aOpts: Pointer): LongInt; cdecl;
  pdcMvWDelCh:       function(aWindow: PWindow; aY, aX: LongInt): LongInt; cdecl;
  pdcMvWGetCh:       function(aWindow: PWindow; aY, aX: LongInt): LongInt; cdecl;
  pdcMvWGetNStr:     function(aWindow: PWindow; aY, aX: LongInt;
                              aText: PAnsiChar; aCount: LongInt): LongInt; cdecl;
  pdcMvWGetStr:      function(aWindow: PWindow; aY, aX: LongInt;
                              aText: PAnsiChar): LongInt; cdecl;
  pdcMvWHLine:       function(aWindow: PWindow; aY, aX: LongInt; aChar: TChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWinChNStr:    function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWinChStr:     function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PChType): LongInt; cdecl;
  pdcMvWinCh:        function(aWindow: PWindow; aY, aX: LongInt): TChType; cdecl;
  pdcMvWinNStr:      function(aWindow: PWindow; aY, aX: LongInt;
                              aText: PAnsiChar; aCount: LongInt): LongInt; cdecl;
  pdcMvWinsCh:       function(aWindow: PWindow; aY, aX: LongInt;
                              aChar: TChType): LongInt; cdecl;
  pdcMvWinsNStr:     function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWinsStr:      function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PAnsiChar): LongInt; cdecl;
  pdcMvWinStr:       function(aWindow: PWindow; aY, aX: LongInt;
                              aText: PAnsiChar): LongInt; cdecl;
  pdcMvWin:          function(aWindow: PWindow; aY, aX: LongInt): LongInt; cdecl;
  pdcMvWPrintW:      function(aWindow: PWindow; aY, aX: LongInt;
                              const aFormat: PAnsiChar;
                              const aArgs: array of const): LongInt; cdecl;
  pdcMvWScanW:       function(aWindow: PWindow; aY, aX: LongInt;
                              const aFormat: PAnsiChar;
                              const aArgs: array of const): LongInt; cdecl;
  pdcMvWVLine:       function(aWindow: PWindow; aY, aX: LongInt; aChar: TChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcNapMS:          function(aTime: LongInt): LongInt; cdecl;
  pdcNewPad:         function(aLineCount, aColCount: LongInt): PWindow; cdecl;
  pdcNewTerm:        function(const aType: PAnsiChar;
                              aInFile, aOutFile: PFile): PScreen; cdecl;
  pdcNewWin:         function(aLineCount, aColCount,
                              aBegY, aBegX: LongInt): PWindow; cdecl;
  pdcNL:             function: LongInt; cdecl;
  pdcNoCBreak:       function: LongInt; cdecl;
  pdcNoDelay:        function(aWindow: PWindow; aFlag: TBool): LongInt; cdecl;
  pdcNoEcho:         function: LongInt; cdecl;
  pdcNoNL:           function: LongInt; cdecl;
  pdcNoQIFlush:      procedure; cdecl;
  pdcNoRaw:          function: LongInt; cdecl;
  pdcNoTimeout:      function(aWindow: PWindow; aFlag: TBool): LongInt; cdecl;
  pdcOverlay:        function(const aSrcWin: PWindow;
                              aDestWin: PWindow): LongInt; cdecl;
  pdcOverwrite:      function(const aSrcWin: PWindow;
                              aDestWin: PWindow): LongInt; cdecl;
  pdcPairContent:    function(aPair: SmallInt;
                              aFore, aBack: PSmallInt): LongInt; cdecl;
  pdcPEchoChar:      function(aPad: PWindow; aChar: TChType): LongInt; cdecl;
  pdcPNOutRefresh:   function(aWindow: PWindow; aPY, aPX, aSY1, aSX1,
                              aSY2, aSX2: LongInt): LongInt; cdecl;
  pdcPRefresh:       function(aWindow: PWindow; aPY, aPX, aSY1, aSX1,
                              aSY2, aSX2: LongInt): LongInt; cdecl;
  pdcPrintW:         function(const aFormat: PAnsiChar;
                              aArgs: array of const): LongInt; cdecl;
  pdcPutWin:         function(aWindow: PWindow;
                              aFilePointer: PFile): LongInt; cdecl;
  pdcQIFlush:        procedure; cdecl;
  pdcRaw:            function: LongInt; cdecl;
  pdcRedrawWin:      function(aWindow: PWindow): LongInt; cdecl;
  pdcRefresh:        function: LongInt; cdecl;
  pdcResetProgMode:  function: LongInt; cdecl;
  pdcResetShellMode: function: LongInt; cdecl;
  pdcResetTy:        function: LongInt; cdecl;
  pdcRopOffline:     function(aLine: LongInt;
                              aInitFunc: TWinInit): LongInt; cdecl;
  pdcSaveTty:        function: LongInt; cdecl;
  pdcScanW:          function(const aFormat: PAnsiChar;
                              const aArgs: array of const): LongInt; cdecl;
  pdcScrDump:        function(const aFilename: PAnsiChar): LongInt; cdecl;
  pdcScrInit:        function(const aFilename: PAnsiChar): LongInt; cdecl;
  pdcScrRestore:     function(const aFilename: PAnsiChar): LongInt; cdecl;
  pdcScrSet:         function(const aFilename: PAnsiChar): LongInt; cdecl;
  pdcScrl:           function(aCount: LongInt): LongInt; cdecl;
  pdcScroll:         function(aWindow: PWindow): LongInt; cdecl;
  pdcScrollOk:       function(aWindow: PWindow; aFlag: TBool): LongInt; cdecl;
  pdcSetTerm:        function(aNewScreen: PScreen): PScreen; cdecl;
  pdcSetScrReg:      function(aTop, aBottom: LongInt): LongInt; cdecl;
  pdcSlkAttrOff:     function(const aAttrs: TChType): LongInt; cdecl;
  pdcSlkAttr_Off:    function(const aAttrs: TAttr;
                              aOpts: Pointer): LongInt; cdecl;
  pdcSlkAttrOn:      function(const aAttrs: TChType): LongInt; cdecl;
  pdcSlkAttr_On:     function(const aAttrs: TAttr;
                              aOpts: Pointer): LongInt; cdecl;
  pdcSlkAttrSet:     function(const aAttrs: TChType): LongInt; cdecl;
  pdcSlkAttr_Set:    function(const aAttrs: TAttr; aColorPair: SmallInt;
                              aOpts: Pointer): LongInt; cdecl;
  pdcSlkClear:       function: LongInt; cdecl;
  pdcSlkColor:       function(aColorPair: ShortInt): LongInt; cdecl;
  pdcSlkInit:        function(aFormat: LongInt): LongInt; cdecl;
  pdcSlkLabel:       function(aLabelId: LongInt): PAnsiChar; cdecl;
  pdcSlkNOutRefresh: function: LongInt; cdecl;
  pdcSlkRefresh:     function: LongInt; cdecl;
  pdcSlkRestore:     function: LongInt; cdecl;
  pdcSlkSet:         function(aLabelId: LongInt; aText: PAnsiChar;
                              aJustify: LongInt): LongInt; cdecl;
  pdcSlkTouch:       function: LongInt; cdecl;
  pdcStandEnd:       function: LongInt; cdecl;
  pdcStandOut:       function: LongInt; cdecl;
  pdcStartColor:     function: LongInt; cdecl;
  pdcSubPad:         function(aWindow: PWindow; aLineCount, aColCount,
                              aBegY, aBegX: LongInt): PWindow; cdecl;
  pdcSubWin:         function(aWindow: PWindow; aLineCount, aColCount,
                              aBegY, aBegX: LongInt): PWindow; cdecl;
  pdcSyncOk:         function(aWindow: PWindow; aFlag: TBool): LongInt; cdecl;
  pdcTermAttrs:      function: TChType; cdecl;
  pdcTerm_Attrs:     function: TAttr; cdecl;
  pdcTermName:       function: PAnsiChar; cdecl;
  pdcTimeout:        procedure(aDelay: LongInt); cdecl;
  pdcTouchLine:      function(aWindow: PWindow;
                              aStart, aCount: LongInt): LongInt; cdecl;
  pdcTouchWin:       function(aWindow: PWindow): LongInt; cdecl;
  pdcTypeAhead:      function(aFilDes: LongInt): LongInt; cdecl;
  pdcUnTouchWin:     function(aWindow: PWindow): LongInt; cdecl;
  pdcUseEnv:         procedure(aFlag: TBool); cdecl;
  pdcVidAttr:        function(aAttr: TChType): LongInt; cdecl;
  pdcVid_Attr:       function(aAttr: TAttr; aColorPair: SmallInt;
                              aOpt: Pointer): LongInt; cdecl;
  pdcVidPutS:        function(aAttr: TChType; aPutFunc: TPutC): LongInt; cdecl;
  pdcVid_PutS:       function(aAttr: TAttr; aColorPair: SmallInt;
                              aOpt: Pointer; aPutFunc: TPutC): LongInt; cdecl;
  pdcVLine:          function(aChar: TChType; aCount: LongInt): LongInt; cdecl;

{$IFDEF ASSEMBLER}
{
  Functions used to overcome the inability of using C(++)'s va_list type
}
function pdcVW_PrintW(aWindow: PWindow; const aFormat: PAnsiChar;
                      const aArgs: array of const): LongInt;
function pdcVWPrintW(aWindow: PWindow; const aFormat: PAnsiChar;
                     const aArgs: array of const): LongInt;
function pdcVW_ScanW(aWindow: PWindow; const aFormat: PAnsiChar;
                     const aArgs: array of const): LongInt;
function pdcVWScanW(aWindow: PWindow; const aFormat: PAnsiChar;
                    const aArgs: array of const): LongInt;
{$ENDIF ASSEMBLER}

var
  pdcWAddChNStr:     function(aWindow: PWindow; const aChar: PChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcWAddChStr:      function(aWindow: PWindow;
                              const aChar: PChType): LongInt; cdecl;
  pdcWAddCh:         function(aWindow: PWindow;
                              const aChar: TChType): LongInt; cdecl;
  pdcWAddNStr:       function(aWindow: PWindow; const aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcWAddStr:        function(aWindow: PWindow;
                              const aText: PAnsiChar): LongInt; cdecl;
  pdcWAttrOff:       function(aWindow: PWindow; aAttr: TChType): LongInt; cdecl;
  pdcWAttrOn:        function(aWindow: PWindow; aAttr: TChType): LongInt; cdecl;
  pdcWAttrSet:       function(aWindow: PWindow; aAttr: TChType): LongInt; cdecl;
  pdcWAttr_Get:      function(aWindow: PWindow; aAttr: PAttr; aColor: PSmallInt;
                              aOpts: Pointer): LongInt; cdecl;
  pdcWAttr_Off:      function(aWindow: PWindow; aAttr: TAttr;
                              aOpts: Pointer): LongInt; cdecl;
  pdcWAttr_On:       function(aWindow: PWindow; aAttr: TAttr;
                              aOpts: Pointer): LongInt; cdecl;
  pdcWAttr_Set:      function(aWindow: PWindow; aAttr: TAttr; aColor: SmallInt;
                              aOpts: Pointer): LongInt; cdecl;
  pdcWBkgdSet:       procedure(aWindow: PWindow; aColor: TChType); cdecl;
  pdcWBkgd:          function(aWindow: PWindow; aColor: TChType): LongInt; cdecl;
  pdcWBorder:        function(aWindow: PWindow; aLS, aRS, aTS, aBS, aTL, aTR,
                              aBL, aBR: TChType): LongInt; cdecl;
  pdcWChgAt:         function(aWindow: PWindow; aCount: LongInt;
                              aAttr: TAttr; aColor: SmallInt;
                              const aOpts: Pointer): LongInt; cdecl;
  pdcWClear:         function(aWindow: PWindow): LongInt; cdecl;
  pdcWClrToBot:      function(aWindow: PWindow): LongInt; cdecl;
  pdcWClrToEOL:      function(aWindow: PWindow): LongInt; cdecl;
  pdcWColorSet:      function(aWindow: PWindow; aColorPair: SmallInt;
                              aOpts: Pointer): LongInt; cdecl;
  pdcWCurSyncUp:     procedure(aWindow: PWindow); cdecl;
  pdcWDelCh:         function(aWindow: PWindow): LongInt; cdecl;
  pdcWDeleteLn:      function(aWindow: PWindow): LongInt; cdecl;
  pdcWEchoChar:      function(aWindow: PWindow;
                              const aChar: TChType): LongInt; cdecl;
  pdcWErase:         function(aWindow: PWindow): LongInt; cdecl;
  pdcWGetCh:         function(aWindow: PWindow): LongInt; cdecl;
  pdcWGetNStr:       function(aWindow: PWindow; aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcWGetStr:        function(aWindow: PWindow; aText: PAnsiChar): LongInt; cdecl;
  pdcWHLine:         function(aWindow: PWindow; aChar: TChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcWInChNStr:      function(aWindow: PWindow; aChar: PChType;
                              aCount: LongInt): LongInt; cdecl;
  pdcWInChStr:       function(aWindow: PWindow; aChar: PChType): LongInt; cdecl;
  pdcWInCh:          function(aWindow: PWindow): TChType; cdecl;
  pdcWInNStr:        function(aWindow: PWindow; aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcWInsCh:         function(aWindow: PWindow; aChar: TChType): LongInt; cdecl;
  pdcWInsDelLn:      function(aWindow: PWindow; aCount: LongInt): LongInt; cdecl;
  pdcWInsertLn:      function(aWindow: PWindow): LongInt; cdecl;
  pdcWInsNStr:       function(aWindow: PWindow; const aText: PAnsiChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcWInsStr:        function(aWindow: PWindow;
                              const aText: PAnsiChar): LongInt; cdecl;
  pdcWInStr:         function(aWindow: PWindow; aText: PAnsiChar): LongInt; cdecl;
  pdcWMove:          function(aWindow: PWindow; aY, aX: LongInt): LongInt; cdecl;
  pdcWNOutRefresh:   function(aWindow: PWindow; aY, aX: LongInt): LongInt; cdecl;
  pdcWPrintW:        function(aWindow: PWindow; aFormat: PAnsiChar;
                              const aArgs: array of const): LongInt; cdecl;
  pdcWRedrawLn:      function(aWindow: PWindow;
                              begLine, aCount: LongInt): LongInt; cdecl;
  pdcWRefresh:       function(aWindow: PWindow): LongInt; cdecl;
  pdcWScanW:         function(aWindow: PWindow; const aFormat: PAnsiChar;
                              const aArgs: array of const): LongInt; cdecl;
  pdcWScrl:          function(aWindow: PWindow; aCount: LongInt): LongInt; cdecl;
  pdcWSetScrReg:     function(aWindow: PWindow;
                              aTop, aBottom: LongInt): LongInt; cdecl;
  pdcWStandEnd:      function(aWindow: PWindow): LongInt; cdecl;
  pdcWStandOut:      function(aWindow: PWindow): LongInt; cdecl;
  pdcWSyncDown:      procedure(aWindow: PWindow); cdecl;
  pdcWSyncUp:        procedure(aWindow: PWindow); cdecl;
  pdcWTimeout:       procedure(aWindow: PWindow; aTime: LongInt); cdecl;
  pdcWTouchLn:       function(aWindow: PWindow;
                               aY, aX, aChanged: LongInt): LongInt; cdecl;
  pdcWVLine:         function(aWindow: PWindow; aChar: TChType;
                              aCount: LongInt): LongInt; cdecl;

// Wide-character functions
{$IFDEF PDC_WIDE}
  pdcAddNWStr:       function(const aText: PWideChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcAddWStr:        function(const aText: PWideChar): LongInt; cdecl;
  pdcAddWCh:         function(const aChar: PCChar): LongInt; cdecl;
  pdcAddWChNStr:     function(const aText: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcAddWChStr:      function(const aText: PCChar): LongInt; cdecl;
  pdcBorderSet:      function(const aLS, aRS, aTS, aBS,
                              aTL, atr, aBL, aBR: PCChar): LongInt; cdecl;
  pdcBoxSet:         function(aWindow: PWindow;
                              const aVChar, aHChar: PCChar): LongInt; cdecl;
  pdcEchoWChar:      function(const aChar: PCChar): LongInt; cdecl;
  pdcEraseWChar:     function(aChar: PWideChar): LongInt; cdecl;
  pdcGetBkgrnd:      function(aChar: PCChar): LongInt; cdecl;
  pdcGetCChar:       function(const aWCVal: PCChar; aChar: PWideChar;
                              aAttrs: PAttr; aColorPair: PSmallInt;
                              aOpts: Pointer): LongInt; cdecl;
  pdcGetNWStr:       function(aText: PLongint; aCount: LongInt): LongInt; cdecl;
  pdcGetWCh:         function(aChar: PLongInt): LongInt; cdecl;
  pdcGetWStr:        function(aText: PLongInt): LongInt; cdecl;
  pdcHLineSet:       function(const aChar: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcInNWStr:        function(aText: PWideChar; aCount: LongInt): LongInt; cdecl;
  pdcInsNWStr:       function(const aText: PWideChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcInsWCh:         function(const aChar: PCChar): LongInt; cdecl;
  pdcInsWStr:        function(const aText: PWideChar): LongInt; cdecl;
  pdcInWStr:         function(aText: PWideChar): LongInt; cdecl;
  pdcInWCh:          function(aChar: PCChar): LongInt; cdecl;
  pdcInWChNStr:      function(aChar: PCChar; aCount: LongInt): LongInt; cdecl;
  pdcInWChStr:       function(aChar: PCChar): LongInt; cdecl;
  pdcWKeyName:       function(aKey: WideChar): PAnsiChar; cdecl;
  pdcKillWChar:      function(aChar: PWideChar): LongInt; cdecl;
  pdcMvAddNWStr:     function(aY, aX: LongInt; const aText: PWideChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvAddWStr:      function(aY, aX: LongInt;
                              const aText: PWideChar): LongInt; cdecl;
  pdcMvAddWCh:       function(aY, aX: LongInt;
                              const aChar: PCChar): LongInt; cdecl;
  pdcMvAddWChNStr:   function(aY, aX: LongInt; const aChar: PCChar;
                              acount: LongInt): LongInt; cdecl;
  pdcMvAddWChStr:    function(aY, aX: LongInt;
                              const aChar: PCChar): LongInt; cdecl;
  pdcMvGetNWStr:     function(aY, aX: LongInt; aText: PLongInt;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvGetWCh:       function(aY, aX: LongInt; aChar: PLongInt): LongInt; cdecl;
  pdcMvGetWStr:      function(aY, aX: LongInt; aText: PLongInt): LongInt; cdecl;
  pdcMvHLineSet:     function(aY, aX: LongInt; const aChar: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvInNWStr:      function(aY, aX: LongInt; aText: PWideChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvInsNWStr:     function(aY, aX: LongInt; const aText: PWideChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvInsWCh:       function(aY, aX: LongInt;
                              const aChar: PCChar): LongInt; cdecl;
  pdcMvInsWStr:      function(aY, aX: LongInt;
                              const aText: PWideChar): LongInt; cdecl;
  pdcMvInWStr:       function(aY, aX: LongInt; aText: PWideChar): LongInt; cdecl;
  pdcMvInWCh:        function(aY, aX: LongInt; aChar: PCChar): TChType; cdecl;
  pdcMvInWChNStr:    function(aY, aX: LongInt; aChar: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvInWChStr:     function(aY, aX: LongInt; aChar: PCChar): LongInt; cdecl;
  pdcMvVLineSet:     function(aY, aX: LongInt; const aChar: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWAddNWStr:    function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PWideChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWAddWStr:     function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PWideChar): LongInt; cdecl;
  pdcMvWAddWCh:      function(aWindow: PWindow; aY, aX: LongInt;
                              const aChar: PCChar): LongInt; cdecl;
  pdcMvWAddWChNStr:  function(aWindow: PWindow; aY, aX: LongInt;
                              const aChar: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWAddWChStr:   function(aWindow: PWindow; aY, aX: LongInt;
                              const aChar: PCChar): LongInt; cdecl;
  pdcMvWGetNWStr:    function(aWindow: PWindow; aY, aX: LongInt;
                              aText: PLongInt; aCount: LongInt): LongInt; cdecl;
  pdcMvWGetWCh:      function(aWindow: PWindow; aY, aX: LongInt;
                              aChar: PLongInt): LongInt; cdecl;
  pdcMvWGetWStr:     function(aWindow: PWindow; aY, aX: LongInt;
                              aText: PLongInt): LongInt; cdecl;
  pdcMvWHLineSet:    function(aWindow: PWindow; aY, aX: LongInt;
                              const aChar: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWinNWStr:     function(aWindow: PWindow; aY, aX: LongInt;
                              aText: PWideChar; aCount: LongInt): LongInt; cdecl;
  pdcMvWinsNWStr:    function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PWideChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWinsWCh:      function(aWindow: PWindow; aY, aX: LongInt;
                              aChar: PCChar): LongInt; cdecl;
  pdcMvWinsWStr:     function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PWideChar): LongInt; cdecl;
  pdcMvWinWCh:       function(aWindow: PWindow; aY, aX: LongInt;
                              aChar: PCChar): LongInt; cdecl;
  pdcMvWinWChNStr:   function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcMvWinWChStr:    function(aWindow: PWindow; aY, aX: LongInt;
                              const aText: PCChar): LongInt; cdecl;
  pdcMvWinWStr:      function(aWindow: PWindow; aY, aX: LongInt;
                              aText: PWideChar): LongInt; cdecl;
  pdcMvWVLineSet:    function(aWindow: PWindow; aY, aX: LongInt;
                              const aChar: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcPEchoWChar:     function(aWindow: PWindow;
                              const aChar: PCChar): LongInt; cdecl;
  pdcSetCChar:       function(aWCVal: PCChar; const aChar: PWideChar;
                              const aAttrs: TAttr; aColorPair: SmallInt;
                              const aOpts: Pointer): LongInt; cdecl;
  pdcSlkWSet:        function(aLabelId: LongInt; aText: PWideChar;
                              aJustify: LongInt): LongInt; cdecl;
  pdcUnGetWCh:       function(const aChar: WideChar): LongInt; cdecl;
  pdcVLineSet:       function(aChar: PCChar; aCount: LongInt): LongInt; cdecl;
  pdcWAddNWStr:      function(aWindow: PWindow; const aText: PWideChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcWAddWStr:       function(aWindow: PWindow;
                              const aText: PWideChar): LongInt; cdecl;
  pdcWAddWCh:        function(aWindow: PWindow;
                              const aChar: PCChar): LongInt; cdecl;
  pdcWAddWChNStr:    function(aWindow: PWindow; const aChar: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcWAddWChStr:     function(aWindow: PWindow;
                              const aChar: PCChar): LongInt; cdecl;
  pdcWBkgrnd:        function(aWindow: PWindow;
                              const aChar: PCChar): LongInt; cdecl;
  pdcWBkgrndSet:     procedure(aWindow: PWindow; const aChar: PCChar); cdecl;
  pdcWBorderSet:     function(aWindow: PWindow; const aLS, aRS, aTS, aBS,
                              aTL, atr, aBL, aBR: PCChar): LongInt; cdecl;
  pdcWEchoWChar:     function(aWindow: PWindow;
                              const aChar: PCChar): LongInt; cdecl;
  pdcWGetBkgrnd:     function(aWindow: PWindow; aChar: PCChar): LongInt; cdecl;
  pdcWGetNWStr:      function(aWindow: PWindow; aText: PLongint;
                              aCount: LongInt): LongInt; cdecl;
  pdcWGetWCh:        function(aWindow: PWindow; aChar: PLongInt): LongInt; cdecl;
  pdcWGetWStr:       function(aWindow: PWindow; aText: PLongInt): LongInt; cdecl;
  pdcWHLineSet:      function(aWindow: PWindow; const aChar: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcWInNWStr:       function(aWindow: PWindow; aText: PWideChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcWInsNWStr:      function(aWindow: PWindow; const aText: PWideChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcWInsWCh:        function(aWindow: PWindow;
                              const aChar: PCChar): LongInt; cdecl;
  pdcWInsWStr:       function(aWindow: PWindow;
                              const aText: PWideChar): LongInt; cdecl;
  pdcWInWStr:        function(aWindow: PWindow;
                              aText: PWideChar): LongInt; cdecl;
  pdcWInWCh:         function(aWindow: PWindow; aChar: PCChar): LongInt; cdecl;
  pdcWInWChNStr:     function(aWindow: PWindow; aChar: PCChar;
                              aCount: LongInt): LongInt; cdecl;
  pdcWInWChStr:      function(aWindow: PWindow; aChar: PCChar): LongInt; cdecl;
  pdcWUnCtrl:        function(aChar: PCChar): PWideChar; cdecl;
  pdcWVLineSet:      function(aWindow: PWindow; const aChar: PCChar;
                              aCount: LongInt): LongInt; cdecl;
{$ENDIF PDC_WIDE}

// Quasi-standard
var
  pdcGetAttrs:        function(aWindow: PWindow): TChType; cdecl;
  pdcGetBegX:         function(aWindow: PWindow): LongInt; cdecl;
  pdcGetBegY:         function(aWindow: PWindow): LongInt; cdecl;
  pdcGetMaxX:         function(aWindow: PWindow): LongInt; cdecl;
  pdcGetMaxY:         function(aWindow: PWindow): LongInt; cdecl;
  pdcGetParX:         function(aWindow: PWindow): LongInt; cdecl;
  pdcGetParY:         function(aWindow: PWindow): LongInt; cdecl;
  pdcGetCurX:         function(aWindow: PWindow): LongInt; cdecl;
  pdcGetCurY:         function(aWindow: PWindow): LongInt; cdecl;
  pdcTraceOff:        procedure; cdecl;
  pdcTraceOn:         procedure; cdecl;
  pdcUnCtrl:          function(aChar: TChType): PAnsiChar; cdecl;

  pdcCrMode:          function: LongInt; cdecl;
  pdcNoCrMode:        function: LongInt; cdecl;
  pdcDrainO:          function(aTime: LongInt): LongInt; cdecl;
  pdcResetTerm:       function: LongInt; cdecl;
  pdcFixTerm:         function: LongInt; cdecl;
  pdcSaveTerm:        function: LongInt; cdecl;
  pdcSetSYX:          function(aY, aX: LongInt): LongInt; cdecl;

  pdcMouseSet:        function(aMouseButtonEvent: LongWord): LongInt; cdecl;
  pdcMouseOn:         function(aMouseButtonEvent: LongWord): LongInt; cdecl;
  pdcMouseOff:        function(aMouseButtonEvent: LongWord): LongInt; cdecl;
  pdcRequestMousePos: function: LongInt; cdecl;
  pdcMapButton:       function(aButton: LongWord): LongInt; cdecl;
  pdcWMousePosition:  procedure(aWindow: PWindow; aY, aX: PLongWord); cdecl;
  pdcGetMouse:        function: LongWord; cdecl;
  pdcGetBMap:         function: LongWord; cdecl;

// ncurses
var
  pdcAssumeDefaultColors: function(aFore, aBack: LongInt): LongInt; cdecl;
  pdcCursesVersion:       function: PAnsiChar; cdecl;
  pdcHasKey:              function(aKey: PLongInt): TBool; cdecl;
  pdcUseDefaultColors:    function: LongInt; cdecl;
  pdcWResize:             function(aWindow: PWindow; aLineCount,
                                   aColCount: LongInt): LongInt; cdecl;

  pdcMouseInterval:       function(aInterval: LongInt): LongInt; cdecl;
  pdcMouseMask:           function(aMask: TMMask;
                                   aOldMask: PMMask): TMMask; cdecl;
  pdcMouseTrafo:          function(aY, aX: PLongInt;
                                   aToScreen: TBool): TBool; cdecl;
  pdcNCGetMouse:          function(aEvent: PMEvent): LongInt; cdecl;
  pdcUnGetMouse:          function(aEvent: PMEvent): LongInt; cdecl;
  pdcWEnclose:            function(const aWindow: PWindow;
                                   aY, aX: LongInt): TBool; cdecl;
  pdcWMouseTrafo:         function(const aWindow: PWindow; aY, aX: PLongInt;
                                   aToScreen: TBool): TBool; cdecl;

// PDCurses
const
  FUNCTION_KEY_SHUT_DOWN    = 0;
  FUNCTION_KEY_PASTE        = 1;
  FUNCTION_KEY_ENLARGE_FONT = 2;
  FUNCTION_KEY_SHRINK_FONT  = 3;
  FUNCTION_KEY_CHOOSE_FONT  = 4;
  FUNCTION_KEY_ABORT        = 5;
  PDC_MAX_FUNCTION_KEYS     = 6;

var
  pdcAddRawCh:           function(aChar: TChType): LongInt; cdecl;
  pdcInsRawCh:           function(aChar: TChType): LongInt; cdecl;
  pdcIsTermResized:      function: TBool; cdecl;
  pdcMvAddRawCh:         function(aY, aX: LongInt;
                                  aChar: TChType): LongInt; cdecl;
  pdcMvDeleteLn:         function(aY, aX: LongInt): LongInt; cdecl;
  pdcMvInsertLn:         function(aY, aX: LongInt): LongInt; cdecl;
  pdcMvInsRawCh:         function(aY, aX: LongInt;
                                  aChar: TChType): LongInt; cdecl;
  pdcMvWAddRawCh:        function(aWindow: PWindow; aY, aX: LongInt;
                                  aChar: TChType): LongInt; cdecl;
  pdcMvWDeleteLn:        function(aWindow: PWindow;
                                  aY, aX: LongInt): LongInt; cdecl;
  pdcMvWInsertLn:        function(aWindow: PWindow;
                                  aY, aX: LongInt): LongInt; cdecl;
  pdcMvWInsRawCh:        function(aWindow: PWindow; aY, aX: LongInt;
                                  aChar: TChType): LongInt; cdecl;
  pdcRawOutput:          function(aFlag: TBool): LongInt; cdecl;
  pdcResizeTerm:         function(aLineCount, aColCount: LongInt): LongInt; cdecl;
  pdcResizeWindow:       function(aWindow: PWindow; aLineCount,
                                  aColCount: LongInt): LongInt; cdecl;
  pdcWAddRawCh:          function(aWindow: PWindow;
                                  aChar: TChType): LongInt; cdecl;
  pdcWInsRawCh:          function(aWindow: PWindow;
                                  aChar: TChType): LongInt; cdecl;
  pdcWordChar:           function: AnsiChar; cdecl;
{$IFDEF PDC_WIDE}
  pdcSlkWLabel:          function(aLabelId: LongInt): PWideChar; cdecl;
{$ENDIF PDC_WIDE}
  pdcDebug:              procedure(const aFormat: PAnsiChar;
                                   const aArgs: array of const); cdecl;
  pdcUnGetCh:            function(aChar: LongInt): LongInt; cdecl;
  pdcSetBlink:           function(aFlag: TBool): LongInt; cdecl;
  pdcSetLineColor:       function(aColor: SmallInt): LongInt; cdecl;
  pdcSetTitle:           procedure(const aText: PAnsiChar); cdecl;
  pdcClearClipboard:     function: LongInt; cdecl;
  pdcFreeClipboard:      function(aContents: PAnsiChar): LongInt; cdecl;
  pdcGetClipboard:       function(aContents: PPAnsiChar;
                                  aLength: PLongInt): LongInt; cdecl;
  pdcSetClipboard:       function(const aContents: PAnsiChar;
                                  aLength: LongInt): LongInt; cdecl;
  pdcGetInputFd:         function: LongWord; cdecl;
  pdcGetKeyModifiers:    function: LongWord; cdecl;
  pdcReturnKeyModifiers: function(aFlag: TBool): LongInt; cdecl;
  pdcSaveKeyModifiers:   function(aFlag: TBool): LongInt; cdecl;
  pdcSetResizeLimits:    procedure(const aMinLineCount, aMaxLineCount,
                                   aMinColCount, aMaxColCount: LongInt); cdecl;
  pdcSetFunctionKey:     function(const aFunc: LongWord;
                                  const aNewKey: LongInt): LongInt; cdecl;
  pdcXInitScr:           function(aArgA: LongInt;
                                  aArgV: PPAnsiChar): PWindow; cdecl;

{
  Functions defined as macros
}
// getch() and ungetch() conflict with some DOS libraries
function pdcGetCh: LongInt;

function pdcColorPair(aColor: TChType): TChType;
function pdcPairNumber(aNumber: TChType): TChType;

function pdcGetBegYX(aWindow: PWindow): TPoint;
function pdcGetMaxYX(aWindow: PWindow): TPoint;
function pdcGetParYX(aWindow: PWindow): TPoint;
function pdcGetYX(aWindow: PWindow): TPoint;

function pdcGetSYX: TPoint;

{$IFDEF NCURSES_MOUSE_VERSION}
function pdcGetMouse(aMouseEvent: PMEvent): LongInt;
{$ENDIF}

{
  return codes from PDC_getclipboard() and PDC_setclipboard() calls
}
const
  PDC_CLIP_SUCCESS      = 0;
  PDC_CLIP_ACCESS_ERROR = 1;
  PDC_CLIP_EMPTY        = 2;
  PDC_CLIP_MEMORY_ERROR = 3;

{
  PDCurses key modifier masks
}
const
  PDC_KEY_MODIFIER_SHIFT   = 1;
  PDC_KEY_MODIFIER_CONTROL = 2;
  PDC_KEY_MODIFIER_ALT     = 4;
  PDC_KEY_MODIFIER_NUMLOCK = 8;

{
  Non-lib functions
}
{$IFDEF MSWINDOWS}
function pdcGetProcAddr(aProcName: PAnsiChar;
                        aFromPanelLib: Boolean = False): Pointer;
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
function pdcGetProcAddr(aProcName: PChar;
                        aFromPanelLib: Boolean = False): Pointer;
{$ENDIF POSIX}
procedure pdcInitLib;
procedure pdcFreeLib;
function pdcPortToStr(aPort: TPort): string;

implementation
{
  PDCurses Mouse Interface -- SYSVR4, with extensions
}
function MOUSE_X_POS: LongInt;
begin
  MOUSE_X_POS := pdcSValMouseStatus.X;
end;

function MOUSE_Y_POS: LongInt;
begin
  MOUSE_Y_POS := pdcSValMouseStatus.Y;
end;

function A_BUTTON_CHANGED: LongInt;
begin
  A_BUTTON_CHANGED := pdcSValMouseStatus.changes AND 7;
end;

function MOUSE_MOVED: LongInt;
begin
  MOUSE_MOVED := pdcSValMouseStatus.changes AND PDC_MOUSE_MOVED;
end;

function MOUSE_POS_REPORT: LongInt;
begin
  MOUSE_POS_REPORT := pdcSValMouseStatus.changes AND PDC_MOUSE_POSITION;
end;

function BUTTON_CHANGED(aButton: LongInt): LongInt;
begin
  BUTTON_CHANGED := pdcSValMouseStatus.changes AND ($1 SHL (aButton - 1));
end;

function BUTTON_STATUS(aButton: LongInt): LongInt;
begin
  BUTTON_STATUS := pdcSValMouseStatus.button[aButton - 1];
end;

function MOUSE_WHEEL_UP: LongInt;
begin
  MOUSE_WHEEL_UP := pdcSValMouseStatus.changes AND PDC_MOUSE_WHEEL_UP;
end;

function MOUSE_WHEEL_DOWN: LongInt;
begin
  MOUSE_WHEEL_DOWN := pdcSValMouseStatus.changes AND PDC_MOUSE_WHEEL_DOWN;
end;

function MOUSE_WHEEL_LEFT: LongInt;
begin
  MOUSE_WHEEL_LEFT := pdcSValMouseStatus.changes AND PDC_MOUSE_WHEEL_LEFT;
end;

function MOUSE_WHEEL_RIGHT: LongInt;
begin
  MOUSE_WHEEL_RIGHT := pdcSValMouseStatus.changes AND PDC_MOUSE_WHEEL_RIGHT;
end;

{
  PDCurses External Variables
}
function pdcSValLines: LongInt;
var
  PValLines: PLongInt;
begin
    PValLines    := pdcGetProcAddr('LINES');
    pdcSValLines := PValLines^;
end;

function pdcSValCols: LongInt;
var
  PValCols: PLongInt;
begin
  PValCols    := pdcGetProcAddr('COLS');
  pdcSValCols := PValCols^;
end;

function pdcSValStdScr: PWindow;
var
  PValStdScr: PPWindow;
begin
  PValStdScr    := pdcGetProcAddr('stdscr');
  pdcSValStdScr := PValStdScr^;
end;

function pdcSValCurScr: PWindow;
var
  PValCurScr: PPWindow;
begin
  PValCurScr    := pdcGetProcAddr('curscr');
  pdcSValCurScr := PValCurScr^;
end;

function pdcSValSP: PScreen;
var
  PValSP: PPScreen;
begin
  PValSP    := pdcGetProcAddr('SP');
  pdcSValSP := PValSP^;
end;

function pdcSValMouseStatus: TMouseStatus;
var
  PValMouseStatus: PMouseStatus;
begin
  PValMouseStatus    := pdcGetProcAddr('Mouse_status');
  pdcSValMouseStatus := PValMouseStatus^;
end;

function pdcSValColors: LongInt;
var
  PValColors: PLongInt;
begin
  PValColors    := pdcGetProcAddr('COLORS');
  pdcSValColors := PValColors^;
end;

function pdcSValColorPairs: LongInt;
var
  PValColorPairs: PLongInt;
begin
  PValColorPairs    := pdcGetProcAddr('COLOR_PAIRS');
  pdcSValColorPairs := PValColorPairs^;
end;

function pdcSValTabSize: LongInt;
var
  PValTabSize: PLongInt;
begin
  PValTabSize    := pdcGetProcAddr('TABSIZE');
  pdcSValTabSize := PValTabSize^;
end;

function pdcSValAcsMap: TAcsMap;
var
  PValAcsMap: PAcsMap;
begin
  PValAcsMap    := pdcGetProcAddr('acs_map');
  pdcSValAcsMap := PValAcsMap^;
end;

{$IFDEF MSWINDOWS}
function pdcSValTtyType: AnsiString;
var
  PValTtyType: PAnsiChar;
begin
  PValTtyType    := pdcGetProcAddr('ttytype');
  pdcSValTtyType := AnsiString(PValTtyType);
end;
{$ENDIF MSWINDOWS}
{$IFDEF LINUX}
function pdcSValTtyType: string;
var
  PValTtyType: MarshaledAString;
begin
  PValTtyType    := pdcGetProcAddr('ttytype');
  pdcSValTtyType := string(PValTtyType);
end;
{$ENDIF LINUX}
function pdcSValVersion: TVersionInfo;
var
  PValVersion: PVersionInfo;
begin
  PValVersion    := pdcGetProcAddr('PDC_version');
  pdcSValVersion := PValVersion^;
end;

{
  Video attribute macros
}
{$IFDEF CHTYPE_EXTRA_LONG}
function A_RGB(aRFore, aGFore, aBFore, aRBack, aGBack, aBBack: TChType): TChType;
begin
  A_RGB := (
    (
      (aBFore SHL $19) OR (aGFore SHL $14) OR (aRFore SHL $F) OR
      (aBBack SHL $A)  OR (aGBack SHL $5)  OR aRBack
    ) SHL PDC_COLOR_SHIFT
  ) OR A_RGB_COLOR;
end;
{$ENDIF CHTYPE_EXTRA_LONG}

{
  Alternate character set macros
}
function pdcAcsPick(aWChar, aNChar: AnsiChar): TChType;
begin
{$IF Defined(CHTYPE_LONG) OR Defined(CHTYPE_EXTRA_LONG)}
  Result := TChType(aWChar) OR A_ALTCHARSET;
{$ELSE}
  Result := TChType(aNChar);
{$ENDIF}
end;

// VT100-compatible symbols -- box chars
function ACS_LRCORNER: TChType;
begin
  ACS_LRCORNER := pdcAcsPick('V', '+');
end;

function ACS_URCORNER: TChType;
begin
  ACS_URCORNER := pdcAcsPick('W', '+');
end;

function ACS_ULCORNER: TChType;
begin
  ACS_ULCORNER := pdcAcsPick('X', '+');
end;

function ACS_LLCORNER: TChType;
begin
  ACS_LLCORNER := pdcAcsPick('Y', '+');
end;

function ACS_PLUS: TChType;
begin
  ACS_PLUS := pdcAcsPick('Z', '+');
end;

function ACS_LTEE: TChType;
begin
  ACS_LTEE := pdcAcsPick('[', '+');
end;

function ACS_RTEE: TChType;
begin
  ACS_RTEE := pdcAcsPick('\', '+');
end;

function ACS_BTEE: TChType;
begin
  ACS_BTEE := pdcAcsPick(']', '+');
end;

function ACS_TTEE: TChType;
begin
  ACS_TTEE := pdcAcsPick('^', '+');
end;

function ACS_HLINE: TChType;
begin
  ACS_HLINE := pdcAcsPick('_', '-');
end;

function ACS_VLINE: TChType;
begin
  ACS_VLINE := pdcAcsPick('`', '|');
end;

// PDCurses-only ACS chars.  Don't use if ncurses compatibility matters.
// Some won't work in non-wide X11 builds (see 'acs_defs.h' for details).
function ACS_CENT: TChType;
begin
  ACS_CENT := pdcAcsPick('{', 'c');
end;

function ACS_YEN: TChType;
begin
  ACS_YEN := pdcAcsPick('|', 'y');
end;

function ACS_PESETA: TChType;
begin
  ACS_PESETA := pdcAcsPick('}', 'p');
end;

function ACS_HALF: TChType;
begin
  ACS_HALF := pdcAcsPick('&', '/');
end;

function ACS_QUARTER: TChType;
begin
  ACS_QUARTER := pdcAcsPick(#039, '/'); // #039 = $027 = '
end;

function ACS_LEFT_ANG_QU: TChType;
begin
  ACS_LEFT_ANG_QU := pdcAcsPick(')',  '<');
end;

function ACS_RIGHT_ANG_QU: TChType;
begin
  ACS_RIGHT_ANG_QU := pdcAcsPick('*',  '>');
end;

function ACS_D_HLINE: TChType;
begin
  ACS_D_HLINE := pdcAcsPick('a', '-');
end;

function ACS_D_VLINE: TChType;
begin
  ACS_D_VLINE := pdcAcsPick('b', '|');
end;

function ACS_CLUB: TChType;
begin
  ACS_CLUB := pdcAcsPick(#11, 'C');
end;

function ACS_HEART: TChType;
begin
  ACS_HEART := pdcAcsPick(#12, 'H');
end;

function ACS_SPADE: TChType;
begin
  ACS_SPADE := pdcAcsPick(#13, 'S');
end;

function ACS_SMILE: TChType;
begin
  ACS_SMILE := pdcAcsPick(#14, 'O');
end;

function ACS_REV_SMILE: TChType;
begin
  ACS_REV_SMILE := pdcAcsPick(#15, 'O');
end;

function ACS_MED_BULLET: TChType;
begin
  ACS_MED_BULLET := pdcAcsPick(#16, '.');
end;

function ACS_WHITE_BULLET: TChType;
begin
  ACS_WHITE_BULLET := pdcAcsPick(#17, 'O');
end;

function ACS_PILCROW: TChType;
begin
  ACS_PILCROW := pdcAcsPick(#18, 'O');
end;

function ACS_SECTION: TChType;
begin
  ACS_SECTION := pdcAcsPick(#19, 'O');
end;

function ACS_SUP2: TChType;
begin
  ACS_SUP2 := pdcAcsPick(',', '2');
end;

function ACS_ALPHA: TChType;
begin
  ACS_ALPHA := pdcAcsPick('.', 'a');
end;

function ACS_BETA: TChType;
begin
  ACS_BETA := pdcAcsPick('/', 'b');
end;

function ACS_GAMMA: TChType;
begin
  ACS_GAMMA := pdcAcsPick('0', 'y');
end;

function ACS_UP_SIGMA: TChType;
begin
  ACS_UP_SIGMA := pdcAcsPick('1', 'S');
end;

function ACS_LO_SIGMA: TChType;
begin
  ACS_LO_SIGMA := pdcAcsPick('2', 's');
end;

function ACS_MU: TChType;
begin
  ACS_MU := pdcAcsPick('4', 'u');
end;

function ACS_TAU: TChType;
begin
  ACS_TAU := pdcAcsPick('5', 't');
end;

function ACS_UP_PHI: TChType;
begin
  ACS_UP_PHI := pdcAcsPick('6', 'F');
end;

function ACS_THETA: TChType;
begin
  ACS_THETA := pdcAcsPick('7', 't');
end;

function ACS_OMEGA: TChType;
begin
  ACS_OMEGA := pdcAcsPick('8', 'w');
end;

function ACS_DELTA: TChType;
begin
  ACS_DELTA := pdcAcsPick('9', 'd');
end;

function ACS_INFINITY: TChType;
begin
  ACS_INFINITY := pdcAcsPick('-', 'i');
end;

function ACS_LO_PHI: TChType;
begin
  ACS_LO_PHI := pdcAcsPick(#22, 'f');
end;

function ACS_EPSILON: TChType;
begin
  ACS_EPSILON := pdcAcsPick(':', 'e');
end;

function ACS_INTERSECT: TChType;
begin
  ACS_INTERSECT := pdcAcsPick('e', 'u');
end;

function ACS_TRIPLE_BAR: TChType;
begin
  ACS_TRIPLE_BAR := pdcAcsPick('f', '=');
end;

function ACS_DIVISION: TChType;
begin
  ACS_DIVISION := pdcAcsPick('c', '/');
end;

function ACS_APPROX_EQ: TChType;
begin
  ACS_APPROX_EQ := pdcAcsPick('d', '~');
end;

function ACS_SM_BULLET: TChType;
begin
  ACS_SM_BULLET := pdcAcsPick('g', '.');
end;

function ACS_SQUARE_ROOT: TChType;
begin
  ACS_SQUARE_ROOT := pdcAcsPick('i', '!');
end;

function ACS_UBLOCK: TChType;
begin
  ACS_UBLOCK := pdcAcsPick('p', '^');
end;

function ACS_BBLOCK: TChType;
begin
  ACS_BBLOCK := pdcAcsPick('q', '_');
end;

function ACS_LBLOCK: TChType;
begin
  ACS_LBLOCK := pdcAcsPick('r', '<');
end;

function ACS_RBLOCK: TChType;
begin
  ACS_RBLOCK := pdcAcsPick('s', '>');
end;

function ACS_A_ORDINAL: TChType;
begin
  ACS_A_ORDINAL := pdcAcsPick(#20, 'a');
end;

function ACS_O_ORDINAL: TChType;
begin
  ACS_O_ORDINAL := pdcAcsPick(#21, 'o');
end;

function ACS_INV_QUERY: TChType;
begin
  ACS_INV_QUERY := pdcAcsPick(#24, '?');
end;

function ACS_REV_NOT: TChType;
begin
  ACS_REV_NOT := pdcAcsPick(#25, '!');
end;

function ACS_NOT: TChType;
begin
  ACS_NOT := pdcAcsPick(#26, '!');
end;

function ACS_INV_BANG: TChType;
begin
  ACS_INV_BANG := pdcAcsPick(#23, '!');
end;

function ACS_UP_INTEGRAL: TChType;
begin
  ACS_UP_INTEGRAL := pdcAcsPick(#27, '|');
end;

function ACS_LO_INTEGRAL: TChType;
begin
  ACS_LO_INTEGRAL := pdcAcsPick(#28, '|');
end;

function ACS_SUP_N: TChType;
begin
  ACS_SUP_N := pdcAcsPick(#29, 'n');
end;

function ACS_CENTER_SQU: TChType;
begin
  ACS_CENTER_SQU := pdcAcsPick(#30,  'x');
end;

function ACS_F_WITH_HOOK: TChType;
begin
  ACS_F_WITH_HOOK := pdcAcsPick(#31,  'f');
end;

function ACS_SD_LRCORNER: TChType;
begin
  ACS_SD_LRCORNER := pdcAcsPick(';', '+');
end;

function ACS_SD_URCORNER: TChType;
begin
  ACS_SD_URCORNER := pdcAcsPick('<', '+');
end;

function ACS_SD_ULCORNER: TChType;
begin
  ACS_SD_ULCORNER := pdcAcsPick('=', '+');
end;

function ACS_SD_LLCORNER: TChType;
begin
  ACS_SD_LLCORNER := pdcAcsPick('>', '+');
end;

function ACS_SD_PLUS: TChType;
begin
  ACS_SD_PLUS := pdcAcsPick('?', '+');
end;

function ACS_SD_LTEE: TChType;
begin
  ACS_SD_LTEE := pdcAcsPick('@', '+');
end;

function ACS_SD_RTEE: TChType;
begin
  ACS_SD_RTEE := pdcAcsPick('A', '+');
end;

function ACS_SD_BTEE: TChType;
begin
  ACS_SD_BTEE := pdcAcsPick('B', '+');
end;

function ACS_SD_TTEE: TChType;
begin
  ACS_SD_TTEE := pdcAcsPick('C', '+');
end;

function ACS_D_LRCORNER: TChType;
begin
  ACS_D_LRCORNER := pdcAcsPick('D', '+');
end;

function ACS_D_URCORNER: TChType;
begin
  ACS_D_URCORNER := pdcAcsPick('E', '+');
end;

function ACS_D_ULCORNER: TChType;
begin
  ACS_D_ULCORNER := pdcAcsPick('F', '+');
end;

function ACS_D_LLCORNER: TChType;
begin
  ACS_D_LLCORNER := pdcAcsPick('G', '+');
end;

function ACS_D_PLUS: TChType;
begin
  ACS_D_PLUS := pdcAcsPick('H', '+');
end;

function ACS_D_LTEE: TChType;
begin
  ACS_D_LTEE := pdcAcsPick('I', '+');
end;

function ACS_D_RTEE: TChType;
begin
  ACS_D_RTEE := pdcAcsPick('J', '+');
end;

function ACS_D_BTEE: TChType;
begin
  ACS_D_BTEE := pdcAcsPick('K', '+');
end;

function ACS_D_TTEE: TChType;
begin
  ACS_D_TTEE := pdcAcsPick('L', '+');
end;

function ACS_DS_LRCORNER: TChType;
begin
  ACS_DS_LRCORNER := pdcAcsPick('M', '+');
end;

function ACS_DS_URCORNER: TChType;
begin
  ACS_DS_URCORNER := pdcAcsPick('N', '+');
end;

function ACS_DS_ULCORNER: TChType;
begin
  ACS_DS_ULCORNER := pdcAcsPick('O', '+');
end;

function ACS_DS_LLCORNER: TChType;
begin
  ACS_DS_LLCORNER := pdcAcsPick('P', '+');
end;

function ACS_DS_PLUS: TChType;
begin
  ACS_DS_PLUS := pdcAcsPick('Q', '+');
end;

function ACS_DS_LTEE: TChType;
begin
  ACS_DS_LTEE := pdcAcsPick('R', '+');
end;

function ACS_DS_RTEE: TChType;
begin
  ACS_DS_RTEE := pdcAcsPick('S', '+');
end;

function ACS_DS_BTEE: TChType;
begin
  ACS_DS_BTEE := pdcAcsPick('T', '+');
end;

function ACS_DS_TTEE: TChType;
begin
  ACS_DS_TTEE := pdcAcsPick('U', '+');
end;

// VT100-compatible symbols -- other
function ACS_S1: TChType;
begin
  ACS_S1 := pdcAcsPick('l', '-');
end;

function ACS_S9: TChType;
begin
  ACS_S9 := pdcAcsPick('o', '_');
end;

function ACS_DIAMOND: TChType;
begin
  ACS_DIAMOND := pdcAcsPick('j', '+');
end;

function ACS_CKBOARD: TChType;
begin
  ACS_CKBOARD := pdcAcsPick('k', ':');
end;

function ACS_DEGREE: TChType;
begin
  ACS_DEGREE := pdcAcsPick('w', #039); // #039 = $027 = '
end;

function ACS_PLMINUS: TChType;
begin
  ACS_PLMINUS := pdcAcsPick('x', '#');
end;

function ACS_BULLET: TChType;
begin
  ACS_BULLET := pdcAcsPick('h', 'o');
end;

// Teletype 5410v1 symbols -- these are defined in SysV curses, but
// are not well-supported by most terminals. Stick to VT100 characters
// for optimum portability.
function ACS_LARROW: TChType;
begin
  ACS_LARROW := pdcAcsPick('!', '<');
end;

function ACS_RARROW: TChType;
begin
  ACS_RARROW := pdcAcsPick(' ', '>');
end;

function ACS_DARROW: TChType;
begin
  ACS_DARROW := pdcAcsPick('#', 'v');
end;

function ACS_UARROW: TChType;
begin
  ACS_UARROW := pdcAcsPick('"', '^');
end;

function ACS_BOARD: TChType;
begin
  ACS_BOARD := pdcAcsPick('+', '#');
end;

function ACS_LTBOARD: TChType;
begin
  ACS_LTBOARD := pdcAcsPick('y', '#');
end;

function ACS_LANTERN: TChType;
begin
  ACS_LANTERN := pdcAcsPick('z', '*');
end;

function ACS_BLOCK: TChType;
begin
  ACS_BLOCK := pdcAcsPick('t', '#');
end;

// That goes double for these -- undocumented SysV symbols. Don't use them.
function ACS_S3: TChType;
begin
  ACS_S3 := pdcAcsPick('m', '-');
end;

function ACS_S7: TChType;
begin
  ACS_S7 := pdcAcsPick('n', '-');
end;

function ACS_LEQUAL: TChType;
begin
  ACS_LEQUAL := pdcAcsPick('u', '<');
end;

function ACS_GEQUAL: TChType;
begin
  ACS_GEQUAL := pdcAcsPick('v', '>');
end;

function ACS_PI: TChType;
begin
  ACS_PI := pdcAcsPick('$', 'n');
end;

function ACS_NEQUAL: TChType;
begin
  ACS_NEQUAL := pdcAcsPick('%', '+');
end;

function ACS_STERLING: TChType;
begin
  ACS_STERLING := pdcAcsPick('~', 'L');
end;

// Box char aliases
function ACS_BSSB: TChType;
begin
  ACS_BSSB := ACS_ULCORNER;
end;

function ACS_SSBB: TChType;
begin
  ACS_SSBB := ACS_LLCORNER;
end;

function ACS_BBSS: TChType;
begin
  ACS_BBSS := ACS_URCORNER;
end;

function ACS_SBBS: TChType;
begin
  ACS_SBBS := ACS_LRCORNER;
end;

function ACS_SBSS: TChType;
begin
  ACS_SBSS := ACS_RTEE;
end;

function ACS_SSSB: TChType;
begin
  ACS_SSSB := ACS_LTEE;
end;

function ACS_SSBS: TChType;
begin
  ACS_SSBS := ACS_BTEE;
end;

function ACS_BSSS: TChType;
begin
  ACS_BSSS := ACS_TTEE;
end;

function ACS_BSBS: TChType;
begin
  ACS_BSBS := ACS_HLINE;
end;

function ACS_SBSB: TChType;
begin
  ACS_SBSB := ACS_VLINE;
end;

function ACS_SSSS: TChType;
begin
  ACS_SSSS := ACS_PLUS;
end;

// cchar_t aliases
{$IFDEF PDC_WIDE}
function WACS_LRCORNER: TCChar;
begin
  WACS_LRCORNER := pdcSValAcsMap['V'];
end;

function WACS_URCORNER: TCChar;
begin
  WACS_URCORNER := pdcSValAcsMap['W'];
end;

function WACS_ULCORNER: TCChar;
begin
  WACS_ULCORNER := pdcSValAcsMap['X'];
end;

function WACS_LLCORNER: TCChar;
begin
  WACS_LLCORNER := pdcSValAcsMap['Y'];
end;

function WACS_PLUS: TCChar;
begin
  WACS_PLUS := pdcSValAcsMap['Z'];
end;

function WACS_LTEE: TCChar;
begin
  WACS_LTEE := pdcSValAcsMap['['];
end;

function WACS_RTEE: TCChar;
begin
  WACS_RTEE := pdcSValAcsMap['\'];
end;

function WACS_BTEE: TCChar;
begin
  WACS_BTEE := pdcSValAcsMap[']'];
end;

function WACS_TTEE: TCChar;
begin
  WACS_TTEE := pdcSValAcsMap['^'];
end;

function WACS_HLINE: TCChar;
begin
  WACS_HLINE := pdcSValAcsMap['_'];
end;

function WACS_VLINE: TCChar;
begin
  WACS_VLINE := pdcSValAcsMap['`'];
end;

function WACS_CENT: TCChar;
begin
  WACS_CENT := pdcSValAcsMap['{'];
end;

function WACS_YEN: TCChar;
begin
  WACS_YEN := pdcSValAcsMap['|'];
end;

function WACS_PESETA: TCChar;
begin
  WACS_PESETA := pdcSValAcsMap['}'];
end;

function WACS_HALF: TCChar;
begin
  WACS_HALF := pdcSValAcsMap['&'];
end;

function WACS_QUARTER: TCChar;
begin
  WACS_QUARTER := pdcSValAcsMap[#039]; // #039 = $027 = '
end;

function WACS_LEFT_ANG_QU: TCChar;
begin
  WACS_LEFT_ANG_QU := pdcSValAcsMap[')'];
end;

function WACS_RIGHT_ANG_QU: TCChar;
begin
  WACS_RIGHT_ANG_QU := pdcSValAcsMap['*'];
end;

function WACS_D_HLINE: TCChar;
begin
  WACS_D_HLINE := pdcSValAcsMap['a'];
end;

function WACS_D_VLINE: TCChar;
begin
  WACS_D_VLINE := pdcSValAcsMap['b'];
end;

function WACS_CLUB: TCChar;
begin
  WACS_CLUB := pdcSValAcsMap[#11];
end;

function WACS_HEART: TCChar;
begin
  WACS_HEART := pdcSValAcsMap[#12];
end;

function WACS_SPADE: TCChar;
begin
  WACS_SPADE := pdcSValAcsMap[#13];
end;

function WACS_SMILE: TCChar;
begin
  WACS_SMILE := pdcSValAcsMap[#14];
end;

function WACS_REV_SMILE: TCChar;
begin
  WACS_REV_SMILE := pdcSValAcsMap[#15];
end;

function WACS_MED_BULLET: TCChar;
begin
  WACS_MED_BULLET := pdcSValAcsMap[#16];
end;

function WACS_WHITE_BULLET: TCChar;
begin
  WACS_WHITE_BULLET := pdcSValAcsMap[#17];
end;

function WACS_PILCROW: TCChar;
begin
  WACS_PILCROW := pdcSValAcsMap[#18];
end;

function WACS_SECTION: TCChar;
begin
  WACS_SECTION := pdcSValAcsMap[#19];
end;

function WACS_SUP2: TCChar;
begin
  WACS_SUP2 := pdcSValAcsMap[','];
end;

function WACS_ALPHA: TCChar;
begin
  WACS_ALPHA := pdcSValAcsMap['.'];
end;

function WACS_BETA: TCChar;
begin
  WACS_BETA := pdcSValAcsMap['/'];
end;

function WACS_GAMMA: TCChar;
begin
  WACS_GAMMA := pdcSValAcsMap['0'];
end;

function WACS_UP_SIGMA: TCChar;
begin
  WACS_UP_SIGMA := pdcSValAcsMap['1'];
end;

function WACS_LO_SIGMA: TCChar;
begin
  WACS_LO_SIGMA := pdcSValAcsMap['2'];
end;

function WACS_MU: TCChar;
begin
  WACS_MU := pdcSValAcsMap['4'];
end;

function WACS_TAU: TCChar;
begin
  WACS_TAU := pdcSValAcsMap['5'];
end;

function WACS_UP_PHI: TCChar;
begin
  WACS_UP_PHI := pdcSValAcsMap['6'];
end;

function WACS_THETA: TCChar;
begin
  WACS_THETA := pdcSValAcsMap['7'];
end;

function WACS_OMEGA: TCChar;
begin
  WACS_OMEGA := pdcSValAcsMap['8'];
end;

function WACS_DELTA: TCChar;
begin
  WACS_DELTA := pdcSValAcsMap['9'];
end;

function WACS_INFINITY: TCChar;
begin
  WACS_INFINITY := pdcSValAcsMap['-'];
end;

function WACS_LO_PHI: TCChar;
begin
  WACS_LO_PHI := pdcSValAcsMap[#22];
end;

function WACS_EPSILON: TCChar;
begin
  WACS_EPSILON := pdcSValAcsMap[':'];
end;

function WACS_INTERSECT: TCChar;
begin
  WACS_INTERSECT := pdcSValAcsMap['e'];
end;

function WACS_TRIPLE_BAR: TCChar;
begin
  WACS_TRIPLE_BAR := pdcSValAcsMap['f'];
end;

function WACS_DIVISION: TCChar;
begin
  WACS_DIVISION := pdcSValAcsMap['c'];
end;

function WACS_APPROX_EQ: TCChar;
begin
  WACS_APPROX_EQ := pdcSValAcsMap['d'];
end;

function WACS_SM_BULLET: TCChar;
begin
  WACS_SM_BULLET := pdcSValAcsMap['g'];
end;

function WACS_SQUARE_ROOT: TCChar;
begin
  WACS_SQUARE_ROOT := pdcSValAcsMap['i'];
end;

function WACS_UBLOCK: TCChar;
begin
  WACS_UBLOCK := pdcSValAcsMap['p'];
end;

function WACS_BBLOCK: TCChar;
begin
  WACS_BBLOCK := pdcSValAcsMap['q'];
end;

function WACS_LBLOCK: TCChar;
begin
  WACS_LBLOCK := pdcSValAcsMap['r'];
end;

function WACS_RBLOCK: TCChar;
begin
  WACS_RBLOCK := pdcSValAcsMap['s'];
end;

function WACS_A_ORDINAL: TCChar;
begin
  WACS_A_ORDINAL := pdcSValAcsMap[#20];
end;

function WACS_O_ORDINAL: TCChar;
begin
  WACS_O_ORDINAL := pdcSValAcsMap[#21];
end;

function WACS_INV_QUERY: TCChar;
begin
  WACS_INV_QUERY := pdcSValAcsMap[#24];
end;

function WACS_REV_NOT: TCChar;
begin
  WACS_REV_NOT := pdcSValAcsMap[#25];
end;

function WACS_NOT: TCChar;
begin
  WACS_NOT := pdcSValAcsMap[#26];
end;

function WACS_INV_BANG: TCChar;
begin
  WACS_INV_BANG := pdcSValAcsMap[#23];
end;

function WACS_UP_INTEGRAL: TCChar;
begin
  WACS_UP_INTEGRAL := pdcSValAcsMap[#27];
end;

function WACS_LO_INTEGRAL: TCChar;
begin
  WACS_LO_INTEGRAL := pdcSValAcsMap[#28];
end;

function WACS_SUP_N: TCChar;
begin
  WACS_SUP_N := pdcSValAcsMap[#29];
end;

function WACS_CENTER_SQU: TCChar;
begin
  WACS_CENTER_SQU := pdcSValAcsMap[#30];
end;

function WACS_F_WITH_HOOK: TCChar;
begin
  WACS_F_WITH_HOOK := pdcSValAcsMap[#31];
end;

function WACS_SD_LRCORNER: TCChar;
begin
  WACS_SD_LRCORNER := pdcSValAcsMap[';'];
end;

function WACS_SD_URCORNER: TCChar;
begin
  WACS_SD_URCORNER := pdcSValAcsMap['<'];
end;

function WACS_SD_ULCORNER: TCChar;
begin
  WACS_SD_ULCORNER := pdcSValAcsMap['='];
end;

function WACS_SD_LLCORNER: TCChar;
begin
  WACS_SD_LLCORNER := pdcSValAcsMap['>'];
end;

function WACS_SD_PLUS: TCChar;
begin
  WACS_SD_PLUS := pdcSValAcsMap['?'];
end;

function WACS_SD_LTEE: TCChar;
begin
  WACS_SD_LTEE := pdcSValAcsMap['@'];
end;

function WACS_SD_RTEE: TCChar;
begin
  WACS_SD_RTEE := pdcSValAcsMap['A'];
end;

function WACS_SD_BTEE: TCChar;
begin
  WACS_SD_BTEE := pdcSValAcsMap['B'];
end;

function WACS_SD_TTEE: TCChar;
begin
  WACS_SD_TTEE := pdcSValAcsMap['C'];
end;

function WACS_D_LRCORNER: TCChar;
begin
  WACS_D_LRCORNER := pdcSValAcsMap['D'];
end;

function WACS_D_URCORNER: TCChar;
begin
  WACS_D_URCORNER := pdcSValAcsMap['E'];
end;

function WACS_D_ULCORNER: TCChar;
begin
  WACS_D_ULCORNER := pdcSValAcsMap['F'];
end;

function WACS_D_LLCORNER: TCChar;
begin
  WACS_D_LLCORNER := pdcSValAcsMap['G'];
end;

function WACS_D_PLUS: TCChar;
begin
  WACS_D_PLUS := pdcSValAcsMap['H'];
end;

function WACS_D_LTEE: TCChar;
begin
  WACS_D_LTEE := pdcSValAcsMap['I'];
end;

function WACS_D_RTEE: TCChar;
begin
  WACS_D_RTEE := pdcSValAcsMap['J'];
end;

function WACS_D_BTEE: TCChar;
begin
  WACS_D_BTEE := pdcSValAcsMap['K'];
end;

function WACS_D_TTEE: TCChar;
begin
  WACS_D_TTEE := pdcSValAcsMap['L'];
end;

function WACS_DS_LRCORNER: TCChar;
begin
  WACS_DS_LRCORNER := pdcSValAcsMap['M'];
end;

function WACS_DS_URCORNER: TCChar;
begin
  WACS_DS_URCORNER := pdcSValAcsMap['N'];
end;

function WACS_DS_ULCORNER: TCChar;
begin
  WACS_DS_ULCORNER := pdcSValAcsMap['O'];
end;

function WACS_DS_LLCORNER: TCChar;
begin
  WACS_DS_LLCORNER := pdcSValAcsMap['P'];
end;

function WACS_DS_PLUS: TCChar;
begin
  WACS_DS_PLUS := pdcSValAcsMap['Q'];
end;

function WACS_DS_LTEE: TCChar;
begin
  WACS_DS_LTEE := pdcSValAcsMap['R'];
end;

function WACS_DS_RTEE: TCChar;
begin
  WACS_DS_RTEE := pdcSValAcsMap['S'];
end;

function WACS_DS_BTEE: TCChar;
begin
  WACS_DS_BTEE := pdcSValAcsMap['T'];
end;

function WACS_DS_TTEE: TCChar;
begin
  WACS_DS_TTEE := pdcSValAcsMap['U'];
end;

function WACS_S1: TCChar;
begin
  WACS_S1 := pdcSValAcsMap['l'];
end;

function WACS_S9: TCChar;
begin
  WACS_S9 := pdcSValAcsMap['o'];
end;

function WACS_DIAMOND: TCChar;
begin
  WACS_DIAMOND := pdcSValAcsMap['j'];
end;

function WACS_CKBOARD: TCChar;
begin
  WACS_CKBOARD := pdcSValAcsMap['k'];
end;

function WACS_DEGREE: TCChar;
begin
  WACS_DEGREE := pdcSValAcsMap['w'];
end;

function WACS_PLMINUS: TCChar;
begin
  WACS_PLMINUS := pdcSValAcsMap['x'];
end;

function WACS_BULLET: TCChar;
begin
  WACS_BULLET := pdcSValAcsMap['h'];
end;

function WACS_LARROW: TCChar;
begin
  WACS_LARROW := pdcSValAcsMap['!'];
end;

function WACS_RARROW: TCChar;
begin
  WACS_RARROW := pdcSValAcsMap[' '];
end;

function WACS_DARROW: TCChar;
begin
  WACS_DARROW := pdcSValAcsMap['#'];
end;

function WACS_UARROW: TCChar;
begin
  WACS_UARROW := pdcSValAcsMap['"'];
end;

function WACS_BOARD: TCChar;
begin
  WACS_BOARD := pdcSValAcsMap['+'];
end;

function WACS_LTBOARD: TCChar;
begin
  WACS_LTBOARD := pdcSValAcsMap['y'];
end;

function WACS_LANTERN: TCChar;
begin
  WACS_LANTERN := pdcSValAcsMap['z'];
end;

function WACS_BLOCK: TCChar;
begin
  WACS_BLOCK := pdcSValAcsMap['t'];
end;

function WACS_S3: TCChar;
begin
  WACS_S3 := pdcSValAcsMap['m'];
end;

function WACS_S7: TCChar;
begin
  WACS_S7 := pdcSValAcsMap['n'];
end;

function WACS_LEQUAL: TCChar;
begin
  WACS_LEQUAL := pdcSValAcsMap['u'];
end;

function WACS_GEQUAL: TCChar;
begin
  WACS_GEQUAL := pdcSValAcsMap['v'];
end;

function WACS_PI: TCChar;
begin
  WACS_PI := pdcSValAcsMap['$'];
end;

function WACS_NEQUAL: TCChar;
begin
  WACS_NEQUAL := pdcSValAcsMap['%'];
end;

function WACS_STERLING: TCChar;
begin
  WACS_STERLING := pdcSValAcsMap['~'];
end;

function WACS_BSSB: TCChar;
begin
  WACS_BSSB := WACS_ULCORNER;
end;

function WACS_SSBB: TCChar;
begin
  WACS_SSBB := WACS_LLCORNER;
end;

function WACS_BBSS: TCChar;
begin
  WACS_BBSS := WACS_URCORNER;
end;

function WACS_SBBS: TCChar;
begin
  WACS_SBBS := WACS_LRCORNER;
end;

function WACS_SBSS: TCChar;
begin
  WACS_SBSS := WACS_RTEE;
end;

function WACS_SSSB: TCChar;
begin
  WACS_SSSB := WACS_LTEE;
end;

function WACS_SSBS: TCChar;
begin
  WACS_SSBS := WACS_BTEE;
end;

function WACS_BSSS: TCChar;
begin
  WACS_BSSS := WACS_TTEE;
end;

function WACS_BSBS: TCChar;
begin
  WACS_BSBS := WACS_HLINE;
end;

function WACS_SBSB: TCChar;
begin
  WACS_SBSB := WACS_VLINE;
end;

function WACS_SSSS: TCChar;
begin
  WACS_SSSS := WACS_PLUS;
end;
{$ENDIF PDC_WIDE}

{$IFDEF ASSEMBLER}
{
  Functions used to overcome the inability of using C(++)'s va_list type
}
function pdcVW_PrintW(aWindow: PWindow; const aFormat: PAnsiChar;
                      const aArgs: array of const): LongInt;
var
   retVal: PLongInt;
   func: function(aWindow: PWindow; const aFormat: PAnsiChar;
                  va_list: Pointer): LongInt; cdecl;
begin
  @func  := pdcGetProcAddr('vw_printw');
  retVal := CallVA_ListFunction(@func, aWindow, aFormat, aArgs);
  Result := retVal^;
end;

function pdcVWPrintW(aWindow: PWindow; const aFormat: PAnsiChar;
                     const aArgs: array of const): LongInt;
var
   retVal: PLongInt;
   func: function(aWindow: PWindow; const aFormat: PAnsiChar;
                  va_list: Pointer): LongInt; cdecl;
begin
  @func  := pdcGetProcAddr('vwprintw');
  retVal := CallVA_ListFunction(@func, aWindow, aFormat, aArgs);
  Result := retVal^;
end;

function pdcVW_ScanW(aWindow: PWindow; const aFormat: PAnsiChar;
                     const aArgs: array of const): LongInt;
var
   retVal: PLongInt;
   func: function(aWindow: PWindow; const aFormat: PAnsiChar;
                  va_list: Pointer): LongInt; cdecl;
begin
  @func  := pdcGetProcAddr('vw_scanw');
  retVal := CallVA_ListFunction(@func, aWindow, aFormat, aArgs);
  Result := retVal^;
end;

function pdcVWScanW(aWindow: PWindow; const aFormat: PAnsiChar;
                    const aArgs: array of const): LongInt;
var
   retVal: PLongInt;
   func: function(aWindow: PWindow; const aFormat: PAnsiChar;
                  va_list: Pointer): LongInt; cdecl;
begin
  @func  := pdcGetProcAddr('vwscanw');
  retVal := CallVA_ListFunction(@func, aWindow, aFormat, aArgs);
  Result := retVal^;
end;
{$ENDIF ASSEMBLER}


function KEY_F(aNum: Byte): TChType;
begin
  KEY_F := KEY_F0 + aNum;
end;

{
  Functions defined as macros
}
function pdcGetCh: LongInt;
begin
  Result := pdcWGetCh(pdcSValStdScr);
end;

function pdcColorPair(aColor: TChType): TChType;
begin
  Result := ((aColor SHL PDC_COLOR_SHIFT) AND A_COLOR);
end;

function pdcPairNumber(aNumber: TChType): TChType;
begin
  Result := ((aNumber AND A_COLOR) SHR PDC_COLOR_SHIFT);
end;

function pdcGetBegYX(aWindow: PWindow): TPoint;
begin
  Result.Y := pdcGetBegY(aWindow);
  Result.X := pdcGetBegX(aWindow);
end;

function pdcGetMaxYX(aWindow: PWindow): TPoint;
begin
  Result.Y := pdcGetMaxY(aWindow);
  Result.X := pdcGetMaxX(aWindow);
end;

function pdcGetParYX(aWindow: PWindow): TPoint;
begin
  Result.Y := pdcGetParY(aWindow);
  Result.X := pdcGetParX(aWindow);
end;

function pdcGetYX(aWindow: PWindow): TPoint;
begin
  Result.Y := pdcGetCurY(aWindow);
  Result.X := pdcGetCurX(aWindow);
end;

function pdcGetSYX: TPoint;
begin
  if pdcSValCurScr._leaveit > 0 then
  begin
    Result.Y := -1;
    Result.X := -1;
  end else
  begin
    Result := pdcGetYX(pdcSValCurScr);
  end;
end;

{$IFDEF NCURSES_MOUSE_VERSION}
function pdcGetMouse(aMouseEvent: PMEvent): LongInt;
begin
  Result := pdcNCGetMouse(aMouseEvent);
end;
{$ENDIF}

{
  Non-lib functions
}
{$IFDEF MSWINDOWS}
function pdcGetProcAddr(aProcName: PAnsiChar; aFromPanelLib: Boolean): Pointer;
begin
  Result := GetProcAddress(HMODULE(PDCLibHandle), aProcName);

{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
function pdcGetProcAddr(aProcName: PChar; aFromPanelLib: Boolean): Pointer;
var
  Error: MarshaledAString;
  M:     TMarshaller;
begin
  dlerror;

  if aFromPanelLib then
    Result := dlsym(PDCPanelLibHandle, M.AsAnsi(aProcName, CP_UTF8).ToPointer)
  else
    Result := dlsym(PDCLibHandle, M.AsAnsi(aProcName, CP_UTF8).ToPointer);

  Error  := dlerror;

  if Error <> nil then
    Result := nil;
{$ENDIF POSIX}

  if Result = nil then
    raise EDLLLoadError.Create('Unable to find the method address.');
end;

procedure pdcInitLib;
{$IFDEF MSWINDOWS}
begin
  if PDCLibHandle <> nil then Exit;

  PDCLibHandle := Pointer(LoadLibrary(PChar(LIBPDCURSES)));
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
var
  Marshaller: TMarshaller;
begin
  if PDCLibHandle <> nil then Exit;

  PDCLibHandle := dlopen(Marshaller.AsAnsi(LIBPDCURSES, CP_UTF8).ToPointer,
                         RTLD_LAZY);
{$ENDIF POSIX}

  if PDCLibHandle <> nil then
  begin
    // Load the library functions
    // Standard
    @pdcAddCh          := pdcGetProcAddr('addch');
    @pdcAddChNStr      := pdcGetProcAddr('addchnstr');
    @pdcAddChStr       := pdcGetProcAddr('addchstr');
    @pdcAddNStr        := pdcGetProcAddr('addnstr');
    @pdcAddStr         := pdcGetProcAddr('addstr');
    @pdcAttrOff        := pdcGetProcAddr('attroff');
    @pdcAttrOn         := pdcGetProcAddr('attron');
    @pdcAttrSet        := pdcGetProcAddr('attrset');
    @pdcAttrOptsGet    := pdcGetProcAddr('attr_get');
    @pdcAttrOptsOff    := pdcGetProcAddr('attr_off');
    @pdcAttrOptsOn     := pdcGetProcAddr('attr_on');
    @pdcAttrOptsSet    := pdcGetProcAddr('attr_set');
    @pdcBaudRate       := pdcGetProcAddr('baudrate');
    @pdcBeep           := pdcGetProcAddr('beep');
    @pdcBkgd           := pdcGetProcAddr('bkgd');
    @pdcBkgdSet        := pdcGetProcAddr('bkgdset');
    @pdcBorder         := pdcGetProcAddr('border');
    @pdcBox            := pdcGetProcAddr('box');
    @pdcCanChangeColor := pdcGetProcAddr('can_change_color');
    @pdcCBreak         := pdcGetProcAddr('cbreak');
    @pdcChgAt          := pdcGetProcAddr('chgat');
    @pdcClearOk        := pdcGetProcAddr('clearok');
    @pdcClear          := pdcGetProcAddr('clear');
    @pdcClrToBot       := pdcGetProcAddr('clrtobot');
    @pdcClrToEOL       := pdcGetProcAddr('clrtoeol');
    @pdcColorContent   := pdcGetProcAddr('color_content');
    @pdcColorSet       := pdcGetProcAddr('color_set');
    @pdcCopyWin        := pdcGetProcAddr('copywin');
    @pdcCursSet        := pdcGetProcAddr('curs_set');
    @pdcDefProgMode    := pdcGetProcAddr('def_prog_mode');
    @pdcDefShellMode   := pdcGetProcAddr('def_shell_mode');
    @pdcDelayOutput    := pdcGetProcAddr('delay_output');
    @pdcDelCh          := pdcGetProcAddr('delch');
    @pdcDeleteLn       := pdcGetProcAddr('deleteln');
    @pdcDelScreen      := pdcGetProcAddr('delscreen');
    @pdcDelWin         := pdcGetProcAddr('delwin');
    @pdcDerWin         := pdcGetProcAddr('derwin');
    @pdcDoUpdate       := pdcGetProcAddr('doupdate');
    @pdcDupWin         := pdcGetProcAddr('dupwin');
    @pdcEchoChar       := pdcGetProcAddr('echochar');
    @pdcEcho           := pdcGetProcAddr('echo');
    @pdcEndWin         := pdcGetProcAddr('endwin');
    @pdcEraseChar      := pdcGetProcAddr('erasechar');
    @pdcErase          := pdcGetProcAddr('erase');
    @pdcFilter         := pdcGetProcAddr('filter');
    @pdcFlash          := pdcGetProcAddr('flash');
    @pdcFlushInp       := pdcGetProcAddr('flushinp');
    @pdcGetBkgd        := pdcGetProcAddr('getbkgd');
    @pdcGetNStr        := pdcGetProcAddr('getnstr');
    @pdcGetStr         := pdcGetProcAddr('getstr');
    @pdcGetWin         := pdcGetProcAddr('getwin');
    @pdcHalfDelay      := pdcGetProcAddr('halfdelay');
    @pdcHasColors      := pdcGetProcAddr('has_colors');
    @pdcHasIC          := pdcGetProcAddr('has_ic');
    @pdcHasIL          := pdcGetProcAddr('has_il');
    @pdcHLine          := pdcGetProcAddr('hline');
    @pdcIDCOk          := pdcGetProcAddr('idcok');
    @pdcIDLOk          := pdcGetProcAddr('idlok');
    @pdcImmedOk        := pdcGetProcAddr('immedok');
    @pdcInChNStr       := pdcGetProcAddr('inchnstr');
    @pdcInChStr        := pdcGetProcAddr('inchstr');
    @pdcInCh           := pdcGetProcAddr('inch');
    @pdcInitColor      := pdcGetProcAddr('init_color');
    @pdcInitPair       := pdcGetProcAddr('init_pair');
    @pdcInitScr        := pdcGetProcAddr('initscr');
    @pdcInNStr         := pdcGetProcAddr('innstr');
    @pdcInsCh          := pdcGetProcAddr('insch');
    @pdcInsDelLn       := pdcGetProcAddr('insdelln');
    @pdcInsertLn       := pdcGetProcAddr('insertln');
    @pdcInsNStr        := pdcGetProcAddr('insnstr');
    @pdcInsStr         := pdcGetProcAddr('insstr');
    @pdcInStr          := pdcGetProcAddr('instr');
    @pdcIntrFlush      := pdcGetProcAddr('intrflush');
    @pdcIsEndWin       := pdcGetProcAddr('isendwin');
    @pdcIsLineTouched  := pdcGetProcAddr('is_linetouched');
    @pdcIsWinTouched   := pdcGetProcAddr('is_wintouched');
    @pdcKeyName        := pdcGetProcAddr('keyname');
    @pdcKeyPad         := pdcGetProcAddr('keypad');
    @pdcKillChar       := pdcGetProcAddr('killchar');
    @pdcLeaveOk        := pdcGetProcAddr('leaveok');
    @pdcLongName       := pdcGetProcAddr('longname');
    @pdcMeta           := pdcGetProcAddr('meta');
    @pdcMove           := pdcGetProcAddr('move');
    @pdcMvAddCh        := pdcGetProcAddr('mvaddch');
    @pdcMvAddChNStr    := pdcGetProcAddr('mvaddchnstr');
    @pdcMvAddChStr     := pdcGetProcAddr('mvaddchstr');
    @pdcMvAddNStr      := pdcGetProcAddr('mvaddnstr');
    @pdcMvAddStr       := pdcGetProcAddr('mvaddstr');
    @pdcMvChgAt        := pdcGetProcAddr('mvchgat');
    @pdcMvCur          := pdcGetProcAddr('mvcur');
    @pdcMvDelCh        := pdcGetProcAddr('mvdelch');
    @pdcMvDerWin       := pdcGetProcAddr('mvderwin');
    @pdcMvGetCh        := pdcGetProcAddr('mvgetch');
    @pdcMvGetNStr      := pdcGetProcAddr('mvgetnstr');
    @pdcMvGetStr       := pdcGetProcAddr('mvgetstr');
    @pdcMvHLine        := pdcGetProcAddr('mvhline');
    @pdcMvInCh         := pdcGetProcAddr('mvinch');
    @pdcMvInChNStr     := pdcGetProcAddr('mvinchnstr');
    @pdcMvInChStr      := pdcGetProcAddr('mvinchstr');
    @pdcMvInNStr       := pdcGetProcAddr('mvinnstr');
    @pdcMvInsCh        := pdcGetProcAddr('mvinsch');
    @pdcMvInsNStr      := pdcGetProcAddr('mvinsnstr');
    @pdcMvInsStr       := pdcGetProcAddr('mvinsstr');
    @pdcMvInStr        := pdcGetProcAddr('mvinstr');
    @pdcMvPrintW       := pdcGetProcAddr('mvprintw');
    @pdcMvScanW        := pdcGetProcAddr('mvscanw');
    @pdcMvVLine        := pdcGetProcAddr('mvvline');
    @pdcMvWAddChNStr   := pdcGetProcAddr('mvwaddchnstr');
    @pdcMvWAddChStr    := pdcGetProcAddr('mvwaddchstr');
    @pdcMvWAddCh       := pdcGetProcAddr('mvwaddch');
    @pdcMvWAddNStr     := pdcGetProcAddr('mvwaddnstr');
    @pdcMvWAddStr      := pdcGetProcAddr('mvwaddstr');
    @pdcMvWChgAt       := pdcGetProcAddr('mvwchgat');
    @pdcMvWDelCh       := pdcGetProcAddr('mvwdelch');
    @pdcMvWGetCh       := pdcGetProcAddr('mvwgetch');
    @pdcMvWGetNStr     := pdcGetProcAddr('mvwgetnstr');
    @pdcMvWGetStr      := pdcGetProcAddr('mvwgetstr');
    @pdcMvWHLine       := pdcGetProcAddr('mvwhline');
    @pdcMvWinChNStr    := pdcGetProcAddr('mvwinchnstr');
    @pdcMvWinChStr     := pdcGetProcAddr('mvwinchstr');
    @pdcMvWinCh        := pdcGetProcAddr('mvwinch');
    @pdcMvWinNStr      := pdcGetProcAddr('mvwinnstr');
    @pdcMvWinsCh       := pdcGetProcAddr('mvwinsch');
    @pdcMvWinsNStr     := pdcGetProcAddr('mvwinsnstr');
    @pdcMvWinsStr      := pdcGetProcAddr('mvwinsstr');
    @pdcMvWinStr       := pdcGetProcAddr('mvwinstr');
    @pdcMvWin          := pdcGetProcAddr('mvwin');
    @pdcMvWPrintW      := pdcGetProcAddr('mvwprintw');
    @pdcMvWScanW       := pdcGetProcAddr('mvwscanw');
    @pdcMvWVLine       := pdcGetProcAddr('mvwvline');
    @pdcNapMS          := pdcGetProcAddr('napms');
    @pdcNewPad         := pdcGetProcAddr('newpad');
    @pdcNewTerm        := pdcGetProcAddr('newterm');
    @pdcNewWin         := pdcGetProcAddr('newwin');
    @pdcNL             := pdcGetProcAddr('nl');
    @pdcNoCBreak       := pdcGetProcAddr('nocbreak');
    @pdcNoDelay        := pdcGetProcAddr('nodelay');
    @pdcNoEcho         := pdcGetProcAddr('noecho');
    @pdcNoNL           := pdcGetProcAddr('nonl');
    @pdcNoQIFlush      := pdcGetProcAddr('noqiflush');
    @pdcNoRaw          := pdcGetProcAddr('noraw');
    @pdcNoTimeout      := pdcGetProcAddr('notimeout');
    @pdcOverlay        := pdcGetProcAddr('overlay');
    @pdcOverwrite      := pdcGetProcAddr('overwrite');
    @pdcPairContent    := pdcGetProcAddr('pair_content');
    @pdcPEchoChar      := pdcGetProcAddr('pechochar');
    @pdcPNOutRefresh   := pdcGetProcAddr('pnoutrefresh');
    @pdcPRefresh       := pdcGetProcAddr('prefresh');
    @pdcPrintW         := pdcGetProcAddr('printw');
    @pdcPutWin         := pdcGetProcAddr('putwin');
    @pdcQIFlush        := pdcGetProcAddr('qiflush');
    @pdcRaw            := pdcGetProcAddr('raw');
    @pdcRedrawWin      := pdcGetProcAddr('redrawwin');
    @pdcRefresh        := pdcGetProcAddr('refresh');
    @pdcResetProgMode  := pdcGetProcAddr('reset_prog_mode');
    @pdcResetShellMode := pdcGetProcAddr('reset_shell_mode');
    @pdcResetTy        := pdcGetProcAddr('resetty');
    @pdcRopOffline     := pdcGetProcAddr('ripoffline');
    @pdcSaveTty        := pdcGetProcAddr('savetty');
    @pdcScanW          := pdcGetProcAddr('scanw');
    @pdcScrDump        := pdcGetProcAddr('scr_dump');
    @pdcScrInit        := pdcGetProcAddr('scr_init');
    @pdcScrRestore     := pdcGetProcAddr('scr_restore');
    @pdcScrSet         := pdcGetProcAddr('scr_set');
    @pdcScrl           := pdcGetProcAddr('scrl');
    @pdcScroll         := pdcGetProcAddr('scroll');
    @pdcScrollOk       := pdcGetProcAddr('scrollok');
    @pdcSetTerm        := pdcGetProcAddr('set_term');
    @pdcSetScrReg      := pdcGetProcAddr('setscrreg');
    @pdcSlkAttrOff     := pdcGetProcAddr('slk_attroff');
    @pdcSlkAttr_Off    := pdcGetProcAddr('slk_attr_off');
    @pdcSlkAttrOn      := pdcGetProcAddr('slk_attron');
    @pdcSlkAttr_On     := pdcGetProcAddr('slk_attr_on');
    @pdcSlkAttrSet     := pdcGetProcAddr('slk_attrset');
    @pdcSlkAttr_Set    := pdcGetProcAddr('slk_attr_set');
    @pdcSlkClear       := pdcGetProcAddr('slk_clear');
    @pdcSlkColor       := pdcGetProcAddr('slk_color');
    @pdcSlkInit        := pdcGetProcAddr('slk_init');
    @pdcSlkLabel       := pdcGetProcAddr('slk_label');
    @pdcSlkNOutRefresh := pdcGetProcAddr('slk_noutrefresh');
    @pdcSlkRefresh     := pdcGetProcAddr('slk_refresh');
    @pdcSlkRestore     := pdcGetProcAddr('slk_restore');
    @pdcSlkSet         := pdcGetProcAddr('slk_set');
    @pdcSlkTouch       := pdcGetProcAddr('slk_touch');
    @pdcStandEnd       := pdcGetProcAddr('standend');
    @pdcStandOut       := pdcGetProcAddr('standout');
    @pdcStartColor     := pdcGetProcAddr('start_color');
    @pdcSubPad         := pdcGetProcAddr('subpad');
    @pdcSubWin         := pdcGetProcAddr('subwin');
    @pdcSyncOk         := pdcGetProcAddr('syncok');
    @pdcTermAttrs      := pdcGetProcAddr('termattrs');
    @pdcTerm_Attrs     := pdcGetProcAddr('term_attrs');
    @pdcTermName       := pdcGetProcAddr('termname');
    @pdcTimeout        := pdcGetProcAddr('timeout');
    @pdcTouchLine      := pdcGetProcAddr('touchline');
    @pdcTouchWin       := pdcGetProcAddr('touchwin');
    @pdcTypeAhead      := pdcGetProcAddr('typeahead');
    @pdcUnTouchWin     := pdcGetProcAddr('untouchwin');
    @pdcUseEnv         := pdcGetProcAddr('use_env');
    @pdcVidAttr        := pdcGetProcAddr('vidattr');
    @pdcVid_Attr       := pdcGetProcAddr('vid_attr');
    @pdcVidPutS        := pdcGetProcAddr('vidputs');
    @pdcVid_PutS       := pdcGetProcAddr('vid_puts');
    @pdcVLine          := pdcGetProcAddr('vline');
    // The va_list methods are handled elsewhere
    @pdcWAddChNStr     := pdcGetProcAddr('waddchnstr');
    @pdcWAddChStr      := pdcGetProcAddr('waddchstr');
    @pdcWAddCh         := pdcGetProcAddr('waddch');
    @pdcWAddNStr       := pdcGetProcAddr('waddnstr');
    @pdcWAddStr        := pdcGetProcAddr('waddstr');
    @pdcWAttrOff       := pdcGetProcAddr('wattroff');
    @pdcWAttrOn        := pdcGetProcAddr('wattron');
    @pdcWAttrSet       := pdcGetProcAddr('wattrset');
    @pdcWAttr_Get      := pdcGetProcAddr('wattr_get');
    @pdcWAttr_Off      := pdcGetProcAddr('wattr_off');
    @pdcWAttr_On       := pdcGetProcAddr('wattr_on');
    @pdcWAttr_Set      := pdcGetProcAddr('wattr_set');
    @pdcWBkgdSet       := pdcGetProcAddr('wbkgdset');
    @pdcWBkgd          := pdcGetProcAddr('wbkgd');
    @pdcWBorder        := pdcGetProcAddr('wborder');
    @pdcWChgAt         := pdcGetProcAddr('wchgat');
    @pdcWClear         := pdcGetProcAddr('wclear');
    @pdcWClrToBot      := pdcGetProcAddr('wclrtobot');
    @pdcWClrToEOL      := pdcGetProcAddr('wclrtoeol');
    @pdcWColorSet      := pdcGetProcAddr('wcolor_set');
    @pdcWCurSyncUp     := pdcGetProcAddr('wcursyncup');
    @pdcWDelCh         := pdcGetProcAddr('wdelch');
    @pdcWDeleteLn      := pdcGetProcAddr('wdeleteln');
    @pdcWEchoChar      := pdcGetProcAddr('wechochar');
    @pdcWErase         := pdcGetProcAddr('werase');
    @pdcWGetCh         := pdcGetProcAddr('wgetch');
    @pdcWGetNStr       := pdcGetProcAddr('wgetnstr');
    @pdcWGetStr        := pdcGetProcAddr('wgetstr');
    @pdcWHLine         := pdcGetProcAddr('whline');
    @pdcWInChNStr      := pdcGetProcAddr('winchnstr');
    @pdcWInChStr       := pdcGetProcAddr('winchstr');
    @pdcWInCh          := pdcGetProcAddr('winch');
    @pdcWInNStr        := pdcGetProcAddr('winnstr');
    @pdcWInsCh         := pdcGetProcAddr('winsch');
    @pdcWInsDelLn      := pdcGetProcAddr('winsdelln');
    @pdcWInsertLn      := pdcGetProcAddr('winsertln');
    @pdcWInsNStr       := pdcGetProcAddr('winsnstr');
    @pdcWInsStr        := pdcGetProcAddr('winsstr');
    @pdcWInStr         := pdcGetProcAddr('winstr');
    @pdcWMove          := pdcGetProcAddr('wmove');
    @pdcWNOutRefresh   := pdcGetProcAddr('wnoutrefresh');
    @pdcWPrintW        := pdcGetProcAddr('wprintw');
    @pdcWRedrawLn      := pdcGetProcAddr('wredrawln');
    @pdcWRefresh       := pdcGetProcAddr('wrefresh');
    @pdcWScanW         := pdcGetProcAddr('wscanw');
    @pdcWScrl          := pdcGetProcAddr('wscrl');
    @pdcWSetScrReg     := pdcGetProcAddr('wsetscrreg');
    @pdcWStandEnd      := pdcGetProcAddr('wstandend');
    @pdcWStandOut      := pdcGetProcAddr('wstandout');
    @pdcWSyncDown      := pdcGetProcAddr('wsyncdown');
    @pdcWSyncUp        := pdcGetProcAddr('wsyncup');
    @pdcWTimeout       := pdcGetProcAddr('wtimeout');
    @pdcWTouchLn       := pdcGetProcAddr('wtouchln');
    @pdcWVLine         := pdcGetProcAddr('wvline');

    // Wide-character functions
{$IFDEF PDC_WIDE}
    @pdcAddNWStr       := pdcGetProcAddr('addnwstr');
    @pdcAddWStr        := pdcGetProcAddr('addwstr');
    @pdcAddWCh         := pdcGetProcAddr('add_wch');
    @pdcAddWChNStr     := pdcGetProcAddr('add_wchnstr');
    @pdcAddWChStr      := pdcGetProcAddr('add_wchstr');
    @pdcBorderSet      := pdcGetProcAddr('border_set');
    @pdcBoxSet         := pdcGetProcAddr('box_set');
    @pdcEchoWChar      := pdcGetProcAddr('echo_wchar');
    @pdcEraseWChar     := pdcGetProcAddr('erasewchar');
    @pdcGetBkgrnd      := pdcGetProcAddr('getbkgrnd');
    @pdcGetCChar       := pdcGetProcAddr('getcchar');
    @pdcGetNWStr       := pdcGetProcAddr('getn_wstr');
    @pdcGetWCh         := pdcGetProcAddr('get_wch');
    @pdcGetWStr        := pdcGetProcAddr('get_wstr');
    @pdcHLineSet       := pdcGetProcAddr('hline_set');
    @pdcInNWStr        := pdcGetProcAddr('innwstr');
    @pdcInsNWStr       := pdcGetProcAddr('ins_nwstr');
    @pdcInsWCh         := pdcGetProcAddr('ins_wch');
    @pdcInsWStr        := pdcGetProcAddr('ins_wstr');
    @pdcInWStr         := pdcGetProcAddr('inwstr');
    @pdcInWCh          := pdcGetProcAddr('in_wch');
    @pdcInWChNStr      := pdcGetProcAddr('in_wchnstr');
    @pdcInWChStr       := pdcGetProcAddr('in_wchstr');
    @pdcWKeyName       := pdcGetProcAddr('key_name');
    @pdcKillWChar      := pdcGetProcAddr('killwchar');
    @pdcMvAddNWStr     := pdcGetProcAddr('mvaddnwstr');
    @pdcMvAddWStr      := pdcGetProcAddr('mvaddwstr');
    @pdcMvAddWCh       := pdcGetProcAddr('mvadd_wch');
    @pdcMvAddWChNStr   := pdcGetProcAddr('mvadd_wchnstr');
    @pdcMvAddWChStr    := pdcGetProcAddr('mvadd_wchstr');
    @pdcMvGetNWStr     := pdcGetProcAddr('mvgetn_wstr');
    @pdcMvGetWCh       := pdcGetProcAddr('mvget_wch');
    @pdcMvGetWStr      := pdcGetProcAddr('mvget_wstr');
    @pdcMvHLineSet     := pdcGetProcAddr('mvhline_set');
    @pdcMvInNWStr      := pdcGetProcAddr('mvinnwstr');
    @pdcMvInsNWStr     := pdcGetProcAddr('mvins_nwstr');
    @pdcMvInsWCh       := pdcGetProcAddr('mvins_wch');
    @pdcMvInsWStr      := pdcGetProcAddr('mvins_wstr');
    @pdcMvInWStr       := pdcGetProcAddr('mvinwstr');
    @pdcMvInWCh        := pdcGetProcAddr('mvin_wch');
    @pdcMvInWChNStr    := pdcGetProcAddr('mvin_wchnstr');
    @pdcMvInWChStr     := pdcGetProcAddr('mvin_wchstr');
    @pdcMvVLineSet     := pdcGetProcAddr('mvvline_set');
    @pdcMvWAddNWStr    := pdcGetProcAddr('mvwaddnwstr');
    @pdcMvWAddWStr     := pdcGetProcAddr('mvwaddwstr');
    @pdcMvWAddWCh      := pdcGetProcAddr('mvwadd_wch');
    @pdcMvWAddWChNStr  := pdcGetProcAddr('mvwadd_wchnstr');
    @pdcMvWAddWChStr   := pdcGetProcAddr('mvwadd_wchstr');
    @pdcMvWGetNWStr    := pdcGetProcAddr('mvwgetn_wstr');
    @pdcMvWGetWCh      := pdcGetProcAddr('mvwget_wch');
    @pdcMvWGetWStr     := pdcGetProcAddr('mvwget_wstr');
    @pdcMvWHLineSet    := pdcGetProcAddr('mvwhline_set');
    @pdcMvWinNWStr     := pdcGetProcAddr('mvwinnwstr');
    @pdcMvWinsNWStr    := pdcGetProcAddr('mvwins_nwstr');
    @pdcMvWinsWCh      := pdcGetProcAddr('mvwins_wch');
    @pdcMvWinsWStr     := pdcGetProcAddr('mvwins_wstr');
    @pdcMvWinWCh       := pdcGetProcAddr('mvwin_wch');
    @pdcMvWinWChNStr   := pdcGetProcAddr('mvwin_wchnstr');
    @pdcMvWinWChStr    := pdcGetProcAddr('mvwin_wchstr');
    @pdcMvWinWStr      := pdcGetProcAddr('mvwinwstr');
    @pdcMvWVLineSet    := pdcGetProcAddr('mvwvline_set');
    @pdcPEchoWChar     := pdcGetProcAddr('pecho_wchar');
    @pdcSetCChar       := pdcGetProcAddr('setcchar');
    @pdcSlkWSet        := pdcGetProcAddr('slk_wset');
    @pdcUnGetWCh       := pdcGetProcAddr('unget_wch');
    @pdcVLineSet       := pdcGetProcAddr('vline_set');
    @pdcWAddNWStr      := pdcGetProcAddr('waddnwstr');
    @pdcWAddWStr       := pdcGetProcAddr('waddwstr');
    @pdcWAddWCh        := pdcGetProcAddr('wadd_wch');
    @pdcWAddWChNStr    := pdcGetProcAddr('wadd_wchnstr');
    @pdcWAddWChStr     := pdcGetProcAddr('wadd_wchstr');
    @pdcWBkgrnd        := pdcGetProcAddr('wbkgrnd');
    @pdcWBkgrndSet     := pdcGetProcAddr('wbkgrndset');
    @pdcWBorderSet     := pdcGetProcAddr('wborder_set');
    @pdcWEchoWChar     := pdcGetProcAddr('wecho_wchar');
    @pdcWGetBkgrnd     := pdcGetProcAddr('wgetbkgrnd');
    @pdcWGetNWStr      := pdcGetProcAddr('wgetn_wstr');
    @pdcWGetWCh        := pdcGetProcAddr('wget_wch');
    @pdcWGetWStr       := pdcGetProcAddr('wget_wstr');
    @pdcWHLineSet      := pdcGetProcAddr('whline_set');
    @pdcWInNWStr       := pdcGetProcAddr('winnwstr');
    @pdcWInsNWStr      := pdcGetProcAddr('wins_nwstr');
    @pdcWInsWCh        := pdcGetProcAddr('wins_wch');
    @pdcWInsWStr       := pdcGetProcAddr('wins_wstr');
    @pdcWInWStr        := pdcGetProcAddr('winwstr');
    @pdcWInWCh         := pdcGetProcAddr('win_wch');
    @pdcWInWChNStr     := pdcGetProcAddr('win_wchnstr');
    @pdcWInWChStr      := pdcGetProcAddr('win_wchstr');
    @pdcWUnCtrl        := pdcGetProcAddr('wunctrl');
    @pdcWVLineSet      := pdcGetProcAddr('wvline_set');
{$ENDIF PDC_WIDE}

    // Quasi-standard
    @pdcGetAttrs        := pdcGetProcAddr('getattrs');
    @pdcGetBegX         := pdcGetProcAddr('getbegx');
    @pdcGetBegY         := pdcGetProcAddr('getbegy');
    @pdcGetMaxX         := pdcGetProcAddr('getmaxx');
    @pdcGetMaxY         := pdcGetProcAddr('getmaxy');
    @pdcGetParX         := pdcGetProcAddr('getparx');
    @pdcGetParY         := pdcGetProcAddr('getpary');
    @pdcGetCurX         := pdcGetProcAddr('getcurx');
    @pdcGetCurY         := pdcGetProcAddr('getcury');
    @pdcTraceOff        := pdcGetProcAddr('traceoff');
    @pdcTraceOn         := pdcGetProcAddr('traceon');
    @pdcUnCtrl          := pdcGetProcAddr('unctrl');

    @pdcCrMode          := pdcGetProcAddr('crmode');
    @pdcNoCrMode        := pdcGetProcAddr('nocrmode');
    @pdcDrainO          := pdcGetProcAddr('draino');
    @pdcResetTerm       := pdcGetProcAddr('resetterm');
    @pdcFixTerm         := pdcGetProcAddr('fixterm');
    @pdcSaveTerm        := pdcGetProcAddr('saveterm');
    @pdcSetSYX          := pdcGetProcAddr('setsyx');

    @pdcMouseSet        := pdcGetProcAddr('mouse_set');
    @pdcMouseOn         := pdcGetProcAddr('mouse_on');
    @pdcMouseOff        := pdcGetProcAddr('mouse_off');
    @pdcRequestMousePos := pdcGetProcAddr('request_mouse_pos');
    @pdcMapButton       := pdcGetProcAddr('map_button');
    @pdcWMousePosition  := pdcGetProcAddr('wmouse_position');
    @pdcGetMouse        := pdcGetProcAddr('getmouse');
    @pdcGetBMap         := pdcGetProcAddr('getbmap');

    // ncurses
    @pdcAssumeDefaultColors := pdcGetProcAddr('assume_default_colors');
    @pdcCursesVersion       := pdcGetProcAddr('curses_version');
    @pdcHasKey              := pdcGetProcAddr('has_key');
    @pdcUseDefaultColors    := pdcGetProcAddr('use_default_colors');
    @pdcWResize             := pdcGetProcAddr('wresize');

    @pdcMouseInterval       := pdcGetProcAddr('mouseinterval');
    @pdcMouseMask           := pdcGetProcAddr('mousemask');
    @pdcMouseTrafo          := pdcGetProcAddr('mouse_trafo');
    @pdcNCGetMouse          := pdcGetProcAddr('nc_getmouse');
    @pdcUnGetMouse          := pdcGetProcAddr('ungetmouse');
    @pdcWEnclose            := pdcGetProcAddr('wenclose');
    @pdcWMouseTrafo         := pdcGetProcAddr('wmouse_trafo');

    // PDCurses
    @pdcAddRawCh           := pdcGetProcAddr('addrawch');
    @pdcInsRawCh           := pdcGetProcAddr('insrawch');
    @pdcIsTermResized      := pdcGetProcAddr('is_termresized');
    @pdcMvAddRawCh         := pdcGetProcAddr('mvaddrawch');
    @pdcMvDeleteLn         := pdcGetProcAddr('mvdeleteln');
    @pdcMvInsertLn         := pdcGetProcAddr('mvinsertln');
    @pdcMvInsRawCh         := pdcGetProcAddr('mvinsrawch');
    @pdcMvWAddRawCh        := pdcGetProcAddr('mvwaddrawch');
    @pdcMvWDeleteLn        := pdcGetProcAddr('mvwdeleteln');
    @pdcMvWInsertLn        := pdcGetProcAddr('mvwinsertln');
    @pdcMvWInsRawCh        := pdcGetProcAddr('mvwinsrawch');
    @pdcRawOutput          := pdcGetProcAddr('raw_output');
    @pdcResizeTerm         := pdcGetProcAddr('resize_term');
    @pdcResizeWindow       := pdcGetProcAddr('resize_window');
    @pdcWAddRawCh          := pdcGetProcAddr('waddrawch');
    @pdcWInsRawCh          := pdcGetProcAddr('winsrawch');
    @pdcWordChar           := pdcGetProcAddr('wordchar');
{$IFDEF PDC_WIDE}
    @pdcSlkWLabel          := pdcGetProcAddr('slk_wlabel');
{$ENDIF PDC_WIDE}
    @pdcDebug              := pdcGetProcAddr('PDC_debug');
    @pdcUnGetCh            := pdcGetProcAddr('PDC_ungetch');
    @pdcSetBlink           := pdcGetProcAddr('PDC_set_blink');
    @pdcSetLineColor       := pdcGetProcAddr('PDC_set_line_color');
    @pdcSetTitle           := pdcGetProcAddr('PDC_set_title');
    @pdcClearClipboard     := pdcGetProcAddr('PDC_clearclipboard');
    @pdcFreeClipboard      := pdcGetProcAddr('PDC_freeclipboard');
    @pdcGetClipboard       := pdcGetProcAddr('PDC_getclipboard');
    @pdcSetClipboard       := pdcGetProcAddr('PDC_setclipboard');
    @pdcGetInputFd         := pdcGetProcAddr('PDC_get_input_fd');
    @pdcGetKeyModifiers    := pdcGetProcAddr('PDC_get_key_modifiers');
    @pdcReturnKeyModifiers := pdcGetProcAddr('PDC_return_key_modifiers');
    @pdcSaveKeyModifiers   := pdcGetProcAddr('PDC_save_key_modifiers');
    @pdcSetResizeLimits    := pdcGetProcAddr('PDC_set_resize_limits');
    @pdcSetFunctionKey     := pdcGetProcAddr('PDC_set_function_key');
    @pdcXInitScr           := pdcGetProcAddr('Xinitscr');
  end else
    raise EDLLLoadError.Create('Unable to load the library.');
end;

procedure pdcFreeLib;
begin
{$IFDEF MACOS}
  if PDCPanelLibHandle <> nil then
    dlclose(PDCPanelLibHandle);
{$ENDIF MACOS}

  if PDCLibHandle <> nil then
{$IFDEF MSWINDOWS}
    FreeLibrary(HMODULE(PDCLibHandle));
{$ELSE MSWINDOWS}
  {$IFDEF POSIX}
    dlclose(PDCLibHandle);
  {$ENDIF POSIX}
{$ENDIF MSWINDOWS}
end;

function pdcPortToStr(aPort: TPort): string;
begin
  case aPort of
    PDC_PORT_X11:    begin Result := 'X11';    Exit; end;
    PDC_PORT_WIN32:  begin Result := 'WIN32';  Exit; end;
    PDC_PORT_WIN32A: begin Result := 'WIN32A'; Exit; end;
    PDC_PORT_DOS:    begin Result := 'DOS';    Exit; end;
    PDC_PORT_OS2:    begin Result := 'OS2';    Exit; end;
    PDC_PORT_SDL1:   begin Result := 'SDL1';   Exit; end;
    PDC_PORT_SDL2:   begin Result := 'SDL2';   Exit; end;
  end;
end;

end.


