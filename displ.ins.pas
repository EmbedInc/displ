{   Public include file for the DISPL (display list) library.
*
*   This library maintains a list of graphics primitives.  The provides
*   facilities for editing the list, and for drawing the list to a RENDlib
*   device.
}
const
  displ_subsys_k = -68;                {subsystem ID for the DISPL library}

type
  displ_item_p_t = ^displ_item_t;

  displ_color_p_t = ^displ_color_t;
  displ_color_t = record               {one fixed color}
    red: real;                         {0.0 to 1.0 color component intensities}
    grn: real;
    blu: real;
    opac: real;                        {0.0 to 1.0 opacity}
    end;

  displ_rend_p_t = ^displ_rend_t;
  displ_rend_t = record                {all the current state that effects rendering}
    color_p: displ_color_p_t;          {points to current color}
    vect_parm_p: rend_vect_parms_p_t;  {points to vector drawing parameters}
    text_parm_p: rend_text_parms_p_t;  {points to text drawing parameters}
    end;

  displ_p_t = ^displ_t;
  displ_t = record                     {top structure of a display list}
    mem_p: util_mem_context_p_t;       {points to mem context to use for this list}
    first_p: displ_item_p_t;           {points to first item in the list}
    last_p: displ_item_p_t;            {points to last item in the list}
    rend: displ_rend_t;                {default render settings for subordinate items}
    end;

  displ_coor2d_ent_p_t = ^displ_coor2d_ent_t;
  displ_coor2d_ent_t = record          {2D coordinate list entry}
    prev_p: displ_coor2d_ent_p_t;      {points to previous coordinate}
    next_p: displ_coor2d_ent_p_t;      {points to next coordinate}
    x, y: real;                        {2D coordinate}
    end;

  displ_item_k_t = (                   {IDs for each of the possible list items}
    displ_item_none_k,                 {indicates no item, unknown, etc}
    displ_item_list_k,                 {sub-list}
    displ_item_vect_k);                {chain of linked vectors}

  displ_item_t = record                {one item in the display list}
    list_p: displ_p_t;                 {points to list containing this item}
    prev_p: displ_item_p_t;            {points to previous item in the list}
    next_p: displ_item_p_t;            {points to next item in the list}
    item: displ_item_k_t;              {ID for the type of this list entry}
    case displ_item_k_t of
displ_item_none_k: (                   {unused item}
      );
displ_item_list_k: (                   {sub-list}
      list_sub_p: displ_p_t;           {points to the subordinate list}
      );
displ_item_vect_k: (                   {chain of vectors, RENDlib 2D space}
      vect_first_p: displ_coor2d_ent_p_t; {points starting coordinate}
      vect_last_p: displ_coor2d_ent_p_t; {points to ending coordinate}
      vect_color_p: displ_color_p_t;   {points to color, NIL inherits}
      vect_parm_p: rend_vect_parms_p_t; {points to vector properties, NIL iherits}
      );
    end;

  displ_edit_p_t = ^displ_edit_t;
  displ_edit_t = record                {state for editing a display list}
    list_p: displ_p_t;                 {points to list being edited}
    item_p: displ_item_p_t;            {points to item at or after, NIL = start of list}
    end;

  displ_edvect_p_t = ^displ_edvect_t;
  displ_edvect_t = record              {state for editing a VECT list item}
    item_p: displ_item_p_t;            {points to the VECT item}
    coor_p: displ_coor2d_ent_p_t;      {points to curr coordinate, NIL = start of list}
    end;
{
*   Subroutines and functions.
}
procedure displ_draw_item (            {draw item, current RENDlib state is default}
  in      item: displ_item_t);         {the item to draw}
  val_param; extern;

procedure displ_draw_list (            {draw display list, curr RENDlib state is default}
  in      list: displ_t);              {the display list to draw}
  val_param; extern;

procedure displ_edit_del (             {delete current display list item}
  in out  edit: displ_edit_t;          {display list edit position}
  in      fwd: boolean);               {try to move forward, not backward after del}
  val_param; extern;

procedure displ_edit_init (            {init for editing a list}
  out     edit: displ_edit_t;          {edit state to init, pos before first item}
  in var  list: displ_t);              {the list to set up editing of}
  val_param; extern;

function displ_edit_next (             {move to next item in list}
  in out  edit: displ_edit_t)          {list editing state}
  :boolean;                            {moved to new item, not at end of list}
  val_param; extern;

function displ_edit_prev (             {move to previous item in list}
  in out  edit: displ_edit_t)          {list editing state}
  :boolean;                            {moved to new item, not at start of list}
  val_param; extern;

procedure displ_edvect_add (           {add coordinate to VECT item after curr}
  in out  edvect: displ_edvect_t;      {VECT edit state, new coor will be curr}
  in      x, y: real);                 {the 2D coordinate}
  val_param; extern;

procedure displ_edvect_del (           {delete current coordinate of VECT item}
  in out  edvect: displ_edvect_t;      {VECT item editing state}
  in      fwd: boolean);               {move forward to next coor, if possible}
  val_param; extern;

procedure displ_edvect_init (          {init for editing a VECT item}
  out     edvect: displ_edvect_t;      {edit state to init, pos before first coor}
  in var  item: displ_item_t);         {the item to set up editing of}
  val_param; extern;

function displ_edvect_next (           {move to next coordinate in VECT item}
  in out  edvect: displ_edvect_t)      {VECT item editing state}
  :boolean;                            {moved to new coor, not end of list}
  val_param; extern;

function displ_edvect_prev (           {move to previous coordinate in VECT item}
  in out  edvect: displ_edvect_t)      {VECT item editing state}
  :boolean;                            {moved to new coor, not start of list}
  val_param; extern;

procedure displ_item_list (            {make current item reference to a list}
  in out  edit: displ_edit_t;          {list edit state, curr item must be type NONE}
  in var  list: displ_t);              {the list to reference}
  val_param; extern;

procedure displ_item_new (             {create new item in a list}
  in out  edit: displ_edit_t);         {list edit state, item added after curr pos}
  val_param; extern;

procedure displ_item_vect (            {make current item chain of 2D vectors}
  in out  edit: displ_edit_t);         {list edit state, curr item must be type NONE}
  val_param; extern;

procedure displ_list_del (             {delete list, deallocate resources}
  in out  list: displ_t);              {the list to delete}
  val_param; extern;

procedure displ_list_new (             {create a new display list}
  in out  mem: util_mem_context_t;     {parent mem context, subordinate created for list}
  out     list: displ_t);              {returned filled-in list descriptor}
  val_param; extern;
