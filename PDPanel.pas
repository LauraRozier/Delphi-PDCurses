unit PDPanel;
// Public Domain Curses
{
  *----------------------------------------------------------------------*
  *                         Panels for PDCurses                          *
  *----------------------------------------------------------------------*
}
{$I PDCurses.inc}

interface
uses
  PDCurses;

const
{$IFDEF MACOS}
  FROM_PANEL_LIB = True;
{$ELSE MACOS}
  FROM_PANEL_LIB = False;
{$ENDIF MACOS}

type
  PPANELOBS = ^PANELOBS;
  PPANEL    = ^PANEL;

  PANELOBS = record
    above: PPANELOBS;
    pan:   PPANEL;
  end;

  PANEL = record
    win: PWINDOW;
    wstarty,
    wendy,
    wstartx,
    wendx: LongInt;
    below,
    above: PPANEL;
    user: Pointer;
    obscure: PPANELOBS;
  end;

var
  pdcBottomPanel:     function(aPanel: PPanel): LongInt; cdecl;
  pdcDelPanel:        function(aPanel: PPanel): LongInt; cdecl;
  pdcHidePanel:       function(aPanel: PPanel): LongInt; cdecl;
  pdcMovePanel:       function(aPanel: PPanel): LongInt; cdecl;
  pdcNewPanel:        function(aWindow: PWindow): PPanel; cdecl;

  pdcPanelAbove:      function(const aPanel: PPanel): PPanel; cdecl;
  pdcPanelBelow:      function(const aPanel: PPanel): PPanel; cdecl;
  pdcPanelHidden:     function(const aPanel: PPanel): LongInt; cdecl;
  pdcPanelUserptr:    function(const aPanel: PPanel): Pointer; cdecl;
  pdcPanelWindow:     function(const aPanel: PPanel): PWindow; cdecl;

  pdcReplacePanel:    function(aPanel: PPanel; win: PWindow): LongInt; cdecl;
  pdcSetPanelUserPtr: function(aPanel: PPanel; const aUserPointer: Pointer): LongInt; cdecl;
  pdcShowPanel:       function(aPanel: PPanel): LongInt; cdecl;
  pdcTopPanel:        function(aPanel: PPanel): LongInt; cdecl;
  pdcUpdatePanels:    procedure; cdecl;

{
  Non-lib functions
}
procedure pdcInitPanelLib;

implementation

{
  Non-lib functions
}
procedure pdcInitPanelLib;
{$IFDEF MACOS}
var
  Marshaller: TMarshaller;
begin
  if PDCPanelLibHandle <> nil then Exit;

  PDCPanelLibHandle := dlopen(Marshaller.AsAnsi(LIBPDCPANEL, CP_UTF8).ToPointer,
                              RTLD_LAZY);

  if PDCPanelLibHandle <> nil then
  begin
{$ELSE MACOS}
begin
  if PDCLibHandle <> nil then
  begin
{$ENDIF MACOS}
    @pdcBottomPanel     := pdcGetProcAddr('bottom_panel', FROM_PANEL_LIB);
    @pdcDelPanel        := pdcGetProcAddr('del_panel', FROM_PANEL_LIB);
    @pdcHidePanel       := pdcGetProcAddr('hide_panel', FROM_PANEL_LIB);
    @pdcMovePanel       := pdcGetProcAddr('move_panel', FROM_PANEL_LIB);
    @pdcNewPanel        := pdcGetProcAddr('new_panel', FROM_PANEL_LIB);

    @pdcPanelAbove      := pdcGetProcAddr('panel_above', FROM_PANEL_LIB);
    @pdcPanelBelow      := pdcGetProcAddr('panel_below', FROM_PANEL_LIB);
    @pdcPanelHidden     := pdcGetProcAddr('panel_hidden', FROM_PANEL_LIB);
    @pdcPanelUserptr    := pdcGetProcAddr('panel_userptr', FROM_PANEL_LIB);
    @pdcPanelWindow     := pdcGetProcAddr('panel_window', FROM_PANEL_LIB);

    @pdcReplacePanel    := pdcGetProcAddr('replace_panel', FROM_PANEL_LIB);
    @pdcSetPanelUserPtr := pdcGetProcAddr('set_panel_userptr', FROM_PANEL_LIB);
    @pdcShowPanel       := pdcGetProcAddr('show_panel', FROM_PANEL_LIB);
    @pdcTopPanel        := pdcGetProcAddr('top_panel', FROM_PANEL_LIB);
    @pdcUpdatePanels    := pdcGetProcAddr('update_panels', FROM_PANEL_LIB);
  end else
    raise EDLLLoadError.Create('Unable to load the panel library.');
end;

end.
