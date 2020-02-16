{   Routines that do drawing.
}
module displ_draw;
define displ_draw_item;
define displ_draw_itemst;
define displ_draw_item_vect;
define displ_draw_list;
define displ_draw_listst;
%include 'displ2.ins.pas';
{
********************************************************************************
*
*   Subroutine DISPL_DRAW_ITEM (ITEM)
*
*   Draw the indicated display list item.  The current drawing state is assumed
*   to be the default.
}
procedure displ_draw_item (            {draw item, current RENDlib state is default}
  in      item: displ_item_t);         {the item to draw}
  val_param;

var
  draw: displ_draw_t;                  {resolved drawing state}
  color: displ_color_t;                {default color}
  vect_parm: displ_vparm_t;            {default vector drawing parameters}
  text_parm: displ_tparm_t;            {default text drawing parameters}

begin
  rend_set.enter_rend^;                {enter graphics mode}
{
*   Get the current settings that modify drawing.
}
  rend_get.rgba^ (                     {get the current color}
    color.red, color.grn, color.blu, color.opac);
  rend_get.vect_parms^ (vect_parm.vparm); {get the current vector drawing parameters}
  rend_get.text_parms^ (text_parm.tparm); {get the current text drawing parameters}
{
*   Fill in the resolved drawing state.
}
  displ_rend_init (draw.curr);         {make sure all fields are set}
  draw.curr.color_p := addr(color);    {init current settings}
  draw.curr.vect_parm_p := addr(vect_parm);
  draw.curr.text_parm_p := addr(text_parm);

  displ_rend_init (draw.def);          {make sure all fields are set}
  if item.list_p <> nil then begin     {parent list exists ?}
    displ_rend_resolve (draw.def, item.list_p^.rend); {apply defaults from parent list}
    end;
  displ_rend_resolve (draw.def, draw.curr); {use current settings for remaining defaults}

  displ_draw_itemst (item, draw);      {actually draw the item, pass drawing state}

  rend_set.exit_rend^;                 {pop back out of graphics mode}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_DRAW_ITEMST (ITEM, DRAW)
*
*   Low level routine to draw one display list item.  The drawing state is
*   supplied by the caller.
}
procedure displ_draw_itemst (          {draw item, drawing state supplied}
  in      item: displ_item_t;          {the item to draw}
  in out  draw: displ_draw_t);         {drawing state}
  val_param;

begin
  case item.item of                    {what kind of item is this ?}

displ_item_list_k: begin
      displ_draw_item_list (item, draw); {draw the LIST item}
      end;

displ_item_vect_k: begin
      displ_draw_item_vect (item, draw); {draw the VECT item}
      end;

    end;                               {end of item type cases}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_DRAW_ITEM_LIST (ITEM, DRAW)
*
*   Draw the subordinate list item ITEM.  DRAW is the drawing state.
*
*   This is a low level routine that requires ITEM to be of type LIST, which is
*   not checked.
}
procedure displ_draw_item_list (       {draw subordinate list display list item}
  in      item: displ_item_t;          {the item to draw, must be type LIST}
  in out  draw: displ_draw_t);         {drawing state}
  val_param;

var
  dr: displ_draw_t;                    {drawing state to use for the list}

begin
  if item.list_sub_p = nil then return; {no subordinate list, nothing to do ?}
{
*   Fill in drawing state to use only for the subordinate list.
}
  dr.curr := draw.curr;                {copy the current drawing state}

  dr.def := item.list_sub_p^.rend;     {init defaults to settings for the sub-list}
  displ_rend_resolve (dr.def, draw.def); {remaining defaults from parent draw state}

  displ_draw_listst (item.list_sub_p^, dr); {draw the subordinate list}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_DRAW_ITEM_VECT (ITEM, DRAW)
*
*   Draw the chained vectors list item ITEM.  DRAW is the drawing state.
*
*   This is a low level routine that requires ITEM to be of type VECT, which is
*   not checked.
}
procedure displ_draw_item_vect (       {draw chained vectors display list item}
  in      item: displ_item_t;          {the item to draw, must be type VECT}
  in out  draw: displ_draw_t);         {drawing state}
  val_param;

var
  coor_p: displ_coor2d_ent_p_t;        {pointer to current coor of vectors list}

begin
  coor_p := item.vect_first_p;         {init pointer to starting coordinate}
  if coor_p = nil then return;         {no coordinate, nothing to draw ?}
  if coor_p^.next_p = nil then return; {no second coordinate, nothing to draw ?}

  displ_rend_set_color (               {set the color}
    item.vect_color_p, draw);
  displ_rend_set_vect (                {set vector drawing parameters}
    item.vect_parm_p, draw);

  rend_set.cpnt_2d^ (coor_p^.x, coor_p^.y); {set current point to first coordinate}
    coor_p := coor_p^.next_p;          {advance to the second coordinate}

 repeat                                {back here each new vector to draw}
   rend_prim.vect_2d^ (coor_p^.x, coor_p^.y); {draw vector to this coordinate}
   coor_p := coor_p^.next_p;           {advance to next coordinate in list}
   until coor_p = nil;                 {back until hit end of list}
 end;
{
********************************************************************************
*
*   Subroutine DISPL_DRAW_LIST (LIST)
*
*   Draw all the contents of the indicate display list.  The current drawing
*   state is assumed to be the default.
}
procedure displ_draw_list (            {draw display list, curr RENDlib state is default}
  in      list: displ_t);              {the display list to draw}
  val_param;

var
  draw: displ_draw_t;                  {resolved drawing state}
  color: displ_color_t;                {default color}
  vect_parm: displ_vparm_t;            {default vector drawing parameters}
  text_parm: displ_tparm_t;            {default text drawing parameters}

begin
  rend_set.enter_rend^;                {enter graphics mode}
{
*   Get the current settings that modify drawing.
}
  rend_get.rgba^ (                     {get the current color}
    color.red, color.grn, color.blu, color.opac);
  rend_get.vect_parms^ (vect_parm.vparm); {get the current vector drawing parameters}
  rend_get.text_parms^ (text_parm.tparm); {get the current text drawing parameters}
{
*   Fill in the resolved drawing state.
}
  displ_rend_init (draw.curr);         {make sure all fields are set}
  draw.curr.color_p := addr(color);    {init current settings}
  draw.curr.vect_parm_p := addr(vect_parm);
  draw.curr.text_parm_p := addr(text_parm);

  displ_rend_init (draw.def);          {make sure all fields are set}
  displ_rend_resolve (draw.def, draw.curr); {use current settings for remaining defaults}

  displ_draw_listst (list, draw);      {actually draw the list, pass drawing state}

  rend_set.exit_rend^;                 {pop back out of graphics mode}
  end;
{
********************************************************************************
*
*   Subroutine DISPL_DRAW_LISTST (LIST, DRAW)
*
*   Low level routine to draw the contents of a display list.  The drawing state
*   is supplied by the caller.
}
procedure displ_draw_listst (          {draw list, drawing state supplied}
  in      list: displ_t;               {the list to draw}
  in out  draw: displ_draw_t);         {drawing state}
  val_param;

var
  item_p: displ_item_p_t;              {points to current item in display list}

begin
  item_p := list.first_p;              {init to first item in the list}
  while item_p <> nil do begin         {loop over the list of items}
    displ_draw_itemst (item_p^, draw); {draw this item}
    item_p := item_p^.next_p;          {advance to next item in the list}
    end;                               {back to draw this new item}
  end;
