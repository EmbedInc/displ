@echo off
rem
rem   BUILD_LIB
rem
rem   Build the DISPL library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% %libname%_dagl
call src_pas %srcdir% %libname%_edit
call src_pas %srcdir% %libname%_edvect
call src_pas %srcdir% %libname%_file_rd
call src_pas %srcdir% %libname%_file_wr
call src_pas %srcdir% %libname%_draw
call src_pas %srcdir% %libname%_draw_img
call src_pas %srcdir% %libname%_item
call src_pas %srcdir% %libname%_list
call src_pas %srcdir% %libname%_rend

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%
