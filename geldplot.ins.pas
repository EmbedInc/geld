{   Include file for the modules implementing the GELDPLOT program.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'geld.ins.pas';

const
  def_datadir = '~/geld/data/2025';    {default directory holding tree of GELD data}
  def_ifnam = '/temp/geld.jpg';        {default image output file name}
  aafactor = 4;                        {anti-aliasing factor for image file output}

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

  data_class_pp_t = ^data_class_p_t;
  data_class_p_t = ^data_class_t;
  data_class_t = record                {data to plot for one rate class}
    next_p: data_class_p_t;            {to next rate class data in list}
    id: sys_int_machine_t;             {1-N rate class ID, 0 for total}
    ave: double;                       {average value in DAT}
    max: double;                       {maximum value in DAT}
    dat: geld_power_t;                 {average Watts per slice, dimensioned as needed}
    end;

  data_p_t = ^data_t;
  data_t = record                      {data to plot}
    mem_p: util_mem_context_p_t;       {to mem context for subordinate memory}
    ndat: sys_int_machine_t;           {number of points in each data array}
    slsec: sys_int_machine_t;          {seconds data time per array entry}
    slx: real;                         {X axis increment per array entry}
    labx: string_var80_t;              {X axis label}
    data_p: data_class_p_t;            {to list of classes, descending power order}
    maxval: double;                    {max of all data values}
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

procedure geldplot_data_del (          {delete plot data, deallocate resources}
  in out  data_p: data_p_t);           {to data to delete, returned NIL}
  val_param; extern;

procedure geldplot_data_make (         {compute data to plot under current config}
  out     data_p: data_p_t);           {returned pointer to plottable data}
  val_param; extern;

procedure geldplot_init;               {init program state after data files read}
  val_param; extern;

procedure geldplot_plot_csv (          {plot data to CSV file}
  in      fnam: univ string_var_arg_t; {name of CSV file to write}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure geldplot_plot_rend (         {plot data using RENDlib}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
