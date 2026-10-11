/*   Error and other messages related to the GELD library.
/*
msg err1
  lan english -def
    Invalid meter multipliers file header line.  The first three fields
    must be "METER ID", "RATE", and "MULTIPLIER", case-insensitive.
msg err2
  lan english -def
    Bad meter ID on line %p2i of file "%p1s".
msg err3
  lan english -def
    Error reading rate class code on line %p2i of file "%p1s".
msg err4
  lan english -def
    Invalid rate class code on line %p2i of file "%p1s".
msg err5
  lan english -def
    Bad meter multiplier on line %p2i of file "%p1s".
msg err6
  lan english -def
    Attempt to set rate class for a meter with a different rate class
    previously set.  New rate class encountered on line %p2i of file "%p1s".
msg err7
  lan english -def
    Error reading date on line %p2i of file "%p1s".
msg err8
  lan english -def
    Error reading time of day on line %p2i of file "%p1s".
msg err9
  lan english -def
    Bad meter reading on line %p2i of file "%p1s".
msg err10
  lan english -def
    Invalid date "%p1s" on line %p3i of file "%p2s".
msg err11
  lan english -def
    Invalid time of day "%p1s" on line %p3i of file "%p2s".
msg err12
  lan english -def
    Attempt to re-define meter measuring interval.  The interval was
    previously set to %p1f7.1 minutes, now being set to %p2f7.1.  Error
    encountered on line %p4i of file "%p3s".
