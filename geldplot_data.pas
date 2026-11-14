{   Create and delete data to plot.
}
module geldplot_data;
define geldplot_data_del;
define geldplot_data_make;
%include 'geldplot.ins.pas';
{
********************************************************************************
*
*   Local subroutine GELDPLOT_DATA_NEW (DATA_P)
*
*   Allocate and initialize a plottable data descriptor.
}
procedure geldplot_data_new (          {create and init new data descriptor}
  out     data_p: data_p_t);           {returned pointing to new descriptor}
  val_param; internal;

var
  mem_p: util_mem_context_p_t;         {to mem context for new descriptor}

begin
  util_mem_context_get (geld_p^.mem_p^, mem_p); {create new mem context}
  util_mem_context_err_bomb (mem_p);

  util_mem_grab (                      {alloc mem for the new descriptor}
    sizeof(data_p^), mem_p^, false, data_p);
  util_mem_grab_err_bomb (data_p, sizeof(data_p^));

  data_p^.mem_p := mem_p;              {initialize the new descriptor}
  data_p^.ndat := 0;
  data_p^.slsec := 0;
  data_p^.slx := 0.0;
  data_p^.labx.max := size_char(data_p^.labx.str);
  data_p^.labx.len := 0;
  data_p^.data_p := nil;
  data_p^.maxval := 0.0;
  end;
{
********************************************************************************
*
*   Subroutine GELDPLOT_DATA_DEL (DATA_P)
*
*   Delete the plottable data descriptor at DATA_P and release any associated
*   system resources.  DATA_P is returned NIL.
}
procedure geldplot_data_del (          {delete plot data, deallocate resources}
  in out  data_p: data_p_t);           {to data to delete, returned NIL}
  val_param;

var
  mem_p: util_mem_context_p_t;         {to mem context for new descriptor}

begin
  if data_p = nil then return;         {no descriptor, nothing to do ?}

  mem_p := data_p^.mem_p;              {save pointer to mem context for this data}
  util_mem_context_del (mem_p);        {deallocate all the descriptor's memory}

  data_p := nil;                       {return pointer to the data as invalid}
  end;
{
********************************************************************************
*
*   Local subroutine CLASSDAT_NEW (DATA, CLASS_P)
*
*   Create a descriptor for the data of one rate class.  The new descriptor will
*   be added to the list of classes for the plot data DATA.  The new class data
*   will be initialized.  CLASS_P is returned pointing to the new class data.
}
procedure classdat_new (               {create, init, and add to list new class data}
  in out  data: data_t;                {plot data to add new class data descriptor to}
  out     class_p: data_class_p_t);    {returned pointing to the new class data}
  val_param; internal;

var
  sz: sys_int_adr_t;                   {memory size}

begin
{
*   Allocate memory for the new rate class data descriptor.
}
  sz := offset(data_class_t.dat);      {size of structure up to data array}
  sz := sz +                           {add size of the data array}
    (data.ndat * sizeof(data_class_t.dat[1]));

  util_mem_grab (sz, data.mem_p^, false, class_p); {alloc mem}
  util_mem_grab_err_bomb (class_p, sz);
{
*   Initialize some of the fields.
}
  class_p^.id := 0;                    {init to rate class ID not set yet}
  class_p^.ave := 0.0;                 {init average value in data array}
  class_p^.max := 0.0;                 {init maximum value in data array}
{
*   Link the new rate class data to the start of the list.
}
  class_p^.next_p := data.data_p;      {point forward to existing start of list}
  data.data_p := class_p;              {update start of list pointer}
  end;
{
********************************************************************************
*
*   Local subroutine GET_DATA (DATA, CLASS)
*
*   Get the data values for the rate class data CLASS.  The average and maximum
*   values are also set.  CLASS.ID must be previously set to indicate the rate
*   class to get data for.  When CLASS.ID is 0, the total of all rate classes
*   indicated by PLOTCTRL.DATASET.CLASSES is totaled.
}
procedure get_data (                   {get data for rate class}
  in      data: data_t;                {base plot data}
  in out  class: data_class_t);        {rate class descriptor to fill in data of}
  val_param; internal;

var
  classes: geld_classset_t;            {set of rate classes}
  acc: double;                         {accumulator}
  nacc: sys_int_machine_t;             {number of values summed in accumulator}
  ii: sys_int_machine_t;               {scratch integer and loop counter}

begin
  if class.id = 0
    then begin                         {get totals for all enabled rate classes}
      classes := plotctrl.dataset.classes;
      end
    else begin                         {get data for one rate class}
      classes := geld_classset_none (geld_p^); {init set of rate classes to empty}
      geld_classset_add (geld_p^, class.id, classes); {add this one class}
      end
    ;

  geld_avepower (                      {compute averaged data for this class}
    geld_p^,                           {GELD library use state}
    class.dat,                         {array to return the data in}
    data.ndat,                         {number of entries in data array}
    data.slsec,                        {data time each array entry, seconds}
    plotctrl.dataset.tstart,           {start time of data to average}
    plotctrl.dataset.tend,             {end time of data to average}
    classes);                          {set of classes to include}

  acc := 0.0;                          {init sum of all data points}
  nacc := 0;
  for ii := 0 to data.ndat-1 do begin  {scan all values in new data array}
    acc := acc + class.dat[ii];        {accumulate this data value}
    nacc := nacc + 1;
    class.max := max(class.max, class.dat[ii]); {update max value}
    end;                               {back for next data array entry}
  class.ave := acc / nacc;             {make and save averge of all data values}
  end;
{
********************************************************************************
*
*   Subroutine GELDPLOT_DATA_MAKE (DATA_P)
*
*   Compute the plottable data according to the current plot configuration.  A
*   new plottable data descriptor is created, and DATA_P returned pointing to
*   it.  System resources may be allocated to the new descriptor until it is
*   deleted with GELDPLOT_DATA_DEL.
}
procedure geldplot_data_make (         {compute data to plot under current config}
  out     data_p: data_p_t);           {returned pointer to plottable data}
  val_param;

var
  cl: sys_int_machine_t;               {current rate class ID}
  nclasses: sys_int_machine_t;         {number of rate classes being plotted}
  class_p: data_class_p_t;             {to rate class data list entry}
  class_pp: data_class_pp_t;           {to pointer to rate class data}
  best_pp: data_class_pp_t;            {to link pointing to best entry so far}
  best_p: data_class_p_t;              {to list entry with best value so far}
  best: double;                        {best value so far}
  other_p: data_class_p_t;             {other entry to compare curr to}
  other_pp: data_class_pp_t;           {to link pointing to other entry}

begin
  geldplot_data_new (data_p);          {create and initialize new data descriptor}

  case plotctrl.xaxis.cfg of           {how is X axis configured ?}
xaxis_cfg_day_k: begin                 {one day, compute data per minute}
      data_p^.ndat := 24 * 60;         {number of 1-minute time slices in a day}
      data_p^.slsec := 60;             {data slice length, seconds}
      string_vstring (data_p^.labx, 'Hour'(0), -1);
      data_p^.slx := 1.0 / 60.0;       {X axis increment per slice}
      end;
xaxis_cfg_year_k: begin                {one year, compute data per day}
      data_p^.ndat := 365;             {number of 1-day time slices in a year}
      data_p^.slsec := 24 * 60 * 60;   {data slice length, seconds}
      string_vstring (data_p^.labx, 'Day'(0), -1);
      data_p^.slx := 1.0;              {X axis increment per slice}
      end;
otherwise
    geldplot_data_del (data_p);        {delete plot data}
    writeln ('INTERNAL ERROR: X axis config ID of ', ord(plotctrl.xaxis.cfg));
    writeln ('not supported in GELDPLOT_DATA_MAKE.');
    sys_bomb;
    end;
{
*   Loop over all the rate classes and get a data array for each rate class this
*   plot is configured for.
}
  nclasses := 0;                       {init number of rate classes used}
  for cl := 1 to geld_p^.nrateclasses do begin {once for each rate class}
    if not geld_classset_in (geld_p^, cl, plotctrl.dataset.classes) {not this class ?}
      then next;

    nclasses := nclasses + 1;          {update number of rate classes have data for}
    classdat_new (data_p^, class_p);   {create new rate classes data list entry}
    class_p^.id := cl;                 {set ID for this rate class}
    get_data (data_p^, class_p^);      {get the data for this rate class}
    end;                               {back for next rate class}
{
*   If plotting data for more than one rate class, make a rate class list entry
*   for the total of all classes.
}
  if nclasses > 1 then begin           {plotting data for multiple rate classes ?}
    classdat_new (data_p^, class_p);   {create new rate classes data list entry}
    class_p^.id := 0;                  {indicate total of all included rate classes}
    get_data (data_p^, class_p^);      {get summed data for all enabled rate classes}
    end;
{
*   Sort the list entries for each data class by descending average value.
}
  class_pp := addr(data_p^.data_p);    {get pointer to first list entry pointer}
  class_p := data_p^.data_p;           {init to first list entry}

  while class_p <> nil do begin        {back here each new list entry}
    other_p := class_p^.next_p;        {init to first other entry to check}
    if other_p = nil then exit;        {no other entries to sort against ?}
    other_pp := addr(class_p^.next_p); {init pointer to link to other entry}
    best_pp := class_pp;               {init best entry so far to current entry}
    best_p := class_p;
    best := class_p^.ave;
    while other_p <> nil do begin      {scan remaining list entries after current}
      if other_p^.ave > best then begin {this other entry has higher value ?}
        best_pp := other_pp;           {update state for best entry so far}
        best_p := other_p;
        best := other_p^.ave;
        end;
      other_pp := addr(other_p^.next_p); {to next list entry to check against}
      other_p := other_p^.next_p;
      end;                             {back to check against this new list entry}
    {
    *   The BEST state indicates the list entry that is next in the sort order.
    }
    if best_p <> class_p then begin    {best entry is not the current entry ?}
      best_pp^ := best_p^.next_p;      {unlink best entry from list}
      class_pp^ := best_p;             {link best entry into list before curr entry}
      best_p^.next_p := class_p;
      end;

    class_p := class_pp^;              {point to first entry in curr part of list}
    class_pp := addr(class_p^.next_p); {to next list entry}
    class_p := class_p^.next_p;
    end;                               {back sort list from new entry to end}

  end;
