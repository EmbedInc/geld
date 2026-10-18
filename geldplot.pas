{   Program GELDPLOT
*
*   Generate various plots and statistics from a tree of GELD data files.
}
program geldplot;
define geldplot_com;                   {define common block in GELDPLOT.INS.PAS}
%include 'geldplot.ins.pas';

var
  stat: sys_err_t;                     {completion status}

begin
{
*   Initialize the global program state to default or benign values.
}
  geld_p := nil;                       {init to GELD library not open}
  datadir.max := size_char(datadir.str); {init name of tree containing GELD data}
  string_vstring (datadir, def_datadir, size_char(def_datadir));
  plotctrl.outty := outty_screen_k;
  plotctrl.xaxis.cfg := xaxis_cfg_day_k;
  plotctrl.yaxis.cfg := yaxis_cfg_power_k;
  plotctrl.dataset.rateclass := ~setof(geld_rateclass_t);
  plotctrl.dataset.rateclass := plotctrl.dataset.rateclass - [geld_rateclass_none_k];
  plotctrl.sizex := 1920;
  plotctrl.sizex := 1080;
  plotctrl.posx := 0;
  plotctrl.posy := 0;
  plotctrl.fnam.max := size_char(plotctrl.fnam.str);
  plotctrl.fnam.len := 0;
  plotctrl.title.max := size_char(plotctrl.title.str);
  plotctrl.title.len := 0;

  cmline_read;                         {read command line, update global state}

  geld_lib_new (util_top_mem_context, geld_p); {start our use of the GELD library}

  geld_read_tree (geld_p^, datadir, stat); {read the tree of data files}
  sys_error_abort (stat, '', '', nil, 0);
  geld_show_read_stats (geld_p^);      {show stats about reading data files}

  geldplot_cmd;                        {run the command processor}

  geld_lib_end (geld_p);               {close the GELD library}
  end.
