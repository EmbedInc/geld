{   Draw the plot to RENDlib.  Only the drawing is done to the current RENDlib
*   device in its current configuration.  Resizing, events, etc, are handled by
*   the caller.
}
module geldplot_draw;
define geldplot_draw;
%include 'geldplot.ins.pas';
%include 'vect.ins.pas';
%include 'img.ins.pas';
%include 'rend.ins.pas';
%include 'gui.ins.pas';
%include 'math.ins.pas';

const
  text_minfrac = 1.0 / 60.0;           {min text height rel to drawing height}
  text_minpix = 12.0;                  {min text height, final output pixels}
  text_vwid = 0.10;                    {text vector width, fraction of height}
  ticklen = 0.005;                     {length of ticks past edge of plot}
  tickspx = 0.2;                       {char cell space for label in X}
  tickspy = 0.4;                       {char call space for label in Y}
  chylab = 7.0;                        {char room for Y axis labels}
  chrit = 6.0;                         {char room right of plot}
  pmindx = 0.2;                        {min plot width}
  pmindy = 0.2;                        {min plot height}
  tick0b = 0.85;                       {brightness for level 0 tick mark}
  tick1b = 0.88;                       {brightness for level 1 tick mark}
  tick2b = 0.91;                       {brightness for level 2 and higher tick mark}
  h48b = 0.95;                         {brightness for 16:00-20:00 hours background}
  hue0 = 2.0;                          {hue for first trace, 0 RED 1 GRN 2 BLU}
  sat = 1.0;                           {0-1 saturation for data traces}
  inten = 1.0;                         {0-1 intensity for data traces}
  ytop = 1.03;                         {top plot Y as fraction of max data value}
  colspl = 0.9;                        {char cell space left of color rect}
  colspr = 0.3;                        {char cell space right of color rect}
  coldx = 1.5;                         {char cell width of color rect}
  coldy = 1.0;                         {char cell height of color rect}
{
********************************************************************************
*
*   Subroutine GELDPLOT_DRAW (CFG, DATA)
*
*   Draw the plot data to the current RENDlib device as currently configured.
*   CFG describes the configuration of the drawing device.  DATA is the data to
*   show with the plot.
*
*   RENDlib is assumed to not be in graphics mode.  This routine leaves the
*   graphics mode enter level the same as it was on entry.
}
procedure geldplot_draw (              {draw plot to RENDlib, drawing only}
  in      cfg: drawcfg_t;              {draw area configuration}
  in      data: data_t);               {plot data to draw}
  val_param;

var
  x, y: real;                          {scratch X and Y values}
  xy: vect_2d_t;                       {scratch X,Y coordinate}
  pnt1, pnt2: vect_2d_t;               {scratch 2D coordinates}
  r: real;                             {scratch floating point}
  s: string_var80_t;                   {scratch string}
  tk: string_var32_t;                  {scratch token}
  tick_p: gui_tick_p_t;                {to tick mark description}
  arrn: sys_int_machine_t;             {0-N number of array being plotted}
  hue: real;                           {0-3 color hue}
  dhue: real;                          {hue change per data array}
  col: rend_rgb_t;                     {scratch RGB color}
  ii: sys_int_machine_t;               {scratch integer and loop counter}
  class_p: data_class_p_t;             {to data for current rate class}

  pixx, pixy: real;                    {drawing area size in pixels}
  scalex, scaley: real;                {final output to drawing area pixels scale}
  tparm: rend_text_parms_t;            {text control parameters}
  chardx, chardy: real;                {character cell width and height}
  xfdat: vect_xf2d_t;                  {data value to drawing coordinate transform}

  plftx, pritx, pboty, ptopy: real;    {edges of plot area}
  tickx: real;                         {left X of Y axis tick marks}
  ticky: real;                         {bottom Y of X axis tick marks}
  coll, colr: real;                    {color rectangles left/right X}
  colt: real;                          {start of text X right of color rect}

label
  next_ytick;
{
********************************************************************************
*
*   Local function PLOTX (DATX)
*   This function is internal to GELDPLOT_DRAW.
*
*   Convert the X axis data value to the corresponding drawing area X.
}
function plotx (                       {drawing X from X axis data value}
  in      datx: real)                  {X axis data value}
  :real;                               {2D space X}
  val_param; internal;

begin
  plotx := datx * xfdat.xb.x + xfdat.ofs.x;
  end;
{
********************************************************************************
*
*   Local function PLOTY (DATY)
*   This function is internal to GELDPLOT_DRAW.
*
*   Convert the Y axis data value to the corresponding drawing area Y.
}
function ploty (                       {drawing Y from Y axis data value}
  in      daty: real)                  {Y axis data value}
  :real;                               {2D space Y}
  val_param; internal;
{
********************************************************************************
*
*   Start of GELDPLOT_DRAW main routine.
}
begin
  ploty := daty * xfdat.yb.y + xfdat.ofs.y;
  end;

begin
  tk.max := size_char(tk.str);         {init local var strings}
  s.max := size_char(s.str);
{
*   Determine parameters about the drawing area.
}
  xy.x := 0.0;
  xy.y := 0.0;
  rend_get.xfpnt_2d^ (xy, pnt1);       {find lower left in 2DIM space}
  xy.x := cfg.xrit;
  xy.y := cfg.ytop;
  rend_get.xfpnt_2d^ (xy, pnt2);       {find upper right in 2DIM space}

  pixx := round(pnt2.x - pnt1.x);      {drawing area width in pixels}
  pixy := round(pnt1.y - pnt2.y);      {drawing area height in pixels}

  scalex := pixx / cfg.xout;           {find final output to drawing area scale factors}
  scaley := pixy / cfg.yout;
{
*   Set the text size to be the larger of TEXT_MINFRAC fraction of the drawing
*   area height or TEXT_MINPIX pixels in the final image.
}
  r := text_minpix * scaley / pixy;    {2D text size according to min pixel size}
  r := max(r, text_minfrac * cfg.ytop); {apply min fraction of drawing area size}

  rend_get.text_parms^ (tparm);        {get the current text parameters}
  tparm.size := r;                     {set text size, pixels in 2DIM space}
  tparm.coor_level := rend_space_2d_k; {coor space to draw text to}
  tparm.vect_width := text_vwid;       {vector width relative to char cell height}
  tparm.poly := cfg.aa;                {draw vectors as polygons if anti-aliasing}
  tparm.end_org := rend_torg_down_k;   {down line line after draw text}
  rend_set.text_parms^ (tparm);        {update text parameters}

  chardx := tparm.size * tparm.width;  {save character cell width}
  chardy := tparm.size * tparm.height; {save character cell height}
{
*   Determine locations and sizes of various parts of the drawing.
}
  r := chylab + tickspx;               {char room left of Y axis ticks}
  r := r * chardx;                     {room in 2D space}
  tickx := r;                          {left end of Y axis ticks}

  plftx := tickx + ticklen;            {plot area left edge}

  r := colspl + coldx + colspr + chrit; {char cell room required right of plot}
  pritx := cfg.xrit - (r * chardx);    {plot area right edge}

  r := 3.0 + (3.0 * tparm.lspace) + tickspy; {char room below X axis ticks}
  r := r * chardy;                     {room in 2D space}
  ticky := r;                          {bottom end of X axis ticks}

  pboty := ticky + ticklen;            {plot area bottom edge}

  r := 1.5 + (2.0 * tparm.lspace);     {char room above plot}
  r := r * chardy;                     {room in 2D space}
  ptopy := cfg.ytop - r;               {plot area top edge}

  r := pritx - plftx;                  {total plot width}
  if r < pmindx then begin             {smaller than allowed ?}
    r := (plftx + pritx) / 2.0;        {middle}
    plftx := r - pmindx / 2.0;
    pritx := plftx + pmindx;
    end;
  r := ptopy - pboty;                  {total plot height}
  if r < pmindy then begin             {smaller than allowed ?}
    r := (pboty + ptopy) / 2.0;        {middle}
    pboty := r - pmindy / 2.0;
    ptopy := pboty + pmindy;
    end;

  coll := pritx + (colspl * chardx);   {left X of color rectangles}
  colr := coll + (coldx * chardx);     {right X of color rectangles}
  colt := colr + (colspr * chardx);    {left X of color rectangles labels}
{
*   Set up the 2D transform from data values to drawing coordinates.
}
  xfdat.xb.x := (pritx - plftx) / (data.slsec * data.ndat);
  xfdat.xb.y := 0.0;
  xfdat.yb.x := 0.0;
  xfdat.yb.y := (ptopy - pboty) / (data.data_p^.max * ytop);
  xfdat.ofs.x := plftx;
  xfdat.ofs.y := pboty;
{
*   Draw the plot.
}
  rend_set.enter_rend^;                {into graphics mode}
  {
  *   Init everything to the background.
  }
  rend_set.rgb^ (1.0, 1.0, 1.0);       {init everything to white}
  rend_prim.clear^;
  {
  *   Draw the plot title.
  }
  rend_set.rgb^ (0.0, 0.0, 0.0);       {color}
  tparm.start_org := rend_torg_um_k;   {curr pnt at top center of string}
  rend_set.text_parms^ (tparm);        {update text parameters}
  rend_set.cpnt_2d^ (                  {to top center of title string}
    cfg.xrit / 2.0,
    cfg.ytop - tparm.lspace * chardy);
  rend_prim.text^ (plotctrl.title.str, plotctrl.title.len);
  {
  *   Shade the background for 16:00 to 20:00 hours if the X axis is hours of
  *   the day.
  }
  if plotctrl.xaxis.cfg = xaxis_cfg_day_k then begin {X axis is hours of day ?}
    pnt1.x := plotx (16.0 * 3600.0);   {get left X}
    pnt2.x := plotx (20.0 * 3600.0);   {get right X}
    rend_set.rgb^ (h48b, h48b, h48b);
    rend_set.cpnt_2d^ (pnt1.x, pboty);
    rend_prim.rect_2d^ (pnt2.x - pnt1.x, ptopy - pboty);
    end;
  {
  *   Draw the horizontal grid lines, tick marks, and labels.
  }
  tparm.start_org := rend_torg_mr_k;   {curr pnt at middle right of text string}
  rend_set.text_parms^ (tparm);        {update text parameters}

  gui_ticks_make (                     {compute tick marks and labels}
    0.0, data.data_p^.max * ytop,      {range of data values}
    ptopy - pboty,                     {corresponding drawing range}
    false,                             {labels are stacked vertically}
    data.mem_p^,                       {parent memory context}
    tick_p);                           {to first tick definition}

  while tick_p <> nil do begin         {loop over the tick marks}
    case tick_p^.level of              {what level is this tick mark ?}
0:    r := tick0b;
1:    r := tick1b;
2:    r := tick2b;
otherwise
      goto next_ytick;                 {ignore this tick}
      end;
    rend_set.rgb^ (r, r, r);           {set color for this tick mark}
    y := ploty(tick_p^.val);           {get Y for this tick}
    rend_set.cpnt_2d^ (pritx, y);      {to right end}
    if tick_p^.lab.len <= 0
      then begin                       {no label}
        rend_prim.vect_2d^ (plftx, y);
        end
      else begin                       {this tick mark has a label}
        rend_prim.vect_2d^ (tickx, y);
        rend_set.rcpnt_2d^ (-tickspx * chardx, 0.0); {leave room right of label}
        rend_set.rgb^ (0.0, 0.0, 0.0); {draw labels in full black}
        rend_prim.text^ (tick_p^.lab.str, tick_p^.lab.len); {draw the tick label}
        end
      ;
next_ytick:                            {advance to the next tick mark}
    tick_p := tick_p^.next_p;
    end;                               {back to handle this new tick mark}

  rend_set.rgb^ (0.0, 0.0, 0.0);       {units label full black}
  tparm.start_org := rend_torg_lr_k;   {anchor text at lower right}
  rend_set.text_parms^ (tparm);
  rend_set.cpnt_2d^ (                  {to lower right of Y units label}
    tickx - tickspx * chardx,
    ptopy + ((tparm.height * 0.5) + tparm.lspace) * tparm.size);
  string_vstring (s, 'Watts'(0), -1);
  rend_prim.text^ (s.str, s.len);
  {
  *   Draw the X axis vertical grid lines, tick marks, and labels.
  }
  case plotctrl.xaxis.cfg of           {what is being shown on X axis ?}

xaxis_cfg_day_k: begin                 {hours within day}
  tparm.start_org := rend_torg_um_k;   {anchor text at top center}
  rend_set.text_parms^ (tparm);
  for ii := 0 to 24 do begin           {once for each hour tick}
    x := plotx (ii * 3600.0);          {make X of this tick}
    string_f_int (s, ii);              {make label string}
    rend_set.rgb^ (tick0b, tick0b, tick0b);
    rend_set.cpnt_2d^ (x, ptopy);      {to top end of tick}
    rend_prim.vect_2d^ (x, ticky);     {draw tick to bottom end}
    rend_set.rcpnt_2d^ (0.0, -tickspy * chardy); {leave room above label}
    rend_set.rgb^ (0.0, 0.0, 0.0);     {draw labels in full black}
    rend_prim.text^ (s.str, s.len);    {draw the label for this tick}
    end;                               {back for next tick}

  rend_set.cpnt_2d^ (                  {to top center of X units label}
    (plftx + pritx) / 2.0,
    ticky - (tickspy + 1.0 + tparm.lspace) * chardy);
  rend_prim.text^ (data.labx.str, data.labx.len); {write X axis units}
  end;

xaxis_cfg_year_k: begin                {days within year}
  end;

    end;                               {end of X axis configuration cases}
  {
  *   Plot the data arrays.
  }
  tparm.start_org := rend_torg_ml_k;   {anchor text at middle left}
  rend_set.text_parms^ (tparm);

  ii := data.narr - 2;                 {number of hue jumps needed}
  ii := max(ii, 1);                    {avoid dividing by 0}
  dhue := -3.0 / (ii + 1);             {save delta hue per array}

  class_p := data.data_p;              {init to first class in list}
  arrn := 0;                           {init 0-N number of this array}
  while class_p <> nil do begin        {once for each trace to draw}
    {
    *   Set the color to show this data array with.
    }
    if arrn = 0
      then begin                       {totals array}
        if data.narr = 1
          then begin                   {only drawing this one trace}
            math_ihs_rgb (             {convert color to RGB}
              inten, hue0, sat,        {input intensity, hue, saturation}
              col.red, col.grn, col.blu); {returned RGB}
            end
          else begin                   {multiple traces, this one is totals}
            col.red := 0.0;            {show totals in black}
            col.grn := 0.0;
            col.blu := 0.0;
            end
          ;
        end
      else begin                       {data array is for a specific rate class}
        hue := hue0 + (arrn - 1) * dhue; {make hue value for this trace}
        r := abs(hue - 0.5);           {distance from yellow}
        r := r / 0.5;                  {adjust to full distance 0.5 hue away}
        r := min(r, 1.0);              {clip to no effect past full distance}
        r := 1.0 - 0.10 * (1.0 - r);   {scale to make final color intensity}
        math_ihs_rgb (                 {convert color to RGB}
          r, hue, sat,                 {input intensity, hue, saturation}
          col.red, col.grn, col.blu);  {returned RGB}
        end
      ;
    rend_set.rgb^ (col.red, col.grn, col.blu); {set color for this trace}
    {
    *   Draw the trace.
    }
    x := plftx;
    y := ploty ((class_p^.dat[0] + class_p^.dat[data.ndat-1]) / 2.0);
    rend_set.cpnt_2d^ (x, y);          {start at average of first and last}

    for ii := 0 to data.ndat-1 do begin {loop over the array entries}
      x := plotx ((ii + 0.5) * data.slsec);
      y := ploty (class_p^.dat[ii]);
      rend_prim.vect_2d^ (x, y);
      end;

    x := pritx;
    y := ploty ((class_p^.dat[0] + class_p^.dat[data.ndat-1]) / 2.0);
    rend_prim.vect_2d^ (x, y);         {end at average of first and last}
    {
    *   Draw the color rectangle for this trace and label it.  The current color
    *   is set to the color for this trace.
    }
    pnt2.y := ptopy - arrn * (1.0 + tparm.lspace) * chardy; {top Y of color rect}
    pnt1.y := pnt2.y - (coldy * chardy); {bottom Y of color rect}
    rend_set.cpnt_2d^ (coll, pnt1.y);  {draw the color rectangle}
    rend_prim.rect_2d^ (colr - coll, pnt2.y - pnt1.y);

    rend_set.rgb^ (0.0, 0.0, 0.0);     {draw the label in full black}
    rend_set.cpnt_2d^ (colt, (pnt1.y + pnt2.y) / 2.0);
    geld_rateclass_t_code (            {get the text code for this rate class}
      geld_p^,                         {GELD library use state}
      class_p^.id,                     {rate class ID}
      s);                              {returned rate class code string}
    if s.len = 0 then begin            {not a valid rate class ID}
      string_vstring (s, 'Total'(0), -1);
      end;
    rend_prim.text^ (s.str, s.len);    {draw the label for this trace}
    {
    *   Advance to next trace.
    }
    class_p := class_p^.next_p;        {to next data array}
    arrn := arrn + 1;                  {update 0-N number of curr array}
    end;                               {back to draw next trace}

  rend_set.exit_rend^;                 {leave graphics mode}
  end;
