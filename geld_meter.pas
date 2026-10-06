{   Routines for manipulating data for individual meters.
}
module geld_meter;
define geld_meter_init;
define geld_meter_class_set;
define geld_meter_mult_set;
define geld_meter_intv_add;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_METER_INIT (ID, METER)
*
*   Initialize the meter data METER to default or benign values.  ID is the ID
*   of the meter.
}
procedure geld_meter_init (            {initialize meter data descriptor}
  in      id: geld_meterid_t;          {ID of meter initializing state of}
  out     meter: geld_meter_t);        {meter data to initialize}
  val_param;

begin
  meter.id := id;                      {save meter ID}
  meter.class := geld_rateclass_none_k; {init to rate class not set}
  meter.mult := 1.0;                   {init meter multiplier to make kWh}
  meter.intv_first_p := nil;           {init to no measured intervals}
  meter.intv_last_p := nil;
  end;
{
********************************************************************************
*
*   Function GELD_METER_CLASS_SET (GELD, METER, CLASS)
*
*   Set the rate class for the meter.  The function returns TRUE on success.
*   That means the meter is now set to the specified rate class, and that it was
*   previously either set to that class or no class was set.  The function
*   returns FALSE and does not change the rate class if it was previously set
*   to a different value.
}
function geld_meter_class_set (        {set rate class for a meter}
  in out  geld: geld_t;                {library use state}
  in out  meter: geld_meter_t;         {meter to set rateclass of}
  in      class: geld_rateclass_k_t)   {rate class of this meter}
  :boolean;                            {success, class was previously same or not set}
  val_param;

begin
  geld_meter_class_set := false;       {init to error}

  if                                   {trying to change class ?}
      (meter.class <> geld_rateclass_none_k) and {specific class previously set ?}
      (class <> meter.class)           {different from the new class ?}
    then return;

  meter.class := class;                {set the rate class for this meter}
  geld_meter_class_set := true;        {indicate success}
  end;
{
********************************************************************************
*
*   Subroutine GELD_METER_MULT_SET (GELD, METER, MULT)
*
*   Set the multiplication factor for a meter.  MULT is the factor to multiply
*   raw meter readings by to make killowatt hours (kWh).
}
procedure geld_meter_mult_set (        {set meter mult factor to make kWh}
  in out  geld: geld_t;                {library use state}
  in out  meter: geld_meter_t;         {meter to set multiplier of}
  in      mult: real);                 {mult factor (x reading = kWh)}
  val_param;

begin
  meter.mult := mult;                  {set mult factor for this meter}
  end;
{
********************************************************************************
*
*   Subroutine GELD_METER_INTV_ADD (GELD, METER, ST, EN, READING)
*
*   Add an interval measured by the indicated meter.  ST and EN are the start
*   and end times of the interval.  READING is the raw meter reading.  READING
*   will be multiplied by the mult factor for the specific meter to make kWh.
*
*   The new measured interval will be inserted into the list of measured
*   intervals for this meter in chronological order.
}
procedure geld_meter_intv_add (        {add measured interval to data for a meter}
  in out  geld: geld_t;                {library use state}
  in out  meter: geld_meter_t;         {meter to add measured interval to}
  in      st, en: sys_clock_t;         {interval start/end times}
  in      reading: real);              {energy reading, will be multiplied by meter factor}
  val_param;

var
  intv_p: geld_intv_p_t;               {to saved description of measured interval}
  ent_p: geld_intv_p_t;                {to existing measured intervals list entry}

begin
{
*   Create and initialize a new measured interval descriptor.
}
  util_mem_grab (sizeof(intv_p^), geld.mem_p^, false, intv_p); {alloc mem for new measurement}
  util_mem_grab_err_bomb (intv_p, sizeof(intv_p^));

  geld_intv_init (intv_p^);            {initialize the interval descriptor}
  geld_intv_set (                      {set the interval data}
    intv_p^,                           {interval to set data of}
    st, en,                            {interval start and end times}
    reading * meter.mult);             {consumed energy in kWh}
{
*   Handle special case of this is first measured intervals list entry.
}
  if meter.intv_first_p = nil then begin {there is no existing intervals list to add to ?}
    meter.intv_first_p := intv_p;      {this interval is now first and last list entry}
    meter.intv_last_p := intv_p;
    return;
    end;
{
*   Scan backwards thru the existing intervals list to find the first entry that
*   starts before this new interval.  This methods optimizes adding intervals in
*   forwards time order, which is how they are generally stored in the raw data
*   files.
}
  ent_p := meter.intv_last_p;          {init to last list entry}
  while ent_p <> nil do begin          {loop over the existing list of intervals}
    if ent_p^.tst <= intv_p^.tst then begin {add new interval after this list entry ?}
      intv_p^.prev_p := ent_p;         {link new entry back to previous}
      intv_p^.next_p := ent_p^.next_p; {link new entry forwards to next}
      if ent_p^.next_p = nil
        then begin                     {adding new entry to end of list}
          meter.intv_last_p := intv_p;
          end
        else begin                     {there is a next entry}
          ent_p^.next_p^.prev_p := intv_p;
          end
        ;
      ent_p^.next_p := intv_p;         {link previous entry forward to new}
      return;                          {done adding new interval to list}
      end;
    ent_p := ent_p^.prev_p;            {to previous list entry}
    end;                               {back to check this new list entry}
{
*   The whole existing intervals list was checked, and all entries are later
*   than the new interval.  Add the new interval to the start of the list.
}
  meter.intv_first_p^.prev_p := intv_p; {link existing first entry back to new}
  intv_p^.next_p := meter.intv_first_p; {link forward to first existing list entry}
  meter.intv_first_p := intv_p;        {new entry is now first in list}
  end;
