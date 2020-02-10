{   Routines for editing a display list.
}
module displ_edit;
define displ_edit_init;
define displ_edit_next;
define displ_edit_prev;
define displ_edit_del;
%include displ2.ins.pas;
{
********************************************************************************
*
*   Subroutine DISPL_EDIT_INIT (EDIT, LIST)
*
*   Initialize for editing a display list.  The edit position will be
*   initialized to before the first list item.
}
procedure displ_edit_init (            {init for editing a list}
  out     edit: displ_edit_t;          {edit state to init, pos before first item}
  in var  list: displ_t);              {the list to set up editing of}
  val_param;

begin
  edit.list_p := addr(list);           {point to the list being edited}
  edit.item_p := nil;                  {init position to before first list item}
  end;
{
********************************************************************************
*
*   Function DISPL_EDIT_NEXT (EDIT)
*
*   Advance to the next item in the list.  The function returns TRUE if the edit
*   position was advance, and FALSE if not (was at end of list).
}
function displ_edit_next (             {move to next item in list}
  in out  edit: displ_edit_t)          {list editing state}
  :boolean;                            {moved to new item, not at end of list}
  val_param;

begin
  displ_edit_next := false;            {init to position not moved}
  if edit.list_p = nil then return;    {no list (shouldn't happen) ?}

  if edit.item_p = nil then begin      {at start of list ?}
    if edit.list_p^.first_p = nil then return; {the list is empty}
    edit.item_p := edit.list_p^.first_p; {go to first list item}
    displ_edit_next := true;           {indicate position moved}
    return;
    end;

  if edit.item_p^.next_p = nil then return; {at end of list ?}
  edit.item_p := edit.item_p^.next_p;  {advance to the next item}
  displ_edit_next := true;             {indicate position moved}
  end;
{
********************************************************************************
*
*   Function DISPL_EDIT_PREV (EDIT)
*
*   Position to the previous item in the list.  The function returns TRUE if the
*   edit position was moved, and FALSE if not (was at start of list).
}
function displ_edit_prev (             {move to previous item in list}
  in out  edit: displ_edit_t)          {list editing state}
  :boolean;                            {moved to new item, not at start of list}
  val_param;

begin
  displ_edit_prev := false;            {init to position not moved}
  if edit.list_p = nil then return;    {no list (shouldn't happen) ?}

  if edit.item_p = nil then return;    {already before first item ?}

  edit.item_p := edit.item_p^.prev_p;  {go to previous item}
  displ_edit_prev := true;             {inidicate position moved}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_EDIT_DEL (EDIT, FWD)
*
*   Delete the display list item at the current edit position.  Nothing is done
*   if the current edit position is not on a item.  When the current item is
*   deleted, then FWD indicates to try to go to the next sequential when TRUE,
*   and to the previous item when FALSE.
}
procedure displ_edit_del (             {delete current display list item}
  in out  edit: displ_edit_t;          {display list edit position}
  in      fwd: boolean);               {try to move forward, not backward after del}
  val_param;

var
  item_p: displ_item_p_t;              {pointer to item to delete}

begin
  if edit.list_p = nil then return;    {invalid edit state ?}
  if edit.item_p = nil then return;    {not on item, nothing to delete ?}

  item_p := edit.item_p;               {save pointer to the item to delete}
  if item_p^.prev_p = nil
    then begin                         {deleting first item in list}
      edit.list_p^.first_p := item_p^.next_p; {update link to first item in list}
      end
    else begin                         {linked after another item}
      item_p^.prev_p^.next_p := item_p^.next_p; {update forward link in prev item}
      end
    ;
  if item_p^.next_p = nil
    then begin                         {deleting last item in list}
      edit.list_p^.last_p := item_p^.prev_p; {update link to last item in list}
      end
    else begin                         {another item follows this one}
      item_p^.next_p^.prev_p := item_p^.prev_p; {update backwards link in next item}
      end
    ;

  if fwd
    then begin                         {try to move to next item}
      if item_p^.next_p = nil
        then edit.item_p := item_p^.prev_p {no next item, move back}
        else edit.item_p := item_p^.next_p; {move to the next item}
      end
    else begin                         {move to the previous item}
      edit.item_p := item_p^.prev_p;
      end
    ;

  util_mem_ungrab (                    {deallocate the item's memory}
    item_p, edit.list_p^.mem_p^);
  end;
