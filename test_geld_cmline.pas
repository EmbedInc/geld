module test_geld_cmline;
define cmline_read;
%include 'test_geld.ins.pas';
{
********************************************************************************
*
*   Subrouitine CMLINE_READ
*
*   Process the TEST_GELD program command line and update the global program
*   state accordingly.
}
procedure cmline_read;                 {read the command line, update global state}
  val_param;

const
  max_msg_args = 2;                    {max arguments we can pass to a message}

var
  opt: string_var32_t;                 {upcased command line option}
  parm: string_treename_t;             {command line option parameter}
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status}

label
  next_opt, err_parm, parm_bad, done_opts;

begin
  opt.max := size_char(opt.str);       {init local var strings}
  parm.max := size_char(parm.str);

  string_cmline_init;                  {initialize for reading the command line}
{
*   Back here each new command line option.
}
next_opt:
  string_cmline_token (opt, stat);     {get next command line option name}
  if string_eos(stat) then goto done_opts; {exhausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  string_tkpick80 (opt,                {pick command line option name from list}
    '-TREE',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -TREE tnam
}
1: begin
  string_cmline_token (parm, stat);
  if sys_error(stat) then goto err_parm;
  string_treename (parm, datadir);     {save full pathname of data tree}
  end;
{
*   Unrecognized command line option.
}
otherwise
    string_cmline_opt_bad;             {unrecognized command line option}
    end;                               {end of command line option case statement}

err_parm:                              {jump here on error with parameter}
  string_cmline_parm_check (stat, opt); {check for bad command line option parameter}
  goto next_opt;                       {back for next command line option}

parm_bad:                              {jump here on got illegal parameter}
  string_cmline_reuse;                 {re-read last command line token next time}
  string_cmline_token (parm, stat);    {re-read the token for the bad parameter}
  sys_msg_parm_vstr (msg_parm[1], parm);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);

done_opts:                             {done with all the command line options}
  end;
