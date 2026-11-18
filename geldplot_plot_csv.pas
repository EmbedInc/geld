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
  xscale: real;                        {array index to X value scale factor}
  wmult: real;                         {multiplier to apply to Watts}
  csv: csv_out_t;                      {CSV file writing state}
  r: real;                             {scratch floating point}
  units: string_var16_t;               {X axis units string}
  s: string_var80_t;                   {scratch string}
  date: sys_date_t;                    {expanded date/time}
  indstart: sys_int_machine_t;         {data array index for left edge of plot}
  ind: sys_int_machine_t;              {current data array index}
  ii: sys_int_machine_t;               {scratch integer and loop counter}
  labx: string_var32_t;                {X axis label}
  stat2: sys_err_t;                    {to avoid overwriting existing err in STAT}

label
  abort1, leave;
{
********************************************************************************
*
*   Local function IND_NEXT (IND)
*   This function is internal to GELDPLOT_PLOT_CSV.
*
*   Return the data array index for the next sequential data value.  Each data
*   array is a circular set of values.  This routine performs the circular
*   wrapping as needed.
}
function ind_next (                    {get next sequential 0-N data index}
  in      ind: sys_int_machine_t)      {starting index}
  :sys_int_machine_t;                  {next sequential index forwards}
  val_param; internal;

var
  ii: sys_int_machine_t;               {scratch index}

begin
  ii := ind + 1;                       {to next index}
  if ii >= data_p^.ndat then begin     {incremented past end of array ?}
    ii := ii - data_p^.ndat;           {wrap back to start}
    end;
  ind_next := ii;                      {return the final value}
  end;
{
********************************************************************************
*
*   Local function IND_PREV (IND)
*   This function is internal to GELDPLOT_PLOT_CSV.
*
*   Return the data array index for the previous sequential data value.  Each
*   data array is a circular set of values.  This routine performs the circular
*   wrapping as needed.
}
function ind_prev (                    {get previous sequential 0-N data index}
  in      ind: sys_int_machine_t)      {starting index}
  :sys_int_machine_t;                  {next sequential index backwards}
  val_param; internal;

var
  ii: sys_int_machine_t;               {scratch index}

begin
  ii := ind - 1;                       {to previous index}
  if ii < 0 then begin                 {decremented past start of array ?}
    ii := ii + data_p^.ndat;           {wrap back to end}
    end;
  ind_prev := ii;                      {return the final value}
  end;
{
********************************************************************************
*
*   Start of GELDPLOT_PLOT_CSV main routine.
}
begin
  units.max := size_char(units.str);   {init local var strings}
  s.max := size_char(s.str);
  labx.max := size_char(labx.str);

  geldplot_data_make (data_p);         {make the data to plot}

  indstart := 0;                       {init data index to start writing values at}
  xscale := 1.0;                       {init array index to X value scale factor}
  case plotctrl.xaxis.cfg of           {how is X axis configured ?}

xaxis_cfg_day_k: begin                 {one day, X is hours into day}
      xfrac := 3;                      {fraction digits to write X values with}
      xscale := data_p^.slsec / 3600.0;
      string_vstring (labx, 'Hour of day'(0), -1);
      end;

xaxis_cfg_week_k: begin                {one week, X is days into week}
      xfrac := 3;                      {fraction digits to write X values with}
      xscale := data_p^.slsec / (24.0 * 3600.0);
      string_vstring (labx, 'Day of week'(0), -1);
      sys_clock_to_date (              {make expanded date/time of data start time}
        plotctrl.dataset.tstart,       {time value to convert}
        geld_p^.tzone.tzone,           {time zone ID}
        geld_p^.tzone.hours_west,      {time zone hours west of CUT}
        geld_p^.tzone.daysave,         {time zone daylight savings time strategy}
        date);                         {returned expanded date/time}
      ii := sys_date_dayofweek (date); {day of week data starts at, Sunday = 0}
      ii := 1 - ii;                    {days to jump forwards to get to Monday}
      if ii < 0 then ii := ii + 7;     {wrap to make positive offset}
      ii := ii * 24 * 3600;            {seconds to jump forwards to get to Monday}
      indstart := ii div data_p^.slsec; {number of array entries to jump forward}
      end;

xaxis_cfg_year_k: begin                {one year, X is day into year}
      xfrac := 1;                      {fraction digits to write X values with}
      xscale := data_p^.slsec / (24.0 * 3600.0);
      string_vstring (labx, 'Day of year'(0), -1);
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
  csv_out_vstr (csv, labx, stat);      {write header line}
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
  *   Write line for the starting values.
  }
  ind := indstart;                     {set index to start of data}
  csv_out_fp_fixed (csv, 0.0, xfrac, stat);
  if sys_error(stat) then goto abort1;
  class_p := data_p^.data_p;
  while class_p <> nil do begin        {loop thru the data sets to plot}
    r :=                               {ave first and last}
      (class_p^.dat[ind] + class_p^.dat[ind_prev(ind)]) * wmult / 2.0;
    csv_out_fp_fixed (csv, r, yfrac, stat);
    if sys_error(stat) then goto abort1;
    class_p := class_p^.next_p;        {to next dataset}
    end;
  csv_out_line (csv, stat);
  if sys_error(stat) then goto abort1;
  {
  *   Write one line for each data array entry.
  }
  ind := indstart;                     {init curr index to data start}
  for ii := 0 to data_p^.ndat-1 do begin {once for each data point}
    r := (ii + 0.5) * xscale;          {make X value at center of this slice}
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
    ind := ind_next(ind);              {to next data array entry}
    end;
  {
  *   Write line for the ending values.
  }
  ind := indstart;                     {set index to start of data}
  r := data_p^.ndat * xscale;
  csv_out_fp_fixed (csv, r, xfrac, stat);
  if sys_error(stat) then goto abort1;
  class_p := data_p^.data_p;
  while class_p <> nil do begin        {loop thru the data sets to plot}
    r :=                               {ave first and last}
      (class_p^.dat[ind] + class_p^.dat[ind_prev(ind)]) * wmult / 2.0;
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
