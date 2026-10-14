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
  stat: sys_err_t;                     {completion status}

begin
  tk.max := size_char(tk.str);         {init local var string}

  d := geld.nintv;                     {get total number of reading intervals}
  string_f_fp (                        {convert to string}
    tk,                                {output string}
    d,                                 {input number}
    0, 0,                              {free format, no fixed field width}
    1,                                 {min required significant digits}
    12,                                {max digits allowed left of point}
    0, 0,                              {min/max digits allowed right of point}
    [string_ffp_group_k],              {show digits in groups}
    stat);
  sys_error_abort (stat, '', '', nil, 0);
  write (geld.nfiles, ' files containing ',
    geld.nmeters, ' meters and ',
    tk.str:tk.len, ' readings read in ');

  string_f_fp_fixed (tk, geld.tread, 1); {make seconds spent reading string}
  write (tk.str:tk.len, ' seconds.');
  writeln;
  end;
