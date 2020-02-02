{   Routines that do drawing.
}
module displ_draw;
module displ_draw_item;
module displ_draw_itemst;
module displ_draw_item_vect;
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
  vect_parm: rend_vect_parms_t;        {default vector drawing parameters}
  text_parm: rend_text_parms_t;        {default text drawing parameters}

begin
  rend_set.enter_rend^;                {enter graphics mode}
{
*   Get the current settings that modify drawing.
}
  rend_get.rgba^ (                     {get the current color}
    color.red, color.grn, color.blu, color.opac);
  rend_get.vect_parms^ (vect_parm);    {get the current vector drawing parameters}
  rend_get.text_parms^ (text_parm);    {get the current text drawing parameters}
{
*   Fill in the resolved drawing state.
}
  draw.parent_p := nil;                {this will be the top level drawing state}

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
      if item.list_sub_p = nil then return; {no list linked to ?}
      displ_draw_listst (item.list_sub_p^, draw); {draw the subordinate list}
      end;

displ_item_vect_k: begin
      displ_draw_item_vect (item, draw); {draw the VECT item}
      end;

    end;                               {end of item type cases}
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

 displ_rend_set_color (                {set the color}
   item.vect_color_p, draw);
 displ_rend_set_vect (                 {set vector drawing parameters}
   item.vect_parm_p, draw);

 rend_set.cpnt_2d^ (coor_p^.x, coor_p^.y); {set current point to first coordinate}
  coor_p := coor_p^.next_p;            {advance to the second coordinate}

 repeat                                {back here each new vector to draw}
   rend_prim.vect_2d^ (coor_p^.x, coor_p^.y); {draw vector to this coordinate}
   coor_p := coor_p^.next_p;           {advance to next coordinate in list}
   until coor_p = nil;                 {back until hit end of list}
 end;
