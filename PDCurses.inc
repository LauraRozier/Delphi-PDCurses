// Public Domain Curses

{
  *----------------------------------------------------------------------*
  *                              PDCurses                                *
  *----------------------------------------------------------------------*

man-start**************************************************************

  PDCurses definitions list:  (Only define those needed)
    PDC_DLL_BUILD         True if building a Win32 DLL.
    XCURSES               True if compiling for X11.
    PDC_RGB               True if you want to use RGB color definitions
                          (Red = 1, Green = 2, Blue = 4) instead of BGR.
    PDC_WIDE              True if building wide-character support.
    NCURSES_MOUSE_VERSION Use the ncurses mouse API instead
                          of PDCurses' traditional mouse API.

  PDCurses portable platform definitions list:
    PDC_BUILD         Defines API build version.
    PDCURSES          Enables access to PDCurses-only routines.
    XOPEN             Always true.
    SYSVcurses        True if you are compiling for SYSV portability.
    BSDcurses         True if you are compiling for BSD portability.
    CHTYPE_LONG       Defines the size of chtype; 32 bits if defined.
    CHTYPE_EXTRA_LONG Defines the size of chtype; 64 bits if defined.

man-end****************************************************************
}
{$IFNDEF CONSOLE}
  {$MESSAGE FATAL 'PDCurses is a console-only library.'}
{$ENDIF}
{$INLINE AUTO}

{$DEFINE PDCURSES}             // PDCurses-only routines
{$DEFINE XOPEN}                // X/Open Curses routines
{$DEFINE SYSVcurses}           // System V Curses routines
{$DEFINE BSDcurses}            // BSD Curses routines
{$DEFINE CHTYPE_LONG}          // chtypes will be 32 bits
{$DEFINE CHTYPE_EXTRA_LONG}    // chtypes will be (default) 64 bits
{$DEFINE PDC_HAS_VERSION_INFO} // Available since 4.0

{$IFDEF MSWINDOWS}
  {$DEFINE PDC_DLL_BUILD}
{$ELSE MSWINDOWS}
  {$IFDEF LINUX}
    {$DEFINE XCURSES}
  {$ENDIF LINUX}
{$ENDIF MSWINDOWS}

{.$DEFINE PDC_RGB}
{$DEFINE PDC_WIDE}
{.$DEFINE NCURSES_MOUSE_VERSION}
