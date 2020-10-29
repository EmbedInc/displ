{   Private include file for the modules implementing the DISPL library.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'img.ins.pas';
%include 'vect.ins.pas';
%include 'rend.ins.pas';
%include 'displ.ins.pas';
{
*   Private subroutines and functions.
}
procedure displ_draw_item_img (        {draw overlayed image display list item}
  in      item: displ_item_t;          {the item to draw, must be type IMG}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param; extern;

procedure displ_draw_item_list (       {draw subordinate list display list item}
  in      item: displ_item_t;          {the item to draw, must be type LIST}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param; extern;

procedure displ_draw_item_vect (       {draw chained vectors display list item}
  in      item: displ_item_t;          {the item to draw, must be type VECT}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param; extern;

procedure displ_draw_itemst (          {draw item, drawing state supplied}
  in      item: displ_item_t;          {the item to draw}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param; extern;

procedure displ_draw_listst (          {draw list, drawing state supplied}
  in      list: displ_t;               {the list to draw}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param; extern;

procedure displ_rend_init (            {init render settings descriptor}
  out     rend: displ_rend_t);         {the descriptor to set all fields of}
  val_param; extern;

procedure displ_rend_default (         {make subordinate default draw settings}
  in      par: displ_rend_t;           {parent default settings}
  in      here: displ_rend_t;          {settings specified for this level}
  out     def: displ_rend_t);          {resulting defaults for this level}
  val_param; extern;

procedure displ_rend_resolve (         {resolve render settings by applying defaults}
  in out  rend: displ_rend_t;          {render settings to update}
  in      def: displ_rend_t);          {defaults to apply as needed}
  val_param; extern;

procedure displ_rend_set_color (       {set color as appropriate}
  in      color_p: displ_color_p_t;    {NIL or points to explicit setting}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param; extern;

procedure displ_rend_set_text (        {set text parameters as appropriate}
  in      text_p: displ_tparm_p_t;     {NIL or points to explicit setting}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param; extern;

procedure displ_rend_set_vect (        {set vector parameters as appropriate}
  in      vect_p: displ_vparm_p_t;     {NIL or points to explicit setting}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param; extern;
