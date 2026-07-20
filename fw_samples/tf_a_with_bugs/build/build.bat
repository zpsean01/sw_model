@echo off
set CLANG=D:\llvm-mingw\bin\clang.exe
set LLDDIR=D:\llvm-mingw\bin
set SRCDIR=D:\programming\sw_model\fw_samples\tf_a_with_bugs

echo Compiling gicv3_main.c...
"%CLANG%" -c -w -nostdinc -I "%SRCDIR%\include" -I "D:\llvm-mingw\lib\clang\22\include" -target aarch64-none-elf -D__aarch64__ -DGIC_EXT_INTID=0 -DGIC_ENABLE_V4_EXTN=0 -DHW_ASSISTED_COHERENCY=1 -D__ASSEMBLER__=0 -o "%SRCDIR%\build\gicv3_main.o" "%SRCDIR%\drivers\arm\gic\v3\gicv3_main.c"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo Compiling stubs.c...
"%CLANG%" -c -w -nostdinc -I "%SRCDIR%\include" -I "D:\llvm-mingw\lib\clang\22\include" -target aarch64-none-elf -D__aarch64__ -DGIC_EXT_INTID=0 -DGIC_ENABLE_V4_EXTN=0 -DHW_ASSISTED_COHERENCY=1 -D__ASSEMBLER__=0 -o "%SRCDIR%\build\stubs.o" "%SRCDIR%\build\stubs.c"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo Linking gic_harness.elf...
"%LLDDIR%\ld.lld" -o "%SRCDIR%\build\gic_harness.elf" "%SRCDIR%\build\gicv3_main.o" "%SRCDIR%\build\stubs.o" -e _start -nostdlib -static
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo Build successful!
