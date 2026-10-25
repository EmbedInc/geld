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
  sz: sys_int_adr_t;                   {memory size}
  dat_p: geld_power_p_t;               {to data values}
  ndat: sys_int_machine_t;             {number of data values at DAT_P}
  slsec: sys_int_machine_t;            {data slice time, seconds}
  slx: real;                           {X axis increment per slice}
  xfrac: sys_int_machine_t;            {fraction digits for X axis values}
  labx: string_var32_t;                {X axis label}
  csv: csv_out_t;                      {CSV file writing state}
  ind: sys_int_machine_t;              {data array index}
  r: real;                             {scratch floating point}
  stat2: sys_err_t;                    {to avoid overwriting existing err in STAT}

label
  abort1, leave;

begin
  labx.max := size_char(labx.str);     {init local var string}
  dat_p := nil;                        {init to data array not allocated}

  case plotctrl.xaxis.cfg of           {how is X axis configured ?}
xaxis_cfg_day_k: begin                 {one day, compute data per minute}
      ndat := 24 * 60;                 {number of 1-minute time slices in a day}
      slsec := 60;                     {data slice length, seconds}
      string_vstring (labx, 'Hour'(0), -1);
      slx := 1.0 / 60.0;               {X axis increment per slice}
      xfrac := 3;                      {fraction digits to write X values with}
      end;
xaxis_cfg_year_k: begin                {one year, compute data per day}
      ndat := 365;                     {number of 1-day time slices in a year}
      slsec := 24 * 60 * 60;           {data slice length, seconds}
      string_vstring (labx, 'Day'(0), -1);
      slx := 1.0;                      {X axis increment per slice}
      xfrac := 1;                      {fraction digits to write X values with}
      end;
otherwise
    sys_stat_set (sys_subsys_k, sys_stat_not_impl_name_k, stat);
    sys_stat_parm_str ('X axis configuration', stat);
    return;
    end;

  sz := ndat * sizeof(dat_p^[1]);      {size of data array}
  sys_mem_alloc (sz, dat_p);           {allocate the data array}
  util_mem_grab_err_bomb (dat_p, sz);  {bomb on didn't get the memory}

  geld_avepower (                      {compute the averaged data}
    geld_p^,                           {GELD library use state}
    dat_p^,                            {array to return the data in}
    ndat,                              {number of entries in data array}
    slsec,                             {seconds data time per array entry}
    plotctrl.dataset.tstart,           {start time of data to include}
    plotctrl.dataset.tend,             {end time of data to include}
    plotctrl.dataset.classes);         {rate classes to include}
{
*   DAT_P points to the averaged data to show.
}
  csv_out_open (fnam, csv, stat);      {open the CSV output file}
  if sys_error(stat) then goto leave;
  {
  *   Write header line.
  }
  csv_out_vstr (csv, labx, stat);      {write header line}
  if sys_error(stat) then goto abort1;
  csv_out_str (csv, 'MW'(0), stat);
  if sys_error(stat) then goto abort1;
  csv_out_line (csv, stat);
  if sys_error(stat) then goto abort1;
  {
  *   Interpolate to the X starting value.
  }
  csv_out_fp_fixed (csv, 0.0, xfrac, stat);
  if sys_error(stat) then goto abort1;
  r := (dat_p^[0] + dat_p^[ndat-1]) / 2000.0; {ave first and last}
  csv_out_fp_fixed (csv, r, yfrac, stat);
  if sys_error(stat) then goto abort1;
  csv_out_line (csv, stat);
  if sys_error(stat) then goto abort1;
  {
  *   Write one line for each data array entry.
  }
  for ind := 0 to ndat-1 do begin      {once for each data point}
    r := (ind + 0.5) * slx;            {make X value at center of this slice}
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
  r := ndat * slx;
  csv_out_fp_fixed (csv, r, xfrac, stat);
  if sys_error(stat) then goto abort1;
  r := (dat_p^[0] + dat_p^[ndat-1]) / 2000.0; {ave first and last}
  csv_out_fp_fixed (csv, r, yfrac, stat);
  if sys_error(stat) then goto abort1;
  csv_out_line (csv, stat);
  if sys_error(stat) then goto abort1;

  csv_out_close (csv, stat);           {close the CSV output file}
  goto leave;

abort1:                                {CSV output file is open}
  csv_out_close (csv, stat2);

leave:                                 {common exit point}
  if dat_p <> nil then begin           {data array still allocated ?}
    sys_mem_dealloc (dat_p);           {deallocate it}
    end;
  end;
