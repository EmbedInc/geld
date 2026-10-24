module geld_avepower;
define geld_avepower;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_AVEPOWER (GELD, POWER, NPOWER, SLSEC, ST, EN, CLASSES)
*
*   Compute the average power consumed over a time interval into a fixed set of
*   time slices.  Power is averaged per meter, but summed across meters.
*
*   POWER is the array of returned averages for each time slice.  NPOWER is the
*   number of time slices, which is the number of entries in NPOWER.  SLSEC is
*   the size of each time slice in seconds.
*
*   ST and EN are the start and end times within which to compute the averages.
*
*   CLASSES is the set of rate classes to include in the averaged data.
*
*   The start of the first time slice is aligned with ST.  The time slice array
*   is wrapped as needed when the ending time exceeds the start time plus the
*   total length of the time slices in the POWER array.  Every point in time
*   therefore maps to some POWER array entry.
*
*   For example, if NPOWER is 24 and SLSEC is 3600, then the average power per
*   hour of the day will be accumulated for the entire ST to EN time range.  ST
*   to EN could be a week, month, year, etc.
}
procedure geld_avepower (              {compute average power over interval}
  in      geld: geld_t;                {library use state}
  out     power: univ geld_power_t;    {average power per time slice, Watts}
  in      npower: sys_int_machine_t;   {number of POWER entries, wrapped as needed}
  in      slsec: sys_int_machine_t;    {size of each slice, seconds}
  in      st, en: sys_clock_t;         {start and end time to average over}
  in      classes: geld_classset_t);   {set of rate classes to include}
  val_param;

type
  nave_t = array[0..128] of sys_int_conv32_t; {template for NAVE array}

var
  plast: sys_int_machine_t;            {last valid 0-N POWER array index}
  arsec: sys_int_conv32_t;             {seconds of all slices, returned array}
  winstart, winend: sys_clkmin32_t;    {window start/end time in absolute minutes}
  winsec: sys_int_conv32_t;            {window size in seconds}
  sz: sys_int_adr_t;                   {memory size}
  ave_p: geld_power_p_t;               {to accumulated values from curr meter}
  nave_p: ^nave_t;                     {to number of seconds accumulated each slice}
  ind: sys_int_machine_t;              {0-PLAST array index}
  posid: geld_idpos_t;                 {position in list of meter IDs}
  meter_p: geld_meter_p_t;             {to current meter accumulating data from}
  posrd: geld_intvpos_t;               {position in readings list of a meter}
  intv_p: geld_intv_p_t;               {to current meter reading}
  intvminend: sys_int_conv32_t;        {absolute minute of reading interval end}
  secst, secen: sys_int_conv32_t;      {abs seconds start and end of reading}
  watts: double;                       {Watts average during curr reading interval}
  secleft: sys_int_conv32_t;           {seconds left in current reading interval}
  secbase: sys_int_conv32_t;           {window seconds at curr wrap of slices}
  slst, slen: sys_int_conv32_t;        {window seconds at start/end curr slice}
  sec: sys_int_conv32_t;               {scratch seconds}

begin
  if npower <= 0 then return;          {no place to return any data ?}
  if slsec <= 0 then return;           {invalid slice length ?}

  plast := npower - 1;                 {make last valid 0-N POWER array index}
  arsec := npower * slsec;             {seconds for whole array (all slices)}
  winstart := sys_clock_to_clkmin32(st); {make window start time in abs minutes}
  winend := sys_clock_to_clkmin32(en); {make window end time in abs minutes}
  winsec := (winend - winstart) * 60;  {make window length in seconds}

  sz := npower * sizeof(ave_p^[0]);    {size of whole AVE array}
  sys_mem_alloc (sz, ave_p);           {create the AVE array}
  util_mem_grab_err_bomb (ave_p, sz);

  sz := npower * sizeof(nave_p^[0]);   {size of whole NAVE array}
  sys_mem_alloc (sz, nave_p);          {create the NAVE array}
  util_mem_grab_err_bomb (nave_p, sz);

  for ind := 0 to plast do begin       {once for each slice}
    power[ind] := 0.0;                 {init accumulated value}
    end;

  geld_id_pos_start (geld, posid);     {to before start of IDs list}
  while true do begin                  {back here each new meter ID in list}
    geld_id_next (geld, posid, meter_p); {get pointer to next meter in list}
    if meter_p = nil then exit;        {hit end of meter IDs list ?}
    if not geld_classset_in (geld, meter_p^.class, classes) {not including this class ?}
      then next;
    for ind := 0 to plast do begin     {init values from this meter}
      ave_p^[ind] := 0.0;              {init accumulated values}
      nave_p^[ind] := 0;               {init number of accumulated values}
      end;
    geld_intv_pos_time (meter_p^, st, posrd); {to before first reading in our window}
    while true do begin                {back here each new reading interval this meter}
      geld_intv_next (posrd, intv_p);  {to next reading for this meter}
      if intv_p = nil then exit;       {hit end of readings this meter ?}
      intvminend := intv_p^.tend;      {abs minutes end time of this reading}
      if intvminend <= winstart then next; {whole reading is before start of window ?}
      secen := (intvminend - winstart) * 60; {interval end in window seconds}
      secst := secen - meter_p^.period; {interval start in window seconds}
      if secst >= winsec then exit;    {whole interval is past end of window ?}
      watts := intv_p^.kwh * 3600000.0 / meter_p^.period; {ave Watts this interval}
      {
      *   The current interval extends from SECST to SECEN seconds into the
      *   window.  At least some part of the interval is within the window.
      *   WATTS is the average power in Watts during the interval.
      }
      secleft := secen - secst;        {init seconds left this interval}
      secbase := (secst div arsec) * arsec; {base window sec for this wrap of array}
      ind := (secst - secbase) div slsec; {make 0-N slice index for interval start}
      while secleft > 0 do begin       {accumulate into slices until interval exhausted}
        slst := secbase + (ind * slsec); {window seconds at start of slice}
        slen := slst + slsec;          {window seconds at end of slice}
        slst := max(slst, secst);      {clip to interval start}
        slen := min(slen, secen);      {clip to interval end}
        sec := slen - slst;            {seconds of interval within this slice}
        ave_p^[ind] := ave_p^[ind] + (watts * sec); {accumulate Joules this slice}
        nave_p^[ind] := nave_p^[ind] + sec; {update seconds Joules accumulated over}
        ind := ind + 1;                {to next slice}
        if ind > plast then ind := 0;  {wrap back to first slice ?}
        secleft := secleft - sec;      {update interval seconds left to accumulate}
        end;                           {back to accumulate into new slice}
      end;                             {back for next reading this meter}
    {
    *   Done accumulating data from all reading intervals this meter.
    }
    for ind := 0 to plast do begin     {once for each slice}
      if nave_p^[ind] <= 0 then next;  {no accumulated data this slice ?}
      power[ind] := power[ind] +       {add accumulated data from this slice}
        (ave_p^[ind] / nave_p^[ind]);
      end;                             {back for next data slice}
    end;                               {back for next meter in IDs list}

  sys_mem_dealloc (ave_p);             {release accumulated values array}
  sys_mem_dealloc (nave_p);            {release number of accumulated values array}
  end;
