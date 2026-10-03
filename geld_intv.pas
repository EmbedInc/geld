{   Manipulation of meter measurements over a time interval.
}
module geld_intv;
define geld_intv_init;
define geld_intv_set;
define geld_intv_get;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_INTV_INIT (INTV)
*
*   Initialize the measured interval descriptor INTV to default or bening
*   values to the extent possible.
}
procedure geld_intv_init (             {initialize a measured interval descriptor}
  out     intv: geld_intv_t);          {interval to initialize}
  val_param;

begin
  intv.prev_p := nil;                  {not pointing to previous entry in list}
  intv.next_p := nil;                  {not pointing to next entry in list}
  intv.tst := 0;                       {init start and end times of the interval}
  intv.ten := 0;
  intv.kwh := 0.0;                     {init measured energy during the interval}
  end;
{
********************************************************************************
*
*   Subroutine GELD_INTV_SET (INTV, ST, EN, KWH)
*
*   Set the data values of a measured energy interval.  INTV is the descriptor
*   for the interval.  ST and EN are the start and end times of the measurement.
*   KWH is the energy consumed during the time interval, in kWh.
}
procedure geld_intv_set (              {set the data of a measured interval}
  in out  intv: geld_intv_t;           {measured interval to set values of}
  in      st, en: sys_clock_t;         {interval start and end time}
  in      kwh: real);                  {kWh energy consumed during the interval}
  val_param;

begin
  intv.tst := sys_clock_to_clkmin32 (st); {save interval start time}
  intv.ten := sys_clock_to_clkmin32 (en); {save interval end time}
  intv.kwh := kwh;                     {save energy consumed during the interval}
  end;
{
********************************************************************************
*
*   Subroutine GELD_INTV_GET (INTV, ST, EN, KWH, SEC, WATTS)
*
*   Get the data of a measured time interval.  INTV is the descriptor of the
*   interval to get data about.  ST and EN are the start and end times of the
*   interval.  KWH is the energy consumed during the interval, in kWh.  SEC
*   is the duration of the interval in seconds.  WATTS is the average power
*   consumed during the interval, in Watts.
}
procedure geld_intv_get (              {get data of a measured interval}
  in      intv: geld_intv_t;           {the interval to get data about}
  out     st, en: sys_clock_t;         {absolute start and end times}
  out     kwh: real;                   {energy consumed during interval, kWh}
  out     sec: real;                   {interval length, seconds}
  out     watts: real);                {average power consumption, Watts}
  val_param;

begin
  st := sys_clock_from_clkmin32 (intv.tst); {get interval start time}
  en := sys_clock_from_clkmin32 (intv.ten); {get interval end time}
  kwh := intv.kwh;                     {get kWh consumed during the interval}
  sec := sys_clock_to_fp2 (            {compute interval duration in seconds}
    sys_clock_sub (en, st)
    );
  watts := kwh * 3600000.0 / sec;      {average power consumption, Watts}
  end;
