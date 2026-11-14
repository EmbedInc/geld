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
  dat_p: geld_power_p_t;               {to raw data to plot for current class}
  xfrac: sys_int_machine_t;            {fraction digits for X axis values}
  csv: csv_out_t;                      {CSV file writing state}
  ind: sys_int_machine_t;              {data array index}
  r: real;                             {scratch floating point}
  stat2: sys_err_t;                    {to avoid overwriting existing err in STAT}

label
  abort1, leave;

begin
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
{
*   DATA_P points to the overall data to plot.
}
  csv_out_open (fnam, csv, stat);      {open the CSV output file}
  if sys_error(stat) then goto leave;
  csv.flags :=                         {min required output characters, no padding}
    csv.flags + [csv_outflag_minchar_k];

  {   ***** TEMP DEBUG *****
  *   Set up DAT_P for the totalized data to be compatible with previous
  *   versions of this routine.  For now we are ignoring data for individual
  *   rate classes.
  }
  class_p := data_p^.data_p;           {to totals for all included classes}
  dat_p := addr(class_p^.dat);         {to raw data for this totals "class"}

  {
  *   Write header line.
  }
  csv_out_vstr (csv, data_p^.labx, stat); {write header line}
  if sys_error(stat) then goto abort1;
  csv_out_str (csv, 'kW'(0), stat);
  if sys_error(stat) then goto abort1;
  csv_out_line (csv, stat);
  if sys_error(stat) then goto abort1;
  {
  *   Interpolate to the X starting value.
  }
  csv_out_fp_fixed (csv, 0.0, xfrac, stat);
  if sys_error(stat) then goto abort1;
  r := (dat_p^[0] + dat_p^[data_p^.ndat-1]) / 2000.0; {ave first and last}
  csv_out_fp_fixed (csv, r, yfrac, stat);
  if sys_error(stat) then goto abort1;
  csv_out_line (csv, stat);
  if sys_error(stat) then goto abort1;
  {
  *   Write one line for each data array entry.
  }
  for ind := 0 to data_p^.ndat-1 do begin {once for each data point}
    r := (ind + 0.5) * data_p^.slx;    {make X value at center of this slice}
    csv_out_fp_fixed (csv, r, xfrac, stat);
    if sys_error(stat) then goto abort1;
    csv_out_fp_fixed (csv, dat_p^[ind]/1000.0, yfrac, stat);
    if sys_error(stat) then goto abort1;
    csv_out_line (csv, stat);
    if sys_error(stat) then goto abort1;
    end;
  {
  *   Interpolate to the X ending value.
  }
  r := data_p^.ndat * data_p^.slx;
  csv_out_fp_fixed (csv, r, xfrac, stat);
  if sys_error(stat) then goto abort1;
  r := (dat_p^[0] + dat_p^[data_p^.ndat-1]) / 2000.0; {ave first and last}
  csv_out_fp_fixed (csv, r, yfrac, stat);
  if sys_error(stat) then goto abort1;
  csv_out_line (csv, stat);
  if sys_error(stat) then goto abort1;

  csv_out_close (csv, stat);           {close the CSV output file}
  goto leave;

abort1:                                {CSV output file is open}
  csv_out_close (csv, stat2);

leave:                                 {common exit point}
  geldplot_data_del (data_p);          {deallocate plot data if still exists}
  end;
