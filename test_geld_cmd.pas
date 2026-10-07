{   Interactive command processor in TEST_GELD program.
}
module test_geld_cmd;
define test_geld_cmd;
%include 'test_geld.ins.pas';

const
  prompt_text = ': ';                  {prompt to user to enter new command}
  namewid = 15;                        {min chars cmd name width show in list}
  nlist = 60;                          {default lines to show in list}
{
********************************************************************************
*
*   Subroutine TEST_GELD_CMD
*
*   Run an interactive command processor.  This allows the user to examine the
*   current GELD library state and perform various tests of the GELD routines.
}
procedure test_geld_cmd;               {interactive command processor}
  val_param;

var
  meterid: geld_meterid_t;             {meter ID number}
  meter_p: geld_meter_p_t;             {to current meter, if any}
  i1: sys_int_machine_t;               {scratch command parameter}
  ii: sys_int_machine_t;               {scratch integer}
  pos: geld_idpos_t;                   {position within meter IDs list}

  cmds: string_var1024_t;              {command names, blank-separated, upper case}
  desc: string_list_t;                 {list of descriptions for each command}
  prompt: string_var4_t;               {prompt to have user enter next command}
  cmline: string_var8192_t;            {command line entered by user}
  p: string_index_t;                   {parse index into CMLINE}
  cmd: string_var32_t;                 {command name from command line, upper case}
  parm: string_var8192_t;              {parameter parsed from command line}
  xtra: string_var32_t;                {extra parameter after end of command}
  pick: sys_int_machine_t;             {number of keyword picked from list}
  stat: sys_err_t;                     {completion status}

label
  loop_command, done_command,
  parm_missing, parm_bad, parm_extra, error, remind, leave;
{
****************************************
*
*   Subroutine ADD_COMMAND (NAME, DSC)
*   This routine is local to TEST_GELD_CMD.
*
*   Add the command NAME to the end of the commands list.  DSC is a brief
*   description of the command.
}
procedure add_command (                {add command to commands list}
  in      name: string;                {name of command and parameters description}
  in      dsc: string);                {short command description}
  val_param; internal;

var
  vstr: string_var132_t;               {scratch var string}
  p: string_index_t;                   {CMDSTR parse index}
  tk: string_var132_t;                 {scratch token parsed from string}
  dstr: string_var132_t;               {assembled description string}
  stat: sys_err_t;                     {completion status}

begin
  vstr.max := size_char(vstr.str);     {init local var strings}
  tk.max := size_char(tk.str);
  dstr.max := size_char(dstr.str);
  dstr.len := 0;                       {init description string to empty}

  string_vstring (vstr, name, -1);     {make name and parameters var string}
  p := 1;                              {init CMDSTR parse index}
{
*   Extract the bare command name from cmd/parameters string.  Add the command
*   to the end of the list in CMDS, and initialize the description string with
*   the command name.
}
  string_token (vstr, p, dstr, stat);  {get bare command name into DSTR}
  sys_error_abort (stat, '', '', nil, 0);
  string_upcase (dstr);                {all command names stored upper case}
  if cmds.len > 0 then begin           {there is a previous command in list ?}
    string_append1 (cmds, ' ');        {add separator before new command}
    end;
  string_append (cmds, dstr);          {add this command to the end of the list}
{
*   Append any parameters in the cmd/parameters string to the description
*   string.
}
  while (p <= vstr.len) and then (vstr.str[p] = ' ') do begin {skip blanks}
    p := p + 1;
    end;
  if p <= vstr.len then begin          {command parameters string exists ?}
    string_substr (                    {extract command parameters string into TK}
      vstr,                            {string to extract from}
      p,                               {start index of substring}
      vstr.len,                        {end index of substring}
      tk);                             {extracted substring}
    string_append1 (dstr, ' ');        {blank separator before parameters}
    string_append (dstr, tk);          {add parameters to description string}
    end;
{
*   Append the string in DSC to the end of the description string.
}
  string_vstring (vstr, dsc, -1);      {make var string bare description}
  if vstr.len > 0 then begin           {there is a description to add ?}
    while dstr.len < namewid do begin  {pad command/parameters to common column}
      string_append1 (dstr, ' ');
      end;
    if dstr.str[dstr.len] <> ' ' then begin {make sure there is preceeding blank}
      string_append1 (dstr, ' ');
      end;
    string_appendn (dstr, '- ', 2);    {separator before text description}
    string_append (dstr, vstr);        {add description text}
    end;

  string_list_str_add (desc, dstr);    {add description to end of list}
  end;
{
****************************************
*
*   Function NOT_EOL
*   This function is local to TEST_GELD_CMD.
*
*   Return FALSE iff the command line in CMLINE has not been exhausted.
}
function not_eol:                      {check for unused command parameter}
  boolean;                             {found unused command parameter, in PARM}
  val_param; internal;

var
  stat: sys_err_t;                     {completion status}

begin
  string_token (cmline, p, xtra, stat);
  not_eol := not string_eos(stat);
  end;
{
****************************************
*
*   Start of main routine.
}
begin
  cmds.max := size_char(cmds.str);     {init local var strings}
  prompt.max := size_char(prompt.str);
  cmline.max := size_char(cmline.str);
  cmd.max := size_char(cmd.str);
  parm.max := size_char(parm.str);
  xtra.max := size_char(xtra.str);
{
*   Build the list of command names in CMDS.
}
  cmds.len := 0;                       {init the commands list to empty}
  string_list_init (desc, geld_p^.mem_p^); {create empty command descriptions list}
  desc.deallocable := false;           {don't need to deallocate entries separately}

  add_command ('?',                    {1}
    'Show list of commands');
  add_command ('Q',                    {2}
    'Quit the program');
  add_command ('STAT',                 {3}
    'Show statistics');
  add_command ('MET meter',            {4}
    'Set curr meter, show basics');
  add_command ('LM start [n]',         {5}
    'List meters');
{
*   Initialize local state before command processing.
}
  string_vstring (prompt, prompt_text, -1); {set PROMPT to the prompt string}
{
*   Get the next command from the user.
}
loop_command:
  string_prompt (prompt);              {prompt user to enter a new command}
  string_readin (cmline);              {get the command line into CMLINE}
  string_unpad (cmline);               {truncate trailing blanks}
  if cmline.len <= 0 then goto loop_command; {ignore blank input lines}

  p := 1;                              {init parse index into CMLINE}
  string_token (cmline, p, cmd, stat); {get command name}
  if sys_error_check (stat, '', '', nil, 0) then goto loop_command;
  string_upcase (cmd);                 {make upper case command name in CMD}
  string_tkpick (cmd, cmds, pick);     {pick this command from the list}
  case pick of                         {which command is it ?}
{
********************
*
*   ?
*
*   Show list of commands with short descriptions.
}
1: begin
  if not_eol then goto parm_extra;

  string_list_pos_abs (desc, 1);       {to first command description}
  while desc.str_p <> nil do begin     {loop thru the command descriptions}
    writeln (desc.str_p^.str:desc.str_p^.len); {show this description}
    string_list_pos_rel (desc, 1);     {to next description in list}
    end;                               {back to show next description string}
  end;
{
********************
*
*   Q
*
*   Quit the program.
}
2: begin
  if not_eol then goto parm_extra;
  goto leave;
  end;
{
********************
*
*   STAT
*
*   Show statistics about the data in memory.
}
3: begin
  if not_eol then goto parm_extra;

  writeln (geld_p^.nmeters, ' meters defined.');
  end;
{
********************
*
*   MET meter
*
*   Make the meter with ID METER current and show basic info about the meter.
}
4: begin
  string_token_int (cmline, p, meterid, stat); {get meter ID number}
  if sys_error(stat) then goto error;
  if not_eol then goto parm_extra;

  geld_id_find (geld_p^, meterid, meter_p); {try to find meter descriptor}
  if meter_p = nil then begin
    writeln ('No such meter');
    goto done_command;
    end;

  geld_show_meter (meter_p^);          {show basic info about this meter}
  end;
{
********************
*
*   LM start [n]
*
*   List meters starting at or after the indicate meter number.  N is the
*   maximum number of meters to list, which defaults to NLIST (constant at top
*   of this module).
}
5: begin
  string_token_int (cmline, p, meterid, stat); {get starting meter ID}
  if sys_error(stat) then goto error;
  string_token_int (cmline, p, i1, stat); {try to get number of meters to list}
  if string_eos(stat)
    then begin                         {no token, use default}
      i1 := nlist;
      end
    else begin                         {other then end of input string}
      if sys_error(stat) then goto error; {hard error ?}
      if not_eol then goto parm_extra;
      end
    ;
  if i1 <= 0 then goto done_command;

  ii := 0;                             {init number of meters shown}
  geld_id_pos_id (geld_p^, meterid, meter_p, pos); {start at or after indicated meter}
  while meter_p <> nil do begin        {back here each new meter}
    geld_show_meter (meter_p^);        {show basic info about this meter}
    ii := ii + 1;                      {count one more meter shown}
    i1 := i1 - 1;                      {one less list entry allowed to show}
    if i1 <= 0 then exit;              {already showed max allowed meters ?}
    geld_id_next (geld_p^, pos, meter_p); {to next with next higher ID}
    end;
  write (ii, ' meter');
  if ii <> 1 then write ('s');
  writeln (' shown.');
  end;
{
********************
*
*   Unrecognized command name.
}
otherwise
    writeln ('Command "', cmd.str:cmd.len, '" is not recognized.');
    goto remind;
    end;                               {end of which command cases}
done_command:                          {done with the current command}
  goto loop_command;                   {done with this command, back for next}

parm_missing:                          {missing required parameter}
  writeln ('A required parameter to command ', cmd.str:cmd.len, ' is missing.');
  goto remind;

parm_bad:                              {parameter in PARM is bad}
  writeln ('Command parameter "', parm.str:parm.len, '" makes no sense here.');
  goto remind;

parm_extra:                            {extra parameter, in PARM}
  writeln ('Extra parameter "', xtra.str:xtra.len, '" does not belong here.');
  goto remind;

error:                                 {error while processig command}
  writeln ('Error in command "', cmd.str:cmd.len, '".');
  sys_error_print (stat, '', '', nil, 0);
  goto remind;

remind:                                {show reminder how to get commands list}
  writeln ('Enter "?" for list of commands.');
  goto loop_command;

leave:                                 {common exit point}
  string_list_kill (desc);             {deallocate command descriptions list}
  end;
