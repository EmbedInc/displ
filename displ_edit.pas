{   Routines for editing a display list.
}
module displ_edit;
define displ_edit_init;
define displ_edit_next;
define displ_edit_prev;
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
