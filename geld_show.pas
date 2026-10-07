{   Routines to show data to the user via STDOUT.
}
module geld_show;
define geld_show_meter;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_SHOW_METER (METER)
*
*   Show basic one-line info about the meter from the current output position.
}
procedure geld_show_meter (            {show basic info about a meter}
  in      meter: geld_meter_t);        {meter to show info about}
  val_param;

var
  tk: string_var32_t;                  {scratch token}

begin
  tk.max := size_char(tk.str);         {init local var string}

  write (meter.id:10);                 {meter ID}

  geld_rateclass_t_code (meter.class, tk); {make rate class code}
  if tk.len = 0 then begin             {no rate class set ?}
    string_vstring (tk, '--', 2);      {show dashes}
    end;
  write (', rate class ', tk.str:tk.len);

  write (', multiplier', meter.mult:8:2); {show meter multiplier}
  writeln;
  end;
