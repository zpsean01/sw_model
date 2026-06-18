@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: build.bat — Build firmware sample using llvm-mingw toolchain
:: Toolchain : D:\llvm-mingw\bin\armv7-w64-mingw32-clang
:: Target    : ARM Cortex-M33 (ARMv8-M)
:: Output    : fw_samples\build\firmware_tfm.elf (.map .bin .hex)
:: Generates : build\compile_commands.json for pipeline Stage 1
:: ============================================================

set "TOOLCHAIN=D:\llvm-mingw\bin"
set "BUILD_DIR=%~dp0build"
set "SRC_DIR=%~dp0"
set "LINKER=%~dp0linker.ld"

set "CC=%TOOLCHAIN%\armv7-w64-mingw32-clang.exe"
set "OBJCOPY=%TOOLCHAIN%\armv7-w64-mingw32-objcopy.exe"
set "SIZE=%TOOLCHAIN%\armv7-w64-mingw32-size.exe"

set "TARGET=firmware_tfm"

:: Compiler flags
set "CFLAGS=-mcpu=cortex-m33 -mthumb -mfloat-abi=soft -mcmse"
set "CFLAGS=%CFLAGS% -Wall -Werror -Wextra -Wno-unused-parameter -Wno-unused-function -Wno-unused-variable"
set "CFLAGS=%CFLAGS% -O1 -g3 -ffunction-sections -fdata-sections"
set "CFLAGS=%CFLAGS% -I%SRC_DIR%lib -I%SRC_DIR%src"
set "CFLAGS=%CFLAGS% -std=c99"
set "CFLAGS=%CFLAGS% -D__CORTEX_M33 -DARM_MATH_CM33"

:: Linker flags
set "LDFLAGS=-T %LINKER% -Wl,-Map=%BUILD_DIR%\%TARGET%.map -Wl,--gc-sections"
set "LDFLAGS=%LDFLAGS% -specs=nano.specs -specs=nosys.specs"

echo =======================================================
echo  Building ARM TF-M Simplified Firmware
echo  Toolchain: %TOOLCHAIN%
echo  Target:    %TARGET%
echo  Output:    %BUILD_DIR%
echo =======================================================

:: Create build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

:: Step 1: Compile all source files from lib\ and src\
set "OBJ_FILES="
set "CC_JSON=%BUILD_DIR%\compile_commands.json"
echo [ > "%CC_JSON%"
set "first=1"

:: Helper: compile a single C file
for %%d in (lib src) do (
    for %%f in (%SRC_DIR%%%d\*.c) do (
        set "BASENAME=%%~nf"
        set "OBJ=%BUILD_DIR%\!BASENAME!.o"

        if !first! equ 1 (
            set "first=0"
        ) else (
            echo , >> "%CC_JSON%"
        )

        set "CMD=%CC% %CFLAGS% -c "%%f" -o "!OBJ!""

        :: Write compile_commands.json entry
        echo   { >> "%CC_JSON%"
        echo     "directory": "%SRC_DIR:\=\\%", >> "%CC_JSON%"
        echo     "file": "%%f", >> "%CC_JSON%"
        echo     "command": "!CMD!" >> "%CC_JSON%"
        echo   } >> "%CC_JSON%"

        echo  Compiling %%f ...
        !CMD! || (
            echo ERROR: Compilation failed for %%f
            exit /b 1
        )

        if not defined OBJ_FILES (
            set "OBJ_FILES=!OBJ!"
        ) else (
            set "OBJ_FILES=!OBJ_FILES! !OBJ!"
        )
    )
)

echo ] >> "%CC_JSON%"

:: Step 2: Link
echo.
echo  Linking ...
%CC% %OBJ_FILES% %LDFLAGS% -o "%BUILD_DIR%\%TARGET%.elf" || (
    echo ERROR: Link failed
    exit /b 1
)

:: Step 3: Post-process
%OBJCOPY% -O binary "%BUILD_DIR%\%TARGET%.elf" "%BUILD_DIR%\%TARGET%.bin"
%OBJCOPY% -O ihex   "%BUILD_DIR%\%TARGET%.elf" "%BUILD_DIR%\%TARGET%.hex"

:: Step 4: Show size
echo.
%SIZE% "%BUILD_DIR%\%TARGET%.elf"

echo =======================================================
echo  Build complete!
echo    ELF: %BUILD_DIR%\%TARGET%.elf
echo    MAP: %BUILD_DIR%\%TARGET%.map
echo    BIN: %BUILD_DIR%\%TARGET%.bin
echo    HEX: %BUILD_DIR%\%TARGET%.hex
echo    CC : %BUILD_DIR%\compile_commands.json
echo =======================================================

endlocal