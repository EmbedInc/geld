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
  posrd: geld_intvpos_t;               {position within list of readings of a meter}
  intv_p: geld_intv_p_t;               {to current meter reading interval}
  rdst, rden: sys_clock_t;             {start/end time of curr reading}
  kwh: real;                           {kWh consumed curr reading}
  sec: real;                           {time length of curr reading}
  watts: real;                         {average Watts consumed curr reading}
  comp: sys_compare_k_t;               {result of time comparison}

begin
  plotctrl.dataset.classes := geld_classset_all (geld_p^); {include all rate classes}
{
*   Set the time range of data to include to the min/max time range of all the
*   data.
}
  timeset := false;                    {init to start/end time not initialized}

  geld_id_pos_start (geld_p^, posid);  {to before first meter in list}
  while true do begin                  {back here each new meter}
    geld_id_next (geld_p^, posid, meter_p); {to next meter in list}
    if meter_p = nil then exit;        {hit end of meter IDs list ?}
    geld_intv_pos_start (meter_p^, posrd); {to before first reading this meter}
    while true do begin                {back here each new reading this meter}
      geld_intv_next (posrd, intv_p);  {to next reading interval this meter}
      if intv_p = nil then exit;       {done all readings this meter ?}
      geld_intv_get (                  {get the expanded data for this reading}
        intv_p^, meter_p^, rdst, rden, kwh, sec, watts);
      if not timeset
        then begin                     {no time interval previously set}
          plotctrl.dataset.tstart := rdst; {init data range start time}
          plotctrl.dataset.tend := rden; {init data range end time}
          timeset := true;             {indicate data time range initialized}
          end
        else begin                     {have existing data time range, expand it}
          comp := sys_clock_compare (rdst, plotctrl.dataset.tstart); {compare start}
          if comp = sys_compare_lt_k then begin {earlier ?}
            plotctrl.dataset.tstart := rdst; {update data range start time}
            end;
          comp := sys_clock_compare (rden, plotctrl.dataset.tend); {compare end}
          if comp = sys_compare_gt_k then begin {laster ?}
            plotctrl.dataset.tend := rden; {update data range end time}
            end;
          end
        ;
      end;                             {back for next reading this meter}
    end;                               {back for next meter IDs list entry}

  if not timeset then begin            {time interval not set ?}
    plotctrl.dataset.tstart := sys_clock; {initialize to something valid}
    plotctrl.dataset.tend := plotctrl.dataset.tstart;
    end;
  end;
