{   Private include file for the routines implementing the GELD library.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'geld.ins.pas';

procedure geld_id_node_init (          {init IDs tree node}
  in      parent_p: geld_idnode_p_t;   {to parent node, NIL for init top level}
  out     idnode: geld_idnode_t);      {the tree node to initialize}
  val_param; extern;
