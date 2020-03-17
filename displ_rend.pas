{   Routines that manipulate current rendering settings.
}
module displ_rend;
define displ_rend_init;
define displ_rend_resolve;
define displ_rend_default;
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
*   Subroutine DISPL_REND_DEFAULT (PAR, HERE, DEF)
*
*   Create default drawing settings for a new lower level.  PAR are the parent
*   default draw settings, HERE are the settings specified at the new level,
*   and DEF is the composite result for the new level.
}
procedure displ_rend_default (         {make subordinate default draw settings}
  in      par: displ_rend_t;           {parent default settings}
  in      here: displ_rend_t;          {settings specified for this level}
  out     def: displ_rend_t);          {resulting defaults for this level}
  val_param;

begin
  def := here;                         {init to new settings}
  displ_rend_resolve (def, par);       {default to parent when not specified}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_REND_SET_COLOR (COLOR_P, DRDEF, DRCUR)
*
*   Set the RENDlib current color as appropriate.  COLOR_P can be NIL, or point
*   to the explicit color settings to use.  DRDEF contains the default settings.
*   DRCUR contains the current settings, which will be updated if changes are
*   made.
}
procedure displ_rend_set_color (       {set color as appropriate}
  in      color_p: displ_color_p_t;    {NIL or points to explicit setting}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param;

var
  set_p: displ_color_p_t;              {points to resolved setting}

label
  hset;

begin
  set_p := color_p;                    {try explicit setting}
  if set_p <> nil then goto hset;

  set_p := drdef.color_p;              {try default setting}
  if set_p <> nil then goto hset;

  return;                              {no setting found, leave as is}
{
*   SET_P is pointing to the desired setting.
}
hset:
  if set_p = drcur.color_p then return; {set as desired, nothing to do ?}

  rend_set.rgba^ (                     {change the setting}
    set_p^.red, set_p^.grn, set_p^.blu, set_p^.opac);
  drcur.color_p := set_p;              {update pointer to current setting}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_REND_SET_VECT (VECT_P, DRDEF, DRCUR)
*
*   Set the RENDlib current vector drawing parameters as appropriate.  VECT_P
*   can be NIL, or point to the explicit color settings to use.  DRDEF contains
*   the default settings.  DRCUR contains the current settings, which will be
*   updated if changes are made.
}
procedure displ_rend_set_vect (        {set vector parameters as appropriate}
  in      vect_p: displ_vparm_p_t;     {NIL or points to explicit setting}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param;

var
  set_p: displ_vparm_p_t;              {points to resolved setting}

label
  hset;

begin
  set_p := vect_p;                     {try explicit setting}
  if set_p <> nil then goto hset;

  set_p := drdef.vect_parm_p;          {try default setting}
  if set_p <> nil then goto hset;

  return;                              {no setting found, leave as is}
{
*   SET_P is pointing to the desired setting.
}
hset:
  if set_p = drcur.vect_parm_p         {already set as desired, nothing to do ?}
    then return;

  rend_set.vect_parms^ (set_p^.vparm); {change the setting}
  drcur.vect_parm_p := set_p;          {update pointer to current setting}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_REND_SET_TEXT (TEXT_P, DRDEF, DRCUR)
*
*   Set the RENDlib current text drawing parameters as appropriate.  TEXT_P can
*   be NIL, or point to the explicit color settings to use.  DRDEF contains the
*   default settings.  DRCUR contains the current settings, which will be
*   updated if changes are made.
}
procedure displ_rend_set_text (        {set text parameters as appropriate}
  in      text_p: displ_tparm_p_t;     {NIL or points to explicit setting}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param;

var
  set_p: displ_tparm_p_t;              {points to resolved setting}

label
  hset;

begin
  set_p := text_p;                     {try explicit setting}
  if set_p <> nil then goto hset;

  set_p := drdef.text_parm_p;          {try default setting}
  if set_p <> nil then goto hset;

  return;                              {no setting found, leave as is}
{
*   SET_P is pointing to the desired setting.
}
hset:
  if set_p = drcur.text_parm_p         {already set as desired, nothing to do ?}
    then return;

  rend_set.text_parms^ (set_p^.tparm); {change the setting}
  drcur.text_parm_p := set_p;          {update pointer to current setting}
  end;
