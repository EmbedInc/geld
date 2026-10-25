module geld_classset_f_str;
define geld_classset_f_str;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_CLASSSET_F_STR (GELD, CLASSSET, STR, STAT)
*
*   Update the set of rate classes in CLASSSET according to commands in the
*   string STR.  STR contains commands separated by one or more spaces.  The
*   allowed commands are:
*
*     NONE
*
*       Sets CLASSSET to the empty set.
*
*     ALL
*
*       Sets CLASSSET to the set of all defined rate classes.
*
*     [-]name
*
*       NAME must be the short code for one of the defined rate classes.  It
*       may optionally be proceeded with a minus sign "-".  Without the minus
*       sign, the indicated rate class is added to CLASSSET.  When the minus
*       sign is included, the indicated rate class is removed from CLASSSET.
*
*   All commands are case-insensitive.  Commands are processed in the order they
*   appear in STR.  This makes them order-dependent.  For example, all commands
*   before NONE or ALL are irrelevant.
*
*   If STR contains no commands, then CLASSSET is not altered.
*
*   If an error is encountered then STAT is set to indicate the error and
*   CLASSSET is not altered.
}
procedure geld_classset_f_str (        {update set of rate classes from string}
  in      geld: geld_t;                {library use state}
  in out  classset: geld_classset_t;   {set of rate classes to update}
  in      str: univ string_var_arg_t;  {string of commands}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  p: string_index_t;                   {input string parse index}
  tk: string_var16_t;                  {token parsed from input string}
  cs: geld_classset_t;                 {internal copy of classes set being modified}
  pick: sys_int_machine_t;             {number of keyword picked from list}
  add: boolean;                        {add this class, not remove it}
  ii: sys_int_machine_t;               {scratch integer and loop counter}
  cl: sys_int_machine_t;               {ID for rate class of current command}

label
  next_cmd, cmd_bad;

begin
  tk.max := size_char(tk.str);         {init local var string}
  p := 1;                              {init input string parse index}
  cs := classset;                      {make local copy of set to modify}

next_cmd:                              {back here to get each new command}
  string_token (str, p, tk, stat);     {parse next command from input string}
  if string_eos(stat) then begin       {hit end of commands string ?}
    classset := cs;                    {pass back updated rate classes set}
    return;
    end;
  if sys_error(stat) then return;      {hard error ?}
  string_upcase (tk);                  {make upper case for keyword matching}

  string_tkpick80 (tk,                 {pick keyword from list}
    'NONE ALL',
    pick);                             {1-N number of keyword, 0 for none}
  case pick of                         {which keyword is it ?}
1:  begin                              {NONE}
      cs := geld_classset_none (geld);
      goto next_cmd;
      end;
2:  begin                              {ALL}
      cs := geld_classset_all (geld);
      goto next_cmd;
      end;
    end;                               {end of the fixed keyword cases}

  add := true;                         {init to adding, not removing rate class}
  if tk.len > 1 then begin             {enough chars to allow for leading "-" ?}
    if tk.str[1] = '-' then begin      {leading "-" ?}
      add := false;                    {removing, not adding this rate class}
      for ii := 1 to tk.len-1 do begin {shift left one char to remove "-"}
        tk.str[ii] := tk.str[ii+1];
        end;
      tk.len := tk.len - 1;
      end;
    end;                               {done handling possible leading "-"}

  cl := geld_rateclass_f_code (geld, tk); {get rate class indicated by this command}
  if cl = geld_rateclass_none_k then goto cmd_bad; {unrecognized rate class code ?}

  if add                               {update local classes set to this command}
    then geld_classset_add (geld, cl, cs)
    else geld_classset_sub (geld, cl, cs);
  goto next_cmd;                       {back to get next command in input string}

cmd_bad:                               {TK contains unrecognized command}
  sys_stat_set (geld_subsys_k, geld_stat_clcmd_k, stat);
  sys_stat_parm_vstr (tk, stat);
  end;
