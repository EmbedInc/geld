@echo off
rem
rem   BUILD_LIB
rem
rem   Build the GELD library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% %libname%_id
call src_pas %srcdir% %libname%_intv
call src_pas %srcdir% %libname%_lib
call src_pas %srcdir% %libname%_meter
call src_pas %srcdir% %libname%_rateclass
call src_pas %srcdir% %libname%_read_mult

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%
