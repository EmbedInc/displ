{   High level managment of whole display lists.
}
module displ_list;
define displ_list_new;
define displ_list_del;
%include 'displ2.ins.pas';
{
********************************************************************************
*
*   Internal subroutine LIST_RESET (LIST)
*
*   Reset all the fields of LIST to unused, benign, or default values, except
*   for the MEM_P field, which is not altered.
}
procedure list_reset (                 {reset list fields to unused}
  out     list: displ_t);              {the list descriptor to reset}
  val_param;

begin
  list.first_p := nil;
  list.last_p := nil;
  displ_rend_init (list.rend);
  end;
{
********************************************************************************
*
*   Subroutine DISPL_LIST_NEW (MEM, LIST)
*
*   Create a new display list.  MEM is the parent memory context to use.  A
*   subordinate context will be created for the new list.
}
procedure displ_list_new (             {create a new display list}
  in out  mem: util_mem_context_t;     {parent mem context, subordinate created for list}
  out     list: displ_t);              {returned filled-in list descriptor}
  val_param;

begin
  list_reset (list);                   {reset fields to unused}

  util_mem_context_get (mem, list.mem_p); {make mem context for the list}
  if list.mem_p = nil then begin
    sys_message_bomb ('sys', 'no_mem', nil, 0);
    end;
  end;
{
********************************************************************************
*
*   Subroutine DISPL_LIST_DEL (LIST)
*
*   Delete the indicated list and deallocate any system resources used by the
*   list.  The list descriptor will be returned invalid.  A new list must be
*   created to use the list descriptor again.
}
procedure displ_list_del (             {delete list, deallocate resources}
  in out  list: displ_t);              {the list to delete}
  val_param;

begin
  if list.mem_p <> nil then begin      {memory context is allocated ?}
    util_mem_context_del (list.mem_p); {deallocate it}
    end;

  list_reset (list);                   {reset all other fields to unused}
  end;
