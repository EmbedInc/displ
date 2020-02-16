{   Routines that deal with a flattened display list structure formed from the
*   DAG (directed acyclic graph).  The flattened list is ordered so that any
*   list entry can only depend on later, not earlier, list entries.
}
module displ_dagl;
define displ_dagl_init;
define displ_dagl_close;
define displ_dagl_displ;
%include 'displ2.ins.pas';
{
********************************************************************************
*
*   Subroutine DISPL_DAGL_INIT (MEM, DAGL)
*
*   Initialize the linear DAG list DAGL.  MEM is the parent memory context.  A
*   subordinate memory context will be created, and all new memory for the list
*   will be allocated from that subordinate context.
}
procedure displ_dagl_init (            {init DAG list}
  in out  mem: util_mem_context_t;     {parent memory context}
  out     dagl: displ_dagl_t);         {the DAG list to initialize}
  val_param;

begin
  util_mem_context_get (mem, dagl.mem_p); {create the mem context for this DAG list}
  dagl.first_p := nil;                 {init the list to empty}
  dagl.last_p := nil;
  dagl.n := 0;
  dagl.ncol := 0;                      {no colors in list}
  dagl.nvparm := 0;                    {no vector parameters in the list}
  dagl.ntparm := 0;                    {no text parameters in the list}
  dagl.color_p := nil;                 {init the color list to empty}
  dagl.vparm_p := nil;                 {init the vector parameters list to empty}
  dagl.tparm_p := nil;                 {init the text parmeters list to empty}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_DAGL_CLOSE (DAGL)
*
*   End use of the DAG list DAGL, and deallocate any resources associated with
*   it.
}
procedure displ_dagl_close (           {end use of DAG list, deallocate resources}
  in out  dagl: displ_dagl_t);         {the list to close}
  val_param;

begin
  util_mem_context_del (dagl.mem_p);   {dealloc memory, delete private mem context}
  dagl.first_p := nil;
  dagl.last_p := nil;
  dagl.n := 0;
  dagl.ncol := 0;                      {no colors in list}
  dagl.nvparm := 0;                    {no vector parameters in the list}
  dagl.ntparm := 0;                    {no text parameters in the list}
  dagl.color_p := nil;                 {init the color list to empty}
  dagl.vparm_p := nil;                 {init the vector parameters list to empty}
  dagl.tparm_p := nil;                 {init the text parmeters list to empty}
  end;
{
********************************************************************************
*
*   Local subroutine DISPL_DAGL_COLOR (DAGL, COLOR_P)
*
*   Make sure that the color pointed to by COLOR_P is in the DAG colors list.
}
procedure displ_dagl_color (           {make sure color is in DAG list}
  in out  dagl: displ_dagl_t;          {the DAG list}
  in      color_p: displ_color_p_t);   {pointer to color to ensure in list}
  val_param;

var
  col_p: displ_dagl_color_p_t;         {pointer to color list entry}

begin
  if color_p = nil then return;        {no color, nothing to do ?}
{
*   Check for this color is already in the list.
}
  col_p := dagl.color_p;               {init to first existing list entry}
  while col_p <> nil do begin          {scan the existing list}
    if col_p^.col_p = color_p then return; {this color already in list ?}
    col_p := col_p^.next_p;            {to next list entry}
    end;                               {back to process this new list entry}
{
*   Create a new list entry for this color.
}
  util_mem_grab (                      {allocate mem for the color list entry}
    sizeof(col_p^), dagl.mem_p^, false, col_p);

  col_p^.next_p := dagl.color_p;       {link to start of list}
  dagl.color_p := col_p;
  col_p^.id := 0;                      {ID not yet assigned}
  col_p^.col_p := color_p;             {save pointer to the color}

  dagl.ncol := dagl.ncol + 1;          {count one more color list entry}
  end;
{
********************************************************************************
*
*   Local subroutine DISPL_DAGL_VPARM (DAGL, VPARM_P)
*
*   Make sure that the vector parameters pointed to by VPARM_P are in the DAG
*   vector parameters list.
}
procedure displ_dagl_vparm (           {make sure vector parameters are in DAG list}
  in out  dagl: displ_dagl_t;          {the DAG list}
  in      vparm_p: rend_vect_parms_p_t); {pointer to vector parms to ensure in list}
  val_param;

var
  ent_p: displ_dagl_vparm_p_t;         {pointer to vector parameters list entry}

begin
  if vparm_p = nil then return;        {no parameters, nothing to do ?}
{
*   Check for these parameters are already in the list.
}
  ent_p := dagl.vparm_p;               {init to first existing list entry}
  while ent_p <> nil do begin          {scan the existing list}
    if ent_p^.vparm_p = vparm_p then return; {these parms already in list ?}
    ent_p := ent_p^.next_p;            {to next list entry}
    end;                               {back to process this new list entry}
{
*   Create a new list entry for this vparm.
}
  util_mem_grab (                      {alloc mem for the vector parms list entry}
    sizeof(ent_p^), dagl.mem_p^, false, ent_p);

  ent_p^.next_p := dagl.vparm_p;       {link to start of list}
  dagl.vparm_p := ent_p;
  ent_p^.id := 0;                      {ID not yet assigned}
  ent_p^.vparm_p := vparm_p;           {save pointer to the parameters}

  dagl.nvparm := dagl.nvparm + 1;      {count one more vector parameters list entry}
  end;
{
********************************************************************************
*
*   Local subroutine DISPL_DAGL_TPARM (DAGL, TPARM_P)
*
*   Make sure that the text parameters pointed to by TPARM_P are in the DAG text
*   parameters list.
}
procedure displ_dagl_tparm (           {make sure text parameters are in DAG list}
  in out  dagl: displ_dagl_t;          {the DAG list}
  in      tparm_p: rend_text_parms_p_t); {pointer to text parms to ensure in list}
  val_param;

var
  ent_p: displ_dagl_tparm_p_t;         {pointer to text parameters list entry}

begin
  if tparm_p = nil then return;        {no parameters, nothing to do ?}
{
*   Check for these parameters are already in the list.
}
  ent_p := dagl.tparm_p;               {init to first existing list entry}
  while ent_p <> nil do begin          {scan the existing list}
    if ent_p^.tparm_p = tparm_p then return; {these parms already in list ?}
    ent_p := ent_p^.next_p;            {to next list entry}
    end;                               {back to process this new list entry}
{
*   Create a new list entry for this tparm.
}
  util_mem_grab (                      {alloc mem for the text parms list entry}
    sizeof(ent_p^), dagl.mem_p^, false, ent_p);

  ent_p^.next_p := dagl.tparm_p;       {link to start of list}
  dagl.tparm_p := ent_p;
  ent_p^.id := 0;                      {ID not yet assigned}
  ent_p^.tparm_p := tparm_p;           {save pointer to the parameters}

  dagl.ntparm := dagl.ntparm + 1;      {count one more text parameters list entry}
  end;
{
********************************************************************************
*
*   Local subroutine DISPL_DAGL_ENT_NEW (DAGL, POS_P, NEW_P)
*
*   Add a new display list entry to the DAG list DAGL.  The new entry will be
*   added immediately following the entry pointed to by POS_P.  POS_P may be
*   NIL, in which case the new entry is added to the start of the list.  NEW_P
*   is returned pointing to the new entry.
}
procedure displ_dagl_ent_new (         {add new entry to DAG list}
  in out  dagl: displ_dagl_t;          {list to add new entry to}
  in      pos_p: displ_dagl_ent_p_t;   {add new entry after this one, NIL at list start}
  out     new_p: displ_dagl_ent_p_t);  {returned pointer to the new entry}
  val_param;

begin
  util_mem_grab (                      {allocate memory for the new list entry}
    sizeof(new_p^), dagl.mem_p^, false, new_p);

  if pos_p = nil
    then begin                         {add to start of list}
      new_p^.next_p := dagl.first_p;
      dagl.first_p := new_p;
      new_p^.prev_p := nil;
      end
    else begin                         {adding after a existing list entry}
      new_p^.next_p := pos_p^.next_p;
      pos_p^.next_p := new_p;
      new_p^.prev_p := pos_p;
      end
    ;
  if new_p^.next_p = nil
    then begin                         {new entry is at end of list ?}
      dagl.last_p := new_p;
      end
    else begin                         {there is a following entry}
      new_p^.next_p^.prev_p := new_p;
      end
    ;

  dagl.n := dagl.n + 1;                {count one more entry in the DAG list}

  new_p^.list_p := nil;                {init remaining fields of the new entry}
  new_p^.id := 0;
  end;
{
********************************************************************************
*
*   Local subroutine DISPL_DAGL_DISPL_ADD (DAGL, POS_P, DISPL)
*
*   Add the display list DISPL and all its subordinate lists to the DAG list
*   DAGL after the entry pointed to by POS_P.  POS_P may be NIL, which causes
*   the display list to be added at the start of the DAG list.
*
*   The IDs of new entries are left unassigned.
}
procedure displ_dagl_displ_add (       {add display list to DAG list}
  in out  dagl: displ_dagl_t;          {the DAG list to add to}
  in      pos_p: displ_dagl_ent_p_t;   {add after this entry, NIL for list start}
  in var  displ: displ_t);             {the display list to add, with subordinates}
  val_param;

var
  top_p: displ_dagl_ent_p_t;           {points to entry for DISPL}
  ent_p: displ_dagl_ent_p_t;           {points to current DAG list entry}
  item_p: displ_item_p_t;              {points to current item in display list}

label
  next_ent;

begin
  displ_dagl_ent_new (dagl, pos_p, top_p); {create top level entry for display list}
  top_p^.list_p := addr(displ);        {fill in the entry}

  displ_dagl_color (dagl, displ.rend.color_p); {make rendering states in their lists}
  displ_dagl_vparm (dagl, displ.rend.vect_parm_p);
  displ_dagl_tparm (dagl, displ.rend.text_parm_p);

  item_p := displ.first_p;             {init to first item in the display list}
  while item_p <> nil do begin         {scan the items in this display list}
    case item_p^.item of               {what kind of display list item is this ?}

displ_item_list_k: begin               {subordinate display list}
        {
        *   Scan backwards in the DAG list to make sure this is not a circular
        *   reference.
        }
        ent_p := top_p;                {init to first backwards entry to check}
        while ent_p <> nil do begin    {scan backwards until start of DAG list}
          if item_p^.list_sub_p = ent_p^.list_p then begin {found matching entry ?}
            writeln ('Circular display list references found in DISPL_DAGL_DISPL_ADD');
            sys_bomb;
            end;
          ent_p := ent_p^.prev_p;      {to previous DAG list entry}
          end;                         {back to check this new entry}
        {
        *   Scan forwards looking for this subordinate list already in DAG list.
        }
        ent_p := top_p^.next_p;        {init to first forwards entry to check}
        while ent_p <> nil do begin    {scan forwards until end of DAG list}
          if item_p^.list_sub_p = ent_p^.list_p {found matching entry ?}
            then goto next_ent;
          ent_p := ent_p^.next_p;      {to next DAG list entry}
          end;                         {back to check this new entry}
        {
        *   This subordinate display list is not already in the DAG list.  Add it.
        }
        displ_dagl_displ_add (         {add subordinate display list to DAG list}
          dagl,                        {the DAG list to add to}
          top_p,                       {add to immediately after our top level list}
          item_p^.list_sub_p^);        {the subordinate display list to add}
        end;

displ_item_vect_k: begin               {chain of vectors}
        displ_dagl_color (dagl, item_p^.vect_color_p); {ensure rendering states in their lists}
        displ_dagl_vparm (dagl, item_p^.vect_parm_p);
        end;

      end;                             {end of display list item type cases}

next_ent:                              {done with this display list entry, on to next}
    item_p := item_p^.next_p;          {to next item in the display list}
    end;                               {back to process this new item}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_DAGL_DISPL (DAGL, DISPL)
*
*   Fill in the DAG list DAGL with the display list DISPL and all display lists
*   ultimately called by it.  The new information will be added to the start of
*   the DAG list.
*
*   A unique sequential number will be assigned to each DAG list entry.  The top
*   level entry will be 1, with subordinate entries at higher numbers.
}
procedure displ_dagl_displ (           {fill in DAG list from one display list}
  in out  dagl: displ_dagl_t;          {the DAG list to add to}
  in var  displ: displ_t);             {the top level display list to add}
  val_param;

var
  id: sys_int_machine_t;               {1-N next ID to assign}
  ent_p: displ_dagl_ent_p_t;           {pointer to current DAG list entry}
  col_p: displ_dagl_color_p_t;         {points to curr color parameters list entry}
  vect_p: displ_dagl_vparm_p_t;        {points to curr vector parms list entry}
  text_p : displ_dagl_tparm_p_t;       {points to curr text parms list entry}

begin
  displ_dagl_displ_add (dagl, nil, displ); {add display list to start of DAG list}
{
*   Assign IDs to all the display lists.
}
  id := 1;                             {init next ID to assign}
  ent_p := dagl.first_p;               {init to first entry in the list}
  while ent_p <> nil do begin          {loop over all the list entries}
    ent_p^.id := id;                   {assign ID to this entry}
    ent_p^.list_p^.id := id;           {set the ID in the display list}
    id := id + 1;                      {update ID to assign next entry}
    ent_p := ent_p^.next_p;            {advance to the next entry in the list}
    end;                               {back to do this new entry}
{
*   Assign IDs to all the color sets.
}
  id := 1;                             {init next ID to assign}
  col_p := dagl.color_p;               {init to first entry in the list}
  while col_p <> nil do begin          {loop over all the list entries}
    col_p^.id := id;                   {assign ID to this entry}
    id := id + 1;                      {update ID to assign next entry}
    col_p := col_p^.next_p;            {advance to the next entry in the list}
    end;                               {back to do this new entry}
{
*   Assign IDs to all the vector parameter sets.
}
  id := 1;                             {init next ID to assign}
  vect_p := dagl.vparm_p;              {init to first entry in the list}
  while vect_p <> nil do begin         {loop over all the list entries}
    vect_p^.id := id;                  {assign ID to this entry}
    id := id + 1;                      {update ID to assign next entry}
    vect_p := vect_p^.next_p;          {advance to the next entry in the list}
    end;                               {back to do this new entry}
{
*   Assign IDs to all the text parameter sets.
}
  id := 1;                             {init next ID to assign}
  text_p := dagl.tparm_p;              {init to first entry in the list}
  while text_p <> nil do begin         {loop over all the list entries}
    text_p^.id := id;                  {assign ID to this entry}
    id := id + 1;                      {update ID to assign next entry}
    text_p := text_p^.next_p;          {advance to the next entry in the list}
    end;                               {back to do this new entry}
  end;
