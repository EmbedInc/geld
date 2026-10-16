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
*   Subroutine GELD_SHOW_METER (METER)
*
*   Show basic one-line info about the meter from the current output position.
}
procedure geld_show_meter (            {show basic info about a meter}
  in      meter: geld_meter_t);        {meter to show info about}
  val_param;

var
  r: real;                             {scratch floating point}
  tk: string_var32_t;                  {scratch token}

begin
  tk.max := size_char(tk.str);         {init local var string}

  write (meter.id:10);                 {meter ID}

  geld_rateclass_t_code (meter.class, tk); {make rate class code}
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
  in      cl: geld_rateclass_k_t);     {rate class to show stats for}
  val_param; internal;

var
  tk: string_var32_t;                  {scratch token}
  d: double;                           {scratch floating point}
  stat: sys_err_t;                     {completion status}

begin
  tk.max := size_char(tk.str);         {init local var string}

  if cl = geld_rateclass_none_k
    then begin                         {showing totals}
      string_vstring (tk, 'Total'(0), -1);
      end
    else begin                         {showing a specific rate class}
      geld_rateclass_t_code (cl, tk);  {make rate class code}
      end
    ;
  string_nblanks (5 - tk.len);         {leading blanks before rate class code}
  write (tk.str:tk.len);

  write (geld.stat_class[cl].nmeters:8); {show number of meters}

  string_f_fp (                        {make number of readings string}
    tk,                                {output string}
    geld.stat_class[cl].nintv,         {input number}
    13,                                {field width}
    0,                                 {free format exponent (not used)}
    1,                                 {min required significant digits}
    13,                                {max digits allowed left of point}
    0, 0,                              {min/max digits allowed right of point}
    [string_ffp_group_k],              {show digits in groups}
    stat);
  sys_error_abort (stat, '', '', nil, 0);
  write (tk.str:tk.len);

  string_f_fp (                        {make kWh string}
    tk,                                {output string}
    geld.stat_class[cl].kwh,           {input number}
    13,                                {field width}
    0,                                 {free format exponent (not used)}
    1,                                 {min required significant digits}
    13,                                {max digits allowed left of point}
    0, 0,                              {min/max digits allowed right of point}
    [string_ffp_group_k],              {show digits in groups}
    stat);
  sys_error_abort (stat, '', '', nil, 0);
  write (tk.str:tk.len);

  if geld.stat_class[geld_rateclass_none_k].kwh > 0.1 then begin
    d :=                               {make fraction of total power used}
      geld.stat_class[cl].kwh /
      geld.stat_class[geld_rateclass_none_k].kwh;
    d := d * 100.0;                    {convert to percent}
    write (d:9:1);                     {show % of total power}
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
  class, cl: geld_rateclass_k_t;       {current rate class}
  clshow: array                        {which rate classes still left to show}
    [geld_rateclass_first .. geld_rateclass_last] of boolean;
  nclshow: sys_int_machine_t;          {number of rate classes left to show}

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_f_fp_fixed (tk, geld.tread, 1); {make seconds spent reading string}
  writeln (geld.nfiles, ' files read in ', tk.str:tk.len, ' seconds.');

  writeln;
  writeln (' Rate                                    % Total');
  writeln ('class  Meters     Readings          kWh    power');
  writeln ('-----  ------  -----------  -----------  -------');

  for class := geld_rateclass_first to geld_rateclass_last do begin
    clshow[class] := true;             {init to all classes left to show}
    end;
  nclshow := ord(geld_rateclass_last) - ord(geld_rateclass_first) + 1; {N to show}

  while nclshow > 0 do begin           {back here until all rate classes shown}
    d := -1.0;                         {init highest kWh found so far}
    for cl := geld_rateclass_first to geld_rateclass_last do begin {scan classes}
      if not clshow[cl] then next;     {not show this class ?}
      if geld.stat_class[cl].kwh > d then begin {found better class to show next ?}
        class := cl;                   {update class to show next}
        d := geld.stat_class[class].kwh; {update highest kWh found so far}
        end;
      end;                             {back to check next rate class}
    show_class (geld, class);          {show stats for this rate class}
    clshow[class] := false;            {don't show this rate class again}
    nclshow := nclshow - 1;            {one less class left to show}
    end;                               {back to show next class with highest kWh}

  writeln ('-----  ------  -----------  -----------  -------');
  show_class (geld, geld_rateclass_none_k); {show totals}
  end;
