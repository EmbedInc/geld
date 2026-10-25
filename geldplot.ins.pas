{   Include file for the modules implementing the GELDPLOT program.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'geld.ins.pas';

const
  def_datadir = '~/geld/data/2025';    {default directory holding tree of GELD data}

type
  xaxis_cfg_k_t = (                    {types of X axis configurations}
    xaxis_cfg_day_k,                   {one day, show hours, data by minute}
    xaxis_cfg_year_k);                 {one year, show months, data by day}

  yaxis_cfg_k_t = (                    {types of Y axis configurations}
    yaxis_cfg_power_k);                {average power consumed}

  outty_k_t = (                        {high level plot output means}
    outty_screen_k,                    {full screen}
    outty_window_k,                    {window on screen, size and loc specified}
    outty_file_k,                      {image file}
    outty_csv_k);                      {CSV file}

  xaxis_t = record                     {X axis plot control}
    cfg: xaxis_cfg_k_t;                {overall configuration}
    end;

  yaxis_t = record                     {Y axis plot control}
    cfg: yaxis_cfg_k_t;                {overall configuration}
    end;

  dataset_t = record                   {control of what data is included in plot}
    classes: geld_classset_t;          {which rate classes to include}
    tstart, tend: sys_clock_t;         {start/end time of data to include}
    end;

  plotctrl_t = record                  {plot control parameters}
    outty: outty_k_t;                  {plot output means}
    xaxis: xaxis_t;                    {X axis control}
    yaxis: yaxis_t;                    {Y axis control}
    dataset: dataset_t;                {what set of data to plot}
    sizex, sizey: sys_int_machine_t;   {size, pixels}
    posx, posy: sys_int_machine_t;     {top left position if within larger area}
    fnam: string_treename_t;           {file name when writing to file}
    title: string_var80_t;             {plot title}
    end;

var (geldplot_com)
  geld_p: geld_p_t;                    {to our GELD library use state}
  datadir: string_treename_t;          {location of GELD data tree}
  plotctrl: plotctrl_t;                {plot control parameters}
{
*   Subroutines and functions.
}
procedure cmline_read;                 {read the command line, update global state}
  val_param; extern;

procedure geldplot_cmd;                {interactive command processor}
  val_param; extern;

procedure geldplot_init;               {init program state after data files read}
  val_param; extern;
