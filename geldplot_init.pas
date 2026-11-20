module geldplot_init;
define geldplot_init;
%include 'geldplot.ins.pas';
{
********************************************************************************
*
*   Subroutine GELDPLOT_INIT
*
*   Initialize the program state that depends on the GELD library being in use
*   or data values read from the input files.
}
procedure geldplot_init;               {init program state after data files read}
  val_param;

var
  timeset: boolean;                    {start/end set to valid time within data}
  posid: geld_idpos_t;                 {position within list of meter IDs}
  meter_p: geld_meter_p_t;             {to current meter}
  tst, ten: sys_clock_t;               {meter start/end times}
  comp: sys_compare_k_t;               {result of time comparison}

begin
  plotctrl.dataset.classes := geld_classset_all (geld_p^); {include all rate classes}
{
*   Set the time range of data to the min/max time range of all the data.
}
  timeset := false;                    {init to start/end time not initialized}

  geld_id_pos_start (geld_p^, posid);  {to before first meter in list}
  while true do begin                  {back here each new meter}
    geld_id_next (geld_p^, posid, meter_p); {to next meter in list}
    if meter_p = nil then exit;        {hit end of meter IDs list ?}
    if meter_p^.intv_first_p = nil then next;
    if meter_p^.intv_last_p = nil then next;
    tst := sys_clock_sub (             {starting time of first interval}
      sys_clock_from_clkmin32(meter_p^.intv_first_p^.tend), {interval end time}
      sys_clock_from_fp_rel(meter_p^.period) ); {minus interval length}
    ten :=                             {ending time of last interval}
      sys_clock_from_clkmin32(meter_p^.intv_last_p^.tend);
    if not timeset
      then begin                       {no time interval previously set}
        plotctrl.dataset.tstart := tst; {init data range start time}
        plotctrl.dataset.tend := ten;  {init data range end time}
        timeset := true;               {indicate data time range initialized}
        end
      else begin                       {have existing data time range, expand it}
        comp := sys_clock_compare (tst, plotctrl.dataset.tstart); {compare start}
        if comp = sys_compare_lt_k then begin {earlier ?}
          plotctrl.dataset.tstart := tst; {update data range start time}
          end;
        comp := sys_clock_compare (ten, plotctrl.dataset.tend); {compare end}
        if comp = sys_compare_gt_k then begin {laster ?}
          plotctrl.dataset.tend := ten; {update data range end time}
          end;
        end
      ;
    end;                               {back for next meter IDs list entry}

  if not timeset then begin            {time interval not set ?}
    plotctrl.dataset.tstart := sys_clock; {initialize to something valid}
    plotctrl.dataset.tend := plotctrl.dataset.tstart;
    end;
  end;
