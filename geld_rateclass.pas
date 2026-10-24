{   Routines to manipulate rate classes.
}
module geld_rateclass;
define geld_read_rateclasses;
define geld_rateclass_t_code;
define geld_rateclass_f_code;
%include 'geld2.ins.pas';
%include 'stuff.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_READ_RATECLASSES (GELD, FNAM, STAT)
*
*   Read the rate classes definition file and create the rate classes array.
}
procedure geld_read_rateclasses (      {read rate classes definition file}
  in out  geld: geld_t;                {library use state}
  in      fnam: univ string_var_arg_t; {name of file to read, ".csv" suffix assumed}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cin: csv_in_t;                       {state for reading CSV data from input file}
  csv_open: boolean;                   {CSV file is open}
  list_code: string_list_t;            {list of rate class codes}
  list_desc: string_list_t;            {list of rate class description strings}
  code: string_var4_t;                 {short rate class code, upper case}
  desc: string_var80_t;                {description for current rate class}
  sz: sys_int_adr_t;                   {memory size}
  id: sys_int_machine_t;               {rate class ID}
  stat2: sys_err_t;                    {used when error code to return already in STAT}

label
  err_atline, leave;

begin
  code.max := size_char(code.str);     {init local var strings}
  desc.max := size_char(desc.str);
  csv_open := false;

  csv_in_open (fnam, geld.mem_p^, cin, stat); {open file for reading in CSV format}
  if sys_error(stat) then return;
  csv_open := true;                    {indicate the CSV file is now open}

  string_list_init (list_code, geld.mem_p^); {init list of rate class codes}
  list_code.deallocable := false;
  string_list_init (list_desc, geld.mem_p^); {init list of rate class descriptions}
  list_desc.deallocable := false;
{
*   Read the CSV file and make lists of the rate class codes and descriptions.
}
  while true do begin                  {back here each new CSV file line}
    csv_in_line (cin, stat);           {read next CSV file line}
    if file_eof(stat) then exit;       {hit end of file ?}
    if sys_error(stat) then goto leave; {hard error ?}

    csv_in_field_str (cin, code, stat); {get rate class code}
    if sys_error(stat) then begin
      sys_stat_set (geld_subsys_k, geld_stat_nrdclass_k, stat);
      goto err_atline;
      end;
    string_upcase (code);

    csv_in_field_str (cin, desc, stat); {get rate class description string}
    if sys_error(stat) then begin
      sys_stat_set (geld_subsys_k, geld_stat_rddesc_k, stat);
      goto err_atline;
      end;

    string_list_str_add (list_code, code); {save rate class code}
    string_list_str_add (list_desc, desc); {save rate class description}
    end;                               {back for next CSV file line}
  csv_in_close (cin, stat);
  csv_open := false;                   {indicate the CSV file is now closed}
  if sys_error(stat) then goto leave;
{
*   Create the rate classes array now that the number of rate classes is known.
}
  sz := list_code.n * sizeof(geld.rateclass_p^[1]); {size of rate classes array}
  util_mem_grab (sz, geld.mem_p^, false, geld.rateclass_p); {allocate the array}
  util_mem_grab_err_bomb (geld.rateclass_p, sz);
{
*   Fill in the new rate classes array and set the number of rate classes.
}
  string_list_pos_start (list_code);   {to before the start of the lists}
  string_list_pos_start (list_desc);

  for id := 1 to list_code.n do begin  {once for each rate class}
    string_list_pos_rel (list_code, 1); {to list entries for this ID}
    string_list_pos_rel (list_desc, 1);
    geld.rateclass_p^[id].id := id;    {1-N ID}
    geld.rateclass_p^[id].code.max := size_char(geld.rateclass_p^[id].code.str);
    string_copy (list_code.str_p^, geld.rateclass_p^[id].code);
    geld.rateclass_p^[id].desc.max := size_char(geld.rateclass_p^[id].desc.str);
    string_copy (list_desc.str_p^, geld.rateclass_p^[id].desc);
    geld.rateclass_p^[id].nmeters := 0; {init to no meters in this rate class}
    geld.rateclass_p^[id].nintv := 0;  {init to no reading intervals this rate class}
    geld.rateclass_p^[id].kwh := 0.0;  {init total power measured this rate class}
    end;                               {back for next rate class}

  geld.nrateclasses := list_code.n;    {set official number of rate classes}
  goto leave;

err_atline:                            {add file name and line number to STAT}
  sys_stat_parm_vstr (cin.conn.fnam, stat); {CSV file name}
  sys_stat_parm_int (cin.conn.lnum, stat); {current CSV file line number}

leave:                                 {common exit point after CSV opened, STAT set}
  string_list_kill (list_desc);        {deallocate description strings list}
  string_list_kill (list_code);        {deallocate rate class codes list}
  if csv_open then begin               {CSV file is open ?}
    csv_in_close (cin, stat2);         {close CSV input file, avoid corrupting STAT}
    end;
  end;
{
********************************************************************************
*
*   Subroutine GELD_RATECLASS_T_CODE (GELD, CLASS, CODE)
*
*   Get the 2-letter rate class code from the rate class ID in CLASS.  CODE will
*   be the empty string when CLASS is not a valid rate class.
}
procedure geld_rateclass_t_code (      {get 2-letter rate class code from ID}
  in      geld: geld_t;                {library use state}
  in      class: sys_int_machine_t;    {rate class ID}
  in out  code: univ string_var_arg_t); {returned 2 letter code, empty for invalid}
  val_param;

begin
  code.len := 0;                       {init to rate class ID is invalid}
  if (class < 1) or (class > geld.nrateclasses) then return; {invalid ID ?}
  string_copy (geld.rateclass_p^[class].code, code); {return the code}
  end;
{
********************************************************************************
*
*   Function GELD_RATECLASS_F_CODE (GELD, CODE)
*
*   Interpret the rate class 2-letter code in CODE to the corresponding rate
*   class ID.  CODE may be longer than 2 characters, but then the third
*   character must not be a letter.
*
*   Rate class code strings are upper case.
*
*   The function returns GELD_RATECLASS_NONE_K when CODE does not indicate a
*   valid rate class according to the rules above.
}
function geld_rateclass_f_code (       {get rate class ID from 2-lett code}
  in      geld: geld_t;                {library use state}
  in      code: univ string_var_arg_t) {string, starts with rate class 2-lett code}
  :sys_int_machine_t;                  {1-N rate class or GELD_RATECLASS_NONE_K}
  val_param;

var
  ch3: char;                           {third character of input string, if any}
  tk: string_var4_t;                   {rate class code extracted from input string}
  id: sys_int_machine_t;               {rate class ID}

begin
  tk.max := size_char(tk.str);         {init local var string}
  geld_rateclass_f_code := geld_rateclass_none_k; {init to rate code was invalid}

  if code.len < 2 then return;         {too short to be valid rate code ?}

  if code.len > 2 then begin           {extra chars, make sure 3rd is delimiter ?}
    ch3 := string_upcase_char(code.str[3]); {get first char after 2-char rate code}
    if (ch3 >= 'A') and (ch3 <= 'Z') then return; {not a valid delimiter after code ?}
    end;

  tk.str[1] := code.str[1];            {make just the rate code string}
  tk.str[2] := code.str[2];
  tk.len := 2;

  for id := 1 to geld.nrateclasses do begin {scan the list of rate classes}
    if string_equal (tk, geld.rateclass_p^[id].code) then begin {code matches ?}
      geld_rateclass_f_code := id;     {return ID of the matching rate class}
      return;
      end;
    end;                               {back to check next rate class}
  end;
