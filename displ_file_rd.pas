{   Routines for reading from display list files.
*
*   Quick overview of routines for reading from the input file:
*
*     RDLINE (RD, STAT)  -  Read next line.  FALSE if popped up one level.
*
*     END_OF_LINE (RD, STAT)  -  Check for end of current input line.
*
*     RDTOKEN (RD, TOKEN)  -  Read token.  TRUE when token found.
*
*     RDKEYW (RD, KEYW)  -  Read next token as keyword.  TRUE when token found.
*
*     RDINT (RD, II, STAT)  -  Read next token as integer.
*
*     RDFP (RD, FP, STAT)  -  Read next token as floating point.
*
*     RDBOOL (RD, TF, STAT)  -  Read next token as boolean.
*
*     RDSPACE (RD, SPACE, STAT)  -  Read next token as RENDlib coor space name.
*
*     RDENDSTYLE (RD, ENDSTYLE, STAT)  -  Read next token as RENDlib vector end
*       style.
*
*     RDTORG (RD, TORG, STAT)  -  Read next token as RENDlib text anchor name.
*
*     BLOCK_START (RD)  -  Down into nested block.
*
*     ERR_LINE_FILE (RD, STAT)  -  Add line number and file name to STAT.
}
module disp_file_rd;
define displ_file_read;
%include 'displ2.ins.pas';

type
  lists_p_t = ^lists_t;
  lists_t =                            {pointers to all the lists}
    array [1..1] of displ_p_t;

  colors_p_t = ^colors_t;
  colors_t =                           {pointers to all the color definitions}
    array [1..1] of displ_color_p_t;

  vparms_p_t = ^vparms_t;
  vparms_t =                           {pointers to all the vector parameter blocks}
    array [1..1] of displ_vparm_p_t;

  tparms_p_t = ^tparms_t;
  tparms_t =                           {pointers to all the text parameter blocks}
    array [1..1] of displ_tparm_p_t;

  imgs_p_t = ^imgs_t;
  imgs_t =                             {all the external image descriptors}
    array [1..1] of displ_img_t;

  rd_t = record                        {DISPL file reading state}
    mem_perm_p: util_mem_context_p_t;  {use for mem returned to caller}
    mem_temp_p: util_mem_context_p_t;  {use for temp mem while reading file}
    conn: file_conn_t;                 {connection to the file}
    level: sys_int_machine_t;          {current data reading nesting level, 0 = top}
    llev: sys_int_machine_t;           {nesting level of the current input line}
    buf: string_var80_t;               {current input line}
    p: string_index_t;                 {parse index into BUF}
    eof: boolean;                      {end of file has been read, CONN closed}
    lret: boolean;                     {the current input line has been returned}
    nlists: sys_int_machine_t;         {number of list definitions in the file}
    lists_p: lists_p_t;                {pointer to lists list}
    ncolors: sys_int_machine_t;        {number of color definitions in the file}
    colors_p: colors_p_t;              {pointer to colors list}
    nvparms: sys_int_machine_t;        {number of vector parm blocks in the file}
    vparms_p: vparms_p_t;              {pointer to vector parameters list}
    ntparms: sys_int_machine_t;        {number of text parm blocks in the file}
    tparms_p: tparms_p_t;              {pointer to text parameters list}
    nimgs: sys_int_machine_t;          {number of external images referenced}
    imgs_p: imgs_p_t;                  {pointer to external images list}
    end;
{
********************************************************************************
*
*   Local subroutine DISPL_FILE_READ_OPEN (FNAM, MEM, RD, STAT)
*
*   Open the display list file of name FNAM and set up the reading state RD
*   accordingly.
}
procedure displ_file_read_open (       {open display list file}
  in      fnam: univ string_var_arg_t; {file name, ".displ" suffix implied}
  in out  mem: util_mem_context_t;     {parent memory context}
  out     rd: rd_t;                    {reading state, no resources used on error}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

begin
  file_open_read_text (                {open the file}
    fnam, '.displ',                    {file name and mandatory suffix}
    rd.conn,                           {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  rd.mem_perm_p := addr(mem);          {save pointer to context for mem to return to caller}
  util_mem_context_get (               {create our private temporary memory context}
    rd.mem_perm_p^, rd.mem_temp_p);

  rd.level := 0;                       {init the remaining file reading state}
  rd.buf.max := size_char(rd.buf.str);
  rd.buf.len := 0;
  rd.p := 1;
  rd.eof := false;
  rd.lret := true;
  rd.nlists := 0;
  rd.lists_p := nil;
  rd.ncolors := 0;
  rd.colors_p := nil;
  rd.nvparms := 0;
  rd.vparms_p := nil;
  rd.ntparms := 0;
  rd.tparms_p := nil;
  rd.nimgs := 0;
  rd.imgs_p := nil;
  end;
{
********************************************************************************
*
*   Local subroutine DISPL_FILE_READ_CLOSE (RD)
*
*   Close the input file and deallocate any resources associated with reading
*   it.
}
procedure displ_file_read_close (      {end reading file, dealloc resources}
  in out  rd: rd_t);                   {file reading state, returned invalid}
  val_param; internal;

begin
  if not rd.eof then begin             {file not already closed ?}
    file_close (rd.conn);              {close the file}
    rd.eof := true;
    end;

  util_mem_context_del (rd.mem_temp_p); {deallocate all reading state dyn memory}
  end;
{
********************************************************************************
*
*   Local subroutine ERR_LINE_FILE (RD, STAT)
*
*   Add the line number and file name as the next two parameters to STAT.  STAT
*   must already be set to a specific error code.
}
procedure err_line_file (              {add line number and file name to STAT}
  in out  rd: rd_t;                    {input file reading state}
  out     stat: sys_err_t);            {two parameters will be added}
  val_param; internal;

begin
  sys_stat_parm_int (rd.conn.lnum, stat); {add line number}
  sys_stat_parm_vstr (rd.conn.tnam, stat); {add file name}
  end;
{
********************************************************************************
*
*   Local function RDLINE (RD, STAT)
*
*   Read the next line from the input file.  The function returns TRUE if the
*   new content is at the same level as the previous line.  The function returns
*   FALSE once for each level being popped up.  The function returns FALSE
*   indefinitely after the end of the input file has been encountered.  Lines
*   at a lower nesting level than the current are ignored.
*
*   On error, STAT is set to indicate the error, and the function returns TRUE.
}
function rdline (                      {read next line from input file}
  in out  rd: rd_t;                    {input file reading state}
  out     stat: sys_err_t)             {completion status}
  :boolean;                            {at same nesting level, not popped up}
  val_param; internal;

label
  get_line, have_line;

begin
  if rd.eof then begin                 {previously hit end of file ?}
    sys_error_none (stat);
    rdline := false;                   {always as if popping up a level}
    return;
    end;
  rdline := true;                      {init to continuing at same nesting level}

  if not rd.lret then goto have_line;  {already have input line from last time ?}

get_line:                              {back here to get the next relevant input line}
  file_read_text (rd.conn, rd.buf, stat); {read next line from file}
  if file_eof(stat) then begin         {hit end of file ?}
    file_close (rd.conn);              {close the file}
    rd.eof := true;                    {remember that hit EOF and file closed}
    rd.buf.len := 0;                   {as if empty line}
    rd.p := 1;
    rdline := false;                   {EOF is always as if popping up a level}
    return;                            {return indicating up one level}
    end;
  if sys_error(stat) then return;      {hard error ?}
  string_unpad (rd.buf);               {delete all trailing spaces from input line}
  if rd.buf.len <= 0 then goto get_line; {ignore blank lines}
  rd.p := 1;                           {init new input line parse index}
  while rd.buf.str[rd.p] = ' ' do begin {skip over leading blanks}
    rd.p := rd.p + 1;
    end;
  if rd.buf.str[rd.p] = '*' then goto get_line; {ignore comment lines}
  rd.llev := (rd.p - 1) div 2;         {make nesting level of this line from indentation}
  if ((rd.llev * 2) + 1) <> rd.p then begin {invalid indentation ?}
    sys_stat_set (displ_subsys_k, displ_stat_badindent_k, stat); {set error status}
    sys_stat_parm_vstr (rd.conn.tnam, stat);
    sys_stat_parm_int (rd.conn.lnum, stat);
    return;                            {return with bad indentation error}
    end;
  rd.lret := false;                    {init to this line not returned}

have_line:                             {a new valid line is in the buffer}
  if rd.llev = rd.level then begin     {new line is at existing nesting level ?}
    rd.lret := true;                   {remember that this line was returned}
    return;                            {return with the new line}
    end;

  if rd.llev > rd.level then goto get_line; {ignore lines at lower nesting levels}

  rd.level := rd.level - 1;            {pop up one level}
  rdline := false;                     {indicate the current level has ended}
  end;
{
********************************************************************************
*
*   Local function RDTOKEN (RD, TK)
*
*   Read the next token on the current input line.  When a token is found, the
*   function returns TRUE with the token in TK.  Otherwise the function returns
*   FALSE with TK set to the empty string.
}
function rdtoken (                     {read next token from input line}
  in out  rd: rd_t;                    {input file reading state}
  in out  tk: univ string_var_arg_t)   {the returned token, empty str on EOL}
  :boolean;                            {token found}
  val_param; internal;

var
  stat: sys_err_t;

begin
  rdtoken := true;                     {init to indicate returning with token}

  string_token (rd.buf, rd.p, tk, stat); {try to read the next token}
  if sys_error(stat) then begin        {didn't get a token ?}
    tk.len := 0;                       {return the empty string}
    rdtoken := false;                  {indicate not returning with a token}
    end;
  end;
{
********************************************************************************
*
*   Local function END_OF_LINE (RD, STAT)
*
*   Checks for unread tokens remaining on the current input line.
*
*   If the input line has been exhausted, then the function returns TRUE with
*   STAT set to no error.
*
*   If a token is found, then the function returns FALSE, STAT is set to an
*   appropriate error assuming the extra token is not allowed, and the parse
*   index is restored to before the first extra token.
}
function end_of_line (                 {check for at end of current input line}
  in out  rd: rd_t;                    {input file reading state}
  out     stat: sys_err_t)             {extra token error if not end of line}
  :boolean;                            {TRUE with STAT no err if end of line}
  val_param; internal;

var
  tk: string_var32_t;                  {token}
  p: string_index_t;                   {original parse index}

begin
  tk.max := size_char(tk.str);         {init local var string}

  p := rd.p;                           {save original parse index}
  if not rdtoken (rd, tk) then begin   {no token here, at end of line ?}
    sys_error_none (stat);             {indicate no error}
    end_of_line := true;               {indicate was at end of line}
    return;
    end;

  sys_stat_set (displ_subsys_k, displ_stat_extratk_k, stat); {extra token}
  sys_stat_parm_vstr (tk, stat);       {the extra token}
  err_line_file (rd, stat);            {add line number and file name}
  rd.p := p;                           {restore parse index to before extra token}
  end_of_line := false;                {indicate not at end of line}
  end;
{
********************************************************************************
*
*   Local function RDKEYW (RD, TK)
*
*   Read the next token as a keyword, and return it in TK.  This function is
*   like RDTOKEN except that the token is always returned upper case, regardless
*   of its case in the file.
}
function rdkeyw (                      {read next input line token as keyword}
  in out  rd: rd_t;                    {input file reading state}
  in out  tk: univ string_var_arg_t)   {the returned token, always upper case}
  :boolean;                            {token found}
  val_param; internal;

begin
  rdkeyw := rdtoken (rd, tk);          {read the token}
  string_upcase (tk);                  {force all letters to upper case}
  end;
{
********************************************************************************
*
*   Local subroutine RDINT (RD, II, STAT)
*
*   Read the next token from the current input line and interpret it as an
*   integer.  The result is returned in II.  STAT is set appropriately if no
*   token is available, or the token can not be interpreted as a integer.
}
procedure rdint (                      {read next token as integer}
  in out  rd: rd_t;                    {input file reading state}
  out     ii: sys_int_machine_t;       {returned integer value}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

begin
  string_token_int (rd.buf, rd.p, ii, stat);
  if string_eos(stat) then begin       {no token ?}
    sys_stat_set (displ_subsys_k, displ_stat_noparm_k, stat);
    err_line_file (rd, stat);
    return;
    end;
  if sys_error(stat) then begin        {any other error ?}
    sys_stat_set (displ_subsys_k, displ_stat_badval_k, stat);
    err_line_file (rd, stat);
    return;
    end;
  end;
{
********************************************************************************
*
*   Local subroutine RDFP (RD, FP, STAT)
*
*   Read the next token from the current input line and interpret it as a
*   floating point value.  The result is returned in FP.  STAT is set
*   appropriately if no token is available, or the token can not be interpreted
*   as a floating point value.
}
procedure rdfp (                       {read next token as floating point}
  in out  rd: rd_t;                    {input file reading state}
  out     fp: real;                    {returned floating point value}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

begin
  string_token_fpm (rd.buf, rd.p, fp, stat);
  if string_eos(stat) then begin       {no token ?}
    sys_stat_set (displ_subsys_k, displ_stat_noparm_k, stat);
    err_line_file (rd, stat);
    return;
    end;
  if sys_error(stat) then begin        {any other error ?}
    sys_stat_set (displ_subsys_k, displ_stat_badval_k, stat);
    err_line_file (rd, stat);
    return;
    end;
  end;
{
********************************************************************************
*
*   Local subroutine RDBOOL (RD, TF, STAT)
*
*   Read the next token from the current input line and interpret it as a
*   boolean.  The result is returned in TF.  The token can be either "true",
*   "yes" or "on" for TRUE, or "false", "no", or "off" for FALSE.
}
procedure rdbool (                     {read next token as boolean}
  in out  rd: rd_t;                    {input file reading state}
  out     tf: boolean;                 {returned boolean value}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

begin
  string_token_bool (                  {parse token, interpret as boolean}
    rd.buf,                            {input string}
    rd.p,                              {input string parse index}
    [ string_tftype_tf_k,              {indicate the allowed keywords}
      string_tftype_yesno_k,
      string_tftype_onoff_k],
    tf,                                {returned boolean value}
    stat);
  if string_eos(stat) then begin       {no token ?}
    sys_stat_set (displ_subsys_k, displ_stat_noparm_k, stat);
    err_line_file (rd, stat);
    return;
    end;
  if sys_error(stat) then begin        {any other error ?}
    sys_stat_set (displ_subsys_k, displ_stat_badval_k, stat);
    err_line_file (rd, stat);
    return;
    end;
  end;
{
********************************************************************************
*
*   Local subroutine RDSPACE (RD, SPACE, STAT)
*
*   Read the next token from the current input line and interpret it as a
*   RENDlib coordinate space identifier.  The result is returned in SPACE.
}
procedure rdspace (                    {read next token as RENDlib coor space name}
  in out  rd: rd_t;                    {input file reading state}
  out     space: rend_space_k_t;       {returned RENDlib coordinate space ID}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

var
  tk: string_var32_t;
  pick: sys_int_machine_t;             {number of keyword picked from list}

begin
  tk.max := size_char(tk.str);         {init local var string}

  if not rdkeyw (rd, tk) then begin    {get the coordinate space name keyword}
    sys_stat_set (displ_subsys_k, displ_stat_errsyn_k, stat); {syntax error}
    err_line_file (rd, stat);          {add line number and file name}
    return;
    end;
  string_tkpick80 (tk,                 {pick the command name from the list}
    'NONE 2DIMI 2DIM 2DIMCL 2D 2DCL 3DW 3DWPL 3DWCL 3D 3DPL TEXT TXDRAW',
    pick);
  case pick of                         {which name is it ?}
1:  space := rend_space_none_k;
2:  space := rend_space_2dimi_k;
3:  space := rend_space_2dim_k;
4:  space := rend_space_2dimcl_k;
5:  space := rend_space_2d_k;
6:  space := rend_space_2dcl_k;
7:  space := rend_space_3dw_k;
8:  space := rend_space_3dwpl_k;
9:  space := rend_space_3dwcl_k;
10: space := rend_space_3d_k;
11: space := rend_space_3dpl_k;
12: space := rend_space_text_k;
13: space := rend_space_txdraw_k;
otherwise
    sys_stat_set (displ_subsys_k, displ_stat_badval_k, stat); {bad value}
    err_line_file (rd, stat);          {add line number and file name}
    return;
    end;                               {end of coordinate space name cases}
  end;
{
********************************************************************************
*
*   Local subroutine RDENDSTYLE (RD, ENDSTYLE, STAT)
*
*   Read the next token from the current input line and interpret it as a
*   RENDlib vector end style.  The result is returned in ENDSTYLE.
}
procedure rdendstyle (                 {read next token as RENDlib coor space name}
  in out  rd: rd_t;                    {input file reading state}
  out     endstyle: rend_end_style_t;  {returned vector end style}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

var
  tk: string_var32_t;
  pick: sys_int_machine_t;             {number of keyword picked from list}

begin
  tk.max := size_char(tk.str);         {init local var string}

  if not rdkeyw (rd, tk) then begin    {get the end style name keyword}
    sys_stat_set (displ_subsys_k, displ_stat_errsyn_k, stat); {syntax error}
    err_line_file (rd, stat);          {add line number and file name}
    return;
    end;
  string_tkpick80 (tk,                 {pick the name from the list}
    'RECT CIRC',
    pick);
  case pick of                         {which name is it ?}

1:  begin                              {RECT}
      endstyle.style := rend_end_style_rect_k;
      end;

2:  begin                              {CIRC}
      endstyle.style := rend_end_style_circ_k;
      rdint (rd, endstyle.nsides, stat);
      end;

otherwise
    sys_stat_set (displ_subsys_k, displ_stat_badval_k, stat); {bad value}
    err_line_file (rd, stat);          {add line number and file name}
    end;                               {end of coordinate space name cases}
  end;
{
********************************************************************************
*
*   Local subroutine RDTORG (RD, TORG, STAT)
*
*   Read the next token from the current input line and interpret it as a text
*   anchor point name.  The result is returned in TORG.
}
procedure rdtorg (                     {read next token as RENDlib text anchor name}
  in out  rd: rd_t;                    {input file reading state}
  out     torg: rend_torg_k_t;         {text anchor point ID}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

var
  tk: string_var32_t;
  pick: sys_int_machine_t;             {number of keyword picked from list}

begin
  tk.max := size_char(tk.str);         {init local var string}

  if not rdkeyw (rd, tk) then begin    {get the keyword}
    sys_stat_set (displ_subsys_k, displ_stat_noparm_k, stat); {missing parameter}
    err_line_file (rd, stat);          {add line number and file name}
    return;
    end;
  string_tkpick80 (tk,                 {pick the name from the list}
    'UL UM UR ML MID MR LL LM LR DOWN UP',
    pick);
  case pick of                         {which name is it ?}
1:  torg := rend_torg_ul_k;
2:  torg := rend_torg_um_k;
3:  torg := rend_torg_ur_k;
4:  torg := rend_torg_ml_k;
5:  torg := rend_torg_mid_k;
6:  torg := rend_torg_mr_k;
7:  torg := rend_torg_ll_k;
8:  torg := rend_torg_lm_k;
9:  torg := rend_torg_lr_k;
10: torg := rend_torg_down_k;
11: torg := rend_torg_up_k;
otherwise
    sys_stat_set (displ_subsys_k, displ_stat_badval_k, stat); {bad value}
    err_line_file (rd, stat);          {add line number and file name}
    end;                               {end of coordinate space name cases}
  end;
{
********************************************************************************
*
*   Local subroutine BLOCK_START (RD)
*
*   Go down into a nested block.
}
procedure block_start (                {go down into nexted block}
  in out  rd: rd_t);                   {input file reading state}
  val_param; internal;

begin
  rd.level := rd.level + 1;
  end;
{
********************************************************************************
*
*   Local subroutine RD_COLOR (RD, STAT)
*
*   Read and save a color definition.  The COLOR command keyword has been read.
}
procedure rd_color (                   {read COLOR command}
  in out  rd: rd_t;                    {input file reading state}
  in out  stat: sys_err_t);            {completion status, set to no err on entry}
  val_param; internal;

var
  id: sys_int_machine_t;               {ID for this color}
  col_p: displ_color_p_t;              {pointer to the new color descriptor}

begin
  rdint (rd, id, stat);                {get the color ID}
  if sys_error(stat) then return;
  if (id < 1) or (id > rd.ncolors) then begin {out of range color ID}
    sys_stat_set (displ_subsys_k, displ_stat_badcolid_k, stat);
    sys_stat_parm_int (id, stat);
    err_line_file (rd, stat);
    return;
    end;
  if rd.colors_p^[id] <> nil then begin {color of this ID already defined ?}
    sys_stat_set (displ_subsys_k, displ_stat_dupcol_k, stat);
    sys_stat_parm_int (id, stat);
    err_line_file (rd, stat);
    return;
    end;

  util_mem_grab (                      {allocate memory for the new color descriptor}
    sizeof (col_p^), rd.mem_perm_p^, false, col_p);

  rdfp (rd, col_p^.red, stat);         {get the color values}
  if sys_error(stat) then return;
  rdfp (rd, col_p^.grn, stat);
  if sys_error(stat) then return;
  rdfp (rd, col_p^.blu, stat);
  if sys_error(stat) then return;
  rdfp (rd, col_p^.opac, stat);
  if sys_error(stat) then return;
  if not end_of_line (rd, stat) then return;

  col_p^.id := id;                     {save the ID}
  rd.colors_p^[id] := col_p;           {save pointer to color of this ID}
  end;
{
********************************************************************************
*
*   Local subroutine RD_VPARM (RD, STAT)
*
*   Read and save a vector parameters definition.  The VPARM command keyword has
*   been read.
}
procedure rd_vparm (                   {read VPARM command}
  in out  rd: rd_t;                    {input file reading state}
  in out  stat: sys_err_t);            {completion status, set to no err on entry}
  val_param; internal;

var
  id: sys_int_machine_t;               {ID for this VPARM}
  vparm_p: displ_vparm_p_t;            {pointer to the new VPARM}
  cmd: string_var32_t;                 {command name}
  pick: sys_int_machine_t;             {number of keyword picked from list}

label
  err_syn, err_atline;

begin
  cmd.max := size_char(cmd.str);

  rdint (rd, id, stat);                {get the VPARM ID}
  if sys_error(stat) then return;
  if (id < 1) or (id > rd.nvparms) then begin {ID is out of range ?}
    sys_stat_set (displ_subsys_k, displ_stat_badvpid_k, stat);
    sys_stat_parm_int (id, stat);
    goto err_atline;
    end;
  if rd.vparms_p^[id] <> nil then begin {VPARM of this ID already defined ?}
    sys_stat_set (displ_subsys_k, displ_stat_dupvparm_k, stat);
    sys_stat_parm_int (id, stat);
    goto err_atline;
    end;
  if not end_of_line (rd, stat) then return;

  util_mem_grab (                      {allocate memory for the new descriptor}
    sizeof (vparm_p^), rd.mem_perm_p^, false, vparm_p);

  block_start (rd);                    {down into VPARM block}
  while rdline (rd, stat) do begin     {loop over all the VPARM subcommands}
    if not rdkeyw (rd, cmd) then goto err_syn; {get this command name}
    string_tkpick80 (cmd,              {pick the command name from the list}
      'WIDTH POLY START END SUBPIX',
      pick);
    case pick of                       {which command is it}

1:    begin                            {WIDTH}
        rdfp (rd, vparm_p^.vparm.width, stat);
        end;

2:    begin                            {POLY}
        rdspace (rd, vparm_p^.vparm.poly_level, stat);
        end;

3:    begin                            {START}
        rdendstyle (rd, vparm_p^.vparm.start_style, stat);
        end;

4:    begin                            {END}
        rdendstyle (rd, vparm_p^.vparm.end_style, stat);
        end;

5:    begin                            {SUBPIX}
        rdbool (rd, vparm_p^.vparm.subpixel, stat);
        end;

otherwise
      sys_stat_set (displ_subsys_k, displ_stat_badcmd_k, stat);

      goto err_atline;
      end;                             {end of subcommand cases}
    if sys_error(stat) then return;
    if not end_of_line (rd, stat) then return;
    end;                               {back for next VPARM subcommand}

  vparm_p^.id := id;                   {save the ID}
  rd.vparms_p^[id] := vparm_p;         {save pointer to VPARM of this ID}
  return;                              {normal return point, no error}
{
*   Error, bad syntax in file.
}
err_syn:
  sys_stat_set (displ_subsys_k, displ_stat_errsyn_k, stat);
  goto err_atline;
{
*   Error exit to add line number and file name to STAT.  STAT must already be
*   set, and the next two parameters must be the line number and the file name.
}
err_atline:
  err_line_file (rd, stat);            {add line number and file name to STAT}
  end;
{
********************************************************************************
*
*   Local subroutine RD_TPARM (RD, STAT)
*
*   Read and save a text parameters definition.  The TPARM command keyword has
*   been read.
}
procedure rd_tparm (                   {read TPARM command}
  in out  rd: rd_t;                    {input file reading state}
  in out  stat: sys_err_t);            {completion status, set to no err on entry}
  val_param; internal;

var
  id: sys_int_machine_t;               {ID for this TPARM}
  tparm_p: displ_tparm_p_t;            {pointer to the new TPARM}
  cmd: string_var32_t;                 {command name}
  pick: sys_int_machine_t;             {number of keyword picked from list}

label
  err_syn, err_missing, err_atline;

begin
  cmd.max := size_char(cmd.str);       {init local var string}

  rdint (rd, id, stat);                {get the TPARM ID}
  if sys_error(stat) then return;
  if (id < 1) or (id > rd.ntparms) then begin {ID is out of range ?}
    sys_stat_set (displ_subsys_k, displ_stat_badtpid_k, stat);
    sys_stat_parm_int (id, stat);
    goto err_atline;
    end;
  if rd.tparms_p^[id] <> nil then begin {TPARM of this ID already defined ?}
    sys_stat_set (displ_subsys_k, displ_stat_duptparm_k, stat);
    sys_stat_parm_int (id, stat);
    goto err_atline;
    end;
  if not end_of_line (rd, stat) then return;

  util_mem_grab (                      {allocate memory for the new descriptor}
    sizeof (tparm_p^), rd.mem_perm_p^, false, tparm_p);
  tparm_p^.tparm.font.max := size_char(tparm_p^.tparm.font.str);
  tparm_p^.tparm.font.len := 0;

  block_start (rd);                    {down into TPARM block}
  while rdline (rd, stat) do begin     {loop over all the TPARM subcommands}
    if not rdkeyw (rd, cmd) then goto err_syn; {get this command name}
    string_tkpick80 (cmd,              {pick the command name from the list}
      'SIZE WIDTH HEIGHT SLANT ROT LSPACE VWIDTH FONT COOR STORG ENORG POLY',
      pick);
    case pick of                       {which command is it}

1:    begin                            {SIZE}
        rdfp (rd, tparm_p^.tparm.size, stat);
        end;

2:    begin                            {WIDTH}
        rdfp (rd, tparm_p^.tparm.width, stat);
        end;

3:    begin                            {HEIGHT}
        rdfp (rd, tparm_p^.tparm.height, stat);
        end;

4:    begin                            {SLANT}
        rdfp (rd, tparm_p^.tparm.slant, stat);
        end;

5:    begin                            {ROT}
        rdfp (rd, tparm_p^.tparm.rot, stat);
        end;

6:    begin                            {LSPACE}
        rdfp (rd, tparm_p^.tparm.lspace, stat);
        end;

7:    begin                            {VWIDTH}
        rdfp (rd, tparm_p^.tparm.vect_width, stat);
        end;

8:    begin                            {FONT}
        if not rdtoken (rd, tparm_p^.tparm.font)
          then goto err_missing;
        end;

9:    begin                            {COOR}
        rdspace (rd, tparm_p^.tparm.coor_level, stat);
        end;

10:   begin                            {STORG}
        rdtorg (rd, tparm_p^.tparm.start_org, stat);
        end;

11:   begin                            {ENORG}
        rdtorg (rd, tparm_p^.tparm.end_org, stat);
        end;

12:   begin                            {POLY}
        rdbool (rd, tparm_p^.tparm.poly, stat);
        end;

otherwise
      sys_stat_set (displ_subsys_k, displ_stat_badval_k, stat);
      goto err_atline;
      end;                             {end of subcommand cases}
    if sys_error(stat) then return;
    if not end_of_line (rd, stat) then return;
    end;                               {back for next TPARM subcommand}

  tparm_p^.id := id;                   {save the ID}
  rd.tparms_p^[id] := tparm_p;         {save pointer to TPARM of this ID}
  return;                              {normal return point, no error}
{
*   Error, bad syntax in file.
}
err_syn:
  sys_stat_set (displ_subsys_k, displ_stat_errsyn_k, stat);
  goto err_atline;
{
*   Error, missing parameter.
}
err_missing:
  sys_stat_set (displ_subsys_k, displ_stat_noparm_k, stat);
  goto err_atline;
{
*   Error exit to add line number and file name to STAT.  STAT must already be
*   set, and the next two parameters must be the line number and the file name.
}
err_atline:
  err_line_file (rd, stat);            {add line number and file name to STAT}
  end;
{
********************************************************************************
*
*   Local subroutine RD_VECT (RD, LEDIT, STAT)
*
*   Read a chain of vectors definition from the input file and add it to the
*   list being edited at LEDIT.  The edit position will be moved to the new
*   vectors chain.  The VECT keyword has just bee read.
}
procedure rd_vect (                    {read vectors chain, add to list}
  in out  rd: rd_t;                    {input file reading state}
  in out  ledit: displ_edit_t;         {list editing state}
  in out  stat: sys_err_t);            {completion status, set to no err on entry}
  val_param; internal;

var
  edvect: displ_edvect_t;              {VECT item editing state}
  x, y: real;                          {2D coordinate}
  cmd: string_var32_t;                 {command name}
  pick: sys_int_machine_t;             {number of keyword picked from list}
  id: sys_int_machine_t;

label
  err_syn, err_atline;

begin
  cmd.max := size_char(cmd.str);

  if not end_of_line (rd, stat) then return; {must be end of VECT command}

  displ_item_new (ledit);              {create new list item}
  displ_item_vect (ledit);             {make the new item a vectors list}
  displ_edvect_init (edvect, ledit.item_p^); {init VECT item editing state}

  block_start (rd);                    {down one level into VECT block}
  while rdline (rd, stat) do begin     {loop over all the VPARM subcommands}
    if not rdkeyw (rd, cmd) then goto err_syn; {get this command name}
    string_tkpick80 (cmd,              {pick the command name from the list}
      'COLOR VPARM P',
      pick);
    case pick of                       {which command is it ?}

1:    begin                            {COLOR}
        rdint (rd, id, stat);          {get the color ID}
        if sys_error(stat) then return;
        if (id < 1) or (id > rd.ncolors) then begin
          sys_stat_set (displ_subsys_k, displ_stat_badcolid_k, stat);
          sys_stat_parm_int (id, stat);
          goto err_atline;
          end;
        if rd.colors_p^[id] = nil then begin
          sys_stat_set (displ_subsys_k, displ_stat_undefcol_k, stat);
          sys_stat_parm_int (id, stat);
          goto err_atline;
          end;
        ledit.item_p^.vect_color_p := rd.colors_p^[id]; {set color}
        end;

2:    begin                            {VPARM}
        rdint (rd, id, stat);          {get the VPARM ID}
        if sys_error(stat) then return;
        if (id < 1) or (id > rd.nvparms) then begin
          sys_stat_set (displ_subsys_k, displ_stat_badvpid_k, stat);
          sys_stat_parm_int (id, stat);
          goto err_atline;
          end;
        if rd.vparms_p^[id] = nil then begin
          sys_stat_set (displ_subsys_k, displ_stat_undefvp_k, stat);
          sys_stat_parm_int (id, stat);
          goto err_atline;
          end;
        ledit.item_p^.vect_parm_p := rd.vparms_p^[id]; {set vector parameters}
        end;

3:    begin                            {P}
        rdfp (rd, x, stat);            {read X}
        if sys_error(stat) then return;
        rdfp (rd, y, stat);            {read Y}
        if sys_error(stat) then return;
        displ_edvect_add (edvect, x, y); {add this coordinate to vectors chain}
        end;

otherwise
      sys_stat_set (displ_subsys_k, displ_stat_badcmd_k, stat);
      sys_stat_parm_vstr (cmd, stat);
      goto err_atline;
      end;                             {end of subcommand cases}
    if sys_error(stat) then return;
    if not end_of_line (rd, stat) then return;
    end;                               {back for next VPARM subcommand}
  return;                              {normal return point, no error}
{
*   Error, bad syntax in file.
}
err_syn:
  sys_stat_set (displ_subsys_k, displ_stat_errsyn_k, stat);
  goto err_atline;
{
*   Error exit to add line number and file name to STAT.  STAT must already be
*   set, and the next two parameters must be the line number and the file name.
}
err_atline:
  err_line_file (rd, stat);            {add line number and file name to STAT}
  end;
{
********************************************************************************
*
*   Local subroutine RD_IMAGE (RD, STAT)
*
*   Read the description of one external image.  The IMAGE keyword has been
*   read.
}
procedure rd_image (                   {read IMAGE command}
  in out  rd: rd_t;                    {input file reading state}
  in out  stat: sys_err_t);            {completion status, set to no err on entry}
  val_param; internal;

var
  id: sys_int_machine_t;               {1-N ID}
  name: string_treename_t;             {image file name}
  conn: img_conn_t;                    {connection to the image file}
  img_p: displ_img_p_t;                {pointer to descriptor for this new image}
  ii: sys_int_machine_t;               {scratch integer and loop counter}
  scan_p: img_scan1_arg_p_t;           {pointer to image scan line}

label
  err_syn, err_atline;

begin
  name.max := size_char(name.str);     {init local var string}

  rdint (rd, id, stat);                {get the ID of this image}
  if sys_error(stat) then return;

  if (id < 1) or (id > rd.nlists) then begin
    sys_stat_set (displ_subsys_k, displ_stat_badlistid_k, stat);
    sys_stat_parm_int (id, stat);
    goto err_atline;
    end;
  img_p := addr(rd.imgs_p^[id]);       {get pointer to descriptor for this ID}

  if img_p^.id <> 0 then begin         {this descriptor already filled in ?}
    sys_stat_set (displ_subsys_k, displ_stat_dupimg_k, stat);
    sys_stat_parm_int (id, stat);
    goto err_atline;
    end;

  if not rdtoken (rd, name) then goto err_syn; {get the image file name}
  if not end_of_line (rd, stat) then return;

  img_open_read_img (                  {open the image file}
    name, conn, stat);
  if sys_error(stat) then return;

  img_p^.id := id;                     {save the ID of this image}
  string_alloc (                       {allocate mem for full pathname}
    conn.tnam.len, rd.mem_perm_p^, false, img_p^.tnam_p);
  string_copy (conn.tnam, img_p^.tnam_p^); {save absolute image file pathname}
  img_p^.dx := conn.x_size;            {save image size in pixels}
  img_p^.dy := conn.y_size;
  img_p^.aspect := conn.aspect;        {save aspect ratio}

  util_mem_grab (                      {allocate memory for the image pixels}
    sizeof(img_p^.pix_p^[0]) * img_p^.dx * img_p^.dy, {amount of memory to allocate}
    rd.mem_perm_p^,                    {parent memory context}
    false,                             {won't individually deallocate}
    img_p^.pix_p);                     {returned pointer to the new memory}

  scan_p := img_p^.pix_p;              {init pointer to where to save first scan line}
  for ii := 1 to img_p^.dy do begin    {down the scan lines}
    img_read_scan1 (conn, scan_p^, stat); {read and save this scan line}
    if sys_error(stat) then return;
    scan_p := univ_ptr(                {advance write pointer to next scan line}
      sys_int_adr_t(scan_p) + sizeof(img_p^.pix_p^[0]) * img_p^.dx);
    end;                               {back to get next scan line}
  img_close (conn, stat);              {close the image file}
  if sys_error(stat) then return;

  return;
{
*   Error, bad syntax in file.
}
err_syn:
  sys_stat_set (displ_subsys_k, displ_stat_errsyn_k, stat);
  goto err_atline;
{
*   An error has occurred and STAT has been partially set.  The current line
*   number and file name will be added to STAT before returning to the caller
*   with the error.
}
err_atline:
  err_line_file (rd, stat);
  end;
{
********************************************************************************
*
*   Local subroutine RD_LIST_IMAGE (RD, LEDIT, STAT)
*
*   Read the rest of the LIST IMAGE command, and add the image reference to the
*   list being edited at LEDIT.  The IMAGE keyword has just been read.
}
procedure rd_list_image (              {read LIST IMAGE command}
  in out  rd: rd_t;                    {input file reading state}
  in out  ledit: displ_edit_t;         {list editing state}
  in out  stat: sys_err_t);            {completion status, set to no err on entry}
  val_param; internal;

var
  id: sys_int_machine_t;               {image ID}
  cmd: string_var32_t;                 {command name}
  pick: sys_int_machine_t;             {number of keyword picked from list}

label
  err_syn, err_atline;

begin
  cmd.max := size_char(cmd.str);       {init local var string}

  rdint (rd, id, stat);                {get the image ID}
  if sys_error(stat) then return;
  if not end_of_line (rd, stat) then return; {end of IMAGE command line}

  if (id < 1) or (id > rd.nimgs) then begin {image ID is out of range ?}
    sys_stat_set (displ_subsys_k, displ_stat_badimgid_k, stat);
    goto err_atline;
    end;

  displ_item_new (ledit);              {create new list item}
  displ_item_image (ledit, rd.imgs_p^[id]); {make image overlay item, and init}

  block_start (rd);                    {down one level into IMAGE block}
  while rdline (rd, stat) do begin     {back here each new line in IMAGE block}
    if not rdkeyw (rd, cmd) then goto err_syn; {get this command name}
    string_tkpick80 (cmd,              {pick the command name from the list}
      'RECT XB YB OFS',
      pick);
    case pick of                       {which command is it ?}

1:    begin                            {RECT lft rit bot top}
        rdfp (rd, ledit.item_p^.img_lft, stat);
        if sys_error(stat) then return;
        rdfp (rd, ledit.item_p^.img_rit, stat);
        if sys_error(stat) then return;
        rdfp (rd, ledit.item_p^.img_bot, stat);
        if sys_error(stat) then return;
        rdfp (rd, ledit.item_p^.img_top, stat);
        if sys_error(stat) then return;
        end;

2:    begin                            {XB x y}
        rdfp (rd, ledit.item_p^.img_xf.xb.x, stat);
        if sys_error(stat) then return;
        rdfp (rd, ledit.item_p^.img_xf.xb.y, stat);
        if sys_error(stat) then return;
        end;

3:    begin                            {YB x y}
        rdfp (rd, ledit.item_p^.img_xf.yb.x, stat);
        if sys_error(stat) then return;
        rdfp (rd, ledit.item_p^.img_xf.yb.y, stat);
        if sys_error(stat) then return;
        end;

4:    begin                            {OFS x y}
        rdfp (rd, ledit.item_p^.img_xf.ofs.x, stat);
        if sys_error(stat) then return;
        rdfp (rd, ledit.item_p^.img_xf.ofs.y, stat);
        if sys_error(stat) then return;
        end;

otherwise                              {unrecognized command}
      sys_stat_set (displ_subsys_k, displ_stat_badcmd_k, stat);
      goto err_atline;
      end;                             {end of command keyword cases}

    if not end_of_line (rd, stat) then return; {nothing more allowed after this command}
    end;                               {back to get the next command}

  return;
{
*   Error, bad syntax in file.
}
err_syn:
  sys_stat_set (displ_subsys_k, displ_stat_errsyn_k, stat);
  goto err_atline;
{
*   Error exit to add line number and file name to STAT.  STAT must already be
*   set, and the next two parameters must be the line number and the file name.
}
err_atline:
  err_line_file (rd, stat);            {add line number and file name to STAT}
  end;
{
********************************************************************************
*
*   Local subroutine RD_LIST (RD, STAT)
*
*   Read and save a display list.  The LIST command keyword has been read.
}
procedure rd_list (                    {read LIST command}
  in out  rd: rd_t;                    {input file reading state}
  in out  stat: sys_err_t);            {completion status, set to no err on entry}
  val_param; internal;

var
  id: sys_int_machine_t;               {1-N ID}
  list_p: displ_p_t;                   {pointer to list being added to}
  ledit: displ_edit_t;                 {list editing state}
  cmd: string_var32_t;                 {command name}
  pick: sys_int_machine_t;             {number of keyword picked from list}

label
  err_syn, err_atline;

begin
  cmd.max := size_char(cmd.str);       {init local var string}

  rdint (rd, id, stat);                {get the ID of this list}
  if sys_error(stat) then return;
  if not end_of_line (rd, stat) then return;

  if (id < 1) or (id > rd.nlists) then begin
    sys_stat_set (displ_subsys_k, displ_stat_badlistid_k, stat);
    sys_stat_parm_int (id, stat);
    goto err_atline;
    end;
  list_p := rd.lists_p^[id];           {get pointer to the list}
  if list_p = nil then begin           {list doesn't previously exist ?}
    util_mem_grab (                    {allocate memory for the list descriptor}
      sizeof(list_p^), rd.mem_perm_p^, true, list_p);
    displ_list_new (rd.mem_perm_p^, list_p^); {initialize the list}
    list_p^.id := id;                  {indicate our internal ID for this list}
    rd.lists_p^[id] := list_p;         {save pointer to list of this ID}
    end;

  displ_edit_init (ledit, list_p^);    {init list editing state to start of list}

  block_start (rd);                    {down one level into LIST block}
  while rdline (rd, stat) do begin     {back here each new line in the LIST block}
    if not rdkeyw (rd, cmd) then goto err_syn; {get this command name}
    string_tkpick80 (cmd,              {pick the command name from the list}
      'COLOR VPARM TPARM VECT IMAGE',
      pick);
    case pick of                       {which command is it}

1:    begin                            {COLOR}
        rdint (rd, id, stat);          {get the color ID}
        if sys_error(stat) then return;
        if (id < 1) or (id > rd.ncolors) then begin
          sys_stat_set (displ_subsys_k, displ_stat_badcolid_k, stat);
          sys_stat_parm_int (id, stat);
          goto err_atline;
          end;
        if rd.colors_p^[id] = nil then begin
          sys_stat_set (displ_subsys_k, displ_stat_undefcol_k, stat);
          sys_stat_parm_int (id, stat);
          goto err_atline;
          end;
        list_p^.rend.color_p := rd.colors_p^[id]; {set list default color}
        end;

2:    begin                            {VPARM}
        rdint (rd, id, stat);          {get the VPARM ID}
        if sys_error(stat) then return;
        if (id < 1) or (id > rd.nvparms) then begin
          sys_stat_set (displ_subsys_k, displ_stat_badvpid_k, stat);
          sys_stat_parm_int (id, stat);
          goto err_atline;
          end;
        if rd.vparms_p^[id] = nil then begin
          sys_stat_set (displ_subsys_k, displ_stat_undefvp_k, stat);
          sys_stat_parm_int (id, stat);
          goto err_atline;
          end;
        list_p^.rend.vect_parm_p := rd.vparms_p^[id]; {set list default VPARM}
        end;

3:    begin                            {TPARM}
        rdint (rd, id, stat);          {get the TPARM ID}
        if sys_error(stat) then return;
        if (id < 1) or (id > rd.ntparms) then begin
          sys_stat_set (displ_subsys_k, displ_stat_badtpid_k, stat);
          sys_stat_parm_int (id, stat);
          goto err_atline;
          end;
        if rd.tparms_p^[id] = nil then begin
          sys_stat_set (displ_subsys_k, displ_stat_undeftp_k, stat);
          sys_stat_parm_int (id, stat);
          goto err_atline;
          end;
        list_p^.rend.text_parm_p := rd.tparms_p^[id]; {set list default TPARM}
        end;

4:    begin                            {VECT}
        rd_vect (rd, ledit, stat);     {read vectors chain, add it to the list}
        if sys_error(stat) then return;
        next;                          {back for next command in this LIST block}
        end;

5:    begin                            {IMAGE n}
        rd_list_image (rd, ledit, stat); {read image reference, add it to the list}
        if sys_error(stat) then return;
        next;                          {back for next command in this LIST block}
        end;

otherwise                              {unrecognized LIST subcommand}
      sys_stat_set (displ_subsys_k, displ_stat_badcmd_k, stat);
      sys_stat_parm_vstr (cmd, stat);
      goto err_atline;
      end;                             {end of LIST subcommand cases}

    if not end_of_line (rd, stat) then return;
    end;                               {back for next LIST subcommand}

  return;                              {normal exit point}
{
*   Error, bad syntax in file.
}
err_syn:
  sys_stat_set (displ_subsys_k, displ_stat_errsyn_k, stat);
  goto err_atline;
{
*   An error has occurred and STAT has been partially set.  The current line
*   number and file name will be added to STAT before returning to the caller
*   with the error.
}
err_atline:
  err_line_file (rd, stat);
  end;
{
********************************************************************************
*
*   Subroutine DISPL_FILE_READ (FNAM, DISPL, STAT)
*
*   Read the information in a display list file, and add it to the start of the
*   display list DISPL.
}
procedure displ_file_read (            {read display list from file}
  in      fnam: univ string_var_arg_t; {file name, will always end in ".displ"}
  in out  displ: displ_t;              {display list to add file data to the start of}
  out     stat: sys_err_t);            {returned completion status}
  val_param;

var
  rd: rd_t;                            {file reading state}
  cmd: string_var32_t;                 {command name}
  pick: sys_int_machine_t;             {number of keyword picked from list}
  ii: sys_int_machine_t;               {scratch integer}

label
  done_cmd, err_val, err_syn, err_atline, leave;

begin
  cmd.max := size_char(cmd.str);

  displ_file_read_open (fnam, displ.mem_p^, rd, stat); {open the file to read}
  if sys_error(stat) then return;      {hard error ?}

  while rdline (rd, stat) do begin     {loop over all the top level commands}
    if not rdkeyw (rd, cmd) then goto err_syn; {get this command name}
    string_tkpick80 (cmd,              {pick the command name from the list}
      'LISTS COLORS VPARMS TPARMS COLOR VPARM TPARM LIST IMAGES IMAGE',
      pick);
    case pick of                       {which command is it}

1:    begin                            {LISTS n}
        if rd.lists_p <> nil then begin
          sys_stat_set (displ_subsys_k, displ_stat_2lists_k, stat);
          goto err_atline;
          end;
        rdint (rd, ii, stat);          {get number of lists}
        if sys_error(stat) then goto leave;
        if ii < 1 then goto err_val;
        if not end_of_line (rd, stat) then goto leave;
        rd.nlists := ii;               {save number of lists}
        util_mem_grab (                {allocate mem for lists list}
          sizeof(rd.lists_p^[1]) * rd.nlists, {amount of memory to allocate}
          rd.mem_temp_p^,              {memory context}
          false,                       {will not individually deallocate}
          rd.lists_p);                 {returned pointer to the new memory}
        rd.lists_p^[1] := addr(displ); {set pointer to the top level list}
        for ii := 2 to rd.nlists do begin {init remaining lists to undefined}
          rd.lists_p^[ii] := nil;
          end;
        end;

2:    begin                            {COLORS n}
        if rd.colors_p <> nil then begin
          sys_stat_set (displ_subsys_k, displ_stat_2colors_k, stat);
          goto err_atline;
          end;
        rdint (rd, ii, stat);          {get number of colors}
        if sys_error(stat) then goto leave;
        if not end_of_line (rd, stat) then goto leave;
        if ii < 1 then goto err_val;
        rd.ncolors := ii;              {save number of colors}
        util_mem_grab (                {allocate mem for colors list}
          sizeof(rd.colors_p^[1]) * rd.ncolors, {amount of memory to allocate}
          rd.mem_temp_p^,              {memory context}
          false,                       {will not individually deallocate}
          rd.colors_p);                {returned pointer to the new memory}
        for ii := 1 to rd.ncolors do begin {init all colors to undefined}
          rd.colors_p^[ii] := nil;
          end;
        end;

3:    begin                            {VPARMS n}
        if rd.vparms_p <> nil then begin
          sys_stat_set (displ_subsys_k, displ_stat_2vparms_k, stat);
          goto err_atline;
          end;
        rdint (rd, ii, stat);          {get number of vparms}
        if sys_error(stat) then goto leave;
        if ii < 1 then goto err_val;
        if not end_of_line (rd, stat) then goto leave;
        rd.nvparms := ii;              {save number of vparms}
        util_mem_grab (                {allocate mem for vparms list}
          sizeof(rd.vparms_p^[1]) * rd.nvparms, {amount of memory to allocate}
          rd.mem_temp_p^,              {memory context}
          false,                       {will not individually deallocate}
          rd.vparms_p);                {returned pointer to the new memory}
        for ii := 1 to rd.nvparms do begin {init all vparms to undefined}
          rd.vparms_p^[ii] := nil;
          end;
        end;

4:    begin                            {TPARMS n}
        if rd.tparms_p <> nil then begin
          sys_stat_set (displ_subsys_k, displ_stat_2tparms_k, stat);
          goto err_atline;
          end;
        rdint (rd, ii, stat);          {get number of tparms}
        if sys_error(stat) then goto leave;
        if ii < 1 then goto err_val;
        if not end_of_line (rd, stat) then goto leave;
        rd.ntparms := ii;              {save number of tparms}
        util_mem_grab (                {allocate mem for tparms list}
          sizeof(rd.tparms_p^[1]) * rd.ntparms, {amount of memory to allocate}
          rd.mem_temp_p^,              {memory context}
          false,                       {will not individually deallocate}
          rd.tparms_p);                {returned pointer to the new memory}
        for ii := 1 to rd.ntparms do begin {init all tparms to undefined}
          rd.tparms_p^[ii] := nil;
          end;
        end;

9:    begin                            {IMAGES n}
        if rd.imgs_p <> nil then begin
          sys_stat_set (displ_subsys_k, displ_stat_2imgs_k, stat);
          goto err_atline;
          end;
        rdint (rd, ii, stat);          {get number of images}
        if sys_error(stat) then goto leave;
        if not end_of_line (rd, stat) then goto leave;
        rd.nimgs := ii;                {save number of imgs}
        if rd.nimgs <= 0 then goto done_cmd; {no images, nothing more to do ?}

        util_mem_grab (                {allocate mem for imgs list}
          sizeof(rd.imgs_p^[1]) * rd.nimgs, {amount of memory to allocate}
          rd.mem_perm_p^,              {memory context}
          false,                       {will not individually deallocate}
          rd.imgs_p);                  {returned pointer to the new memory}
        for ii := 1 to rd.nimgs do begin {init all images to undefined}
          rd.imgs_p^[ii].id := 0;
          end;
        end;

5:    begin                            {COLOR n red grn blu opac}
        rd_color (rd, stat);           {process the command}
        end;

6:    begin                            {VPARM n}
        rd_vparm (rd, stat);
        end;

7:    begin                            {TPARM n}
        rd_tparm (rd, stat);
        end;

10:   begin                            {IMAGE n}
        rd_image (rd, stat);
        end;

8:    begin                            {LIST n}
        rd_list (rd, stat);
        end;

otherwise                              {unrecognized command name}
      sys_stat_set (displ_subsys_k, displ_stat_badcmd_k, stat);
      sys_stat_parm_vstr (cmd, stat);
      goto err_atline;
      end;                             {end of command cases}

done_cmd:                              {done processing this command}
    if sys_error(stat) then goto leave;
    end;                               {back to get and process the next command}
  goto leave;                          {exit with current STAT}
{
*   Error, bad value read from file.
}
err_val:
  sys_stat_set (displ_subsys_k, displ_stat_badval_k, stat);
  goto err_atline;
{
*   Error, bad syntax in file.
}
err_syn:
  sys_stat_set (displ_subsys_k, displ_stat_errsyn_k, stat);
  goto err_atline;
{
*   Error exit to add line number and file name to STAT.  STAT must already be
*   set, and the next two parameters must be the line number and the file name.
}
err_atline:
  err_line_file (rd, stat);            {add line qnumber and file name to STAT}
{
*   Common exit point.  STAT must already be set.  All locally allocated
*   resources will be released.
}
leave:
  displ_file_read_close (rd);          {close file, deallocate resources for reading}
  end;
