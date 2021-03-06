@echo off
rem
rem $Id: compile_mingw.bat $
rem

:COMPILE_MINGW

   if not "%HG_ROOT%" == "" goto CHECK

   pushd "%~dp0"
   set HG_ROOT=%CD%
   popd

:CHECK

   if "%1" == "" goto ERROR1
   if not exist %1.prg goto ERROR2

   if "%HG_HRB%"   == "" set HG_HRB=%HG_ROOT%\hb32
   if "%HG_MINGW%" == "" set HG_MINGW=%HG_CCOMP%
   if "%HG_MINGW%" == "" set HG_MINGW=%HG_HRB%\comp\mingw
   if "%HG_CCOMP%" == "" set HG_CCOMP=%HG_MINGW%
   if "%LIB_GUI%"  == "" set LIB_GUI=lib\hb\mingw
   if "%LIB_HRB%"  == "" set LIB_HRB=lib\win\mingw
   if "%BIN_HRB%"  == "" set BIN_HRB=bin
   if "%HG_RC%"    == "" set HG_RC=%HG_ROOT%\resources\oohg_hb32.o

:CLEAN_EXE

   if exist %1.exe del %1.exe
   if exist %1.exe goto ERROR3

:MORE_SETS

   rem *** Third Party Libraries ***
   rem set THR_LIB=-lsocket -liphlpapi -lmysqldll -ldll -lhbmysql -lrddleto -lrddado -lhbusrrdd

   rem *** Force static linking of this libs ***
   set STATIC_LIBS=-static -static-libgcc

   rem *** Set PATH ***
   set TPATH=%PATH%
   set PATH=%HG_MINGW%\bin;%HG_HRB%\%BIN_HRB%

:PARSE_SWITCHES

   set TFILE=%1
   set COMP_TYPE=STD
   set EXTRA=
   set RC_FILE=TRUE
   set NO_RUN=FALSE
   set PRG_LOG=
   set C_LOG=

:LOOP_START

   if "%2" == ""    goto LOOP_END
   if "%2" == "/d"  goto COMP_DEBUG
   if "%2" == "-d"  goto COMP_DEBUG
   if "%2" == "/D"  goto COMP_DEBUG
   if "%2" == "-D"  goto COMP_DEBUG
   if "%2" == "/c"  goto COMP_CONSOLE
   if "%2" == "-c"  goto COMP_CONSOLE
   if "%2" == "/C"  goto COMP_CONSOLE
   if "%2" == "-C"  goto COMP_CONSOLE
   if "%2" == "/i"  goto NORC
   if "%2" == "-i"  goto NORC
   if "%2" == "/I"  goto NORC
   if "%2" == "-I"  goto NORC
   if "%2" == "-p"  goto PPO
   if "%2" == "/p"  goto PPO
   if "%2" == "-P"  goto PPO
   if "%2" == "/P"  goto PPO
   if "%2" == "-w3" goto W3
   if "%2" == "/w3" goto W3
   if "%2" == "-W3" goto W3
   if "%2" == "/W3" goto W3
   if "%2" == "-nr" goto NORUN
   if "%2" == "-Nr" goto NORUN
   if "%2" == "-nR" goto NORUN
   if "%2" == "-NR" goto NORUN
   if "%2" == "/nr" goto NORUN
   if "%2" == "/Nr" goto NORUN
   if "%2" == "/nR" goto NORUN
   if "%2" == "/NR" goto NORUN
   if "%2" == "/l"  goto USELOG
   if "%2" == "-l"  goto USELOG
   if "%2" == "/L"  goto USELOG
   if "%2" == "-L"  goto USELOG
   set EXTRA=%EXTRA% %2
   shift
   goto LOOP_START

:COMP_DEBUG

   set COMP_TYPE=DEBUG
   shift
   goto LOOP_START

:COMP_CONSOLE

   set COMP_TYPE=CONSOLE
   shift
   goto LOOP_START

:NORC

   set RC_FILE=FALSE
   shift
   goto LOOP_START

:PPO

   set EXTRA=%EXTRA% -p
   shift
   goto LOOP_START

:W3

   set EXTRA=%EXTRA% -w3
   shift
   goto LOOP_START

:NORUN

   set NO_RUN=TRUE
   shift
   goto LOOP_START

:USELOG

   set PRG_LOG=-q0 1^>error.lst 2^>^&1
   set C_LOG=1^>error.lst 2^>^&1
   shift
   goto LOOP_START

:LOOP_END

   rem *** Check for Console Switch ***
   if "%COMP_TYPE%" == "CONSOLE" goto CONSOLE_COMP

   rem *** Check for Debug Switch ***
   if "%COMP_TYPE%" == "DEBUG" goto DEBUG_COMP

   goto STD_COMP

:CONSOLE_COMP

   rem *** Compile with Harbour and Check for Errors ***
   %HG_HRB%\%BIN_HRB%\harbour %TFILE%.prg -n1 %EXTRA% -i%HG_HRB%\include;%HG_ROOT%\include;. %PRG_LOG%
   if errorlevel 1 goto CLEANUP1

   rem *** Compile .c Files and Check for Errors ***
   gcc -I. -I%HG_HRB%\include -I%HG_ROOT%\include -Wall -c %TFILE%.c -o%TFILE%.o
   rem *** To Use -mno-cygwin Switch ***
   rem gcc -I. -I%HG_HRB%\include -I%HG_ROOT%\include -mno-cygwin -Wall -c %TFILE%.c -o%TFILE%.o
   if errorlevel 1 goto CLEANUP2

   rem *** Check for Exclude OOHG Resource Switch ***
   if not "%RC_FILE%" == "TRUE" GOTO CONSOLE_COMP_WITHOUT_RC

   rem *** Process Resource File and OOHG Resource File ***
   echo #define oohgpath %HG_ROOT%\RESOURCES > _oohg_resconfig.h
   if exist %TFILE%.rc copy /b %HG_ROOT%\resources\ooHG.rc+%TFILE%.rc _temp.rc > nul
   if exist %TFILE%.rc windres -i _temp.rc -o _temp.o
   if errorlevel 1 goto CLEANUP3

   rem *** Link ***
   if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o %HG_RC% -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem *** To Use -mno-cygwin Switch ***
   rem if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o %HG_RC% -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%

   goto CLEANUP

:CONSOLE_COMP_WITHOUT_RC

   rem *** Process Resource File Without OOHG Resource ***
   if exist %TFILE%.rc copy /b %TFILE%.rc _temp.rc > nul
   if exist %TFILE%.rc windres -i _temp.rc -o _temp.o
   if errorlevel 1 goto CLEANUP3

   rem *** Link ***
   if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o         -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem *** To Use -mno-cygwin Switch ***
   rem if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o         -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%

   goto CLEANUP

:DEBUG_COMP

   rem *** Compile with Harbour and Check for Errors ***
   echo OPTIONS NORUNATSTARTUP > init.cld
   %HG_HRB%\%BIN_HRB%\harbour %TFILE%.prg -n1 %EXTRA% -b -i%HG_HRB%\include;%HG_ROOT%\include;. %PRG_LOG%
   if errorlevel 1 goto CLEANUP1

   rem *** Compile .c Files and Check for Errors ***
   gcc -I. -I%HG_HRB%\include -I%HG_ROOT%\include -Wall -c %TFILE%.c -o%TFILE%.o
   rem *** To Use -mno-cygwin Switch ***
   rem gcc -I. -I%HG_HRB%\include -I%HG_ROOT%\include -mno-cygwin -Wall -c %TFILE%.c -o%TFILE%.o
   if errorlevel 1 goto CLEANUP2

   rem *** Check for Exclude OOHG Resource Switch ***
   if not "%RC_FILE%" == "TRUE" GOTO DEBUG_COMP_WITHOUT_RC

   rem *** Process Resource File and OOHG Resource File ***
   echo #define oohgpath %HG_ROOT%\RESOURCES > _oohg_resconfig.h
   if exist %TFILE%.rc copy /b %HG_ROOT%\resources\ooHG.rc+%TFILE%.rc _temp.rc > nul
   if exist %TFILE%.rc windres -i _temp.rc -o _temp.o
   if errorlevel 1 goto CLEANUP3

   rem *** Link ***
   if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lhbdebug -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o %HG_RC% -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lhbdebug -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem *** To Use -mno-cygwin Switch ***
   rem if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lhbdebug -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o %HG_RC% -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lhbdebug -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%

   goto CLEANUP

:DEBUG_COMP_WITHOUT_RC

   rem *** Process Resource File Without OOHG Resource ***
   if exist %TFILE%.rc copy /b %TFILE%.rc _temp.rc > nul
   if exist %TFILE%.rc windres -i _temp.rc -o _temp.o
   if errorlevel 1 goto CLEANUP3

   rem *** Link ***
   if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lhbdebug -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o         -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lhbdebug -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem *** To Use -mno-cygwin Switch ***
   rem if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lhbdebug -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o %       -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lhbdebug -lgtgui -lgtwin -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%

   goto CLEANUP

:STD_COMP

   rem *** Compile with Harbour and Check for Errors ***
   %HG_HRB%\%BIN_HRB%\harbour %TFILE%.prg -n1 %EXTRA% -i%HG_HRB%\include;%HG_ROOT%\include;. %PRG_LOG%
   if errorlevel 1 goto CLEANUP1

   rem *** Compile .c Files and Check for Errors ***
   gcc -I. -I%HG_HRB%\include -I%HG_ROOT%\include -Wall -c %TFILE%.c -o%TFILE%.o
   rem *** Use -mno-cygwin Switch ***
   rem gcc -I. -I%HG_HRB%\include -I%HG_ROOT%\include -mno-cygwin -Wall -c %TFILE%.c -o%TFILE%.o

   rem *** Check for Exclude OOHG Resource Switch ***
   if not "%RC_FILE%" == "TRUE" GOTO STD_COMP_WITHOUT_RC

   rem *** Process Resource File ***
   echo #define oohgpath %HG_ROOT%\RESOURCES > _oohg_resconfig.h
   if exist %TFILE%.rc copy /b %HG_ROOT%\resources\ooHG.rc+%TFILE%.rc _temp.rc > nul
   if exist %TFILE%.rc windres -i _temp.rc -o _temp.o
   if errorlevel 1 goto CLEANUP3

   rem *** Link ***
   if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -mwindows -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o %HG_RC% -mwindows -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem *** Use -mno-cygwin Switch ***
   rem if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -mwindows -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o %HG_RC% -mwindows -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%

   goto CLEANUP

:STD_COMP_WITHOUT_RC

   rem *** Process Resource File Without OOHG Resource ***
   if exist %TFILE%.rc copy /b %TFILE%.rc _temp.rc > nul
   if exist %TFILE%.rc windres -i _temp.rc -o _temp.o
   if errorlevel 1 goto CLEANUP3

   rem *** Link ***
   if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -mwindows -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o         -mwindows -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem *** Use -mno-cygwin Switch ***
   rem if     exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o _temp.o -mwindows -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%
   rem if not exist %TFILE%.rc gcc -Wall -o%TFILE%.exe %TFILE%.o         -mwindows -L. -L%HG_MINGW%\lib -L%HG_HRB%\%LIB_HRB% -L%HG_ROOT%\%LIB_GUI% -mno-cygwin -Wl,--start-group -looHG -lhbprinter -lminiprint -lbostaurus -lgtgui -lhbsix -lhbvm -lhbrdd -lhbmacro -lhbmemio -lhbpp -lhbrtl -lhbzebra -lhbhpdf -llibhpdf -lpng -lhbziparc -lhblang -lhbcommon -lhbnulrdd -lrddntx -lrddcdx -lrddfpt -lhbct -lhbmisc -lxhb -lhbodbc -lrddsql -lsddodbc -lodbc32 %THR_LIB% -lhbwin -lhbcpage -lhbmzip -lminizip -lhbzlib -lhbtip -lhbpcre -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lws2_32 -lmsimg32 -Wl,--end-group %STATIC_LIBS% %C_LOG%

   goto CLEANUP

:ERROR1

   echo COMPILE ERROR: No file specified !!!
   goto END

:ERROR2

   echo File %1.prg not found !!!
   goto END

:ERROR3

   echo COMPILE ERROR: Is %1.exe running ?
   goto END

:CLEANUP

   rem *** Check for Errors in Linking ***
   if errorlevel 1 goto CLEANUP4

   rem *** Cleanup ***
   if exist _temp.o del _temp.o
   if exist _temp.rc del _temp.rc
   if exist _oohg_resconfig.h del _oohg_resconfig.h
   del %TFILE%.o
   del %TFILE%.c
   set THR_LIB=
   set COMP_TYPE=
   set EXTRA=
   set PATH=%TPATH%
   set TPATH=
   set RC_FILE=
   set PRG_LOG=
   set C_LOG=
   set STATIC_LIBS=

   rem *** Execute ***
   if "%NO_RUN%" == "FALSE" %TFILE%
   set TFILE=
   set NO_RUN=
   goto END

:CLEANUP4

   rem *** Cleanup ***
   if exist _temp.o del _temp.o

:CLEANUP3

   rem *** Cleanup ***
   if exist _temp.rc del _temp.rc
   del _oohg_resconfig.h
   del %TFILE%.o

:CLEANUP2

   rem *** Cleanup ***
   del %TFILE%.c

:CLEANUP1

   rem *** Cleanup ***
   set THR_LIB=
   set COMP_TYPE=
   set EXTRA=
   set PATH=%TPATH%
   set TPATH=
   set NO_RUN=
   set RC_FILE=
   set PRG_LOG=
   set C_LOG=

:END

   rem *** Cleanup ***
   if exist init.cld del init.cld
