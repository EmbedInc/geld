{   High level library management.
}
module geld_lib;
define geld_lib_new;
define geld_lib_end;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Subroutine GELD_LIB_NEW (MEM, GELD_P)
*
*   Create a new use of the GELD library.  MEM is the parent memory context that
*   a subordinate context will be created under.  All GELD library dynamic
*   memory will be allocated under the new subordinate context.
*
*   GELD_P is returned pointing to the new library use state.
}
procedure geld_lib_new (               {create new use of the GELD library}
  in out  mem: util_mem_context_t;     {parent mem context, will create subordinate}
  out     geld_p: geld_p_t);           {returned new library use state}
  val_param;

var
  mem_p: util_mem_context_p_t;         {to our new private memory context}

begin
  util_mem_context_get (mem, mem_p);   {create our new subordinate memory context}
  util_mem_context_err_bomb (mem_p);   {bomb on didn't get the new context}

  util_mem_grab (                      {alloc mem for new library use state}
    sizeof(geld_p^), mem_p^, false, geld_p);
  util_mem_grab_err_bomb (geld_p, sizeof(geld_p^)); {bomb if didn't get the memory}

  geld_p^.mem_p := mem_p;              {save pointer context for new dyn memory}
  geld_id_node_init (nil, geld_p^.idtree); {initialize root meter IDs tree node}
  geld_p^.nmeters := 0;                {init to no meters defined}
  end;
{
********************************************************************************
*
*   Subroutine GELD_LIB_END (GELD_P)
*
*   End a use of the GELD library.  System resources allocated to that library
*   use will be released.  GELD_P points to the library use state on entry, and
*   is returned NIL since the use state will no longer exist after this call.
}
procedure geld_lib_end (               {end a use of the GELD library, dealloc resources}
  in out  geld_p: geld_p_t);           {to library use state, will be returned NIL}
  val_param;

var
  mem_p: util_mem_context_p_t;         {to mem context for the GELD library use}

begin
  if geld_p = nil then return;         {no library use, nothing to do ?}

  mem_p := geld_p^.mem_p;              {save pointer to mem context for this lib use}
  util_mem_context_del (mem_p);        {dealloc lib dyn mem, delete mem context}

  geld_p := nil;                       {invalidate pointer to the lib use}
  end;
