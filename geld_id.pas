{   Meter IDs tree and related.
*
*   Meter IDs are in a large but very sparsely used space.  The code in this
*   module implements a tree for keeping track of all meter IDs.  The details of
*   how meter IDs are indexed and found are private to this module.
}
module geld_id;
define geld_id_node_init;
define geld_id_get;
define geld_id_find;
define geld_id_pos_start;
define geld_id_pos_id;
define geld_id_next;
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
  idnode.pbr := 0;                     {init to first branch within parent}
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
*   Local subroutine GELD_IDP_FIND (GELD, ID, MAKE, NODE_P, BR)
*
*   Follow the meter IDs tree to a particular meter.  NODE_P is returned
*   pointing to the lowest existing tree node for the ID, and BR the 0-N branch
*   within that node.
*
*   When MAKE is TRUE, tree nodes are created for the indicated ID if they do
*   not exist.  In that case, NODE_P is always returned pointing to lowest level
*   tree node, which points directly to meter descriptors.
}
procedure geld_idp_find (              {find pointer to data for particular meter}
  in out  geld: geld_t;                {library use state}
  in      id: geld_meterid_t;          {ID of meter to find to find pointer to}
  in      make: boolean;               {create tree nodes as needed}
  out     node_p: geld_idnode_p_t;     {lowest existing tree node for the ID}
  out     br: sys_int_machine_t);      {0-N branch within node for the ID}
  val_param; internal;

var
  next_p: geld_idnode_p_t;             {to next level down in tree}
  level: sys_int_machine_t;            {0-N current tree level}
  sh: sys_int_machine_t;               {number of bits to shift ID this level}

begin
  node_p := addr(geld.idtree);         {init to root tree node}
  for level := 0 to geld_idlev_last do begin {down the tree levels}
    sh := (geld_idlev_last - level) * geld_idlev_bits; {ID shift bits this level}
    br := rshft(id, sh) & geld_idlev_mask; {make 0-N branch this level}
    if level = geld_idlev_last then return; {at lowest level ?}

    if node_p^.nodep[br] = nil then begin {next level not created yet ?}
      if not make then return;         {don't create new tree nodes ?}
      util_mem_grab (sizeof(next_p^), geld.mem_p^, false, next_p); {alloc new level}
      util_mem_grab_err_bomb (next_p, sizeof(next_p^));
      geld_id_node_init (node_p, next_p^); {initialize the new tree node}
      node_p^.nodep[br] := next_p;     {save pointer to the next tree level}
      next_p^.pbr := br;               {save 0-N branch within parent node}
      end;

    node_p := node_p^.nodep[br];       {down to next tree level}
    end;                               {back to process this new tree level}
  end;
{
********************************************************************************
*
*   Subroutine GELD_ID_GET (GELD, ID, METER_P)
*
*   Get the descriptor for the meter with the indicated ID.  If no descriptor
*   for the meter exists, one is created and initialized to defaults.  METER_P
*   is returned pointing to the meter data, whether found or created.
}
procedure geld_id_get (                {find specific meter, create if not exist}
  in out  geld: geld_t;                {library use state}
  in      id: geld_meterid_t;          {ID of meter to find}
  out     meter_p: geld_meter_p_t);    {returned pointer to data about the meter}
  val_param;

var
  node_p: geld_idnode_p_t;             {to lowest level tree node}
  br: sys_int_machine_t;               {0-N branch within tree node}

begin
  geld_idp_find (geld, id, true, node_p, br); {find lowest level entry for ID}
  meter_p := node_p^.meterp[br];       {get pointer to the meter data}
  if meter_p <> nil then return;       {data for this meter exists ?}
{
*   The data for this meter does not exist yet.  Create and initialize it.
}
  util_mem_grab (sizeof(meter_p^), geld.mem_p^, false, meter_p); {alloc meter mem}
  util_mem_grab_err_bomb (meter_p, sizeof(meter_p^));
  geld_meter_init (id, meter_p^);      {initialize the new meter descriptor}

  node_p^.meterp[br] := meter_p;       {save pointer to data for this meter}
  geld.nmeters := geld.nmeters + 1;    {count one more meter defined}
  end;
{
********************************************************************************
*
*   Subroutine GELD_ID_FIND (GELD, ID, METER_P)
*
*   Look for the meter with the indicated ID.  If no such meter is found, then
*   METER_P is returned NIL.  Otherwise, METER_P is returned pointing to the
*   data for the selected meter.
}
procedure geld_id_find (               {find specific meter}
  in out  geld: geld_t;                {library use state}
  in      id: geld_meterid_t;          {ID of meter to find}
  out     meter_p: geld_meter_p_t);    {to meter data, NIL if no such meter}
  val_param;

var
  node_p: geld_idnode_p_t;             {to lowest level tree node}
  br: sys_int_machine_t;               {0-N branch within tree node}

begin
  meter_p := nil;                      {init to meter not found}
  geld_idp_find (geld, id, false, node_p, br); {find lowest tree node for ID}

  if node_p^.level < geld_idlev_last then return; {final tree node doesn't exist ?}

  meter_p := node_p^.meterp[br];       {pass back pnt to meter, may be NIL}
  end;
{
********************************************************************************
*
*   Subroutine GELD_ID_POS_START (GELD, POS)
*
*   Initialize the IDs list position POS to before the start of the list.
}
procedure geld_id_pos_start (          {init IDs position to start of list}
  in out  geld: geld_t;                {library use state}
  out     pos: geld_idpos_t);          {returned initialized position in IDs list}
  val_param;

begin
  pos.node_p := addr(geld.idtree);
  pos.br := 0;
  end;
{
********************************************************************************
*
*   Subroutine GELD_ID_POS_ID (GELD, ID, METER_P, POS)
*
*   Find the first meter at or after the indicated ID.  METER_P is returned
*   pointing to the meter, and POS the list position.  POS can be used to find
*   next sequential meters.
*
*   When there are no list entries of ID or greater, METER_P is returned NIL and
*   POS is set to after the end of the list
}
procedure geld_id_pos_id (             {init IDs position to specific ID}
  in out  geld: geld_t;                {library use state}
  in      id: geld_meterid_t;          {pos will be first meter at or after this ID}
  out     meter_p: geld_meter_p_t;     {meter at the new position, NIL at end of list}
  out     pos: geld_idpos_t);          {returned initialized position in IDs list}
  val_param;

begin
  geld_idp_find (geld, id, false, pos.node_p, pos.br); {get lowest tree pos for ID}

  if                                   {position is at an existing meter ?}
      (pos.node_p^.level >= geld_idlev_last) and {at a terminal tree node ?}
      (pos.node_p^.meterp[pos.br] <> nil) {valid meter data pointer ?}
      then begin
    meter_p := pos.node_p^.meterp[pos.br]; {pass back pointer to the meter}
    return;
    end;

  geld_id_next (geld, pos, meter_p);   {find next existing meter from here}
  end;
{
********************************************************************************
*
*   Subroutine GELD_ID_NEXT (GELD, POS, METER_P)
*
*   Advance to the next meter in the list from the list position POS.  POS will
*   be updated to the new position, and METER_P returned pointing to the meter
*   at the new position.
*
*   On end of list, METER_P is returned NIL and POS set to after the list.
*   Subsequent attempts to go to the next meter will continue to return no meter
*   and a position after the end of the list.
}
procedure geld_id_next (               {to next ID in list}
  in out  geld: geld_t;                {library use state}
  in out  pos: geld_idpos_t;           {position with IDs list, will be updated}
  out     meter_p: geld_meter_p_t);    {to meter with next higher ID, NIL at list end}
  val_param;

label
  next_branch, curr_branch;

begin
  if pos.node_p = nil then begin       {already past end of list ?}
    meter_p := nil;
    return;
    end;

next_branch:                           {scan forward from next branch this node}
  pos.br := pos.br + 1;                {to next branch in this node}

curr_branch:                           {forward at curr branch this node}
  if pos.br > geld_maxbranch then begin {exhausted current node ?}
    pos.br := pos.node_p^.pbr;         {up to branch in parent level}
    pos.node_p := pos.node_p^.up_p;
    if pos.node_p = nil then begin     {exhausted top tree node ?}
      meter_p := nil;                  {indicate no next meter}
      return;
      end;
    goto next_branch;                  {start at next branch in this parent node}
    end;

  if pos.node_p^.level >= geld_idlev_last then begin {in a terminal node ?}
    if pos.node_p^.meterp[pos.br] <> nil then begin {there is a meter here ?}
      meter_p := pos.node_p^.meterp[pos.br]; {pass back pointer to meter}
      return;
      end;
    goto next_branch;                  {back to try next branch in this node}
    end;
  {
  *   The current node is not a terminal node.
  }
  if pos.node_p^.nodep[pos.br] <> nil then begin {sub-node exists here ?}
    pos.node_p := pos.node_p^.nodep[pos.br]; {down into sub-node}
    pos.br := 0;                       {start at first branch in the new node}
    goto curr_branch;
    end;

  goto next_branch;                    {back to try next branch in curr node}
  end;
