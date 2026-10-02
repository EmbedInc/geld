{   Meter IDs tree and related.
*
*   Meter IDs are in a large but very sparsely used space.  The code in this
*   module implements a tree for keeping track of all meter IDs.  The details of
*   how meter IDs are indexed and found are private to this module.
}
module geld_id;
define geld_id_node_init;
define geld_id_find;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_ID_NODE_INIT (PARENT_P, IDNODE)
*
*   Initialize a tree node to empty.  PARENT_P points to the parent node.
*   PARENT_P may be NIL, which indicates the top level (root) tree node is being
*   initialized.
}
procedure geld_id_node_init (          {init IDs tree node}
  in      parent_p: geld_idnode_p_t;   {to parent node, NIL for init top level}
  out     idnode: geld_idnode_t);      {the tree node to initialize}
  val_param;

var
  nd: sys_int_machine_t;               {0-N subnode index}

begin
  idnode.up_p := parent_p;             {point back to parent node}
  if idnode.up_p = nil
    then begin                         {no parent, initializing root node}
      idnode.level := 0;
      end
    else begin                         {new node is subnode of a parent}
      idnode.level := idnode.up_p^.level + 1; {levels below root of this node}
      end
    ;

  if idnode.level < geld_idlev_last
    then begin                         {not lowest level tree node}
      for nd := 0 to geld_maxbranch do begin
        idnode.nodep[nd] := nil;       {init this branch to empty}
        end;
      end
    else begin                         {lowest level node, points to meter IDs}
      for nd := 0 to geld_maxbranch do begin
        idnode.meterp[nd] := nil;      {init to this meter ID not used}
        end;
      end
    ;
  end;
{
********************************************************************************
*
*   Local subroutine GELD_IDP_FIND (GELD, ID, METER_PP)
*
*   Follow the meter IDs tree to the pointer for a particular meter ID.
*   METER_PP is returned pointing to the METERP[] array entry in the lowest tree
*   node for the particular meter.  Tree nodes necessary for reaching the final
*   meter data pointer are created as necessary.
}
procedure geld_idp_find (              {find pointer to data for particular meter}
  in out  geld: geld_t;                {library use state}
  in      id: geld_meterid_t;          {ID of meter to find to find pointer to}
  out     meter_pp: geld_meter_pp_t);  {to meter data pointer in lowest tree level}
  val_param; internal;

var
  node_p: geld_idnode_p_t;             {to current tree node}
  next_p: geld_idnode_p_t;             {to next level down in tree}
  level: sys_int_machine_t;            {0-N current tree level}
  sh: sys_int_machine_t;               {number of bits to shift ID this level}
  br: sys_int_machine_t;               {0-N branch number at current level}

begin
  node_p := addr(geld.idtree);         {init to root tree node}
  for level := 0 to geld_idlev_last do begin {down the tree levels}
    sh := (geld_idlev_last - level) * geld_idlev_bits; {ID shift bits this level}
    br := rshft(id, sh) & geld_idlev_mask; {make 0-N branch this level}
    if level = geld_idlev_last then begin {at lowest level ?}
      meter_pp := addr(node_p^.meterp[br]); {return pointer to meter data pointer}
      return;
      end;
    if node_p^.nodep[br] = nil then begin {next level not created yet ?}
      util_mem_grab (sizeof(next_p^), geld.mem_p^, false, next_p); {alloc new level}
      util_mem_grab_err_bomb (next_p, sizeof(next_p^));
      geld_id_node_init (node_p, next_p^); {initialize the new tree node}
      node_p^.nodep[br] := next_p;     {save pointer to the next tree level}
      end;
    node_p := node_p^.nodep[br];       {down to next tree level}
    end;                               {back to process this new tree level}
  end;
{
********************************************************************************
*
*   Subroutine GELD_ID_FIND (GELD, ID, METER_P)
*
*   Find the descriptor for the meter with the indicated ID.  If no descriptor
*   for the meter exists, one is created and initialized to defaults.  METER_P
*   is returned pointing to the meter data, whether found or created.
}
procedure geld_id_find (               {find specific meter, create if not exist}
  in out  geld: geld_t;                {library use state}
  in      id: geld_meterid_t;          {ID of meter to find}
  out     meter_p: geld_meter_p_t);    {returned pointer to data about the meter}
  val_param;

var
  meter_pp: geld_meter_pp_t;           {to meter data pointer}

begin
  geld_idp_find (geld, id, meter_pp);  {get pointer to meter data pointer}
  meter_p := meter_pp^;                {get pointer to the meter data}
  if meter_p <> nil then return;       {data for this meter exists ?}
{
*   The data for this meter does not exist yet.  Create and initialize it.
}
  util_mem_grab (sizeof(meter_p^), geld.mem_p^, false, meter_p); {alloc meter mem}
  util_mem_grab_err_bomb (meter_p, sizeof(meter_p^));
  meter_pp^ := meter_p;                {save pointer to data for this meter}
  geld_meter_init (id, meter_p^);      {initialize the new meter descriptor}
  geld.nmeters := geld.nmeters + 1;    {count one more meter defined}
  end;
