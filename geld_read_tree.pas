module geld_read_tree;
define geld_read_tree;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_READ_TREE (GELD, DIR, STAT)
*
*   Read the tree of GELD data files in DIR and update the library use state
*   accordingly.
}
procedure geld_read_tree (             {read tree of GELD data files}
  in out  geld: geld_t;                {library use state}
  in      dir: univ string_var_arg_t;  {name of directory containing data tree}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  fnam, tnam: string_treename_t;       {scratch file names}

begin
  fnam.max := size_char(fnam.str);     {init local var strings}
  tnam.max := size_char(tnam.str);
{
*   Read the meter multipliers file.  All meters not listed in this file will be
*   assumed to have a multiplier of 1.
}
  string_pathname_join (dir, string_v('multiplier.csv'), fnam);
  string_treename (fnam, tnam);        {make full absolute pathname}
  writeln ('Reading "', tnam.str:tnam.len, '".');
  geld_read_mult (geld, tnam, stat);
  if sys_error(stat) then return;




{*** Work in progress.  More files need to be read. ***}


{*** Temp read a single fixed rate class file, for testing. ***}

  string_pathname_join (dir, string_v('SB-Solar Battery.csv'), fnam);
  string_treename (fnam, tnam);        {make full absolute pathname}
  writeln ('Reading "', tnam.str:tnam.len, '".');
  geld_read_intv_class (               {read interval data, all for one rate class}
    geld,                              {library use state}
    tnam,                              {name of file to read}
    geld_rateclass_sb_k,               {rate class for all data in this file}
    stat);


  end;
