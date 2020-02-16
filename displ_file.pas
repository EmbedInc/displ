{   Routines for reading/writing display lists to/from files.
*
*   Quick reference of routines for writing to the output file:
*
*     DISPL_FILE_OPEN (FNAM, OS, STAT)
*
*     WLINE (OS)  -  Write current output line to file, reset line to empty.
*
*     BLANKLINE (OS)  -  Write blank line unless at start of file.
*
*     WVSTR (OS, VSTR)  -  Append var string to output line.
*
*     WSTR (OS, STR)  -  Append Pascal string to output line.
*
*     WVTK (OS, VSTR)  -  Append var string as single token to output line.
*
*     WTK (OS, STR)  -  Append Pascal string as single token to output line.
*
*     WINT (OS, II)  -  Append integer token to output line.
*
*     WFPF (OS, FP, NF)  -  Append FP to output line, NF fraction digits.
*
*     WFPS (OS, FP, SIG)  -  Append FP to output line, SIG significant digits.
*
*     BLOCK_START (OS)  -  Start nested block.
*
*     BLOCK_END (OS)  -  End nested block.
}
module displ_file;
define displ_file_write;
%include 'displ2.ins.pas';

type
  outstate_t = record                  {output file writing state}
    conn: file_conn_t;                 {connection to the output file}
    buf: string_var80_t;               {one line output buffer}
    blklev: sys_int_machine_t;         {block nesting level, 0 at top}
    stat_p: sys_err_p_t;               {points to STAT to write error status to}
    end;
{
********************************************************************************
*
*   Local subroutine DISPL_FILE_OPEN (FNAM, OS, STAT)
*
*   Open the output file FNAM and set up the output file writing state OS
*   accordingly.
}
procedure displ_file_open (            {open output file}
  in      fnam: univ string_var_arg_t; {file name, will always end in ".displ"}
  out     os: outstate_t;              {returned output file writing state}
  in out  stat: sys_err_t);            {completion status}
  val_param;

begin
  file_open_write_text (               {open the output file}
    fnam, '.displ',                    {file name and suffix}
    os.conn,                           {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  os.buf.max := size_char(os.buf.str); {init output buffer var string}
  os.buf.len := 0;                     {init the output buffer to empty}
  os.blklev := 0;                      {init to not within any block}
  os.stat_p := addr(stat);             {set pointer to STAT to set on errors}
  end;
{
********************************************************************************
*
*   Local function WLINE (OS)
*
*   Write the contents of the output buffer to the output file, then reset the
*   output buffer to empty.  STAT is set accordingly.
*
*   The function returns TRUE on no error, FALSE on error.
}
function wline (                       {write line to file, reset line to empty}
  in out  os: outstate_t)              {output file writing state}
  :boolean;                            {no error}
  val_param;

begin
  file_write_text (os.buf, os.conn, os.stat_p^); {write the output buffer to the file}
  os.buf.len := 0;                     {reset the output buffer to empty}
  wline := not sys_error(os.stat_p^);  {return success indication}
  end;
{
********************************************************************************
*
*   Local subroutine BLANKLINE (OS)
*
*   Write a blank line to the output file, unless at the start of the file.  Any
*   existing but unwritten output line is written first.
}
procedure blankline (                  {write blank line unless at start of file}
  in out  os: outstate_t);             {output file writing state}
  val_param;

begin
  if os.buf.len > 0 then begin         {write any unwritten output content}
    if not wline(os) then return;
    end;

  if os.conn.lnum > 0 then begin       {not at start of file ?}
    if not wline(os) then return;
    end;
  end;
{
********************************************************************************
*
*   Local subroutine WVSTR (OS, VSTR)
*
*   Write the var string VSTR to the output line.  If the output line is
*   currently empty, then indentation according to the current block nesting
*   level is written before the string.
}
procedure wvstr (                      {write var string to the output line}
  in out  os: outstate_t;              {output file writing state}
  in      vstr: univ string_var_arg_t); {the string to write}
  val_param;

var
  nsp: sys_int_machine_t;              {number of leading spaces for indentation}

begin
  if os.buf.len <= 0 then begin        {this is first item on the output line ?}
    nsp := os.blklev * 2;              {make number of blanks to add for indentation}
    while nsp > 0 do begin             {add the leading blanks for indentation}
      string_append1 (os.buf, ' ');
      nsp := nsp - 1;                  {count one less leading blank left to write}
      end;
    end;

  string_append (os.buf, vstr);        {append the string to the output line}
  end;
{
********************************************************************************
*
*   Local subroutine WSTR (OS, STR)
*
*   Write the Pascal string STR to the output line.
}
procedure wstr (                       {write Pascal string to output line}
  in out  os: outstate_t;              {output file writing state}
  in      str: string);                {the string to write}
  val_param;

var
  vstr: string_var80_t;

begin
  vstr.max := size_char(vstr.str);     {init local var string}

  string_vstring (vstr, str, size_char(str)); {convert to var string}
  wvstr (os, vstr);                    {write the var string to the output line}
  end;
{
********************************************************************************
*
*   Local subroutine WVTK (OS, VSTR)
*
*   Write the var string VSTR as a separate token to the output line.  A
*   preceeding blank is written, as necessary, to separate the token from any
*   previous content on the line.
}
procedure wvtk (                       {write var string as token to output line}
  in out  os: outstate_t;              {output file writing state}
  in      vstr: univ string_var_arg_t); {var string to write as single token}
  val_param;

var
  tk: string_var80_t;                  {single-token version of input string}

begin
  tk.max := size_char(tk.str);         {init local var string}
  string_token_make (vstr, tk);        {make single token from the input string}

  if os.buf.len > 0 then begin         {the output line has previous contents ?}
    wstr (os, ' ');                    {write blank separator before the token}
    end;
  wvstr (os, tk);                      {write the token to the output line}
  end;
{
********************************************************************************
*
*   Local subroutine WTK (OS, STR)
*
*   Write the Pascal string STR as a separate token to the output line.  A
*   preceeding blank is written, as necessary, to separate the token from any
*   previous content on the line.
}
procedure wtk (                        {write Pascal string as token to output line}
  in out  os: outstate_t;              {output file writing state}
  in      str: string);                {the string to write}
  val_param;

var
  vstr: string_var80_t;

begin
  vstr.max := size_char(vstr.str);     {init local var string}

  string_vstring (vstr, str, size_char(str)); {convert to var string}
  wvtk (os, vstr);                     {write the var string as token to output line}
  end;
{
********************************************************************************
*
*   Local subroutine WINT (OS, II)
*
*   Write the integer value II to the output line as a separate token.
}
procedure wint (                       {write integer token to output line}
  in out  os: outstate_t;              {output file writing state}
  in      ii: sys_int_machine_t);      {integer value to write}
  val_param;

var
  tk: string_var32_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_f_int (tk, ii);               {make integer string}
  wvtk (os, tk);                       {append it as token to the output file}
  end;
{
********************************************************************************
*
*   Local subroutine WFPF (OS, FP, NF)
*
*   Write the floating point value FP to the output line as a separate token.
*   The value will be written with NF fraction digits (digits to the right of
*   the decimal point).
}
procedure wfpf (                       {write FP token to output, N fraction digits}
  in out  os: outstate_t;              {output file writing state}
  in      fp: real;                    {the floating point value to write}
  in      nf: sys_int_machine_t);      {number of fraction digits}
  val_param;

var
  tk: string_var32_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_f_fp_fixed (tk, fp, nf);      {make FP string}
  wvtk (os, tk);                       {append it as token to the output file}
  end;
{
********************************************************************************
*
*   Local subroutine WFPS (OS, FP, SIG)
*
*   Write the floating point value FP to the output line as a separate token.
*   The value will be written with SIG significant digits.
}
procedure wfps (                       {write FP token to output, N significant digits}
  in out  os: outstate_t;              {output file writing state}
  in      fp: real;                    {the floating point value to write}
  in      sig: sys_int_machine_t);     {number of significant digits to write}
  val_param;

var
  tk: string_var32_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_f_fp_free (tk, fp, sig);      {make FP string}
  wvtk (os, tk);                       {append it as token to the output file}
  end;
{
********************************************************************************
*
*   Local subroutine BLOCK_START (OS)
*
*   Indicate that subsequent output file writing will be one nesting level lower
*   within the block structure.
}
procedure block_start (                {start a new subordinate block}
  in out  os: outstate_t);             {output file writing state to update}
  val_param;

begin
  os.blklev := os.blklev + 1;          {indicate one more level within nested blocks}
  end;
{
********************************************************************************
*
*   Local subroutine BLOCK_END (OS)
*
*   Indicate that subsequent output file writing will be one nesting level up
*   within the block structure.
}
procedure block_end (                  {end the current subordinate block}
  in out  os: outstate_t);             {output file writing state to update}
  val_param;

begin
  if os.blklev > 0                     {not already at top nesting level ?}
    then os.blklev := os.blklev - 1;   {indicate one level up in block hierarchy}
  end;
{
********************************************************************************
*
*   Local subroutine DISPL_FILE_WRITE_DISPL (OS, DISPL)
*
*   Write the contents of the display list DISPL to the display list file open
*   on CONN.
}
procedure displ_file_write_displ (     {write single display list to output file}
  in out  os: outstate_t;              {output file writing state}
  in      displ: displ_t);             {the display list to write}
  val_param;

var
  item_p: displ_item_p_t;              {pointer to current item in the list}
  coor2d_p: displ_coor2d_ent_p_t;      {points to current entry in 2D coor list}

label
  done_item;

begin
  blankline (os);                      {leave space before this list}

  wstr (os, 'LIST');                   {start the list}
  wint (os, displ.id);                 {ID of this list}
  if not wline(os) then return;
  block_start (os);                    {now with this LIST block}

  item_p := displ.first_p;             {init to first item in the display list}
  while item_p <> nil do begin         {loop over all the items in this display list}
    case item_p^.item of               {what kind of item is this ?}

displ_item_none_k: begin               {unused item, don't write to file}
        end;

displ_item_list_k: begin               {subordinate display list}
        wstr (os, 'LIST');             {indicate subordinate list}
        wint (os, item_p^.list_sub_p^.id); {ID of list being referenced}
        if not wline(os) then return;
        end;

displ_item_vect_k: begin               {chain of vectors}
        coor2d_p := item_p^.vect_first_p; {init to first coordinate in list}
        if coor2d_p = nil              {no coordinates, ignore this item ?}
          then goto done_item;
        if coor2d_p^.next_p = nil      {only one coor, no vectors here ?}
          then goto done_item;
        wstr (os, 'VECT');             {start chain of vectors}
        if not wline(os) then return;
        block_start (os);              {now in VECT block}
        while coor2d_p <> nil do begin {loop over the chain of coordinates}
          wfps (os, coor2d_p^.x, 7);   {write X}
          wfps (os, coor2d_p^.y, 7);   {write Y}
          if not wline(os) then return;
          coor2d_p := coor2d_p^.next_p; {advance to next coordinate in chain}
          end;                         {back to process this new coordinate}
        block_end (os);                {now no longer in VECT block}
        end;

otherwise                              {unrecognized item type}
      writeln ('INTERNAL ERROR in DISPL_FILE_WRITE_DISPL.');
      writeln ('  Unrecognized display list item type with ID ', ord(item_p^.item));
      sys_bomb;
      end;                             {end of item type cases}

done_item:                             {done processing current item, on to next}
    item_p := item_p^.next_p;          {to next item in the display list}
    end;                               {back to process this new item}

  block_end (os);                      {done with this LIST block}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_FILE_WRITE (FNAM, DISPL, STAT)
*
*   Write the display list DISPL and all data it references to the file of name
*   FNAM.  The resulting file will always have the ".displ" suffix, whether that
*   is included in FNAM or not.
}
procedure displ_file_write (           {write display list DAG to file}
  in      fnam: univ string_var_arg_t; {file name, will always end in ".displ"}
  in out  displ: displ_t;              {top lev disp list, all referenced data written}
  out     stat: sys_err_t);            {returned completion status}
  val_param;

var
  os: outstate_t;                      {the complete output file writing state}
  dagl: displ_dagl_t;                  {flattened directed DAG list}
  ent_p: displ_dagl_ent_p_t;           {points to current entry in DAG list}
  col_p: displ_dagl_color_p_t;         {points to curr color list entry}
  vparm_p: displ_dagl_vparm_p_t;       {points to curr vect parms list entry}
  tparm_p: displ_dagl_tparm_p_t;       {points to curr text parms list entry}

label
  abort;

begin
  displ_file_open (fnam, os, stat);    {open file, set up output file writing state}
  if sys_error(stat) then return;

  displ_dagl_open (util_top_mem_context, dagl); {init the flattened DAG list}
  displ_dagl_displ (dagl, displ);      {build the DAG list, IDs for each disp list}

  wstr (os, 'LISTS');                  {indicate number of display lists in this file}
  wint (os, dagl.nlist);
  if not wline(os) then goto abort;

  wstr (os, 'COLORS');                 {indicate number of color parameter sets in file}
  wint (os, dagl.ncol);
  if not wline(os) then goto abort;

  wstr (os, 'VPARMS');                 {indicate number of vector parm sets in this file}
  wint (os, dagl.nvparm);
  if not wline(os) then goto abort;

  wstr (os, 'TPARMS');                 {indicate number of text parm sets in this file}
  wint (os, dagl.ntparm);
  if not wline(os) then goto abort;
{
*   Write the color sets.
}
  col_p := dagl.color_p;               {init to first list entry}
  while col_p <> nil do begin          {loop over the list entries}
    if col_p^.col_p^.id = 1 then begin {leave blank before start of color definitions}
      blankline (os);
      end;
    wstr (os, 'COLOR');
    wint (os, col_p^.col_p^.id);
    wfpf (os, col_p^.col_p^.red, 3);
    wfpf (os, col_p^.col_p^.grn, 3);
    wfpf (os, col_p^.col_p^.blu, 3);
    wfpf (os, col_p^.col_p^.opac, 3);
    if not wline(os) then goto abort;
    col_p := col_p^.next_p;            {to next list entry}
    end;                               {back to write this new list entry}
{
*   Write vector parameter sets.
}






{
*   Write text parameter sets.
}







  ent_p := dagl.last_p;                {init current list entry to last in list}
  while ent_p <> nil do begin          {scan list lowest to highest in hierarchy}
    displ_file_write_displ (os, ent_p^.list_p^); {write this list to file}
    if sys_error(stat) then goto abort;
    ent_p := ent_p^.prev_p;            {go to next higher DAG list entry}
    end;                               {back to do this next entry}

abort:                                 {skip to here on error with the file open}
  displ_dagl_close (dagl);             {deallocate DAG list resources}
  file_close (os.conn);                {close the output file}
  end;
