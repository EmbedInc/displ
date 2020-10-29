{   Routines that manipulate items in a list.
}
module displ_item;
define displ_item_new;
define displ_item_list;
define displ_item_vect;
define displ_item_image;
%include 'displ2.ins.pas';
{
********************************************************************************
*
*   Subroutine DISPL_ITEM_NEW (EDIT)
*
*   Create a new item in a list following the current edit position.  The item
*   will be initialized to type NONE.
}
procedure displ_item_new (             {create new item in a list}
  in out  edit: displ_edit_t);         {list edit state, item added after curr pos}
  val_param;

var
  item_p: displ_item_p_t;              {pointer to the new item}

begin
  if edit.list_p = nil then return;    {invalid edit state ?}

  util_mem_grab (                      {allocate memory for the new item}
    sizeof(item_p^),                   {amount of memory to allocate}
    edit.list_p^.mem_p^,               {memory context}
    true,                              {allow to be individually deallocated}
    item_p);                           {returned pointer to the new memory}

  item_p^.list_p := edit.list_p;       {link item to its list}
  item_p^.prev_p := edit.item_p;       {link to previous item in list}
  if item_p^.prev_p = nil
    then begin                         {adding to start of list}
      item_p^.next_p := edit.list_p^.first_p; {link to next item}
      edit.list_p^.first_p := item_p;  {set forward link to this new item}
      end
    else begin                         {adding after existing item}
      item_p^.next_p := edit.item_p^.next_p; {link to next item}
      edit.item_p^.next_p := item_p;   {set forward link to this new item}
      end
    ;
  if item_p^.next_p = nil
    then begin                         {new item is at end of list}
      edit.list_p^.last_p := item_p;   {set backward link to this new item}
      end
    else begin                         {existing item follows new item}
      item_p^.next_p^.prev_p := item_p; {set backward link to this new item}
      end
    ;
  item_p^.item := displ_item_none_k;   {init this item to unused}

  edit.item_p := item_p;               {set edit position to new item}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_ITEM_LIST (EDIT, LIST)
*
*   Make the current item reference the list LIST.  The current item must be of
*   type NONE.
}
procedure displ_item_list (            {make current item reference to a list}
  in out  edit: displ_edit_t;          {list edit state, curr item must be type NONE}
  in var  list: displ_t);              {the list to reference}
  val_param;

begin
  if edit.list_p = nil then return;    {invalid edit state ?}
  if edit.item_p = nil then return;    {no item at current position ?}
  if edit.item_p^.item <> displ_item_none_k then return; {not a NONE item ?}

  edit.item_p^.item := displ_item_list_k; {item is now reference to a list}
  edit.item_p^.list_sub_p := addr(list); {point to the list being referenced}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_ITEM_VECT (EDIT)
*
*   Make the current item a chain of 2D vectors.  The current item must be of
*   type NONE.
}
procedure displ_item_vect (            {make current item chain of 2D vectors}
  in out  edit: displ_edit_t);         {list edit state, curr item must be type NONE}
  val_param;

begin
  if edit.list_p = nil then return;    {invalid edit state ?}
  if edit.item_p = nil then return;    {no item at current position ?}
  if edit.item_p^.item <> displ_item_none_k then return; {not a NONE item ?}

  edit.item_p^.item := displ_item_vect_k; {item is now 2D chain of vectors}
  edit.item_p^.vect_color_p := nil;    {init to color is inherited}
  edit.item_p^.vect_parm_p := nil;     {init to vector parameters inherited}
  edit.item_p^.vect_first_p := nil;    {init to no coordinates in the chain}
  edit.item_p^.vect_last_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine DISPL_ITEM_IMAGE (EDIT, IMG)
*
*   Make the current item an image reference.  The current item must be of type
*   NONE.
*
*   The transform from the drawing space to the pixel space of the referenced
*   image is initialized such that the image is maximized and centered in the
*   central square (-1 to +1) of the drawing space.
}
procedure displ_item_image (           {make current item an image overlay}
  in out  edit: displ_edit_t;          {list edit state, curr item must be type NONE}
  in var  img: displ_img_t);           {the image being referenced}
  val_param;

var
  sc: real;                            {scale factor}

begin
  if edit.list_p = nil then return;    {invalid edit state ?}
  if edit.item_p = nil then return;    {no item at current position ?}
  if edit.item_p^.item <> displ_item_none_k then return; {not a NONE item ?}

  edit.item_p^.item := displ_item_img_k; {make item an image reference}
  edit.item_p^.img_p := addr(img);     {link to the image being referenced}
  edit.item_p^.img_lft := -1.0;
  edit.item_p^.img_rit := 1.0;
  edit.item_p^.img_bot := -1.0;
  edit.item_p^.img_top := 1.0;

  if img.aspect >= 1.0
    then begin                         {image is wider than tall}
      sc := img.dx / 2.0;
      end
    else begin                         {image is taller than wide}
      sc := img.dy / 2.0;
      end
    ;
  edit.item_p^.img_xf.xb.x := sc;
  edit.item_p^.img_xf.xb.y := 0.0;
  edit.item_p^.img_xf.yb.x := 0.0;
  edit.item_p^.img_xf.yb.y := -sc;
  edit.item_p^.img_xf.ofs.x := img.dx / 2.0;
  edit.item_p^.img_xf.ofs.y := img.dy / 2.0;
  end;
