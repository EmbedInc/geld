module geldplot_plot_csv;
define geldplot_plot_csv;
%include 'geldplot.ins.pas';
%include 'stuff.ins.pas';
{
********************************************************************************
*
*   Subroutine GELDPLOT_PLOT_CSV (FNAM, STAT)
*
*   Write the data to plot as currently configured to the CSV file FNAM.
}
procedure geldplot_plot_csv (          {plot data to CSV file}
  in      fnam: univ string_var_arg_t; {name of CSV file to write}
  out     stat: sys_err_t);            {completion status}
  val_param;

const
  yfrac = 3;                           {fraction digits to write Y values with}

var
  data_p: data_p_t;                    {to data to plot}
  class_p: data_class_p_t;             {to data to plot for current class}
  xfrac: sys_int_machine_t;            {fraction digits for X axis values}
  wmult: real;                         {multiplier to apply to Watts}
  csv: csv_out_t;                      {CSV file writing state}
  ind: sys_int_machine_t;              {data array index}
  r: real;                             {scratch floating point}
  units: string_var16_t;               {X axis units string}
  s: string_var80_t;                   {scratch string}
  stat2: sys_err_t;                    {to avoid overwriting existing err in STAT}

label
  abort1, leave;

begin
  units.max := size_char(units.str);   {init local var strings}
  s.max := size_char(s.str);

  geldplot_data_make (data_p);         {make the data to plot}

  case plotctrl.xaxis.cfg of           {how is X axis configured ?}
xaxis_cfg_day_k: begin                 {one day, compute data per minute}
      xfrac := 3;                      {fraction digits to write X values with}
      end;
xaxis_cfg_year_k: begin                {one year, compute data per day}
      xfrac := 1;                      {fraction digits to write X values with}
      end;
otherwise
    sys_stat_set (sys_subsys_k, sys_stat_not_impl_name_k, stat);
    sys_stat_parm_str ('X axis configuration', stat);
    return;
    end;

  wmult := 1.0;                        {init to use units of Watts}
  string_vstring (units, 'W'(0), -1);
  if data_p^.data_p^.max >= 1000.0 then begin
    wmult := 0.001;                    {switch to kW}
    string_vstring (units, 'kW'(0), -1);
    end;
  if data_p^.data_p^.max >= 1000000.0 then begin
    wmult := 0.000001;                 {switch to MW}
    string_vstring (units, 'MW'(0), -1);
    end;
{
*   DATA_P points to the overall data to plot.
}
  csv_out_open (fnam, csv, stat);      {open the CSV output file}
  if sys_error(stat) then goto leave;
  csv.flags :=                         {min required output characters, no padding}
    csv.flags + [csv_outflag_minchar_k];
  {
  *   Write header line.
  }
  csv_out_vstr (csv, data_p^.labx, stat); {write header line}
  if sys_error(stat) then goto abort1;
  class_p := data_p^.data_p;
  while class_p <> nil do begin        {loop thru the data sets to plot}
    if class_p^.id = 0
      then begin                       {totals}
        string_vstring (s, 'Total'(0), -1);
        end
      else begin                       {a specific rate class}
        geld_rateclass_t_code (geld_p^, class_p^.id, s); {get rate class code}
        end
      ;
    string_append1 (s, ' ');
    string_append (s, units);
    csv_out_vstr (csv, s, stat);
    if sys_error(stat) then goto abort1;
    class_p := class_p^.next_p;        {to next dataset}
    end;
  csv_out_line (csv, stat);
  if sys_error(stat) then goto abort1;
  {
  *   Interpolate to the X starting value.
  }
  csv_out_fp_fixed (csv, 0.0, xfrac, stat);
  if sys_error(stat) then goto abort1;
  class_p := data_p^.data_p;
  while class_p <> nil do begin        {loop thru the data sets to plot}
    r :=                               {ave first and last}
      (class_p^.dat[0] + class_p^.dat[data_p^.ndat-1]) * wmult / 2.0;
    csv_out_fp_fixed (csv, r, yfrac, stat);
    if sys_error(stat) then goto abort1;
    class_p := class_p^.next_p;        {to next dataset}
    end;
  csv_out_line (csv, stat);
  if sys_error(stat) then goto abort1;
  {
  *   Write one line for each data array entry.
  }
  for ind := 0 to data_p^.ndat-1 do begin {once for each data point}
    r := (ind + 0.5) * data_p^.slx;    {make X value at center of this slice}
    csv_out_fp_fixed (csv, r, xfrac, stat);
    if sys_error(stat) then goto abort1;
    class_p := data_p^.data_p;
    while class_p <> nil do begin      {loop thru the data sets to plot}
      csv_out_fp_fixed (csv, class_p^.dat[ind] * wmult, yfrac, stat);
      if sys_error(stat) then goto abort1;
      class_p := class_p^.next_p;      {to next dataset}
      end;
    csv_out_line (csv, stat);
    if sys_error(stat) then goto abort1;
    end;
  {
  *   Interpolate to the X ending value.
  }
  r := data_p^.ndat * data_p^.slx;
  csv_out_fp_fixed (csv, r, xfrac, stat);
  if sys_error(stat) then goto abort1;
  class_p := data_p^.data_p;
  while class_p <> nil do begin        {loop thru the data sets to plot}
    r :=                               {ave first and last}
      (class_p^.dat[0] + class_p^.dat[data_p^.ndat-1]) * wmult / 2.0;
    csv_out_fp_fixed (csv, r, yfrac, stat);
    if sys_error(stat) then goto abort1;
    class_p := class_p^.next_p;        {to next dataset}
    end;
  csv_out_line (csv, stat);
  if sys_error(stat) then goto abort1;

  csv_out_close (csv, stat);           {close the CSV output file}
  goto leave;

abort1:                                {CSV output file is open}
  csv_out_close (csv, stat2);

leave:                                 {common exit point}
  geldplot_data_del (data_p);          {deallocate plot data if still exists}
  end;
