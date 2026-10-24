{   Public include file for the GELD library.  This library provides facilities
*   for reading and processing Groton Electric Light Department data.
}
const
{
*   Error and status codes.
}
  geld_subsys_k = -90;                 {Embed subsystem ID for the GELD library}
  geld_stat_multhead_k = 1;            {invalid multipliers file header line}
  geld_stat_bmet_k = 2;                {bad meter ID in CSV file}
  geld_stat_nrdclass_k = 3;            {error reading rate class code in CSV file}
  geld_stat_bclass_k = 4;              {bad rate class code in CSV file}
  geld_stat_bmult_k = 5;               {bad meter multiplier in CSV file}
  geld_stat_flineclass_k = 6;          {attempt to change rate class, in file/line}
  geld_stat_errdate_k = 7;             {error reading MM/DD/YEAR date from file}
  geld_stat_errtime_k = 8;             {error reading HH:MM time from file}
  geld_stat_breading_k = 9;            {bad meter reading in file}
  geld_stat_baddate_k = 10;            {bad MM/DD/YEAR date string in file}
  geld_stat_badhhmm_k = 11;            {bad HH:MM time string in file}
  geld_stat_bmetper_k = 12;            {attempt to change meter period in file}
  geld_stat_rddesc_k = 13;             {error reading rate class description}
{
*   Configuration constants.
}
  geld_idlev_bits = 4;                 {meter ID bits per level of IDs tree}
  geld_idbits = 32;                    {max bits per meter ID}
  geld_rateclass_none_k = 0;           {special rate class ID for none or unknown}
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
  geld_rateclass_t = record
    id: sys_int_machine_t;             {1-N unique ID}
    code: string_var4_t;               {short 2-letter code, upper case}
    desc: string_var80_t;              {description string}
    nmeters: sys_int_machine_t;        {number of meters}
    nintv: sys_int_machine_t;          {number of meter reading intervals}
    kwh: double;                       {total kWh consumed}
    end;

  geld_rateclass_ar_p_t = ^geld_rateclass_ar_t;
  geld_rateclass_ar_t =                {array of rate classes}
    array[1..8] of geld_rateclass_t;   {each class, array dimensioned at run time}

  geld_classset_t = sys_int_conv32_t;  {arbitrary set of rate classes}

  geld_meterid_t = sys_int_conv32_t;   {ID of one meter}

  geld_intv_p_t = ^geld_intv_t;
  geld_intv_t = record                 {one measured electricity use interval}
    prev_p: geld_intv_p_t;             {to previous record this meter}
    next_p: geld_intv_p_t;             {to next record this meter}
    tend: sys_clkmin32_t;              {end time of this interval}
    kwh: real;                         {total kWh use during interval}
    end;

  geld_meter_p_t = ^geld_meter_t;
  geld_meter_t = record                {data about one electric meter}
    id: geld_meterid_t;                {meter ID}
    class: sys_int_machine_t;          {rate class ID}
    mult: real;                        {meter reading multiplier to make kWh}
    period: sys_int_conv32_t;          {seconds reading period, 0 = unknown}
    nintv: sys_int_machine_t;          {number of measured intervals in list}
    kwh: double;                       {total kWh measured by this meter}
    intv_first_p: geld_intv_p_t;       {to first measured interval in list}
    intv_last_p: geld_intv_p_t;        {to last measured interval in list}
    end;

  geld_intvpos_t = record              {saved position within list of intervals}
    meter_p: geld_meter_p_t;           {to meter that made the readings}
    intv_p: geld_intv_p_t;             {to curr reading, NIL before first}
    end;

  geld_idnode_k_t = (                  {type of ID tree nodes}
    geld_idnode_tree_k,                {tree node, not last level}
    geld_idnode_last_k);               {last tree level, points to leaves}

  geld_idnode_p_t = ^geld_idnode_t;
  geld_idnode_t = record               {one node in meter IDs tree}
    up_p: geld_idnode_p_t;             {to parent node, NIL at top}
    pbr: sys_int_machine_t;            {0-N branch in parent node}
    level: sys_int_machine_t;          {levels down from top, 0 at top}
    case geld_idnode_k_t of
geld_idnode_tree_k: (                  {tree node, not a leaf node}
      nodep: array[0..geld_maxbranch] of geld_idnode_p_t; {to next level down nodes}
      );
geld_idnode_last_k: (                  {lowest tree node, points to leaves}
      meterp: array[0..geld_maxbranch] of geld_meter_p_t; {to meter descriptors}
      );
    end;

  geld_idpos_t = record                {saved position within IDs tree}
    node_p: geld_idnode_p_t;           {to current node, NIL after end}
    br: sys_int_machine_t;             {0-N branch within node}
    end;

  geld_power_p_t = ^geld_power_t;
  geld_power_t =                       {average power per slice, size variable}
    array[0..128] of double;

  geld_p_t = ^geld_t;
  geld_t = record                      {state for this use of the GELD library}
    mem_p: util_mem_context_p_t;       {to mem context for this lib use}
    nfiles: sys_int_machine_t;         {number of data files read}
    tread: real;                       {time reading data files tree, seconds}
    idtree: geld_idnode_t;             {root node of meter IDs tree}
    nmeters: sys_int_machine_t;        {total number of meters}
    nintv: sys_int_machine_t;          {total number of meter reading intervals}
    kwh: double;                       {total kWh measured}
    nrateclasses: sys_int_machine_t;   {number of rate classes}
    rateclass_p: geld_rateclass_ar_p_t; {to rate classes, index 1 - NRATECLASSES}
    end;
{
*   Subroutines and functions.
}
procedure geld_avepower (              {compute average power over interval}
  in      geld: geld_t;                {library use state}
  out     power: univ geld_power_t;    {average power per time slice, Watts}
  in      npower: sys_int_machine_t;   {number of POWER entries, wrapped as needed}
  in      slsec: sys_int_machine_t;    {size of each slice, seconds}
  in      st, en: sys_clock_t;         {start and end time to average over}
  in      classes: geld_classset_t);   {set of rate classes to include}
  val_param; extern;

procedure geld_classset_add (          {add a rate class to set of rate classes}
  in      geld: geld_t;                {library use state}
  in      class: sys_int_machine_t;    {the rate class to add to the set}
  in out  classset: geld_classset_t);  {set to add the rate class to}
  val_param; extern;

function geld_classset_all (           {return the set of all rate classes}
  in      geld: geld_t)                {library use state}
  :geld_classset_t;
  val_param; extern;

function geld_classset_empty (         {determine whether a set of rate classes is empty}
  in      geld: geld_t;                {library use state}
  in      classset: geld_classset_t)   {the set of rate classes to check}
  :boolean;                            {the set is empty}
  val_param; extern;

function geld_classset_none (          {return the empty set of rate classes}
  in      geld: geld_t)                {library use state}
  :geld_classset_t;
  val_param; extern;

function geld_classset_in (            {determine if a rate class is in a set}
  in      geld: geld_t;                {library use state}
  in      class: sys_int_machine_t;    {rate class ID}
  in      classset: geld_classset_t)   {set of rate classes}
  :boolean;                            {CLASS is in the set}
  val_param; extern;

procedure geld_classset_sub (          {remove a rate class from set of rate classes}
  in      geld: geld_t;                {library use state}
  in      class: sys_int_machine_t;    {the rate class to remove from the set}
  in out  classset: geld_classset_t);  {set to remove the rate class from}
  val_param; extern;

procedure geld_id_find (               {find specific meter}
  in out  geld: geld_t;                {library use state}
  in      id: geld_meterid_t;          {ID of meter to find}
  out     meter_p: geld_meter_p_t);    {to meter data, NIL if no such meter}
  val_param; extern;

procedure geld_id_get (                {find specific meter, create if not exist}
  in out  geld: geld_t;                {library use state}
  in      id: geld_meterid_t;          {ID of meter to find}
  out     meter_p: geld_meter_p_t);    {returned pointer to data about the meter}
  val_param; extern;

procedure geld_id_next (               {to next ID in list}
  in      geld: geld_t;                {library use state}
  in out  pos: geld_idpos_t;           {position with IDs list, will be updated}
  out     meter_p: geld_meter_p_t);    {to meter with next higher ID, NIL at list end}
  val_param; extern;

procedure geld_id_pos_id (             {init IDs position to specific ID}
  in out  geld: geld_t;                {library use state}
  in      id: geld_meterid_t;          {pos will be first meter at or after this ID}
  out     meter_p: geld_meter_p_t;     {meter at the new position, NIL at end of list}
  out     pos: geld_idpos_t);          {returned initialized position in IDs list}
  val_param; extern;

procedure geld_id_pos_start (          {init IDs position to start of list}
  in      geld: geld_t;                {library use state}
  out     pos: geld_idpos_t);          {returned initialized position in IDs list}
  val_param; extern;

procedure geld_intv_get (              {get data of a measured interval}
  in      intv: geld_intv_t;           {the interval to get data about}
  in      meter: geld_meter_t;         {meter that made the measurement}
  out     st, en: sys_clock_t;         {absolute start and end times}
  out     kwh: real;                   {energy consumed during interval, kWh}
  out     sec: real;                   {interval length, seconds}
  out     watts: real);                {average power consumption, Watts}
  val_param; extern;

procedure geld_intv_next (             {get next interval reading in list}
  in out  pos: geld_intvpos_t;         {position within readings list, updated}
  out     intv_p: geld_intv_p_t);      {to next interval, NIL at end of list}
  val_param; extern;

procedure geld_intv_pos_time (         {to before first reading at or after TIME}
  in var  meter: geld_meter_t;         {meter that created the readings}
  in      time: sys_clock_t;           {find first reading at or after this time}
  out     pos: geld_intvpos_t);        {returned position in readings list}
  val_param; extern;

procedure geld_intv_pos_start (        {init position to start of intervals list}
  in var  meter: geld_meter_t;         {meter that created the readings}
  out     pos: geld_intvpos_t);        {returned position, at first reading}
  val_param; extern;

procedure geld_intv_set (              {set the data of a measured interval}
  in out  intv: geld_intv_t;           {measured interval to set values of}
  in      tend: sys_clock_t;           {interval end time}
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
  in      tend: sys_clock_t;           {interval end time}
  in      reading: real);              {energy reading, will be multiplied by meter factor}
  val_param; extern;

function geld_meter_class_set (        {set rate class for a meter}
  in out  geld: geld_t;                {library use state}
  in out  meter: geld_meter_t;         {meter to set rateclass of}
  in      class: sys_int_machine_t)    {rate class ID of this meter}
  :boolean;                            {success, class was previously same or not set}
  val_param; extern;

procedure geld_meter_mult_set (        {set meter mult factor to make kWh}
  in out  geld: geld_t;                {library use state}
  in out  meter: geld_meter_t;         {meter to set multiplier of}
  in      mult: real);                 {mult factor (x reading = kWh)}
  val_param; extern;

function geld_meter_period (           {meter measuring period}
  in      meter: geld_meter_t)         {meter inquiring measuring period of}
  :real;                               {period in seconds, 0 = unknown}
  val_param; extern;

function geld_meter_period_set (       {set reading period for a meter}
  in out  geld: geld_t;                {library use state}
  in out  meter: geld_meter_t;         {meter to update}
  in      sec: real)                   {reading period, seconds}
  :boolean;                            {success, not previously set to different period}
  val_param; extern;

function geld_rateclass_f_code (       {get rate class ID from 2-lett code}
  in      geld: geld_t;                {library use state}
  in      code: univ string_var_arg_t) {string, starts with rate class 2-lett code}
  :sys_int_machine_t;                  {1-N rate class or GELD_RATECLASS_NONE_K}
  val_param; extern;

procedure geld_rateclass_t_code (      {get 2-letter rate class code from ID}
  in      geld: geld_t;                {library use state}
  in      class: sys_int_machine_t;    {rate class ID}
  in out  code: univ string_var_arg_t); {returned 2 letter code, empty for invalid}
  val_param; extern;

procedure geld_read_intv_class (       {read interval data file for specific rate class}
  in out  geld: geld_t;                {library use state}
  in      fnam: univ string_var_arg_t; {name of file to read, ".csv" suffix assumed}
  in      class: sys_int_machine_t;    {rate class ID for all data in the file}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure geld_read_mult (             {read meter multipliers file}
  in out  geld: geld_t;                {library use state}
  in      fnam: univ string_var_arg_t; {name of file to read, ".csv" suffix assumed}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure geld_read_rateclasses (      {read rate classes definition file}
  in out  geld: geld_t;                {library use state}
  in      fnam: univ string_var_arg_t; {name of file to read, ".csv" suffix assumed}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure geld_read_tree (             {read tree of GELD data files}
  in out  geld: geld_t;                {library use state}
  in      dir: univ string_var_arg_t;  {name of directory containing data tree}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure geld_show_meter (            {show basic info about a meter}
  in      geld: geld_t;                {library use state}
  in      meter: geld_meter_t);        {meter to show info about}
  val_param; extern;

procedure geld_show_intv (             {show measured interval}
  in      intv: geld_intv_t;           {the interval to show}
  in      meter: geld_meter_t);        {meter that measured the interval}
  val_param; extern;

procedure geld_show_read_stats (       {show stats from reading data files}
  in      geld: geld_t);               {library use state}
  val_param; extern;
