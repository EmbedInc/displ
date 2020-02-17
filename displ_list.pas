{   High level managment of whole display lists.
}
module displ_list;
define displ_list_new;
define displ_list_del;
define displ_list_draws;
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
  list.id := 0;
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
{
********************************************************************************
*
*   Function DISPL_LIST_DRAWS (LIST)
*
*   Determine whether a display list causes any actual drawing.
}
function  displ_list_draws (           {check whether display list causes drawing}
  in      list: displ_t)               {the display list to check}
  :boolean;                            {causes drawing}
  val_param;

var
  item_p: displ_item_p_t;              {points to current item in the display list}

label
  done_item;

begin
  displ_list_draws := true;            {init to list does cause drawing}

  item_p := list.first_p;              {init to first item in the list}
  while item_p <> nil do begin         {scan the items in the display list}
    case item_p^.item of               {which type of item is this ?}

displ_item_list_k: begin               {subordinate display list}
        if item_p^.list_sub_p = nil then goto done_item; {no list here ?}
        if displ_list_draws(item_p^.list_sub_p^) then return; {sub-list draws}
        end;

displ_item_vect_k: begin               {chain of vectors}
        if item_p^.vect_first_p = nil  {no points at all ?}
          then goto done_item;
        if item_p^.vect_first_p^.next_p = nil {no second point, so no vector ?}
          then goto done_item;
        return;                        {at least one vector, this list draws}
        end;

      end;                             {end of item type cases}

done_item:                             {done with this item, on to next}
    item_p := item_p^.next_p;          {to the next item in this list}
    end;                               {back to check this new item}

  displ_list_draws := false;           {checked whole list, and no drawing}
  end;
