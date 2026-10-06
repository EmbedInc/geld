{   Routines to manipulate rate classes.
}
module geld_rateclass;
define geld_rateclass_t_code;
define geld_rateclass_f_code;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_RATECLASS_T_CODE (CLASS, CODE)
*
*   Make the 2-letter rate class code from the rate class ID in CLASS.  CODE
*   will be the empty string when CLASS is not a valid rate class.
}
procedure geld_rateclass_t_code (      {make 2-letter rate class code from ID}
  in      class: geld_rateclass_k_t;   {rate class ID}
  in out  code: univ string_var_arg_t); {returned 2 letter code, empty for invalid}
  val_param;

var
  lett: array[1..2] of char;           {2-letter rate class string}

begin
  code.len := 0;                       {init to returning the empty string}

  case class of                        {which rate class is it ?}
geld_rateclass_c1_k: lett := 'C1';
geld_rateclass_c2_k: lett := 'C2';
geld_rateclass_f1_k: lett := 'F1';
geld_rateclass_r2_k: lett := 'R2';
geld_rateclass_g1_k: lett := 'G1';
geld_rateclass_g2_k: lett := 'G2';
geld_rateclass_ge_k: lett := 'GE';
geld_rateclass_hh_k: lett := 'HH';
geld_rateclass_ht_k: lett := 'HT';
geld_rateclass_md_k: lett := 'MD';
geld_rateclass_r4_k: lett := 'R4';
geld_rateclass_sb_k: lett := 'SB';
geld_rateclass_ts_k: lett := 'TS';
geld_rateclass_tu_k: lett := 'TU';
otherwise
    return;                            {unrecognized rate class ID}
    end;

  string_appendn (code, lett, 2);      {set returned string to rate class 2-lett code}
  end;
{
********************************************************************************
*
*   Function GELD_RATECLASS_F_CODE (CODE)
*
*   Interpret the rate class 2-letter code in CODE to the corresponding rate
*   class ID.  CODE may be longer than 2 characters, but then the third
*   character must not be a letter.
*
*   Rate class code strings are upper case.
*
*   The function returns GELD_RATECLASS_NONE_K when SID does not indicate a
*   valid rate class according to the rules above.
}
function geld_rateclass_f_code (       {get rate class ID from 2-lett code}
  in      code: univ string_var_arg_t) {string, starts with rate class 2-lett code}
  :geld_rateclass_k_t;                 {rate class ID indicated by the string}
  val_param;

var
  ch3: char;                           {third character of input string, if any}
  tk: string_var4_t;                   {rate class code extracted from input string}
  pick: sys_int_machine_t;             {number of keyword picked from list}

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

  string_tkpick80 (tk,                 {pick rate code from keywords list}
    'C1 C2 F1 R2 G1 G2 GE HH HT MD R4 SB TS TU',
    pick);                             {1-N number of matching keyword, 0 = none}
  case pick of                         {which keyword was matched ?}
1: geld_rateclass_f_code := geld_rateclass_c1_k;
2: geld_rateclass_f_code := geld_rateclass_c2_k;
3: geld_rateclass_f_code := geld_rateclass_f1_k;
4: geld_rateclass_f_code := geld_rateclass_r2_k;
5: geld_rateclass_f_code := geld_rateclass_g1_k;
6: geld_rateclass_f_code := geld_rateclass_g2_k;
7: geld_rateclass_f_code := geld_rateclass_ge_k;
8: geld_rateclass_f_code := geld_rateclass_hh_k;
9: geld_rateclass_f_code := geld_rateclass_ht_k;
10: geld_rateclass_f_code := geld_rateclass_md_k;
11: geld_rateclass_f_code := geld_rateclass_r4_k;
12: geld_rateclass_f_code := geld_rateclass_sb_k;
13: geld_rateclass_f_code := geld_rateclass_ts_k;
14: geld_rateclass_f_code := geld_rateclass_tu_k;
    end;
  end;
