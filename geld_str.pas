{   String conversion routines.
}
module geld_str;
define geld_str_mmddyear;
define geld_str_hhmm;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Function GELD_STR_MMDDYEAR (STR, DATE)
*
*   Set DATE to the start of the day indicated by the MM/DD/YEAR string STR.
*   The function returns TRUE on success.  The function returns FALSE when STR
*   is not a valid date string.
}
function geld_str_mmddyear (           {set date/time from MM/DD/YEAR string}
  in      str: univ string_var_arg_t;  {string to interpret}
  out     date: sys_date_t)            {date/time descriptor to set}
  :boolean;                            {success, not invalid input string}
  val_param;

var
  p: string_index_t;                   {parse index into STR}
  tk: string_var32_t;                  {token parsed from STR}
  ii: sys_int_machine_t;               {scratch integer}
  stat: sys_err_t;                     {completion status}

begin
  tk.max := size_char(tk.str);         {init local var string}
  geld_str_mmddyear := false;          {init to input string is invalid}

  p := 1;                              {init parse index into input string}

  string_token_anyd (                  {parse MM string from the input}
    str,                               {input string}
    p,                                 {parse index}
    '/', 1,                            {list of token delimiters}
    0,                                 {first N delimiters that may be repeated}
    [string_tkopt_padsp_k],            {strip leading/trailing blank padding}
    tk,                                {returned parsed token}
    ii,                                {number of delimiter ending token, unused}
    stat);
  if sys_error(stat) then return;
  string_t_int (tk, ii, stat);         {make 1-N month number}
  if sys_error(stat) then return;
  date.month := ii - 1;                {save 0-N month offset}

  string_token_anyd (                  {parse DD string from the input}
    str,                               {input string}
    p,                                 {parse index}
    '/', 1,                            {list of token delimiters}
    0,                                 {first N delimiters that may be repeated}
    [string_tkopt_padsp_k],            {strip leading/trailing blank padding}
    tk,                                {returned parsed token}
    ii,                                {number of delimiter ending token, unused}
    stat);
  if sys_error(stat) then return;
  string_t_int (tk, ii, stat);         {make 1-N day number}
  if sys_error(stat) then return;
  date.day := ii - 1;                  {save 0-N day offset}

  string_token (str, p, tk, stat);     {get YEAR string}
  if sys_error(stat) then return;
  string_t_int (tk, ii, stat);         {make year number}
  if sys_error(stat) then return;
  date.year := ii;                     {save year}

  string_token (str, p, tk, stat);     {try to get another token}
  if not string_eos(stat) then return; {not hit end of string as expected ?}
{
*   The YEAR, MONTH, and DAY fields of DATE have been set.  Now initialize the
*   rest of the date descriptor.
}
  date.hour := 0;
  date.minute := 0;
  date.second := 0;
  date.sec_frac := 0.0;
  date.tzone_id := sys_tzone_east_usa_k;
  date.daysave := sys_daysave_appl_k;
  sys_date_clean (date, date);         {sanitize all the fields of DATE}

  geld_str_mmddyear := true;           {indicate success}
  end;
{
********************************************************************************
*
*   Function GELD_STR_HHMM (STR, DATE)
*
*   Update DATE to the hour within the day indicated by the HH:MM string STR.
*   The function returns TRUE on success, and FALSE when STR is not a valid
*   HH:MM string.
}
function geld_str_hhmm (               {update date/time from HH:MM string}
  in      str: univ string_var_arg_t;  {string to interpret}
  in out  date: sys_date_t)            {date/time to set time within day of}
  :boolean;                            {success, not invalid input string}
  val_param;

var
  p: string_index_t;                   {parse index into STR}
  tk: string_var32_t;                  {token parsed from STR}
  ii: sys_int_machine_t;               {scratch integer}
  stat: sys_err_t;                     {completion status}

begin
  tk.max := size_char(tk.str);         {init local var string}
  geld_str_hhmm := false;              {init to input string is invalid}

  p := 1;                              {init parse index into input string}

  string_token_anyd (                  {parse HH string from the input}
    str,                               {input string}
    p,                                 {parse index}
    ':', 1,                            {list of token delimiters}
    0,                                 {first N delimiters that may be repeated}
    [string_tkopt_padsp_k],            {strip leading/trailing blank padding}
    tk,                                {returned parsed token}
    ii,                                {number of delimiter ending token, unused}
    stat);
  if sys_error(stat) then return;
  string_t_int (tk, ii, stat);         {make 0-N hour}
  if sys_error(stat) then return;
  date.hour := ii;                     {save hour offset from start of day}

  string_token (str, p, tk, stat);     {get MM string}
  if sys_error(stat) then return;
  string_t_int (tk, ii, stat);         {make 0-N minute within hour}
  if sys_error(stat) then return;
  date.minute := ii;                   {save minutes offset from start of hour}

  string_token (str, p, tk, stat);     {try to get another token}
  if not string_eos(stat) then return; {not hit end of string as expected ?}

  sys_date_clean (date, date);         {sanitize all the fields of DATE}
  geld_str_hhmm := true;               {indicate success}
  end;
