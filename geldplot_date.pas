{   Date/time handling.
}
module geldplot_date;
define geldplot_date_local;
define geldplot_date_str;
%include 'geldplot.ins.pas';
{
********************************************************************************
*
*   Subroutine GELDPLOT_DATE_LOCAL (TIME, DATE)
*
*   Make the expanded date/time in the local time zone into DATE, from the
*   absolute time TIME.
}
procedure geldplot_date_local (        {get expaneded local date/time from abs time}
  in      time: sys_clock_t;           {input absolute time}
  out     date: sys_date_t);           {returned local date/time}
  val_param;

begin
  sys_clock_to_date (                  {convert abs time to expanded date/time}
    time,                              {input absolute time}
    geld_p^.tzone.tzone,               {time zone ID}
    geld_p^.tzone.hours_west,          {time zone hours west of CUT}
    geld_p^.tzone.daysave,             {time zone daylight savings strategy}
    date);                             {returned expanded date/time}
  end;
{
********************************************************************************
*
*   Subroutine GELDPLOT_DATE_STR (TIME, S)
*
*   Return the YYYY/MM/DD.hh:mm date/time string in S for the absolute time in
*   time.  The returned string will be the time as expressed in the local time
*   zone.
}
procedure geldplot_date_str (          {make date/time string from sys clock value}
  in      time: sys_clock_t;           {absolute time}
  in out  s: univ string_var_arg_t);   {returned date/time in local time zone}
  val_param;

var
  date: sys_date_t;                    {expanded date/time in local time zone}
  tk: string_var32_t;                  {scratch token}
  stat: sys_err_t;                     {completion status, unused}

begin
  tk.max := size_char(tk.str);         {init local var string}

  geldplot_date_local (time, date);    {make expanded date/time in local time zone}

  sys_date_string (                    {init returned string with year}
    date, sys_dstr_year_k, 4, s, stat);

  string_append1 (s, '/');             {add 2-digit month number}
  sys_date_string (
    date, sys_dstr_mon_k, 2, tk, stat);
  string_append (s, tk);

  string_append1 (s, '/');             {add 2-digit day number}
  sys_date_string (
    date, sys_dstr_day_k, 2, tk, stat);
  string_append (s, tk);

  string_append1 (s, '.');             {add 2-digit hour}
  sys_date_string (
    date, sys_dstr_hour_k, 2, tk, stat);
  string_append (s, tk);

  string_append1 (s, ':');             {add 2-digit minute}
  sys_date_string (
    date, sys_dstr_min_k, 2, tk, stat);
  string_append (s, tk);
  end;
