{   Routines for drawing images.
}
module displ_draw_img;
define displ_draw_item_img;
%include 'displ2.ins.pas';
{
********************************************************************************
*
*   Subroutine DISPL_DRAW_ITEM_IMG (ITEM, DRDEF, DRCUR)
*
*   Draw the overlayed image item ITEM.  This is a low level routine that
*   requires ITEM to be of type IMG, which is not checked.
}
procedure displ_draw_item_img (        {draw overlayed image display list item}
  in      item: displ_item_t;          {the item to draw, must be type IMG}
  in      drdef: displ_rend_t;         {default drawing settings}
  in out  drcur: displ_rend_t);        {current drawing settings}
  val_param;

var
  rdx, rdy: sys_int_machine_t;         {full device area size, pixels}
  raspect: real;                       {device area aspect ratio, width/height}
  scx, scy: real;                      {X and Y scale factors}
  ofx, ofy: real;                      {X and Y offsets}
  rlft, rrit: sys_int_machine_t;       {left and right dev pixels drawing limits}
  rtop, rbot: sys_int_machine_t;       {top and bottom dev pixels drawing limits}
  r: real;                             {scratch floating point}
  nx, ny: sys_int_machine_t;           {drawing area size, pixels}
  xf: vect_xf2d_t;                     {scratch 2D transform}
  dimg: vect_xf2d_t;                   {drawing pixel to source image pixel xform}
  ix, iy: sys_int_machine_t;           {current drawing pixel coordinate}
  x, y: real;                          {center of current drawing pixel coordinate}
  ovx, ovy: real;                      {overlay image coordinate, pixel space}
  iovx, iovy: sys_int_machine_t;       {overlay image pixel coordinate}
  span_p: img_scan1_arg_p_t;           {pointer to span of pixels in drawing area}
  spx: sys_int_machine_t;              {0-N index of pixel in this span}
  ovi: sys_int_machine_t;              {linear overlay image pixel index}

begin
  if item.img_p = nil then return;     {item not linked to an image ?}

  rend_set.enter_rend^;                {enter graphics mode}
  rend_get.image_size^ (               {get the dimensions of the raw draw area}
    rdx, rdy, raspect);
{
*   Create the scale factors and offset to go from the 2D drawing space to the
*   device pixels space.  This is essentially a simplified transform, since
*   there is no rotation.  The transform to go from the 2D drawing space to the
*   device pixels space is:
*
*     XB =  (scx,   0)
*     YB =  (  0, scy)
*     OFS = (ofx, ofy)
}
  if raspect >= 1.0
    then begin                         {drawing area is wider than tall}
      scx := rdx / (2.0 * raspect);    {X scale factor}
      scy := -rdy / 2.0;               {Y scale factor}
      end
    else begin                         {drawing area is taller than wide}
      scx := rdx / 2.0;                {X scale factor}
      scy := -raspect * rdy / 2.0;     {Y scale factor}
      end
    ;
  ofx := rdx / 2.0;
  ofy := rdy / 2.0;
{
*   Find the left/right top/bottom pixel limits of the area the image will be
*   drawn in.
}
  r := item.img_lft * scx + ofx;       {left edge raw pixel coordinate}
  r := max(0.0, min(rdx, r));          {clip to device limits}
  rlft := trunc(r + 0.5);              {first X included in draw area}

  r := item.img_rit * scx + ofx;       {right edge raw pixel coordinate}
  r := max(0.0, min(rdx, r));          {clip to device limits}
  rrit := trunc(r - 0.5);              {last X included in draw area}

  r := item.img_top * scy + ofy;       {top edge raw pixel coordinate}
  r := max(0.0, min(rdy, r));          {clip to device limits}
  rtop := trunc(r + 0.5);              {first Y included in draw area}

  r := item.img_bot * scy + ofy;       {bottom edge raw pixel coordinate}
  r := max(0.0, min(rdy, r));          {clip to device limits}
  rbot := trunc(r - 0.5);              {last Y included in draw area}

  nx := rrit - rlft + 1;               {make size of region to draw into}
  ny := rbot - rtop + 1;
  if (nx <= 0) or (ny <= 0) then return; {no pixels to draw into ?}
{
*   There is at least one pixel to draw into.
*
*   Set up the drawing pixel to source image pixel transform in DIMG.
}
  xf.xb.x := 1.0 / scx;                {make dev pixels to 2D draw space transform}
  xf.xb.y := 0.0;
  xf.yb.x := 0.0;
  xf.yb.y := 1.0 / scy;
  xf.ofs.x := -ofx / scx;
  xf.ofs.y := -ofy / scy;

  vect_xf2d_mult (                     {combine to make dev pixels to img pixels XF}
    xf,                                {dev pixels to 2D draw space}
    item.img_xf,                       {2D draw space to image pixels}
    dimg);                             {resulting dev pixels to img pixels transform}
{
*   Set up RENDlib for drawing spans into the RLFT,RRIT RTOP,RBOT rectangle.
}
  rend_set.iterp_span_on^ (rend_iterp_red_k, true); {enable for SPAN primitive}
  rend_set.iterp_span_on^ (rend_iterp_grn_k, true);
  rend_set.iterp_span_on^ (rend_iterp_blu_k, true);

  rend_set.iterp_span_ofs^ (           {set offsets of components within pixel}
    rend_iterp_red_k, offset(img_pixel1_t.red));
  rend_set.iterp_span_ofs^ (
    rend_iterp_grn_k, offset(img_pixel1_t.grn));
  rend_set.iterp_span_ofs^ (
    rend_iterp_blu_k, offset(img_pixel1_t.blu));

  rend_set.span_config^ (sizeof(img_pixel1_t)); {offset for one pixel to the right}

  rend_set.cpnt_2dimi^ (rlft, rtop);   {to top left corner of spans rectangle}
  rend_prim.rect_px_2dimcl^ (nx, ny);  {define spans rectangle}

  sys_mem_alloc (                      {allocate temp memory for span of pixels}
    sizeof(span_p^[0]) * nx,           {amount of memory to allocate}
    span_p);                           {returned pointer to the memory}
{
*   Draw the overlay image into the spans rectangle.
}
  for iy := rtop to rbot do begin      {down the spans within the drawing rectangle}
    y := iy + 0.5;                     {center Y of this span}
    for ix := rlft to rrit do begin    {across the pixels in this span}
      spx := ix - rlft;                {make index into this span}
      x := ix + 0.5;                   {center X of this pixel within span}
      ovx := x * dimg.xb.x + y * dimg.yb.x + dimg.ofs.x; {make ovl image coordinate}
      ovy := x * dimg.xb.y + y * dimg.yb.y + dimg.ofs.y;
      if                               {check for outside overlay image bounds}
          (ovx < 0.0) or (ovx >= item.img_p^.dx) or
          (ovy < 0.0) or (ovy >= item.img_p^.dy)
        then begin                     {this pixel maps to outside the source image}
          span_p^[spx].red := 0;
          span_p^[spx].grn := 0;
          span_p^[spx].blu := 0;
          span_p^[spx].alpha := 0;
          end
        else begin                     {this pixel maps to within the source image}
          iovx := trunc(ovx);          {make integer source image pixel coordinate}
          iovy := trunc(ovy);
          ovi := (iovy * item.img_p^.dx) + iovx; {make linear index into source image}
          span_p^[spx] := item.img_p^.pix_p^[ovi]; {fetch the source image value here}
          end
        ;
      end;                             {back to do next pixel accross in this span}

    rend_prim.span_2dimcl^ (           {draw this span}
      nx,                              {number of pixels in this span}
      span_p^);                        {the pixels to write}
    end;                               {back to do next span down in drawing rectangle}

  sys_mem_dealloc (span_p);            {deallocate temporary span buffer}
  rend_set.exit_rend^;                 {pop back out of graphics mode}
  end;
