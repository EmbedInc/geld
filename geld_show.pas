{   Routines to show data to the user via STDOUT.
}
module geld_show;
define geld_show_meter;
define geld_show_intv;
define geld_show_read_stats;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_SHOW_METER (GELD, METER)
*
*   Show basic one-line info about the meter from the current output position.
}
procedure geld_show_meter (            {show basic info about a meter}
  in      geld: geld_t;                {library use state}
  in      meter: geld_meter_t);        {meter to show info about}
  val_param;

var
  r: real;                             {scratch floating point}
  tk: string_var32_t;                  {scratch token}

begin
  tk.max := size_char(tk.str);         {init local var string}

  write (meter.id:10);                 {meter ID}

  geld_rateclass_t_code (geld, meter.class, tk); {make rate class code}
  if tk.len = 0 then begin             {no rate class set ?}
    string_vstring (tk, '--', 2);      {show dashes}
    end;
  write (', rate class ', tk.str:tk.len);

  write (', mult', meter.mult:8:2);    {show meter multiplier}

  r := geld_meter_period (meter);      {get meter period in seconds}
  r := r / 60.0;                       {convert to minutes}
  write (', per', r:6:1, ' min');

  write (', Nrd', meter.nintv:9);

  string_f_fp_fixed (tk, meter.kwh, 1);
  write (', ', tk.str:tk.len, ' kWh');

  writeln;
  end;
{
********************************************************************************
*
*   Subroutine GELD_SHOW_INTV (INTV, METER)
*
*   Show the data for one measured interval.
}
procedure geld_show_intv (             {show measured interval}
  in      intv: geld_intv_t;           {the interval to show}
  in      meter: geld_meter_t);        {meter that measured the interval}
  val_param;

var
  st, en: sys_clock_t;                 {reading start and end times}
  kwh: real;                           {total kWh consumed during interval}
  sec: real;                           {interval length, seconds}
  watts: real;                         {average Watts consumed during interval}
  date: sys_date_t;                    {expanded date/time}
  tk: string_var32_t;                  {scratch string}
  un: string_var16_t;                  {units}
  stat: sys_err_t;                     {completion status}

begin
  tk.max := size_char(tk.str);         {init local var strings}
  un.max := size_char(un.str);

  geld_intv_get (                      {get the data about the measured interval}
    intv, meter,                       {interval and meter that measured it}
    st, en,                            {interval start and end times}
    kwh,                               {total power consumed, kWh}
    sec,                               {interval duration, seconds}
    watts);                            {average power consumed, Watts}

  sys_clock_to_date (                  {make expanded date/time from start time}
    st,                                {time value to convert}
    sys_tzone_east_usa_k,              {time zone to convert into}
    0.0,                               {time zone hours west, not used}
    sys_daysave_appl_k,                {apply daylight savings time}
    date);                             {returned expanded date/time}
{
*   Show the start time as YYYY/MM/DD.HH:MM.
}
  sys_date_string (date, sys_dstr_year_k, 4, tk, stat); {year}
  write (tk.str:tk.len);
  sys_date_string (date, sys_dstr_mon_k, 2, tk, stat); {month number}
  write ('/', tk.str:tk.len);
  sys_date_string (date, sys_dstr_day_k, 2, tk, stat); {day number}
  write ('/', tk.str:tk.len);
  sys_date_string (date, sys_dstr_hour_k, 2, tk, stat); {hour}
  write ('.', tk.str:tk.len);
  sys_date_string (date, sys_dstr_min_k, 2, tk, stat); {minute}
  write (':', tk.str:tk.len);

  string_f_fp_fixed (tk, sec/60.0, 1); {duration in minutes}
  write (' ', tk.str:tk.len, ' min');

  write (kwh:8:1, ' kWh');

  string_f_fp_eng (tk, watts, 3, un);
  write ('  ', tk.str:tk.len, ' ', un.str:un.len, 'W');

  writeln;
  end;
{
********************************************************************************
*
*   Local subroutine SHOW_CLASS (GELD, CL)
*
*   Show the statistics for the rate class CL.
}
procedure show_class (                 {show stats for one rate class}
  in      geld: geld_t;                {library use state}
  in      cl: sys_int_machine_t);      {ID of rate class to show stats for}
  val_param; internal;

var
  totals: boolean;                     {showing totals for all rate classes}
  tk: string_var32_t;                  {scratch token}
  jj: sys_int_conv32_t;                {scratch 32 bit integer}
  d: double;                           {scratch floating point}
  stat: sys_err_t;                     {completion status}

begin
  tk.max := size_char(tk.str);         {init local var string}
{
*   Validate CL and set TOTALS according to whether showing the totals for all
*   rate classes or the values for a specific rate class.
}
  if cl = geld_rateclass_none_k
    then begin                         {show totals for all rate classes}
      totals := true;
      end
    else begin                         {show data for the specific rate class CL}
      if (cl < 1) or (cl > geld.nrateclasses) then return; {invalid rate class ID ?}
      totals := false;
      end
    ;
{
*   Show rate class code or "Total".
}
  if totals
    then string_vstring (tk, 'Total'(0), -1)
    else geld_rateclass_t_code (geld, cl, tk);
  string_nblanks (5 - tk.len);
  write (tk.str:tk.len);
{
*   Show number of meters.
}
  if totals
    then jj := geld.nmeters
    else jj := geld.rateclass_p^[cl].nmeters;
  write (jj:8);                        {show number of meters}
{
*   Show number of meter readings.
}
  if totals
    then d := geld.nintv
    else d := geld.rateclass_p^[cl].nintv;
  string_f_fp (                        {make number of readings string}
    tk,                                {output string}
    d,                                 {input number}
    13,                                {field width}
    0,                                 {free format exponent (not used)}
    1,                                 {min required significant digits}
    13,                                {max digits allowed left of point}
    0, 0,                              {min/max digits allowed right of point}
    [string_ffp_group_k],              {show digits in groups}
    stat);
  sys_error_abort (stat, '', '', nil, 0);
  write (tk.str:tk.len);
{
*   Show consumed kWh.
}
  if totals
    then d := geld.kwh
    else d := geld.rateclass_p^[cl].kwh;
  string_f_fp (                        {make kWh string}
    tk,                                {output string}
    d,                                 {input number}
    13,                                {field width}
    0,                                 {free format exponent (not used)}
    1,                                 {min required significant digits}
    13,                                {max digits allowed left of point}
    0, 0,                              {min/max digits allowed right of point}
    [string_ffp_group_k],              {show digits in groups}
    stat);
  sys_error_abort (stat, '', '', nil, 0);
  write (tk.str:tk.len);
{
*   Show percent of total energy.
}
  if geld.kwh > 0.1
    then begin
      if totals
        then d := geld.kwh
        else d := geld.rateclass_p^[cl].kwh;
      d := d / geld.kwh;               {make fraction of total power used}
      d := d * 100.0;                  {convert to percent}
      write (d:9:1);                   {show % of total power}
      end
    else begin
      if not totals then string_nblanks (9);
      end
    ;
{
*   Show rate class description.
}
  if not totals then begin
    write ('  ', geld.rateclass_p^[cl].desc.str:geld.rateclass_p^[cl].desc.len);
    end;

  writeln;
  end;
{
********************************************************************************
*
*   Subroutine GELD_SHOW_READ_STATS (GELD)
*
*   Show statistics related to all the data files that were read.
}
procedure geld_show_read_stats (       {show stats from reading data files}
  in      geld: geld_t);               {library use state}
  val_param;

var
  tk: string_var32_t;                  {scratch token}
  d: double;                           {scratch double precision floating point}
  class, cl: sys_int_machine_t;        {current rate class}
  clshow: geld_classset_t;             {set of rate classes left to show}

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_f_fp_fixed (tk, geld.tread, 1); {make seconds spent reading string}
  writeln (geld.nfiles, ' files read in ', tk.str:tk.len, ' seconds.');

  writeln;
  writeln (' Rate                                    % Total  Rate class');
  writeln ('class  Meters     Readings          kWh    power  description');
  writeln ('-----  ------  -----------  -----------  -------  -----------');

  clshow := geld_classset_all (geld);  {init to all rate classes left to show}

  while not geld_classset_empty (geld, clshow) do begin {loop while class left to show}
    d := -1.0;                         {init highest kWh found so far}
    for cl := 1 to geld.nrateclasses do begin {scan the classes}
      if not geld_classset_in (geld, cl, clshow) then next; {not show this class ?}
      if geld.rateclass_p^[cl].kwh > d then begin {found better class to show next ?}
        class := cl;                   {update class to show next}
        d := geld.rateclass_p^[cl].kwh; {update highest kWh found so far}
        end;
      end;                             {back to check next rate class}
    show_class (geld, class);          {show stats for this rate class}
    geld_classset_sub (geld, class, clshow); {don't show this rate class again}
    end;                               {back to show next class with highest kWh}

  writeln ('-----  ------  -----------  -----------  -------');
  show_class (geld, geld_rateclass_none_k); {show totals}
  end;
