module geld_read_mult;
define geld_read_mult;
%include 'geld2.ins.pas';
%include 'stuff.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_READ_MULT (GELD, FNAM, STAT)
*
*   Read the meters multiplier factors file and update or create the meters
*   state accordingly.  The multipliers file is in CSV format and may have a
*   header line.  Data lines are assumed to start with:
*
*     meter ID, rate class 2-letter code, multiplier factor
*
*   The multiplier factor is the the value to multiply the raw meter readings by
*   to get energy in killowatt-hours (kWh).  Meters that do not have a
*   multiplier explicitly set are assumed to read directly in kWh (multiplier
*   = 1).
*
*   Here is an example of what the first few lines of a rate multiplier file
*   contain:
*
*     Meter ID,Rate,Multiplier,Socket ID
*     33295705,SB,127,64430
*     32858926,C1,80,1370
*
*   This routine only uses the first three columns, which are the meter number,
*   rate code, and meter multiplier.
}
procedure geld_read_mult (             {read meter multipliers file}
  in out  geld: geld_t;                {library use state}
  in      fnam: univ string_var_arg_t; {name of file to read, ".csv" suffix assumed}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cin: csv_in_t;                       {state for reading CSV data from input file}
  metid: geld_meterid_t;               {ID of the current meter}
  class: geld_rateclass_k_t;           {rate class for the current meter}
  mult: real;                          {multiplier for the current meter}
  meter_p: geld_meter_p_t;             {to descriptor for current meter}
  tk: string_var32_t;                  {one token read from CSV file}
  stat2: sys_err_t;                    {used when error code to return already in STAT}

label
  err_header, err_atline, err_open;

begin
  tk.max := size_char(tk.str);         {init local var string}

  csv_in_open (fnam, geld.mem_p^, cin, stat); {open file for reading in CSV format}
  if sys_error(stat) then return;
{
*   Read and verify the header line.  The first three column names must be
*   "METER ID", "RATE", and "MULTIPLIER", case-insensitive.
}
  csv_in_line (cin, stat);             {read CSV header line}

  csv_in_field_str (cin, tk, stat);    {get column 1 name}
  if sys_error(stat) then return;
  string_upcase (tk);
  if not string_equal(tk, string_v('METER ID'(0))) then begin
err_header:
    sys_stat_set (geld_subsys_k, geld_stat_multhead_k, stat);
    goto err_open;
    end;

  csv_in_field_str (cin, tk, stat);    {get column 2 name}
  if sys_error(stat) then return;
  string_upcase (tk);
  if not string_equal(tk, string_v('RATE'(0))) then begin
    goto err_header;
    end;

  csv_in_field_str (cin, tk, stat);    {get column 3 name}
  if sys_error(stat) then return;
  string_upcase (tk);
  if not string_equal(tk, string_v('MULTIPLIER'(0))) then begin
    goto err_header;
    end;
{
*   Read the data lines and set the rate ID and multiplier for each listed
*   meter.
}
  while true do begin                  {loop over each CSV file line}
    {
    *   Get the next input line.
    }
    csv_in_line (cin, stat);           {read new CSV file line}
    if file_eof(stat) then exit;       {hit end of file ?}
    if sys_error(stat) then goto err_open; {hard error ?}
    {
    *   Read the meter id, rate class code, and rate multiplier fields.
    }
    metid := csv_in_field_int (cin, stat); {get meter ID}
    if sys_error(stat) then begin
      sys_stat_set (geld_subsys_k, geld_stat_bmet_k, stat);
      goto err_atline;
      end;

    csv_in_field_str (cin, tk, stat);  {get rate class code}
    if sys_error(stat) then begin
      sys_stat_set (geld_subsys_k, geld_stat_nrdclass_k, stat);
      goto err_atline;
      end;

    mult := csv_in_field_fp (cin, stat); {get meter multiplier}
    if sys_error(stat) then begin
      sys_stat_set (geld_subsys_k, geld_stat_bmult_k, stat);
      goto err_atline;
      end;
    {
    *   Process the values and create or update the data for this meter.
    }
    class := geld_rateclass_f_code (tk); {interpret rate class code}
    if class = geld_rateclass_none_k then begin {invalid code ?}
      sys_stat_set (geld_subsys_k, geld_stat_bclass_k, stat);
      goto err_atline;
      end;

    geld_id_find (geld, metid, meter_p); {find or create descriptor for this meter}

    if not geld_meter_class_set (geld, meter_p^, class) then begin {set rate class}
      sys_stat_set (geld_subsys_k, geld_stat_flineclass_k, stat);
      goto err_atline;
      end;

    geld_meter_mult_set (geld, meter_p^, mult); {set multiplier for this meter}
    end;                               {back for next CSV file line}

  csv_in_close (cin, stat);            {close the CSV input file}
  return;

err_atline:                            {add file name and line number to STAT}
  sys_stat_parm_vstr (cin.conn.fnam, stat); {CSV file name}
  sys_stat_parm_int (cin.conn.lnum, stat); {current CSV file line number}

err_open:                              {error with CSV file open, STAT set to error}
  csv_in_close (cin, stat2);           {close CSV input file, avoid corrupting STAT}
  end;
