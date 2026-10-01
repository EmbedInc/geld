{   Meter IDs tree and related.
*
*   Meter IDs are in a large but very sparsely used space.  The code in this
*   module implements a tree for keeping track of all meter IDs.  The details of
*   how meter IDs are indexed and found are private to this module.
}
module geld_id;
define geld_id_node_init;
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
