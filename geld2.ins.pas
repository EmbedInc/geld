{   Private include file for the routines implementing the GELD library.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'geld.ins.pas';

type
  geld_meter_pp_t = ^geld_meter_p_t;   {to location of pointer in IDs tree to a meter}

procedure geld_id_node_init (          {initialize IDs tree node}
  in      parent_p: geld_idnode_p_t;   {to parent node, NIL for init top level}
  out     idnode: geld_idnode_t);      {the tree node to initialize}
  val_param; extern;

procedure geld_meter_init (            {initialize meter data descriptor}
  in      id: geld_meterid_t;          {ID of meter initializing state of}
  out     meter: geld_meter_t);        {meter data to initialize}
  val_param; extern;
