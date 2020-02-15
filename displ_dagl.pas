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
  end;
{
********************************************************************************
*
*   Local subroutine DISPL_DAGL_ENT_NEW (DAGL, POS_P, NEW_P)
*
*   Add a new entry to the DAG list DAGL.  The new entry will be added
*   immediately following the entry pointed to by POS_P.  POS_P may be NIL, in
*   which case the new entry is added to the start of the list.  NEW_P is
*   returned pointing to the new entry.
}
procedure displ_dagl_ent_new (         {add new entry to DAG list}
  in out  dagl: displ_dagl_t;          {list to add new entry to}
  in      pos_p: displ_dagl_ent_p_t;   {add new entry after this one, NIL at list start}
  out     new_p: displ_dagl_ent_p_t);  {returned pointer to the new entry}
  val_param;

begin
  util_mem_grab (                      {allocate memory for the new list entry}
    sizeof(new_p), dagl.mem_p^, false, new_p);

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
  edit: displ_edit_t;                  {display list editing state}
  ent_p: displ_dagl_ent_p_t;           {pointer to current DAG list entry}

label
  next_ent;

begin
  displ_dagl_ent_new (dagl, pos_p, top_p); {create top level entry for display list}
  top_p^.list_p := addr(displ);        {fill in the entry}

  displ_edit_init (edit, displ);       {init display list edit state}
  while edit.item_p <> nil do begin    {scan the items in this display list}
    if edit.item_p^.item <> displ_item_list_k
      then goto next_ent;              {not a subordinate display list, ignore}
    {
    *   Scan backwards in the DAG list to make sure this is not a circular
    *   reference.
    }
    ent_p := top_p;                    {init to first backwards entry to check}
    while ent_p <> nil do begin        {scan backwards until start of DAG list}
      if edit.item_p^.list_sub_p = ent_p^.list_p then begin {found matching entry ?}
        writeln ('Circular display list references found in DISPL_DAGL_DISPL_ADD');
        sys_bomb;
        end;
      ent_p := ent_p^.prev_p;          {to previous DAG list entry}
      end;                             {back to check this new entry}
    {
    *   Scan forwards looking for this subordinate list already in DAG list.
    }
    ent_p := top_p^.next_p;            {init to first forwards entry to check}
    while ent_p <> nil do begin        {scan forwards until end of DAG list}
      if edit.item_p^.list_sub_p = ent_p^.list_p {found matching entry ?}
        then goto next_ent;
      ent_p := ent_p^.next_p;          {to next DAG list entry}
      end;                             {back to check this new entry}
    {
    *   This subordinate display list is not already in the DAG list.  Add it.
    }
    displ_dagl_displ_add (             {add subordinate display list to DAG list}
      dagl,                            {the DAG list to add to}
      top_p,                           {add to immediately after our top level list}
      edit.item_p^.list_sub_p^);       {the subordinate display list to add}

next_ent:                              {done with this display list entry, on to next}
    discard( displ_edit_next(edit) );  {advance to the next item}
    end;                               {back to process this new item}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_DAGL_DISPL (DAGL, DISPL)
*
*   Fill in the DAG list DAGL with the display list DISPL and all display lists
*   ultimately called by it.  The new information will be added to the start of
*   the DAGL list.
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

begin
  displ_dagl_displ_add (dagl, nil, displ); {add display list to start of DAG list}

  id := 1;                             {init next ID to assign}
  ent_p := dagl.first_p;               {init to first entry in the list}
  while ent_p <> nil do begin          {loop over all the list entries}
    ent_p^.id := id;                   {assign ID to this entry}
    ent_p^.list_p^.id := id;           {set the ID in the display list}
    id := id + 1;                      {update ID to assign next entry}
    ent_p := ent_p^.next_p;            {advance to the next entry in the list}
    end;                               {back to do this new entry}
  end;
