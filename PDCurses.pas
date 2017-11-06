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
  LOBPBCPANEL = 'panel.lib';
  {$ELSE MACOS}
    {$IFDEF LINUX}
  LIBPDCURSES = 'libXCurses';
    {$ENDIF LINUX}
  {$ENDIF MACOS}
{$ENDIF MSWINDOWS}

var
  PDCLibHandle: Pointer;

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
const
  PDC_VER_MAJOR  = 4;
  PDC_VER_MINOR  = 0;
  PDC_VER_CHANGE = 2;
  PDC_VER_YEAR   = 2017;
  PDC_VER_MONTH  = 07;
  PDC_VER_DAY    = 26;
  PDC_BUILD      = (PDC_VER_MAJOR * 1000) + (PDC_VER_MINOR *100) + PDC_VER_CHANGE;

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
  TAcsMap  = array[Char] of TChType;
  PAcsMap  = ^TAcsMap;
  PPAcsMap = ^PAcsMap;
  TPutc    = function(aArg: LongInt): LongInt; cdecl;
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

  A_ITALIC  = A_INVIS;
  A_PROTECT = A_UNDERLINE OR A_LEFTLINE OR A_RIGHTLINE;
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

  A_STANDOUT = A_REVERSE OR A_BOLD; // X/Open
  CHR_MSK    = A_CHARTEXT;          // Obsolete
  ATR_MSK    = A_ATTRIBUTES;        // Obsolete
  ATR_NRM    = A_NORMAL;            // Obsolete

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
function pdcAcsPick(aWChar, aNChar: AnsiChar): TChType;

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
  pdcInitColor:      function(aId, aRed, aGreen,
                              aBlue: SmallInt): LongInt; cdecl;
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
                              acount: LongInt): LongInt; cdecl;
  pdcMvAddChStr:     function(aY, aX: LongInt;
                              const aChar: PChType): LongInt; cdecl;
  pdcMvAddNStr:      function(aY, aX: LongInt; const aText: PAnsiChar;
                              acount: LongInt): LongInt; cdecl;
  pdcMvAddStr:       function(aY, aX: LongInt;
                              const aText: PAnsiChar): LongInt; cdecl;
{
PDCEX int     mvchgat(int, int, int, attr_t, short, const void *);
PDCEX int     mvcur(int, int, int, int);
PDCEX int     mvdelch(int, int);
PDCEX int     mvderwin(WINDOW *, int, int);
PDCEX int     mvgetch(int, int);
PDCEX int     mvgetnstr(int, int, char *, int);
PDCEX int     mvgetstr(int, int, char *);
PDCEX int     mvhline(int, int, chtype, int);
PDCEX chtype  mvinch(int, int);
PDCEX int     mvinchnstr(int, int, chtype *, int);
PDCEX int     mvinchstr(int, int, chtype *);
PDCEX int     mvinnstr(int, int, char *, int);
PDCEX int     mvinsch(int, int, chtype);
PDCEX int     mvinsnstr(int, int, const char *, int);
PDCEX int     mvinsstr(int, int, const char *);
PDCEX int     mvinstr(int, int, char *);
PDCEX int     mvprintw(int, int, const char *, ...);
PDCEX int     mvscanw(int, int, const char *, ...);
PDCEX int     mvvline(int, int, chtype, int);
PDCEX int     mvwaddchnstr(WINDOW *, int, int, const chtype *, int);
PDCEX int     mvwaddchstr(WINDOW *, int, int, const chtype *);
PDCEX int     mvwaddch(WINDOW *, int, int, const chtype);
PDCEX int     mvwaddnstr(WINDOW *, int, int, const char *, int);
PDCEX int     mvwaddstr(WINDOW *, int, int, const char *);
PDCEX int     mvwchgat(WINDOW *, int, int, int, attr_t, short, const void *);
PDCEX int     mvwdelch(WINDOW *, int, int);
PDCEX int     mvwgetch(WINDOW *, int, int);
PDCEX int     mvwgetnstr(WINDOW *, int, int, char *, int);
PDCEX int     mvwgetstr(WINDOW *, int, int, char *);
PDCEX int     mvwhline(WINDOW *, int, int, chtype, int);
PDCEX int     mvwinchnstr(WINDOW *, int, int, chtype *, int);
PDCEX int     mvwinchstr(WINDOW *, int, int, chtype *);
PDCEX chtype  mvwinch(WINDOW *, int, int);
PDCEX int     mvwinnstr(WINDOW *, int, int, char *, int);
PDCEX int     mvwinsch(WINDOW *, int, int, chtype);
PDCEX int     mvwinsnstr(WINDOW *, int, int, const char *, int);
PDCEX int     mvwinsstr(WINDOW *, int, int, const char *);
PDCEX int     mvwinstr(WINDOW *, int, int, char *);
PDCEX int     mvwin(WINDOW *, int, int);
PDCEX int     mvwprintw(WINDOW *, int, int, const char *, ...);
PDCEX int     mvwscanw(WINDOW *, int, int, const char *, ...);
PDCEX int     mvwvline(WINDOW *, int, int, chtype, int);
}
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
{
PDCEX int     nonl(void);
PDCEX void    noqiflush(void);
PDCEX int     noraw(void);
PDCEX int     notimeout(WINDOW *, bool);
PDCEX int     overlay(const WINDOW *, WINDOW *);
PDCEX int     overwrite(const WINDOW *, WINDOW *);
PDCEX int     pair_content(short, short *, short *);
PDCEX int     pechochar(WINDOW *, chtype);
PDCEX int     pnoutrefresh(WINDOW *, int, int, int, int, int, int);
PDCEX int     prefresh(WINDOW *, int, int, int, int, int, int);
PDCEX int     printw(const char *, ...);
PDCEX int     putwin(WINDOW *, FILE *);
PDCEX void    qiflush(void);
PDCEX int     raw(void);
PDCEX int     redrawwin(WINDOW *);
}
  pdcRefresh:        function: LongInt; cdecl;
{
PDCEX int     reset_prog_mode(void);
PDCEX int     reset_shell_mode(void);
PDCEX int     resetty(void);
PDCEX int     ripoffline(int, int (*)(WINDOW *, int));
PDCEX int     savetty(void);
PDCEX int     scanw(const char *, ...);
PDCEX int     scr_dump(const char *);
PDCEX int     scr_init(const char *);
PDCEX int     scr_restore(const char *);
PDCEX int     scr_set(const char *);
PDCEX int     scrl(int);
PDCEX int     scroll(WINDOW *);
PDCEX int     scrollok(WINDOW *, bool);
PDCEX SCREEN *set_term(SCREEN *);
PDCEX int     setscrreg(int, int);
PDCEX int     slk_attroff(const chtype);
PDCEX int     slk_attr_off(const attr_t, void *);
PDCEX int     slk_attron(const chtype);
PDCEX int     slk_attr_on(const attr_t, void *);
PDCEX int     slk_attrset(const chtype);
PDCEX int     slk_attr_set(const attr_t, short, void *);
PDCEX int     slk_clear(void);
PDCEX int     slk_color(short);
PDCEX int     slk_init(int);
PDCEX char   *slk_label(int);
PDCEX int     slk_noutrefresh(void);
PDCEX int     slk_refresh(void);
PDCEX int     slk_restore(void);
PDCEX int     slk_set(int, const char *, int);
PDCEX int     slk_touch(void);
PDCEX int     standend(void);
PDCEX int     standout(void);
}
  pdcStartColor:     function: LongInt; cdecl;
{
PDCEX WINDOW *subpad(WINDOW *, int, int, int, int);
PDCEX WINDOW *subwin(WINDOW *, int, int, int, int);
PDCEX int     syncok(WINDOW *, bool);
PDCEX chtype  termattrs(void);
PDCEX attr_t  term_attrs(void);
PDCEX char   *termname(void);
PDCEX void    timeout(int);
PDCEX int     touchline(WINDOW *, int, int);
PDCEX int     touchwin(WINDOW *);
PDCEX int     typeahead(int);
PDCEX int     untouchwin(WINDOW *);
PDCEX void    use_env(bool);
PDCEX int     vidattr(chtype);
PDCEX int     vid_attr(attr_t, short, void *);
PDCEX int     vidputs(chtype, int (*)(int));
PDCEX int     vid_puts(attr_t, short, void *, int (*)(int));
PDCEX int     vline(chtype, int);
}

{$IFDEF ASSEMBLER}
{
  Functions used to overcome the inability of using C(++)'s va_list type

  NOTE:
  Don not use any method prefixed by 'dnu_', these require to be
  called through TVarArgCaller, which is already done for you in
  the methods prefixed by 'pdc_'.
}
function dnuVW_PrintW(aWindow: PWindow; const aFormat: PAnsiChar;
                      va_list: Pointer): LongInt; cdecl; library;
  external LIBPDCURSES name 'vw_printw';
function dnuVWPrintW(aWindow: PWindow; const aFormat: PAnsiChar;
                     va_list: Pointer): LongInt; cdecl; library;
  external LIBPDCURSES name 'vwprintw';
function dnuVW_ScanW(aWindow: PWindow; const aFormat: PAnsiChar;
                     va_list: Pointer): LongInt; cdecl; library;
  external LIBPDCURSES name 'vw_scanw';
function dnuVWScanW(aWindow: PWindow; const aFormat: PAnsiChar;
                    va_list: Pointer): LongInt; cdecl; library;
  external LIBPDCURSES name 'vwscanw';

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
{
PDCEX int     waddchnstr(WINDOW *, const chtype *, int);
PDCEX int     waddchstr(WINDOW *, const chtype *);
PDCEX int     waddch(WINDOW *, const chtype);
PDCEX int     waddnstr(WINDOW *, const char *, int);
PDCEX int     waddstr(WINDOW *, const char *);
PDCEX int     wattroff(WINDOW *, chtype);
PDCEX int     wattron(WINDOW *, chtype);
PDCEX int     wattrset(WINDOW *, chtype);
PDCEX int     wattr_get(WINDOW *, attr_t *, short *, void *);
PDCEX int     wattr_off(WINDOW *, attr_t, void *);
PDCEX int     wattr_on(WINDOW *, attr_t, void *);
PDCEX int     wattr_set(WINDOW *, attr_t, short, void *);
PDCEX void    wbkgdset(WINDOW *, chtype);
PDCEX int     wbkgd(WINDOW *, chtype);
PDCEX int     wborder(WINDOW *, chtype, chtype, chtype, chtype,
                       chtype, chtype, chtype, chtype);
PDCEX int     wchgat(WINDOW *, int, attr_t, short, const void *);
PDCEX int     wclear(WINDOW *);
PDCEX int     wclrtobot(WINDOW *);
PDCEX int     wclrtoeol(WINDOW *);
PDCEX int     wcolor_set(WINDOW *, short, void *);
PDCEX void    wcursyncup(WINDOW *);
PDCEX int     wdelch(WINDOW *);
PDCEX int     wdeleteln(WINDOW *);
PDCEX int     wechochar(WINDOW *, const chtype);
PDCEX int     werase(WINDOW *);
}
  pdcWGetCh: function(aWindow: PWindow): LongInt; cdecl;
{
PDCEX int     wgetnstr(WINDOW *, char *, int);
PDCEX int     wgetstr(WINDOW *, char *);
PDCEX int     whline(WINDOW *, chtype, int);
PDCEX int     winchnstr(WINDOW *, chtype *, int);
PDCEX int     winchstr(WINDOW *, chtype *);
PDCEX chtype  winch(WINDOW *);
PDCEX int     winnstr(WINDOW *, char *, int);
PDCEX int     winsch(WINDOW *, chtype);
PDCEX int     winsdelln(WINDOW *, int);
PDCEX int     winsertln(WINDOW *);
PDCEX int     winsnstr(WINDOW *, const char *, int);
PDCEX int     winsstr(WINDOW *, const char *);
PDCEX int     winstr(WINDOW *, char *);
PDCEX int     wmove(WINDOW *, int, int);
PDCEX int     wnoutrefresh(WINDOW *);
PDCEX int     wprintw(WINDOW *, const char *, ...);
PDCEX int     wredrawln(WINDOW *, int, int);
PDCEX int     wrefresh(WINDOW *);
PDCEX int     wscanw(WINDOW *, const char *, ...);
PDCEX int     wscrl(WINDOW *, int);
PDCEX int     wsetscrreg(WINDOW *, int, int);
PDCEX int     wstandend(WINDOW *);
PDCEX int     wstandout(WINDOW *);
PDCEX void    wsyncdown(WINDOW *);
PDCEX void    wsyncup(WINDOW *);
PDCEX void    wtimeout(WINDOW *, int);
PDCEX int     wtouchln(WINDOW *, int, int, int);
PDCEX int     wvline(WINDOW *, chtype, int);
}

// Wide-character functions
{$IFDEF PDC_WIDE}
{
PDCEX int     addnwstr(const wchar_t *, int);
PDCEX int     addwstr(const wchar_t *);
PDCEX int     add_wch(const cchar_t *);
PDCEX int     add_wchnstr(const cchar_t *, int);
PDCEX int     add_wchstr(const cchar_t *);
PDCEX int     border_set(const cchar_t *, const cchar_t *, const cchar_t *,
                   const cchar_t *, const cchar_t *, const cchar_t *,
                   const cchar_t *, const cchar_t *);
PDCEX int     box_set(WINDOW *, const cchar_t *, const cchar_t *);
PDCEX int     echo_wchar(const cchar_t *);
PDCEX int     erasewchar(wchar_t *);
PDCEX int     getbkgrnd(cchar_t *);
PDCEX int     getcchar(const cchar_t *, wchar_t *, attr_t *, short *, void *);
PDCEX int     getn_wstr(wint_t *, int);
PDCEX int     get_wch(wint_t *);
PDCEX int     get_wstr(wint_t *);
PDCEX int     hline_set(const cchar_t *, int);
PDCEX int     innwstr(wchar_t *, int);
PDCEX int     ins_nwstr(const wchar_t *, int);
PDCEX int     ins_wch(const cchar_t *);
PDCEX int     ins_wstr(const wchar_t *);
PDCEX int     inwstr(wchar_t *);
PDCEX int     in_wch(cchar_t *);
PDCEX int     in_wchnstr(cchar_t *, int);
PDCEX int     in_wchstr(cchar_t *);
PDCEX char   *key_name(wchar_t);
PDCEX int     killwchar(wchar_t *);
PDCEX int     mvaddnwstr(int, int, const wchar_t *, int);
PDCEX int     mvaddwstr(int, int, const wchar_t *);
PDCEX int     mvadd_wch(int, int, const cchar_t *);
PDCEX int     mvadd_wchnstr(int, int, const cchar_t *, int);
PDCEX int     mvadd_wchstr(int, int, const cchar_t *);
PDCEX int     mvgetn_wstr(int, int, wint_t *, int);
PDCEX int     mvget_wch(int, int, wint_t *);
PDCEX int     mvget_wstr(int, int, wint_t *);
PDCEX int     mvhline_set(int, int, const cchar_t *, int);
PDCEX int     mvinnwstr(int, int, wchar_t *, int);
PDCEX int     mvins_nwstr(int, int, const wchar_t *, int);
PDCEX int     mvins_wch(int, int, const cchar_t *);
PDCEX int     mvins_wstr(int, int, const wchar_t *);
PDCEX int     mvinwstr(int, int, wchar_t *);
PDCEX int     mvin_wch(int, int, cchar_t *);
PDCEX int     mvin_wchnstr(int, int, cchar_t *, int);
PDCEX int     mvin_wchstr(int, int, cchar_t *);
PDCEX int     mvvline_set(int, int, const cchar_t *, int);
PDCEX int     mvwaddnwstr(WINDOW *, int, int, const wchar_t *, int);
PDCEX int     mvwaddwstr(WINDOW *, int, int, const wchar_t *);
PDCEX int     mvwadd_wch(WINDOW *, int, int, const cchar_t *);
PDCEX int     mvwadd_wchnstr(WINDOW *, int, int, const cchar_t *, int);
PDCEX int     mvwadd_wchstr(WINDOW *, int, int, const cchar_t *);
PDCEX int     mvwgetn_wstr(WINDOW *, int, int, wint_t *, int);
PDCEX int     mvwget_wch(WINDOW *, int, int, wint_t *);
PDCEX int     mvwget_wstr(WINDOW *, int, int, wint_t *);
PDCEX int     mvwhline_set(WINDOW *, int, int, const cchar_t *, int);
PDCEX int     mvwinnwstr(WINDOW *, int, int, wchar_t *, int);
PDCEX int     mvwins_nwstr(WINDOW *, int, int, const wchar_t *, int);
PDCEX int     mvwins_wch(WINDOW *, int, int, const cchar_t *);
PDCEX int     mvwins_wstr(WINDOW *, int, int, const wchar_t *);
PDCEX int     mvwin_wch(WINDOW *, int, int, cchar_t *);
PDCEX int     mvwin_wchnstr(WINDOW *, int, int, cchar_t *, int);
PDCEX int     mvwin_wchstr(WINDOW *, int, int, cchar_t *);
PDCEX int     mvwinwstr(WINDOW *, int, int, wchar_t *);
PDCEX int     mvwvline_set(WINDOW *, int, int, const cchar_t *, int);
PDCEX int     pecho_wchar(WINDOW *, const cchar_t*);
PDCEX int     setcchar(cchar_t*, const wchar_t*, const attr_t, short, const void*);
PDCEX int     slk_wset(int, const wchar_t *, int);
PDCEX int     unget_wch(const wchar_t);
PDCEX int     vline_set(const cchar_t *, int);
PDCEX int     waddnwstr(WINDOW *, const wchar_t *, int);
PDCEX int     waddwstr(WINDOW *, const wchar_t *);
PDCEX int     wadd_wch(WINDOW *, const cchar_t *);
PDCEX int     wadd_wchnstr(WINDOW *, const cchar_t *, int);
PDCEX int     wadd_wchstr(WINDOW *, const cchar_t *);
PDCEX int     wbkgrnd(WINDOW *, const cchar_t *);
PDCEX void    wbkgrndset(WINDOW *, const cchar_t *);
PDCEX int     wborder_set(WINDOW *, const cchar_t *, const cchar_t *,
                     const cchar_t *, const cchar_t *, const cchar_t *,
                     const cchar_t *, const cchar_t *, const cchar_t *);
PDCEX int     wecho_wchar(WINDOW *, const cchar_t *);
PDCEX int     wgetbkgrnd(WINDOW *, cchar_t *);
PDCEX int     wgetn_wstr(WINDOW *, wint_t *, int);
PDCEX int     wget_wch(WINDOW *, wint_t *);
PDCEX int     wget_wstr(WINDOW *, wint_t *);
PDCEX int     whline_set(WINDOW *, const cchar_t *, int);
PDCEX int     winnwstr(WINDOW *, wchar_t *, int);
PDCEX int     wins_nwstr(WINDOW *, const wchar_t *, int);
PDCEX int     wins_wch(WINDOW *, const cchar_t *);
PDCEX int     wins_wstr(WINDOW *, const wchar_t *);
PDCEX int     winwstr(WINDOW *, wchar_t *);
PDCEX int     win_wch(WINDOW *, cchar_t *);
PDCEX int     win_wchnstr(WINDOW *, cchar_t *, int);
PDCEX int     win_wchstr(WINDOW *, cchar_t *);
PDCEX wchar_t *wunctrl(cchar_t *);
PDCEX int     wvline_set(WINDOW *, const cchar_t *, int);
}
{$ENDIF PDC_WIDE}

// Quasi-standard
var
  pdcGetAttrs: function(aWindow: PWindow): TChType; cdecl;
  pdcGetBegX:  function(aWindow: PWindow): LongInt; cdecl;
  pdcGetBegY:  function(aWindow: PWindow): LongInt; cdecl;
  pdcGetMaxX:  function(aWindow: PWindow): LongInt; cdecl;
  pdcGetMaxY:  function(aWindow: PWindow): LongInt; cdecl;
  pdcGetParX:  function(aWindow: PWindow): LongInt; cdecl;
  pdcGetParY:  function(aWindow: PWindow): LongInt; cdecl;
  pdcGetCurX:  function(aWindow: PWindow): LongInt; cdecl;
  pdcGetCurY:  function(aWindow: PWindow): LongInt; cdecl;
  pdcTraceOff: procedure; cdecl;
  pdcTraceOn:  procedure; cdecl;
  pdcUnCtrl:   function(aChar: TChType): PAnsiChar; cdecl;

{
PDCEX int     crmode(void);
PDCEX int     nocrmode(void);
PDCEX int     draino(int);
PDCEX int     resetterm(void);
PDCEX int     fixterm(void);
PDCEX int     saveterm(void);
PDCEX int     setsyx(int, int);

PDCEX int     mouse_set(unsigned long);
PDCEX int     mouse_on(unsigned long);
PDCEX int     mouse_off(unsigned long);
PDCEX int     request_mouse_pos(void);
PDCEX int     map_button(unsigned long);
PDCEX void    wmouse_position(WINDOW *, int *, int *);
PDCEX unsigned long getmouse(void);
PDCEX unsigned long getbmap(void);
}

// ncurses
var
{
PDCEX int     assume_default_colors(int, int);
PDCEX const char *curses_version(void);
PDCEX bool    has_key(int);
PDCEX int     use_default_colors(void);
PDCEX int     wresize(WINDOW *, int, int);

PDCEX int     mouseinterval(int);
PDCEX mmask_t mousemask(mmask_t, mmask_t *);
PDCEX bool    mouse_trafo(int *, int *, bool);
}
  pdcNCGetMouse: function(aEvent: PMEvent): LongInt; cdecl;
{
PDCEX int     ungetmouse(MEVENT *);
PDCEX bool    wenclose(const WINDOW *, int, int);
PDCEX bool    wmouse_trafo(const WINDOW *, int *, int *, bool);
}

// PDCurses
{
PDCEX int     addrawch(chtype);
PDCEX int     insrawch(chtype);
PDCEX bool    is_termresized(void);
PDCEX int     mvaddrawch(int, int, chtype);
PDCEX int     mvdeleteln(int, int);
PDCEX int     mvinsertln(int, int);
PDCEX int     mvinsrawch(int, int, chtype);
PDCEX int     mvwaddrawch(WINDOW *, int, int, chtype);
PDCEX int     mvwdeleteln(WINDOW *, int, int);
PDCEX int     mvwinsertln(WINDOW *, int, int);
PDCEX int     mvwinsrawch(WINDOW *, int, int, chtype);
PDCEX int     raw_output(bool);
PDCEX int     resize_term(int, int);
PDCEX WINDOW *resize_window(WINDOW *, int, int);
PDCEX int     waddrawch(WINDOW *, chtype);
PDCEX int     winsrawch(WINDOW *, chtype);
PDCEX char    wordchar(void);

#ifdef PDC_WIDE
PDCEX wchar_t *slk_wlabel(int);
#endif

PDCEX void    PDC_debug(const char *, ...);
PDCEX int     PDC_ungetch(int);
PDCEX int     PDC_set_blink(bool);
PDCEX int     PDC_set_line_color(short);
PDCEX void    PDC_set_title(const char *);

PDCEX int     PDC_clearclipboard(void);
PDCEX int     PDC_freeclipboard(char *);
PDCEX int     PDC_getclipboard(char **, long *);
PDCEX int     PDC_setclipboard(const char *, long);

PDCEX unsigned long PDC_get_input_fd(void);
PDCEX unsigned long PDC_get_key_modifiers(void);
PDCEX int     PDC_return_key_modifiers(bool);
PDCEX int     PDC_save_key_modifiers(bool);
PDCEX void    PDC_set_resize_limits( const int new_min_lines,
                               const int new_max_lines,
                               const int new_min_cols,
                               const int new_max_cols);
}

const
  FUNCTION_KEY_SHUT_DOWN    = 0;
  FUNCTION_KEY_PASTE        = 1;
  FUNCTION_KEY_ENLARGE_FONT = 2;
  FUNCTION_KEY_SHRINK_FONT  = 3;
  FUNCTION_KEY_CHOOSE_FONT  = 4;
  FUNCTION_KEY_ABORT        = 5;
  PDC_MAX_FUNCTION_KEYS     = 6;

var
  pdcSetFunctionKey: function(const aFunc: LongWord;
                              const aNewKey: LongInt): LongInt; cdecl;
  pdcXInitScr:       function(aArgA: LongInt; aArgV: PPAnsiChar): PWindow; cdecl;

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
function pdcGetProcAddr(aProcName: PAnsiChar): Pointer;
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
function pdcGetProcAddr(aProcName: PChar): Pointer;
{$ENDIF POSIX}
procedure pdcInitLib;
procedure pdcFreeLib;
function pdcPortToStr(aPort: TPort): AnsiString;

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

{$IFDEF ASSEMBLER}
{
  Functions used to overcome the inability of using C(++)'s va_list type
}
{$WARN SYMBOL_LIBRARY OFF}
function pdcVW_PrintW(aWindow: PWindow; const aFormat: PAnsiChar;
                      const aArgs: array of const): LongInt;
var
   retVal: PLongInt;
begin
  retVal := CallVA_ListFunction(@dnuVW_PrintW, aWindow, aFormat, aArgs);
  Result := retVal^;
end;

function pdcVWPrintW(aWindow: PWindow; const aFormat: PAnsiChar;
                     const aArgs: array of const): LongInt;
var
   retVal: PLongInt;
begin
  retVal := CallVA_ListFunction(@dnuVWPrintW, aWindow, aFormat, aArgs);
  Result := retVal^;
end;

function pdcVW_ScanW(aWindow: PWindow; const aFormat: PAnsiChar;
                     const aArgs: array of const): LongInt;
var
   retVal: PLongInt;
begin
  retVal := CallVA_ListFunction(@dnuVW_ScanW, aWindow, aFormat, aArgs);
  Result := retVal^;
end;

function pdcVWScanW(aWindow: PWindow; const aFormat: PAnsiChar;
                    const aArgs: array of const): LongInt;
var
   retVal: PLongInt;
begin
  retVal := CallVA_ListFunction(@dnuVWScanW, aWindow, aFormat, aArgs);
  Result := retVal^;
end;
{$WARN SYMBOL_LIBRARY DEFAULT}
{$ENDIF ASSEMBLER}

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
  Result.X := pdcGetBegY(aWindow);
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
function pdcGetProcAddr(aProcName: PAnsiChar): Pointer;
begin
  Result := GetProcAddress(HMODULE(PDCLibHandle), aProcName);

{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
function pdcGetProcAddr(aProcName: PChar): Pointer;
var
  Error: MarshaledAString;
  M:     TMarshaller;
begin
  dlerror;

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
    pdcAddCh          := pdcGetProcAddr('addch');
    pdcAddChNStr      := pdcGetProcAddr('addchnstr');
    pdcAddChStr       := pdcGetProcAddr('addchstr');
    pdcAddNStr        := pdcGetProcAddr('addnstr');
    pdcAddStr         := pdcGetProcAddr('addstr');
    pdcAttrOff        := pdcGetProcAddr('attroff');
    pdcAttrOn         := pdcGetProcAddr('attron');
    pdcAttrSet        := pdcGetProcAddr('attrset');
    pdcAttrOptsGet    := pdcGetProcAddr('attr_get');
    pdcAttrOptsOff    := pdcGetProcAddr('attr_off');
    pdcAttrOptsOn     := pdcGetProcAddr('attr_on');
    pdcAttrOptsSet    := pdcGetProcAddr('attr_set');
    pdcBaudRate       := pdcGetProcAddr('baudrate');
    pdcBeep           := pdcGetProcAddr('beep');
    pdcBkgd           := pdcGetProcAddr('bkgd');
    pdcBkgdSet        := pdcGetProcAddr('bkgdset');
    pdcBorder         := pdcGetProcAddr('border');
    pdcBox            := pdcGetProcAddr('box');
    pdcCanChangeColor := pdcGetProcAddr('can_change_color');
    pdcCBreak         := pdcGetProcAddr('cbreak');
    pdcChgAt          := pdcGetProcAddr('chgat');
    pdcClearOk        := pdcGetProcAddr('clearok');
    pdcClear          := pdcGetProcAddr('clear');
    pdcClrToBot       := pdcGetProcAddr('clrtobot');
    pdcClrToEOL       := pdcGetProcAddr('clrtoeol');
    pdcColorContent   := pdcGetProcAddr('color_content');
    pdcColorSet       := pdcGetProcAddr('color_set');
    pdcCopyWin        := pdcGetProcAddr('copywin');
    pdcCursSet        := pdcGetProcAddr('curs_set');
    pdcDefProgMode    := pdcGetProcAddr('def_prog_mode');
    pdcDefShellMode   := pdcGetProcAddr('def_shell_mode');
    pdcDelayOutput    := pdcGetProcAddr('delay_output');
    pdcDelCh          := pdcGetProcAddr('delch');
    pdcDeleteLn       := pdcGetProcAddr('deleteln');
    pdcDelScreen      := pdcGetProcAddr('delscreen');
    pdcDelWin         := pdcGetProcAddr('delwin');
    pdcDerWin         := pdcGetProcAddr('derwin');
    pdcDoUpdate       := pdcGetProcAddr('doupdate');
    pdcDupWin         := pdcGetProcAddr('dupwin');
    pdcEchoChar       := pdcGetProcAddr('echochar');
    pdcEcho           := pdcGetProcAddr('echo');
    pdcEndWin         := pdcGetProcAddr('endwin');
    pdcEraseChar      := pdcGetProcAddr('erasechar');
    pdcErase          := pdcGetProcAddr('erase');
    pdcFilter         := pdcGetProcAddr('filter');
    pdcFlash          := pdcGetProcAddr('flash');
    pdcFlushInp       := pdcGetProcAddr('flushinp');
    pdcGetBkgd        := pdcGetProcAddr('getbkgd');
    pdcGetNStr        := pdcGetProcAddr('getnstr');
    pdcGetStr         := pdcGetProcAddr('getstr');
    pdcGetWin         := pdcGetProcAddr('getwin');
    pdcHalfDelay      := pdcGetProcAddr('halfdelay');
    pdcHasColors      := pdcGetProcAddr('has_colors');
    pdcHasIC          := pdcGetProcAddr('has_ic');
    pdcHasIL          := pdcGetProcAddr('has_il');
    pdcHLine          := pdcGetProcAddr('hline');
    pdcIDCOk          := pdcGetProcAddr('idcok');
    pdcIDLOk          := pdcGetProcAddr('idlok');
    pdcImmedOk        := pdcGetProcAddr('immedok');
    pdcInChNStr       := pdcGetProcAddr('inchnstr');
    pdcInChStr        := pdcGetProcAddr('inchstr');
    pdcInCh           := pdcGetProcAddr('inch');
    pdcInitColor      := pdcGetProcAddr('init_color');
    pdcInitPair       := pdcGetProcAddr('init_pair');
    pdcInitScr        := pdcGetProcAddr('initscr');
    pdcInNStr         := pdcGetProcAddr('innstr');
    pdcInsCh          := pdcGetProcAddr('insch');
    pdcInsDelLn       := pdcGetProcAddr('insdelln');
    pdcInsertLn       := pdcGetProcAddr('insertln');
    pdcInsNStr        := pdcGetProcAddr('insnstr');
    pdcInsStr         := pdcGetProcAddr('insstr');
    pdcInStr          := pdcGetProcAddr('instr');
    pdcIntrFlush      := pdcGetProcAddr('intrflush');
    pdcIsEndWin       := pdcGetProcAddr('isendwin');
    pdcIsLineTouched  := pdcGetProcAddr('is_linetouched');
    pdcIsWinTouched   := pdcGetProcAddr('is_wintouched');
    pdcKeyName        := pdcGetProcAddr('keyname');
    pdcKeyPad         := pdcGetProcAddr('keypad');
    pdcKillChar       := pdcGetProcAddr('killchar');
    pdcLeaveOk        := pdcGetProcAddr('leaveok');
    pdcLongName       := pdcGetProcAddr('longname');
    pdcMeta           := pdcGetProcAddr('meta');
    pdcMove           := pdcGetProcAddr('move');
    pdcMvAddCh        := pdcGetProcAddr('mvaddch');
    pdcMvAddChNStr    := pdcGetProcAddr('mvaddchnstr');
    pdcMvAddChStr     := pdcGetProcAddr('mvaddchstr');
    pdcMvAddNStr      := pdcGetProcAddr('mvaddnstr');
    pdcMvAddStr       := pdcGetProcAddr('mvaddstr');

    pdcNapMS          := pdcGetProcAddr('napms');
    pdcNewPad         := pdcGetProcAddr('newpad');
    pdcNewTerm        := pdcGetProcAddr('newterm');
    pdcNewWin         := pdcGetProcAddr('newwin');
    pdcNL             := pdcGetProcAddr('nl');
    pdcNoCBreak       := pdcGetProcAddr('nocbreak');
    pdcNoDelay        := pdcGetProcAddr('nodelay');
    pdcNoEcho         := pdcGetProcAddr('noecho');

    pdcRefresh        := pdcGetProcAddr('refresh');

    pdcStartColor     := pdcGetProcAddr('start_color');

    pdcWGetCh         := pdcGetProcAddr('wgetch');

    // Quasi-standard
    pdcGetAttrs := pdcGetProcAddr('getattrs');
    pdcGetBegX  := pdcGetProcAddr('getbegx');
    pdcGetBegY  := pdcGetProcAddr('getbegy');
    pdcGetMaxX  := pdcGetProcAddr('getmaxx');
    pdcGetMaxY  := pdcGetProcAddr('getmaxy');
    pdcGetParX  := pdcGetProcAddr('getparx');
    pdcGetParY  := pdcGetProcAddr('getpary');
    pdcGetCurX  := pdcGetProcAddr('getcurx');
    pdcGetCurY  := pdcGetProcAddr('getcury');
    pdcTraceOff := pdcGetProcAddr('traceoff');
    pdcTraceOn  := pdcGetProcAddr('traceon');
    pdcUnCtrl   := pdcGetProcAddr('unctrl');

    // ncurses
    pdcNCGetMouse := pdcGetProcAddr('nc_getmouse');
  end else
    raise EDLLLoadError.Create('Unable to load the library.');
end;

procedure pdcFreeLib;
begin
  if PDCLibHandle <> nil then
{$IFDEF MSWINDOWS}
    FreeLibrary(HMODULE(PDCLibHandle));
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
    dlclose(PDCLibHandle);
{$ENDIF POSIX}
end;

function pdcPortToStr(aPort: TPort): AnsiString;
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
