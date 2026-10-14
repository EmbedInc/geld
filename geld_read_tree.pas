module geld_read_tree;
define geld_read_tree;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Local subroutine SUBDIR (GELD, PNAM, CLASS, STAT)
*
*   Process a subdirectory of the top level directory.  FNAM is the pathname of
*   the subdirectory, and LNAM its leafname as presented within the top level
*   directory.
}
procedure subdir (                     {process top level file}
  in out  geld: geld_t;                {library use state}
  in      pnam: univ string_var_arg_t; {directory pathname}
  in      class: geld_rateclass_k_t;   {rate class for all files in this subdir}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

var
  conn: file_conn_t;                   {connection to the directory}
  fnam, tnam: string_treename_t;       {scratch file names}
  dent: string_leafname_t;             {directory entry}
  finfo: file_info_t;                  {info about directory entry}
  tk: string_var32_t;                  {scratch token and substring}
  suff: string_var32_t;                {required file name suffix}
  flist: string_list_t;                {list of files to read from this dir}

label
  next_ent, abort, leave;

begin
  fnam.max := size_char(fnam.str);     {init local var strings}
  tnam.max := size_char(tnam.str);
  dent.max := size_char(dent.str);
  tk.max := size_char(tk.str);
  suff.max := size_char(suff.str);

  string_vstring (suff, '.CSV', 4);    {make mandatory file name suffix, upper case}

  string_list_init (flist, geld.mem_p^); {create and init files list}
  flist.deallocable := false;          {won't individually deallocate list entries}
{
*   Make a list of all the directory entries that resolve to ordinary files with
*   qualifying names.  This allows them to be sorted so that they can be
*   processed in sorted order later.  This routine is called recursively with
*   any sub-directories.
}
  file_open_read_dir (pnam, conn, stat); {open the directory}
  if sys_error(stat) then return;

  while true do begin                  {back here each new directory entry}
    file_read_dir (                    {get next top level directory entry}
      conn,                            {connection to the directory}
      [file_iflag_type_k],             {info requested about dir entry}
      dent,                            {returned directory entry}
      finfo,                           {returned into about this entry}
      stat);
    if file_eof(stat) then exit;       {end of top level directory ?}
    if sys_error(stat) then goto abort; {hard error ?}

    string_pathname_join (conn.tnam, dent, fnam); {make full pathname of this entry}
    string_treename (fnam, tnam);      {follow any links and make full treename}

    if finfo.ftype = file_type_link_k then begin {this entry is a link ?}
      file_info (                      {set FINFO to type of final object}
        tnam, [file_iflag_type_k], finfo, stat);
      if sys_error(stat) then goto abort;
      end;

    case finfo.ftype of                {what kind of object is this dir entry ?}
file_type_data_k: begin                {ordinary data file}
        if dent.len < 5 then goto next_ent; {name too short to be X.CSV ?}
        string_substr (dent, dent.len-3, dent.len, tk); {get last 4 name chars}
        string_upcase (tk);            {upper case to make case-insensitive}
        if not string_equal (tk, suff) then goto next_ent; {not a CSV file ?}
        {
        *   This entry is a data file we need to read.  Add it to the list.
        }
        string_list_str_add (flist, dent); {add this dir entry to list}
        end;
file_type_dir_k: begin                 {subdirectory}
        subdir (geld, tnam, class, stat); {process subdirectory recursively}
        if sys_error(stat) then goto abort; {abort on error}
        end;
      end;                             {end of dir entry type cases}
next_ent:                              {done with this dir entry, on to next}
    end;                               {back for next directory entry}
  file_close (conn);                   {close connection to the directory}
{
*   Sort the list of directory entries, then read the files in sorted order.
}
  string_list_sort (                   {sort the list of files to read}
    flist,                             {the list to sort}
    [ string_comp_ncase_k,             {sort case-insensitive}
      string_comp_num_k]);             {sort numbers as whole numeric fields}

  string_list_pos_start (flist);       {go to before first list entry}
  while true do begin                  {back here each new list entry}
    string_list_pos_rel (flist, 1);    {to next list entry}
    if flist.str_p = nil then exit;    {hit end of list ?}
    string_pathname_join (conn.tnam, flist.str_p^, fnam); {make pathname}
    string_treename (fnam, tnam);      {follow any links and make full treename}
    writeln ('Reading "', tnam.str:tnam.len, '"');
    geld_read_intv_class (             {read this data file}
      geld,                            {library use state}
      tnam,                            {file name}
      class,                           {rate class data in file is for}
      stat);
    if sys_error(stat) then goto leave;
    end;                               {back for next list entry}
  goto leave;                          {all done, normal exit}

abort:                                 {connection to directory is open}
  file_close (conn);                   {close connection to the directory}

leave:                                 {common exit point}
  string_list_kill (flist);            {delete files list, dealloc resources}
  end;
{
********************************************************************************
*
*   Subroutine GELD_READ_TREE (GELD, DIR, STAT)
*
*   Read the tree of GELD data files in DIR and update the library use state
*   accordingly.
}
procedure geld_read_tree (             {read tree of GELD data files}
  in out  geld: geld_t;                {library use state}
  in      dir: univ string_var_arg_t;  {name of directory containing data tree}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  tstart: sys_clock_t;                 {starting time}
  fnam, tnam: string_treename_t;       {scratch file names}
  dent: string_leafname_t;             {directory entry}
  conn: file_conn_t;                   {connection to top level directory}
  finfo: file_info_t;                  {info about directory entry}
  class: geld_rateclass_k_t;           {rate class ID}
  dt: double;                          {elapsed seconds}

label
  leave;

begin
  fnam.max := size_char(fnam.str);     {init local var strings}
  tnam.max := size_char(tnam.str);
  dent.max := size_char(dent.str);

  tstart := sys_clock;                 {save starting time}
{
*   Read the meter multipliers file.  All meters not listed in this file will be
*   assumed to have a multiplier of 1.
}
  string_pathname_join (dir, string_v('multiplier.csv'), fnam);
  string_treename (fnam, tnam);        {make full absolute pathname}
  writeln ('Reading "', tnam.str:tnam.len, '".');
  geld_read_mult (geld, tnam, stat);
  if sys_error(stat) then return;
{
*   Read all the meter reading files in the tree.
}
  file_open_read_dir (dir, conn, stat); {open the top level directory}
  if sys_error(stat) then return;

  while true do begin                  {back here each new directory entry}
    file_read_dir (                    {get next top level directory entry}
      conn,                            {connection to the directory}
      [file_iflag_type_k],             {info requested about dir entry}
      dent,                            {returned directory entry}
      finfo,                           {returned into about this entry}
      stat);
    if file_eof(stat) then exit;       {end of top level directory ?}
    if sys_error(stat) then goto leave; {hard error ?}

    class := geld_rateclass_f_code (dent); {try to get rate class from name}
    if class = geld_rateclass_none_k then next; {not a valid name}

    string_pathname_join (conn.tnam, dent, fnam); {make full pathname of this entry}
    string_treename (fnam, tnam);      {follow any links and make full treename}

    if finfo.ftype = file_type_link_k then begin {this entry is a link ?}
      file_info (                      {set FINFO to type of final object}
        tnam, [file_iflag_type_k], finfo, stat);
      if sys_error(stat) then goto leave;
      end;

    case finfo.ftype of                {what kind of object is this dir entry ?}
file_type_data_k: begin                {ordinary data file}
        writeln ('Reading "', tnam.str:tnam.len, '"');
        geld_read_intv_class (         {read the meter data file}
          geld,                        {state for this library use}
          tnam,                        {name of file to read}
          class,                       {rate class data is for}
          stat);
        end;
file_type_dir_k: begin                 {subdirectory}
        subdir (geld, tnam, class, stat); {process subdirectory}
        end;
      end;                             {end of dir entry type cases}
    if sys_error(stat) then goto leave; {abort on error}
    end;                               {back for next directory entry}

leave:                                 {common exit point with top directory open}
  file_close (conn);                   {close connection to top directory}

  dt := sys_clock_to_fp2 (             {make seconds spent reading all the files}
    sys_clock_sub (sys_clock, tstart)
    );
  geld.tread := geld.tread + dt;       {log time spent reading data files}
  end;
