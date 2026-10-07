{   Program TEST_GELD
*
*   Program to test the features of the GELD library.
}
program test_geld;
define test_geld_com;                  {define common block in TEST_GELD.INS.PAS}
%include 'test_geld.ins.pas';

var
  stat: sys_err_t;                     {completion status}

begin
  geld_p := nil;                       {init to GELD library not open}
  datadir.max := size_char(datadir.str); {init name of tree containing GELD data}
  string_vstring (datadir, def_datadir, size_char(def_datadir));

  cmline_read;                         {read command line, update global state}

  geld_lib_new (util_top_mem_context, geld_p); {start our use of the GELD library}

  geld_read_tree (geld_p^, datadir, stat); {read the tree of data files}
  sys_error_abort (stat, '', '', nil, 0);

  test_geld_cmd;                       {run the command processor}

  geld_lib_end (geld_p);               {close the GELD library}
  end.
