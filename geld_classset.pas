{   Routines to manipulate sets of rate classes.
}
module geld_classset;
define geld_classset_none;
define geld_classset_empty;
define geld_classset_all;
define geld_classset_add;
define geld_classset_sub;
define geld_classset_in;
%include 'geld2.ins.pas';
{
********************************************************************************
*
*   Function GELD_CLASSSET_NONE (GELD)
*
*   Return the empty set of rate classes.
}
function geld_classset_none (          {return the empty set of rate classes}
  in      geld: geld_t)                {library use state}
  :geld_classset_t;
  val_param;

begin
  geld_classset_none := 0;
  end;
{
********************************************************************************
*
*   Function GELD_CLASSSET_EMPTY (GELD, CLASSSET)
*
*   Returns TRUE when the set of rate classes CLASSSET is empty and FALSE
*   otherwise.
}
function geld_classset_empty (         {determine whether a set of rate classes is empty}
  in      geld: geld_t;                {library use state}
  in      classset: geld_classset_t)   {the set of rate classes to check}
  :boolean;                            {the set is empty}
  val_param;

begin
  geld_classset_empty := classset = 0;
  end;
{
********************************************************************************
*
*   Function GELD_CLASSSET_ALL (GELD)
*
*   Return the set of all defined rate classes.
}
function geld_classset_all (           {return the set of all rate classes}
  in      geld: geld_t)                {library use state}
  :geld_classset_t;
  val_param;

begin
  geld_classset_all := ~lshft(~0, geld.nrateclasses);
  end;
{
********************************************************************************
*
*   Subroutine GELD_CLASSSET_ADD (GELD, CLASS, CLASSSET)
*
*   Ensure that the rate class CLASS is a member of the set of rate classes
*   CLASSSET.  CLASS is added to CLASSSET if it it not already a member.
*   Nothing is done when CLASS is not a valid rate class ID.
}
procedure geld_classset_add (          {add a rate class to set of rate classes}
  in      geld: geld_t;                {library use state}
  in      class: sys_int_machine_t;    {the rate class to add to the set}
  in out  classset: geld_classset_t);  {set to add the rate class to}
  val_param;

begin
  if (class < 1) or (class > geld.nrateclasses) then return; {invalid class ?}
  classset := classset ! lshft(1, class - 1); {set bit to indicate this class}
  end;
{
********************************************************************************
*
*   Subroutine GELD_CLASSSET_SUB (GELD, CLASS, CLASSSET)
*
*   Ensure that the rate class CLASS is not a member of the set of rate classes
*   CLASSSET.  CLASS is removed from CLASSSET if it is a member.  Nothing is
*   done when CLASS is not a valid rate class ID.
}
procedure geld_classset_sub (          {remove a rate class from set of rate classes}
  in      geld: geld_t;                {library use state}
  in      class: sys_int_machine_t;    {the rate class to remove from the set}
  in out  classset: geld_classset_t);  {set to remove the rate class from}
  val_param;

begin
  if (class < 1) or (class > geld.nrateclasses) then return; {invalid class ?}
  classset := classset & ~lshft(1, class - 1); {clear bit to indicate this class}
  end;
{
********************************************************************************
*
*   Subroutine GELD_CLASSSET_IN (GELD, CLASS, CLASSSET)
*
*   Returns TRUE iff the rate class CLASS is a member of the set of rate classes
*   CLASSSET.  The function always returns FALSE when CLASS is not a valid rate
*   class ID.
}
function geld_classset_in (            {determine if a rate class is in a set}
  in      geld: geld_t;                {library use state}
  in      class: sys_int_machine_t;    {rate class ID}
  in      classset: geld_classset_t)   {set of rate classes}
  :boolean;                            {CLASS is in the set}
  val_param;

begin
  geld_classset_in := false;           {init to CLASS is not in the set}
  if (class < 1) or (class > geld.nrateclasses) then return; {invalid class ?}

  geld_classset_in := (classset & lshft(1, class - 1)) <> 0;
  end;
