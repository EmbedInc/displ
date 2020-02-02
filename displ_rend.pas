{   Routines that manipulate current rendering settings.
}
module displ_rend;
define displ_rend_init;
define displ_rend_resolve;
define displ_rend_set_color;
define displ_rend_set_vect;
define displ_rend_set_text;
%include 'displ2.ins.pas';
{
********************************************************************************
*
*   Subroutine DISPL_REND_INIT (REND)
*
*   Initialize all fields of the rendering settings descriptor REND to default
*   or benign values.
}
procedure displ_rend_init (            {init render settings descriptor}
  out     rend: displ_rend_t);         {the descriptor to set all fields of}
  val_param;

begin
  rend.color_p := nil;
  rend.vect_parm_p := nil;
  rend.text_parm_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine DISPL_REND_RESOLVE (REND, DEF)
*
*   Resolve the rendering settings given defaults from a higher level.  REND is
*   the set of rendering settings to update.  DEF is the set of default settings
*   to apply.  If a value in REND is not set, then it is taken from DEF.
}
procedure displ_rend_resolve (         {resolve render settings by applying defaults}
  in out  rend: displ_rend_t;          {render settings to update}
  in      def: displ_rend_t);          {defaults to apply as needed}
  val_param;

begin
  if rend.color_p = nil then begin
    rend.color_p := def.color_p;
    end;
  if rend.vect_parm_p = nil then begin
    rend.vect_parm_p := def.vect_parm_p;
    end;
  if rend.text_parm_p = nil then begin
    rend.text_parm_p := def.text_parm_p;
    end;
  end;
{
********************************************************************************
*
*   Subroutine DISPL_REND_SET_COLOR (COLOR_P, DRAW)
*
*   Set the RENDlib current color as appropriate.  COLOR_P can be NIL, or point
*   to the explicit color settings to use.  DRAW contains the current and
*   default settings.
}
procedure displ_rend_set_color (       {set color as appropriate}
  in      color_p: displ_color_p_t;    {NIL or points to explicit setting}
  in out  draw: displ_draw_t);         {current drawing state, may be updated}
  val_param;

var
  set_p: displ_color_p_t;              {points to resolved setting}

label
  hset;

begin
  set_p := color_p;                    {try explicit setting}
  if set_p <> nil then goto hset;

  set_p := draw.def.color_p;           {try default setting}
  if set_p <> nil then goto hset;

  return;                              {no setting found, leave as is}
{
*   SET_P is pointing to the desired setting.
}
hset:
  if set_p = draw.curr.color_p then return; {set as desired, nothing to do ?}

  rend_set.rgba^ (                     {change the setting}
    set_p^.red, set_p^.grn, set_p^.blu, set_p^.opac);
  draw.curr.color_p := set_p;          {update pointer to current setting}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_REND_SET_VECT (VECT_P, DRAW)
*
*   Set the RENDlib current vector drawing state as appropriate.  VECT_P can be
*   NIL, or point to the explicit vector settings to use.  DRAW contains the
*   current and default settings.
}
procedure displ_rend_set_vect (        {set vector parameters as appropriate}
  in      vect_p: rend_vect_parms_p_t; {NIL or points to explicit setting}
  in out  draw: displ_draw_t);         {current drawing state, may be updated}
  val_param;

var
  set_p: rend_vect_parms_p_t;          {points to resolved setting}

label
  hset;

begin
  set_p := vect_p;                     {try explicit setting}
  if set_p <> nil then goto hset;

  set_p := draw.def.vect_parm_p;       {try default setting}
  if set_p <> nil then goto hset;

  return;                              {no setting found, leave as is}
{
*   SET_P is pointing to the desired setting.
}
hset:
  if set_p = draw.curr.vect_parm_p     {already set as desired, nothing to do ?}
    then return;

  rend_set.vect_parms^ (set_p^);       {change the setting}
  draw.curr.vect_parm_p := set_p;      {update pointer to current setting}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_REND_SET_TEXT (TEXT_P, DRAW)
*
*   Set the RENDlib current text drawing state as appropriate.  TEXT_P can be
*   NIL, or point to the explicit text settings to use.  DRAW contains the
*   current and default settings.
}
procedure displ_rend_set_text (        {set text parameters as appropriate}
  in      text_p: rend_text_parms_p_t; {NIL or points to explicit setting}
  in out  draw: displ_draw_t);         {current drawing state, may be updated}
  val_param;

var
  set_p: rend_text_parms_p_t;          {points to resolved setting}

label
  hset;

begin
  set_p := text_p;                     {try explicit setting}
  if set_p <> nil then goto hset;

  set_p := draw.def.text_parm_p;       {try default setting}
  if set_p <> nil then goto hset;

  return;                              {no setting found, leave as is}
{
*   SET_P is pointing to the desired setting.
}
hset:
  if set_p = draw.curr.text_parm_p     {already set as desired, nothing to do ?}
    then return;

  rend_set.text_parms^ (set_p^);       {change the setting}
  draw.curr.text_parm_p := set_p;      {update pointer to current setting}
  end;
