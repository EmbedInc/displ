{   Public include file for the DISPL (display list) library.
*
*   This library maintains a list of graphics primitives.  The provides
*   facilities for editing the list, and for drawing the list to a RENDlib
*   device.
}
const
  displ_subsys_k = -68;                {subsystem ID for the DISPL library}
  displ_stat_badindent_k = 1;          {bad DISPL file indentation level}
  displ_stat_2lists_k = 2;             {multiple LISTS commands}
  displ_stat_2colors_k = 3;            {multiple COLORS commands}
  displ_stat_2vparms_k = 4;            {multiple VPARMS commands}
  displ_stat_2tparms_k = 5;            {multiple TPARMS commands}
  displ_stat_badcmd_k = 6;             {unrecognized command}
  displ_stat_badval_k = 7;             {bad value read from file}
  displ_stat_errsyn_k = 8;             {syntax error in file}
  displ_stat_badcolid_k = 9;           {invalid color ID}
  displ_stat_dupcol_k = 10;            {duplicate color definition}
  displ_stat_badvpid_k = 11;           {invalid VPARM ID}
  displ_stat_dupvparm_k = 12;          {duplicate VPARM  definition}
  displ_stat_noparm_k = 13;            {missing parameter}
  displ_stat_extratk_k = 14;           {extra token}
  displ_stat_badtpid_k = 15;           {invalid TPARM ID}
  displ_stat_duptparm_k = 16;          {duplicate TPARM  definition}
  displ_stat_badlistid_k = 17;         {invalid list ID}
  displ_stat_undeflist_k = 18;         {undefined list referenced}
  displ_stat_undefcol_k = 19;          {undefined color referenced}
  displ_stat_undefvp_k = 20;           {undefined VPARM referenced}
  displ_stat_undeftp_k = 21;           {undefined TPARM referenced}
  displ_stat_2imgs_k = 22;             {multiple IMAGES commands}
  displ_stat_badimgid_k = 23;          {invalid image ID}
  displ_stat_dupimg_k = 24;            {duplicate IMAGE  definition}

type
  displ_item_p_t = ^displ_item_t;

  displ_color_p_t = ^displ_color_t;
  displ_color_t = record               {one fixed color}
    red: real;                         {0.0 to 1.0 color component intensities}
    grn: real;
    blu: real;
    opac: real;                        {0.0 to 1.0 opacity}
    id: sys_int_machine_t;             {assigned 1-N ID, 0 = unassigned}
    end;

  displ_vparm_p_t = ^displ_vparm_t;
  displ_vparm_t = record               {vector drawing parameters}
    vparm: rend_vect_parms_t;          {the RENDlib parameters}
    id: sys_int_machine_t;             {assigned 1-N ID, 0 = unassigned}
    end;

  displ_tparm_p_t = ^displ_tparm_t;
  displ_tparm_t = record               {text drawing parameters}
    tparm: rend_text_parms_t;          {the RENDlib parameters}
    id: sys_int_machine_t;             {assigned 1-N ID, 0 = unassigned}
    end;

  displ_rend_p_t = ^displ_rend_t;
  displ_rend_t = record                {all the current state that effects rendering}
    color_p: displ_color_p_t;          {points to current color}
    vect_parm_p: displ_vparm_p_t;      {points to vector drawing parameters}
    text_parm_p: displ_tparm_p_t;      {points to text drawing parameters}
    end;

  displ_p_t = ^displ_t;
  displ_t = record                     {top structure of a display list}
    mem_p: util_mem_context_p_t;       {points to mem context to use for this list}
    id: sys_int_machine_t;             {assigned 1-N ID, 0 = unassigned}
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
    displ_item_vect_k,                 {chain of linked vectors}
    displ_item_img_k);                 {overlay image}

  displ_img_p_t = ^displ_img_t;
  displ_img_t = record                 {info about one external image}
    id: sys_int_machine_t;             {assigned 1-N, 0 = unassigned}
    tnam_p: string_var_p_t;            {pnt to image file name, tnam after opened}
    dx, dy: sys_int_machine_t;         {image size in pixels}
    aspect: real;                      {width/height of properly displayed image}
    pix_p: img_scan1_arg_p_t;          {points to scan lines}
    end;

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
      vect_first_p: displ_coor2d_ent_p_t; {points to starting coordinate}
      vect_last_p: displ_coor2d_ent_p_t; {points to ending coordinate}
      vect_color_p: displ_color_p_t;   {points to color, NIL inherits}
      vect_parm_p: displ_vparm_p_t;    {points to vector properties, NIL iherits}
      );
displ_item_img_k: (                    {overlay image}
      img_p: displ_img_p_t;            {points to image descriptor}
      img_lft: real;                   {region where overlay image is displayed}
      img_rit: real;
      img_bot: real;
      img_top: real;
      img_xf: vect_xf2d_t;             {drawing --> overlay img pixel coor transform}
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

  displ_dagl_ent_p_t = ^displ_dagl_ent_t;
  displ_dagl_ent_t = record            {one entry in flattened DAG list}
    prev_p: displ_dagl_ent_p_t;        {points to previous list entry, parent direction}
    next_p: displ_dagl_ent_p_t;        {points to next list entry, child direction}
    list_p: displ_p_t;                 {points to the display list for this entry}
    id: sys_int_machine_t;             {sequential 1-N ID assigned, 1 is more parent}
    end;

  displ_dagl_color_p_t = ^displ_dagl_color_t;
  displ_dagl_color_t = record          {one color in list}
    next_p: displ_dagl_color_p_t;      {points to next list entry}
    col_p: displ_color_p_t;            {points to the color}
    end;

  displ_dagl_vparm_p_t = ^displ_dagl_vparm_t;
  displ_dagl_vparm_t = record          {one set of vector parameters in list}
    next_p: displ_dagl_vparm_p_t;      {points to next list entry}
    vparm_p: displ_vparm_p_t;          {points to the vector parameters}
    end;

  displ_dagl_tparm_p_t = ^displ_dagl_tparm_t;
  displ_dagl_tparm_t = record          {one set of text parameters in list}
    next_p: displ_dagl_tparm_p_t;      {points to next list entry}
    tparm_p: displ_tparm_p_t;          {points to the text parameters}
    end;

  displ_dagl_p_t = ^displ_dagl_t;
  displ_dagl_t = record                {linear list of DAG nodes with only fwd dependencies}
    mem_p: util_mem_context_p_t;       {mem context for all DAG list dynamic memory}
    first_p: displ_dagl_ent_p_t;       {points to first list entry, top parent}
    last_p: displ_dagl_ent_p_t;        {poitns to last list entry, no dependencies}
    nlist: sys_int_machine_t;          {number of display lists in DAG list}
    ncol: sys_int_machine_t;           {number of colors in list}
    nvparm: sys_int_machine_t;         {number of vector parameter sets in list}
    ntparm: sys_int_machine_t;         {number of test parameter sets in list}
    color_p: displ_dagl_color_p_t;     {points to list of colors}
    vparm_p: displ_dagl_vparm_p_t;     {points to list of vector parameters}
    tparm_p: displ_dagl_tparm_p_t;     {points to list of text parameters}
    end;
{
*   Subroutines and functions.
}
procedure displ_dagl_close (           {end use of DAG list, deallocate resources}
  in out  dagl: displ_dagl_t);         {the list to close}
  val_param; extern;

procedure displ_dagl_displ (           {fill in DAG list from one display list}
  in out  dagl: displ_dagl_t;          {the DAG list to add to}
  in var  displ: displ_t);             {the top level display list to add}
  val_param; extern;

procedure displ_dagl_open (            {start use of a DAG list}
  in out  mem: util_mem_context_t;     {parent memory context}
  out     dagl: displ_dagl_t);         {the DAG list to initialize}
  val_param; extern;

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

procedure displ_file_read (            {read display list from file}
  in      fnam: univ string_var_arg_t; {file name, will always end in ".displ"}
  in out  displ: displ_t;              {display list to add file data to the start of}
  out     stat: sys_err_t);            {returned completion status}
  val_param; extern;

procedure displ_file_write (           {write display list DAG to file}
  in      fnam: univ string_var_arg_t; {file name, will always end in ".displ"}
  in out  displ: displ_t;              {top lev disp list, all referenced data written}
  out     stat: sys_err_t);            {returned completion status}
  val_param; extern;

procedure displ_item_list (            {make current item reference to a list}
  in out  edit: displ_edit_t;          {list edit state, curr item must be type NONE}
  in var  list: displ_t);              {the list to reference}
  val_param; extern;

procedure displ_item_image (           {make current item an image overlay}
  in out  edit: displ_edit_t;          {list edit state, curr item must be type NONE}
  in var  img: displ_img_t);           {the image being referenced}
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

function  displ_list_draws (           {check whether display list causes drawing}
  in      list: displ_t)               {the display list to check}
  :boolean;                            {causes drawing}
  val_param; extern;

procedure displ_list_new (             {create a new display list}
  in out  mem: util_mem_context_t;     {parent mem context, subordinate created for list}
  out     list: displ_t);              {returned filled-in list descriptor}
  val_param; extern;
