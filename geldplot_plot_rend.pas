module geldplot_plot_rend;
define geldplot_plot_rend;
%include 'geldplot.ins.pas';
%include 'vect.ins.pas';
%include 'img.ins.pas';
%include 'rend.ins.pas';
{
********************************************************************************
*
*   Subroutine GELDPLOT_PLOT_REND (STAT)
*
*   Draw the plot as currently configured using RENDlib.
}
procedure geldplot_plot_rend (         {plot data using RENDlib}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  dat_p: geld_power_p_t;               {to data values}
  ndat: sys_int_machine_t;             {number of data values at DAT_P}
  slsec: sys_int_machine_t;            {data slice time, seconds}
  slx: real;                           {X axis increment per slice}
  sz: sys_int_adr_t;                   {memory size}
  live: boolean;                       {display is live, interactions with user}

  rendopen: boolean;                   {RENDlib is open}
  rendev: rend_dev_id_t;               {RENDlib drawing device ID}
  tparm: rend_text_parms_t;            {our base text control parameters}
  pparm: rend_poly_parms_t;            {our base polygon control parameters}
  vparm: rend_vect_parms_t;            {our base vector control parameters}
  bitmap: rend_bitmap_handle_t;        {handle to bitmap for main drawing}
  bitmap_alloc: boolean;               {pixels are allocated to the bitmap}
  sizex, sizey: sys_int_machine_t;     {drawing area size, pixels}
  aspect: real;                        {DX/DY aspect ratio of drawing device}
  xrit, ytop: real;                    {right/top 2D coor, 0,0 in center}
  ev: rend_event_t;                    {one interactive event}

  str: string_var132_t;                {scratch string}
  tk: string_var32_t;                  {scratch token}

label
  resize, redraw, next_event, done_drawing, abort1, leave;

begin
  str.max := size_char(str.str);       {init local var strings}
  tk.max := size_char(tk.str);
  dat_p := nil;                        {init to data array not allocated}
  rendopen := false;                   {init to RENDlib is not open}

  case plotctrl.xaxis.cfg of           {how is X axis configured ?}
xaxis_cfg_day_k: begin                 {one day, compute data per minute}
      ndat := 24 * 60;                 {number of 1-minute time slices in a day}
      slsec := 60;                     {data slice length, seconds}
      slx := 1.0 / 60.0;               {X axis increment per slice}
      end;
xaxis_cfg_year_k: begin                {one year, compute data per day}
      ndat := 365;                     {number of 1-day time slices in a year}
      slsec := 24 * 60 * 60;           {data slice length, seconds}
      slx := 1.0;                      {X axis increment per slice}
      end;
otherwise
    sys_stat_set (sys_subsys_k, sys_stat_not_impl_name_k, stat);
    sys_stat_parm_str ('X axis configuration', stat);
    return;
    end;

  sz := ndat * sizeof(dat_p^[1]);      {size of data array}
  sys_mem_alloc (sz, dat_p);           {allocate the data array}
  util_mem_grab_err_bomb (dat_p, sz);  {bomb on didn't get the memory}

  geld_avepower (                      {compute the averaged data}
    geld_p^,                           {GELD library use state}
    dat_p^,                            {array to return the data in}
    ndat,                              {number of entries in data array}
    slsec,                             {seconds data time per array entry}
    plotctrl.dataset.tstart,           {start time of data to include}
    plotctrl.dataset.tend,             {end time of data to include}
    plotctrl.dataset.classes);         {rate classes to include}
{
*   DAT_P points to the averaged data to show.
}
  rend_start;                          {start and initialize RENDlib}
  rendopen := true;                    {indicate RENDlib is now open}
  live := false;                       {init to display is not live}

  str.len := 0;                        {init RENDlib device string}
  case plotctrl.outty of               {what device to draw plot on ?}
outty_screen_k: begin                  {draw to whole screen}
      string_appends (str, '*screen*'(0));
      live := true;                    {display is live, user may interact}
      end;
outty_window_k: begin                  {to window on the screen}
      string_appends (str, '*window* :. -root -pos '(0));
      string_f_int (tk, plotctrl.posx);
      string_append (str, tk);
      string_append1 (str, ' ');
      string_f_int (tk, plotctrl.posy);
      string_append (str, tk);
      string_appends (str, ' -size '(0));
      string_f_int (tk, plotctrl.sizex);
      string_append (str, tk);
      string_append1 (str, ' ');
      string_f_int (tk, plotctrl.sizey);
      string_append (str, tk);
      live := true;                    {display is live, user may interact}
      end;
outty_file_k: begin                    {to image file}
      string_appends (str, '*sw* size '(0));
      string_f_int (tk, plotctrl.sizex);
      string_append (str, tk);
      string_append1 (str, ' ');
      string_f_int (tk, plotctrl.sizey);
      string_append (str, tk);
      string_appends (str, ' aspect '(0));
      string_f_int (tk, plotctrl.sizex);
      string_append (str, tk);
      string_append1 (str, ' ');
      string_f_int (tk, plotctrl.sizey);
      string_append (str, tk);
      end;
otherwise
    writeln ('Unexpected PLOTCTRL.OUTTY of ', ord(plotctrl.outty), ' in GELDPLOT_PLOT_REND.');
    sys_bomb;
    end;
{
*   Set up the RENDlib basics.  This is all the one-time setup that can be done
*   independent of the drawing area size.
}
  rend_open (str, rendev, stat);       {open the drawing device}
  if sys_error(stat) then goto leave;
  rend_set.enter_rend^;                {into graphics mode}

  rend_get.text_parms^ (tparm);        {get default text control parameters}
  tparm.width := 0.72;
  tparm.height := 1.0;
  tparm.slant := 0.0;
  tparm.rot := 0.0;
  tparm.lspace := 0.7;
  tparm.coor_level := rend_space_2d_k;
  tparm.poly := false;
  rend_set.text_parms^ (tparm);        {set our new "base" text control parameters}

  rend_get.poly_parms^ (pparm);        {get default polygon control parameters}
  pparm.subpixel := true;
  rend_set.poly_parms^ (pparm);        {set our new "base" polygon control parms}

  rend_get.vect_parms^ (vparm);        {get default vector control parameters}
  vparm.width := 2.0;
  vparm.poly_level := rend_space_none_k;
  vparm.subpixel := false;
  rend_set.vect_parms^ (vparm);        {set our new "base" vector control parameters}

  rend_set.alloc_bitmap_handle^ (      {create handle for our software bitmap}
    rend_scope_dev_k,                  {deallocate handle when device closed}
    bitmap);                           {returned bitmap handle}
  bitmap_alloc := false;               {init to no pixels allocated to bitmap}

  rend_set.iterp_bitmap^ (rend_iterp_red_k, bitmap, 0); {bind interpolants to bitmap}
  rend_set.iterp_bitmap^ (rend_iterp_grn_k, bitmap, 1);
  rend_set.iterp_bitmap^ (rend_iterp_blu_k, bitmap, 2);

  rend_set.iterp_on^ (rend_iterp_red_k, true); {enable the interpolants}
  rend_set.iterp_on^ (rend_iterp_grn_k, true);
  rend_set.iterp_on^ (rend_iterp_blu_k, true);

  rend_set.min_bits_vis^ (24.0);       {try for high color resolution}

  rend_set.update_mode^ (rend_updmode_buffall_k); {buffer SW updates for speed sake}

  if live then begin                   {drawing will be live to the user ?}
    rend_set.event_req_close^ (true);  {enable CLOSE, CLOSE_USER}
    rend_set.event_req_wiped_resize^ (true); {redraw due to size change}
    rend_set.event_req_wiped_rect^ (true); {redraw due to got corrupted}
    rend_set.event_req_key_on^ (       {request ENTER key events}
      rend_get.key_sp^ (rend_key_sp_enter_k, 0), {ID for ENTER key}
      0);                              {user ID for this key, unused}
    rend_event_req_stdin_line (true);  {get user ENTER events}
    end;

  rend_set.exit_rend^;                 {leave graphics mode}
{
*   Configure to the current graphics device drawing area.  We also get back
*   here when the display is live and the user resizes the display area.
}
resize:
  rend_set.enter_rend^;                {into graphics mode}

  rend_get.image_size^ (sizex, sizey, aspect);
  if aspect >= 1.0
    then begin                         {wider than tall}
      xrit := aspect;
      ytop := 1.0;
      end
    else begin                         {taller than wide}
      xrit := 1.0;
      ytop := 1.0 / aspect;
      end
    ;
  if bitmap_alloc then begin           {bitmap has pixels allocated ?}
    rend_set.dealloc_bitmap^ (bitmap); {deallocate the pixels}
    bitmap_alloc := false;             {indicate pixels not allocated}
    end;
  rend_set.alloc_bitmap^ (             {allocate pixels for our bitmap}
    bitmap,                            {bitmap to allocate pixels for}
    sizex, sizey,                      {number of pixels in each dimension}
    3,                                 {address units per pixel}
    rend_scope_dev_k);                 {pixel memory will be in device scope}
  bitmap_alloc := true;                {indicate bitmap has pixels allocated}

  rend_set.exit_rend^;                 {leave graphics mode}
{
*   Draw the plot contents.  We also get back here when the display is live and
*   parts need to be redrawn due to user or system actions.
}
redraw:
  rend_set.enter_rend^;                {into graphics mode}

  {***** TEMP DEBUG *****
  }
  rend_set.rgb^ (0.15, 0.15, 0.60);
  rend_prim.clear^;
  rend_set.rgb^ (1.0, 1.0, 1.0);
  rend_set.cpnt_2d^ (xrit, 0.0);
  rend_prim.vect_2d^ (0.0, ytop);
  rend_prim.vect_2d^ (-xrit, 0.0);
  rend_prim.vect_2d^ (00, -ytop);
  rend_prim.vect_2d^ (xrit, 0.0);

  rend_set.exit_rend^;                 {leave graphics mode}
{
*   If the drawing is live, wait for the user to end the display.  Regions may
*   also need re-drawing, and the drawing device size can change.
}
  if not live then goto done_drawing;

next_event:
  rend_event_get (ev);                 {get next live event}
  case ev.ev_type of                   {what kind of event is this ?}

rend_ev_close_k,
rend_ev_close_user_k,
rend_ev_stdin_line_k,
rend_ev_key_k: begin
      goto done_drawing;
      end;

rend_ev_resize_k,
rend_ev_wiped_resize_k: begin
      goto resize;
      end;

rend_ev_wiped_rect_k: begin
      goto redraw;
      end;

    end;                               {end of which event cases}
  goto next_event;                     {back to wait for and get next event}
{
*   Done with all drawing.  If the display is live, then it can now be deleted.
}
done_drawing:
  sys_mem_dealloc (dat_p);             {deallocate the data array}

  if live then begin                   {live display, all done ?}
    goto leave;
    end;
{
*   The display was not live.  Write the resulting bitmap to an image file.
}
  rend_set.enter_rend^;                {into graphics mode}
  rend_set.image_write^ (              {write bitmap to image file}
    plotctrl.fnam,                     {image file name}
    0, 0,                              {top left bitmap pixel to write}
    plotctrl.sizex, plotctrl.sizey,    {size of bitmap area to write}
    stat);
  if sys_error(stat) then goto abort1;
  rend_set.exit_rend^;                 {leave graphics mode}

leave:                                 {common exit point, STAT set}
  if dat_p <> nil then begin           {data array still allocated ?}
    sys_mem_dealloc (dat_p);           {deallocate it}
    end;
  if rendopen then begin               {RENDlib is open ?}
    rend_end;                          {close RENDlib, deallocate resources}
    end;
  return;

abort1:                                {error, STAT is set to indicate the error}
  goto leave;
  end;
