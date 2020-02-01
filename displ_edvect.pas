{   Routines for editing VECT list items.
}
module displ_edvect;
define displ_edvect_init;
define displ_edvect_next;
define displ_edvect_prev;
define displ_edvect_add;
define displ_edvect_del;
%include 'displ2.ins.pas';
{
********************************************************************************
*
*   Subroutine DISPL_EDVECT_INIT (EDVECT, ITEM)
*
*   Initialize for editing a VECT (2D chain of vectors) item.  EDVECT is the
*   VECT editing state, and will be initialized.  The editing position will be
*   immediately before the first coordinate.  ITEM must be a VECT display list
*   item.
}
procedure displ_edvect_init (          {init for editing a VECT item}
  out     edvect: displ_edvect_t;      {edit state to init, pos before first coor}
  in var  item: displ_item_t);         {the item to set up editing of}
  val_param;

begin
  if item.item <> displ_item_vect_k then begin {not a VECT item ?}
    edvect.item_p := nil;              {return invalid edit state}
    edvect.coor_p := nil;
    return;
    end;

  edvect.item_p := addr(item);         {save pointer to the item being edited}
  edvect.coor_p := nil;                {init position to before first coordinate}
  end;
{
********************************************************************************
*
*   Function DISPL_EDVECT_NEXT (EDVECT)
*
*   Move the editing position one coordinate forwards.  The function returns
*   TRUE if the editing position is moved, and FALSE when it is not (was at end
*   of list).
}
function displ_edvect_next (           {move to next coordinate in VECT item}
  in out  edvect: displ_edvect_t)      {VECT item editing state}
  :boolean;                            {moved to new coor, not end of list}
  val_param;

begin
  displ_edvect_next := false;          {init to postion not moved}
  if edvect.item_p = nil then return;  {invalid editing state ?}

  if edvect.coor_p = nil
    then begin                         {at start of list}
      if edvect.item_p^.vect_first_p = nil then return; {empty list ?}
      edvect.coor_p := edvect.item_p^.vect_first_p; {move to first coordinate}
      end
    else begin                         {at a existing coordinate}
      if edvect.coor_p^.next_p = nil then return; {already at end of list ?}
      edvect.coor_p := edvect.coor_p^.next_p; {move to next sequential coor}
      end
    ;

  displ_edvect_next := true;           {indicate position was moved}
  end;
{
********************************************************************************
*
*   Function DISPL_EDVECT_PREV (EDVECT)
*
*   Move the editing position one coordinate backwards.  The function returns
*   TRUE if the editing position is moved, and FALSE when it is not (was at
*   start of list).
}
function displ_edvect_prev (           {move to previous coordinate in VECT item}
  in out  edvect: displ_edvect_t)      {VECT item editing state}
  :boolean;                            {moved to new coor, not start of list}
  val_param;

begin
  displ_edvect_prev := false;          {init to postion not moved}
  if edvect.item_p = nil then return;  {invalid editing state ?}

  if edvect.coor_p = nil then return;  {already at start of list ?}

  edvect.coor_p := edvect.coor_p^.prev_p; {move to the previous item}
  displ_edvect_prev := true;           {indicate position was moved}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_EDVECT_ADD (EDVECT, X, Y)
*
*   Add a new coordinate to the VECT item being edited.  The new coordinate is
*   initialized to (X,Y), and is added immediately following the current edit
*   position.
}
procedure displ_edvect_add (           {add coordinate to VECT item after curr}
  in out  edvect: displ_edvect_t;      {VECT edit state, new coor will be curr}
  in      x, y: real);                 {the 2D coordinate}
  val_param;

var
  coor_p: displ_coor2d_ent_p_t;        {points to new coordinate descriptor}

begin
  if edvect.item_p = nil then return;  {invalid editing state ?}
  if edvect.item_p^.list_p = nil then return; {parent list missing ?}
  if edvect.item_p^.list_p^.mem_p = nil then return; {no list memory context ?}

  util_mem_grab (                      {allocate memory for the new coordinate}
    sizeof(coor_p^),                   {amount of memory to allocate}
    edvect.item_p^.list_p^.mem_p^,     {memory context}
    true,                              {allow individually deallocating this mem}
    coor_p);                           {returned pointer to the new memory}

  if edvect.coor_p = nil
    then begin                         {adding to start of coordinates list}
      coor_p^.prev_p := nil;           {no previous coor in list}
      coor_p^.next_p := edvect.item_p^.vect_first_p; {link to next coor in list}
      edvect.item_p^.vect_first_p := coor_p; {update start of list pointer}
      end
    else begin                         {link to after existing coordinate}
      coor_p^.prev_p := edvect.coor_p; {link back to previous coor in list}
      coor_p^.next_p := edvect.coor_p^.next_p; {link to next coor in list}
      edvect.coor_p^.next_p := coor_p; {update forward link in previous coor}
      end
    ;
  if coor_p^.next_p = nil
    then begin                         {this is last coordinate in list}
      edvect.item_p^.vect_last_p := coor_p; {update link to last list entry}
      end
    else begin                         {there is a subsequent coor in list}
      coor_p^.next_p^.prev_p := coor_p; {update backward link in previous coor}
      end
    ;

  coor_p^.x := x;                      {set the 2D coordinate value}
  coor_p^.y := y;
  edvect.coor_p := coor_p;             {set edit position to the new coordinate}
  end;
{
********************************************************************************
*
*   DISPL_EDVECT_DEL (EDVECT, FWD)
*
*   Delete the coordinate at the current edit position of a VECT item (2D chain
*   of vectors).  Nothing is done if the current edit position is not at a
*   coordinate (before first coordinate).
*
*   When FWD is TRUE, the edit position is moved forward after the deletion, if
*   any.  If the deleted coordinate was the last in the list, then the edit
*   position is moved backwards.
*
*   When FWD is FALSE, the edit position is moved backward after the deletion,
*   if any.  If the deleted coordinate was the first in the list, then the edit
*   position will be at the start of the list before the first coordinate.
}
procedure displ_edvect_del (           {delete current coordinate of VECT item}
  in out  edvect: displ_edvect_t;      {VECT item editing state}
  in      fwd: boolean);               {move forward to next coor, if possible}
  val_param;

var
  coor_p: displ_coor2d_ent_p_t;        {pointer to coordinate descriptor to delete}

begin
  if edvect.item_p = nil then return;  {invalid editing state ?}
  if edvect.item_p^.list_p = nil then return; {parent list missing ?}
  if edvect.item_p^.list_p^.mem_p = nil then return; {no list memory context ?}

  if edvect.coor_p = nil then return;  {not at coordinate, nothing to delete ?}
  coor_p := edvect.coor_p;             {save pointer to coordinate to delete}

  if coor_p^.prev_p = nil
    then begin                         {at start of list}
      edvect.item_p^.vect_first_p := coor_p^.next_p; {fwd link to skip over this coor}
      end
    else begin                         {after another coordinate}
      coor_p^.prev_p^.next_p := coor_p^.next_p; {fwd link to skip over this coor}
      end
    ;
  if coor_p^.next_p = nil
    then begin                         {at end of list}
      edvect.item_p^.vect_last_p := coor_p^.prev_p; {bkw link to skip over this coor}
      end
    else begin                         {another coordinate follows this one}
      coor_p^.next_p^.prev_p := coor_p^.prev_p; {bkw link to skip over this coor}
      end
    ;

  if fwd
    then begin                         {try to move to next coordinate}
      if coor_p^.next_p = nil
        then begin                     {no following coordinate}
          edvect.coor_p := coor_p^.prev_p; {go back to previous coor}
          end
        else begin                     {there is a following coordinate}
          edvect.coor_p := coor_p^.next_p; {go to it}
          end
        ;
      end
    else begin                         {try to move to previous coordinate}
      edvect.coor_p := coor_p^.prev_p; {move to previous coor or start of list}
      end
    ;

  util_mem_ungrab (                    {deallocate the coordinate descriptor memory}
    coor_p,                            {pointer to start of memory to deallocate}
    edvect.item_p^.list_p^.mem_p^);    {memory context}
  end;
