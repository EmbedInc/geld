module geld_read_intv_class;
define geld_read_intv_class;
%include 'geld2.ins.pas';
%include 'stuff.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_READ_INTV_CLASS (GELD, FNAM, CLASS, STAT)
*
*   Read the CSV file FNAM, which contains measured intervals of possibly
*   multiple meters.  All data in the file is for the rate class CLASS.  It is
*   an error if data for a meter is encountered that was previously set to a
*   different rate class.
*
*   The input file is not expected to have a header line.  An example data line
*   is:
*
*     341461735,12/18/2025,20:00,1.311,kWH
*
*   The fields are:
*
*     Meter number
*     Date of ending time, MM/DD/YEAR
*     Ending time within day, HH:MM
*     Meter reading
*     "kWH"
*
*   The last field looks like it is intended to be the units for the previous
*   field, but it is not.  The last field seems to always be "kWH" even when the
*   meter has a non-unity multiplier, which makes the meter reading not in kWh.
*   The last field is therefore meaningless and is ignored in this routine.
}
procedure geld_read_intv_class (       {read interval data file for specific rate class}
  in out  geld: geld_t;                {library use state}
  in      fnam: univ string_var_arg_t; {name of file to read, ".csv" suffix assumed}
  in      class: sys_int_machine_t;    {rate class ID for all data in the file}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cin: csv_in_t;                       {state for reading CSV data from input file}
  metid: geld_meterid_t;               {ID of the current meter}
  meter_p: geld_meter_p_t;             {to descriptor for current meter}
  nintv: sys_int_machine_t;            {number of sequential intervals this meter}
  date: sys_date_t;                    {expanded date/time}
  tend: sys_clock_t;                   {ending time of this interval}
  tprev: sys_clock_t;                  {ending time of previous interval}
  dt: real;                            {seconds between consecutive readings}
  reading: real;                       {energy delivered, x meter mult = kWh}
  tk: string_var32_t;                  {one token read from CSV file}
  stat2: sys_err_t;                    {used when error code to return already in STAT}

label
  err_atline, err_open;

begin
  tk.max := size_char(tk.str);         {init local var string}

  csv_in_open (fnam, geld.mem_p^, cin, stat); {open file for reading in CSV format}
  if sys_error(stat) then return;
  geld.nfiles := geld.nfiles + 1;      {count one more data file read}
  meter_p := nil;                      {init to no current meter}

  while true do begin                  {back here each new CSV input file line}
    csv_in_line (cin, stat);           {read new CSV file line}
    if file_eof(stat) then exit;       {hit end of file ?}
    if sys_error(stat) then goto err_open; {hard error ?}
    {
    *   Read the fields of this line into the local variables METID, DATE, and
    *   READING.
    }
    metid := csv_in_field_int (cin, stat); {get meter ID}
    if sys_error(stat) then begin
      sys_stat_set (geld_subsys_k, geld_stat_bmet_k, stat);
      goto err_atline;
      end;

    csv_in_field_str (cin, tk, stat);  {get MM/DD/YEAR}
    if sys_error(stat) then begin
      sys_stat_set (geld_subsys_k, geld_stat_errdate_k, stat);
      goto err_atline;
      end;
    if not geld_str_mmddyear (tk, date) then begin {init date/time with date}
      sys_stat_set (geld_subsys_k, geld_stat_baddate_k, stat);
      sys_stat_parm_vstr (tk, stat);
      goto err_atline;
      end;

    csv_in_field_str (cin, tk, stat);  {get HH:MM}
    if sys_error(stat) then begin
      sys_stat_set (geld_subsys_k, geld_stat_errtime_k, stat);
      goto err_atline;
      end;
    if not geld_str_hhmm (tk, date) then begin {add time within day}
      sys_stat_set (geld_subsys_k, geld_stat_badhhmm_k, stat);
      sys_stat_parm_vstr (tk, stat);
      goto err_atline;
      end;

    reading := csv_in_field_fp (cin, stat);
    if csvfield_null(stat) then begin
      reading := 0.0;
      end;
    if sys_error(stat) then begin
      sys_stat_set (geld_subsys_k, geld_stat_breading_k, stat);
      goto err_atline;
      end;
    {
    *   Resolve the meter and set or verify the rate class.
    }
    if                                 {this interval is not for the current meter ?}
        (meter_p = nil) or else        {there is no current meter ?}
        (metid <> meter_p^.id)         {this interval for different meter ?}
        then begin
      geld_id_get (geld, metid, meter_p); {get pointer to this meter}
      nintv := 0;                      {reset number of intervals this meter}
      end;
    nintv := nintv + 1;                {count one more interval this meter}

    if not geld_meter_class_set (geld, meter_p^, class) then begin
      sys_stat_set (geld_subsys_k, geld_stat_flineclass_k, stat);
      goto err_atline;
      end;
    {
    *   Set the meter reading period if this is the second consecutive reading
    *   for the current meter.
    }
    tend := sys_clock_from_date (date); {make ending time of this interval}

    if nintv = 2 then begin            {second interval from this meter ?}
      dt := sys_clock_to_fp2 (         {make seconds since previous reading}
        sys_clock_sub (tend, tprev)
        );
      if not geld_meter_period_set (geld, meter_p^, dt) then begin
        sys_stat_set (geld_subsys_k, geld_stat_bmetper_k, stat);
        sys_stat_parm_real (geld_meter_period(meter_p^)/60.0, stat);
        sys_stat_parm_real (dt/60.0, stat);
        goto err_atline;
        end;
      end;
    {
    *   Add this new reading to the list for the current meter.
    }
    geld_meter_intv_add (              {add this measured interval to meter}
      geld,                            {library use state}
      meter_p^,                        {meter to add reading to}
      tend,                            {ending time of the reading}
      reading);                        {raw meter reading}
    tprev := tend;                     {end time of this interval become previous}
    end;                               {back for next CSV input file line}

  csv_in_close (cin, stat);            {close the CSV input file}
  return;

err_atline:                            {add file name and line number to STAT}
  sys_stat_parm_vstr (cin.conn.fnam, stat); {CSV file name}
  sys_stat_parm_int (cin.conn.lnum, stat); {current CSV file line number}

err_open:                              {error with CSV file open, STAT set to error}
  csv_in_close (cin, stat2);           {close CSV input file, avoid corrupting STAT}
  end;
