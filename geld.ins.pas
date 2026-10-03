{   Public include file for the GELD library.  This library provides facilities
*   for reading and processing Groton Electric Light Department data.
}
const
  geld_subsys_k = -90;                 {Embed subsystem ID for the GELD library}

  geld_idlev_bits = 4;                 {meter ID bits per level of IDs tree}
  geld_idbits = 32;                    {max bits per meter ID}

{
*   Derived constants.
}
  geld_idlevels =                      {number of levels in meter IDs tree}
    (geld_idbits + geld_idlev_bits - 1) div geld_idlev_bits;
  geld_idlev_last = geld_idlevels - 1; {maximum 0-N meter IDs tree level number}
  geld_nbranch = lshft(1, geld_idlev_bits); {number of branches per IDs tree level}
  geld_maxbranch = geld_nbranch - 1;   {max 0-N branch index per IDs tree level}
  geld_idlev_mask = geld_maxbranch;    {mask for ID bits per level}

type
  geld_rateclass_k_t = (               {IDs for each rate class}
    geld_rateclass_none_k,             {class not set or unknown}
    geld_rateclass_c1_k,               {commercial}
    geld_rateclass_c2_k,               {commerical solar}
    geld_rateclass_f1_k,               {farm}
    geld_rateclass_r2_k,               {farm solar}
    geld_rateclass_g1_k,               {municipal}
    geld_rateclass_g2_k,               {non-profit}
    geld_rateclass_ge_k,               {GELD internal use}
    geld_rateclass_hh_k,               {home heating}
    geld_rateclass_ht_k,               {high tension}
    geld_rateclass_md_k,               {municipal demand}
    geld_rateclass_r4_k,               {residential farm solar}
    geld_rateclass_sb_k,               {solar battery}
    geld_rateclass_ts_k,               {time of use solar}
    geld_rateclass_tu_k);              {time of use}

  geld_meterid_t = sys_int_conv32_t;   {ID of one meter}

  geld_intv_p_t = ^geld_intv_t;
  geld_intv_t = record                 {one measured electricity use interval}
    prev_p: geld_intv_p_t;             {to previous record this meter}
    next_p: geld_intv_p_t;             {to next record this meter}
    tst, ten: sys_clkmin32_t;          {start/end time of this interval}
    kwh: real;                         {total kWh use during interval}
    end;

  geld_meter_p_t = ^geld_meter_t;
  geld_meter_t = record                {data about one electric meter}
    id: geld_meterid_t;                {meter ID}
    class: geld_rateclass_k_t;         {rate class ID}
    mult: real;                        {meter reading multiplier to make kWh}
    intv_first_p: geld_intv_p_t;       {to first measured interval in list}
    intv_last_p: geld_intv_p_t;        {to last measured interval in list}
    end;

  geld_idnode_k_t = (                  {type of ID tree nodes}
    geld_idnode_tree_k,                {tree node, not last level}
    geld_idnode_last_k);               {last tree level, points to leaves}

  geld_idnode_p_t = ^geld_idnode_t;
  geld_idnode_t = record               {one node in meter IDs tree}
    up_p: geld_idnode_p_t;             {to parent node, NIL at top}
    level: sys_int_machine_t;          {levels down from top, 0 at top}
    case geld_idnode_k_t of
geld_idnode_tree_k: (                  {tree node, not a leaf node}
      nodep: array[0..geld_maxbranch] of geld_idnode_p_t; {to next level down nodes}
      );
geld_idnode_last_k: (                  {lowest tree node, points to leaves}
      meterp: array[0..geld_maxbranch] of geld_meter_p_t; {to meter descriptors}
      );
    end;

  geld_p_t = ^geld_t;
  geld_t = record                      {state for this use of the GELD library}
    mem_p: util_mem_context_p_t;       {to mem context for this lib use}
    idtree: geld_idnode_t;             {root node of meter IDs tree}
    nmeters: sys_int_machine_t;        {number of meters defined}
    end;
{
*   Subroutines and functions.
}
procedure geld_id_find (               {find specific meter, create if not exist}
  in out  geld: geld_t;                {library use state}
  in      id: geld_meterid_t;          {ID of meter to find}
  out     meter_p: geld_meter_p_t);    {returned pointer to data about the meter}
  val_param; extern;

procedure geld_intv_get (              {get data of a measured interval}
  in      intv: geld_intv_t;           {the interval to get data about}
  out     st, en: sys_clock_t;         {absolute start and end times}
  out     kwh: real;                   {energy consumed during interval, kWh}
  out     sec: real;                   {interval length, seconds}
  out     watts: real);                {average power consumption, Watts}
  val_param; extern;

procedure geld_intv_set (              {set the data of a measured interval}
  in out  intv: geld_intv_t;           {measured interval to set values of}
  in      st, en: sys_clock_t;         {interval start and end time}
  in      kwh: real);                  {kWh energy measured during the interval}
  val_param; extern;

procedure geld_lib_end (               {end a use of the GELD library, dealloc resources}
  in out  geld_p: geld_p_t);           {to library use state, will be returned NIL}
  val_param; extern;

procedure geld_lib_new (               {create new use of the GELD library}
  in out  mem: util_mem_context_t;     {parent mem context, will create subordinate}
  out     geld_p: geld_p_t);           {returned new library use state}
  val_param; extern;

procedure geld_meter_intv_add (        {add measured interval to data for a meter}
  in out  geld: geld_t;                {library use state}
  in out  meter: geld_meter_t;         {meter to add measured interval to}
  in      st, en: sys_clock_t;         {interval start/end times}
  in      reading: real);              {energy reading, will be multiplied by meter factor}
  val_param; extern;

procedure geld_meter_class_set (       {set rate class for a meter}
  in out  geld: geld_t;                {library use state}
  in out  meter: geld_meter_t;         {meter to set rateclass of}
  in      class: geld_rateclass_k_t);  {rate class of this meter}
  val_param; extern;

procedure geld_meter_mult_set (        {set meter mult factor to make kWh}
  in out  geld: geld_t;                {library use state}
  in out  meter: geld_meter_t;         {meter to set multiplier of}
  in      mult: real);                 {mult factor (x reading = kWh)}
  val_param; extern;
