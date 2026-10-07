{   Include file for the modules implementing the TEST_GELD program.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'geld.ins.pas';

const
  def_datadir = '~/geld/data/2025';    {default directory holding tree of GELD data}

var (test_geld_com)
  geld_p: geld_p_t;                    {to our GELD library use state}
  datadir: string_treename_t;          {location of GELD data tree}
{
*   Subroutines and functions.
}
procedure cmline_read;                 {read the command line, update global state}
  val_param; extern;

procedure test_geld_cmd;               {interactive command processor}
  val_param; extern;
