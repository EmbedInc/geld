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
{
********************************************************************************
*
*   Subroutine GELDPLOT_DRAW (DATA, XRIT, YTOP)
*
*   Draw the plot data to the current RENDlib device as currently configured.
*   (XRIT,YTOP) is at the top right corner of the drawing area in the 2D space.
*   The bottom left corner is at (0,0).
*
*   RENDlib is assumed to not be in graphics mode.  This routine leaves the
*   graphics mode enter level the same as it was on entry.
}
procedure geldplot_draw (              {draw plot to RENDlib, drawing only}
  in      data: data_t;                {plot data to draw}
  in      xrit, ytop: real);           {top right draw area coor, 0,0 bottom left}
  val_param;

begin
  rend_set.enter_rend^;                {into graphics mode}

  rend_set.rgb^ (0.15, 0.15, 0.60);    {TEMP DEBUG - draw recognizable pattern}
  rend_prim.clear^;
  rend_set.rgb^ (1.0, 1.0, 1.0);
  rend_set.cpnt_2d^ (xrit, ytop/2.0);
  rend_prim.vect_2d^ (xrit/2.0, ytop);
  rend_prim.vect_2d^ (0.0, ytop/2.0);
  rend_prim.vect_2d^ (xrit/2.0, 0.0);
  rend_prim.vect_2d^ (xrit, ytop/2.0);

  rend_set.exit_rend^;                 {leave graphics mode}
  end;
