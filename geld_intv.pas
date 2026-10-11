{   Manipulation of meter measurements over a time interval.
}
module geld_intv;
define geld_intv_init;
define geld_intv_set;
define geld_intv_get;
define geld_intv_pos_start;
define geld_intv_pos_time;
define geld_intv_next;
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
  intv.tend := 0;                      {init interval ending time}
  intv.kwh := 0.0;                     {init measured energy during the interval}
  end;
{
********************************************************************************
*
*   Subroutine GELD_INTV_SET (INTV, TEND, KWH)
*
*   Set the data values of a measured energy interval.  INTV is the descriptor
*   for the interval.  ST and EN are the start and end times of the measurement.
*   KWH is the energy consumed during the time interval, in kWh.
}
procedure geld_intv_set (              {set the data of a measured interval}
  in out  intv: geld_intv_t;           {measured interval to set values of}
  in      tend: sys_clock_t;           {interval end time}
  in      kwh: real);                  {kWh energy measured during the interval}
  val_param;

begin
  intv.tend := sys_clock_to_clkmin32 (tend); {save interval end time}
  intv.kwh := kwh;                     {save energy consumed during the interval}
  end;
{
********************************************************************************
*
*   Subroutine GELD_INTV_GET (INTV, METER, ST, EN, KWH, SEC, WATTS)
*
*   Get the data of a measured time interval.  INTV is the descriptor of the
*   interval to get data about and METER is the meter that made the
*   mearsurement.
*
*   ST and EN are the start and end times of the interval.  KWH is the energy
*   consumed during the interval, in kWh.  SEC is the duration of the interval
*   in seconds.  WATTS is the average power consumed during the interval, in
*   Watts.
*
*   When the meter measuring period is unknown, KWH, SEC, and WATTS are set to
*   0 and ST is set to the measured interval end time (ST = EN).
}
procedure geld_intv_get (              {get data of a measured interval}
  in      intv: geld_intv_t;           {the interval to get data about}
  in      meter: geld_meter_t;         {meter that made the measurement}
  out     st, en: sys_clock_t;         {absolute start and end times}
  out     kwh: real;                   {energy consumed during interval, kWh}
  out     sec: real;                   {interval length, seconds}
  out     watts: real);                {average power consumption, Watts}
  val_param;

begin
  kwh := intv.kwh;                     {get kWh consumed during the interval}
  en := sys_clock_from_clkmin32 (intv.tend); {end time of this interval}

  sec := geld_meter_period (meter);    {get meter reading period}
  if sec < 0.05 then begin             {meter period not known ?}
    st := en;
    kwh := 0.0;
    sec := 0.0;
    watts := 0.0;
    return;
    end;

  st := sys_clock_sub (                {make interval starting time}
    en,                                {absolute time to start at}
    sys_clock_from_fp_rel(sec) );      {relative time to subtract}

  kwh := intv.kwh;                     {get kWh consumed during the interval}
  sec := sys_clock_to_fp2 (            {compute interval duration in seconds}
    sys_clock_sub (en, st)
    );
  watts := kwh * 3600000.0 / sec;      {average power consumption, Watts}
  end;
{
********************************************************************************
*
*   Subroutine GELD_INTV_POS_START (METER, POS)
*
*   Set POS to before the start of the list of readings from the indicated
*   meter.
}
procedure geld_intv_pos_start (        {init position to start of intervals list}
  in var  meter: geld_meter_t;         {meter that created the readings}
  out     pos: geld_intvpos_t);        {returned position, at first reading}
  val_param;

begin
  pos.meter_p := addr(meter);          {save pointer to the meter}
  pos.intv_p := nil;                   {init to before first reading}
  end;
{
********************************************************************************
*
*   Subroutine GELD_INTV_POS_TIME (METER, TIME, POS)
*
*   Set POS to immediately before the first reading for METER at or after TIME.
}
procedure geld_intv_pos_time (         {to before first reading at or after TIME}
  in var  meter: geld_meter_t;         {meter that created the readings}
  in      time: sys_clock_t;           {find first reading at or after this time}
  out     pos: geld_intvpos_t);        {returned position in readings list}
  val_param;

var
  intv_p: geld_intv_p_t;               {to current list entry}
  tmin: sys_clkmin32_t;                {time in internal format}

begin
  tmin := sys_clock_to_clkmin32 (time); {make time in internal format}
  pos.meter_p := addr(meter);          {save pointer to meter readings are from}

  intv_p := meter.intv_first_p;        {to first entry in list}
  while intv_p <> nil do begin         {scan forwards thru the list of readings}
    if intv_p^.tend > tmin then begin  {found first qualifying list entry ?}
      pos.intv_p := intv_p^.prev_p;    {back one so next will be first}
      return;
      end;
    intv_p := intv_p^.next_p;          {to next reading in the list}
    end;                               {back to check this new reading}

  pos.intv_p := meter.intv_last_p;     {next entry will be end of list}
  end;
{
********************************************************************************
*
*   Subroutine GELD_INTV_NEXT (POS, INTV_P)
*
*   Return INTV_P pointing to the next sequential meter reading from the current
*   position.  POS is updated so that each new call to this routine returns the
*   next sequential meter reading.  INTV_P is returned NIL the end of the list
*   is encoutnered.  Subsequent calls to this routine will continue to return
*   NIL.
}
procedure geld_intv_next (             {get next interval reading in list}
  in out  pos: geld_intvpos_t;         {position within readings list, updated}
  out     intv_p: geld_intv_p_t);      {to next interval, NIL at end of list}
  val_param;

begin
  if pos.intv_p = nil then begin       {before start of list ?}
    pos.intv_p := pos.meter_p^.intv_first_p; {go to first list entry}
    intv_p := pos.intv_p;              {return pointer to current entry}
    return;
    end;

  intv_p := pos.intv_p^.next_p;        {return pointer to next list entry}
  if intv_p <> nil then begin          {didn't just hit end of list ?}
    pos.intv_p := intv_p;              {update position to new list entry}
    end
  end;
