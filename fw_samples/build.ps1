# build.ps1 — Build firmware sample using llvm-mingw toolchain (PowerShell)
# Toolchain : clang.exe --target=thumbv8m.main-none-eabi
# Target    : ARM Cortex-M33 (ARMv8-M) bare-metal
# Output    : build\bin\firmware_tfm.elf (.map .bin .hex)
# Objects   : build\objects\{lib,src}\*.o  (mirrors source tree)

$TOOLCHAIN = "D:\llvm-mingw\bin"
$BUILD_DIR = Join-Path $PSScriptRoot "build"
$OBJ_DIR   = Join-Path $BUILD_DIR "objects"
$BIN_DIR   = Join-Path $BUILD_DIR "bin"
$SRC_DIR   = $PSScriptRoot
$LINKER    = Join-Path $PSScriptRoot "linker.ld"
$TARGET    = "firmware_tfm"

$CC     = "$TOOLCHAIN\clang.exe"
$OBJCOPY = "$TOOLCHAIN\llvm-objcopy.exe"
$SIZE   = "$TOOLCHAIN\llvm-size.exe"

$TARGET_TRIPLE = "thumbv8m.main-none-eabi"

$CFLAGS = @(
    "--target=$TARGET_TRIPLE"
    "-mcpu=cortex-m33"
    "-mthumb"
    "-mfloat-abi=soft"
    "-mcmse"
    "-Wall"
    "-Werror"
    "-Wextra"
    "-Wno-unused-parameter"
    "-Wno-unused-function"
    "-Wno-unused-variable"
    "-O1"
    "-g3"
    "-ffunction-sections"
    "-fdata-sections"
    "-I$SRC_DIR\lib"
    "-I$SRC_DIR\src"
    "-std=c99"
    "-D__CORTEX_M33"
    "-DARM_MATH_CM33"
    "-ffreestanding"
    "-nostdlib"
)

$LDFLAGS = @(
    "-T", "$LINKER"
    "-Wl,-Map=$BIN_DIR\$TARGET.map"
    "-Wl,--gc-sections"
    "-fuse-ld=lld"
    "--target=$TARGET_TRIPLE"
    "-nostdlib"
    "-nostartfiles"
)

Write-Host "======================================================="
Write-Host " Building ARM TF-M Simplified Firmware"
Write-Host " Toolchain: $CC --target=$TARGET_TRIPLE"
Write-Host " Target:    $TARGET"
Write-Host " Output:    $BIN_DIR"
Write-Host " Objects:   $OBJ_DIR\{lib,src}"
Write-Host "======================================================="

# Create build subdirectories
foreach ($d in @($OBJ_DIR, $BIN_DIR, (Join-Path $OBJ_DIR "lib"), (Join-Path $OBJ_DIR "src"))) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# Step 1: Compile all source files
$OBJ_FILES = @()
$CC_JSON = Join-Path $BUILD_DIR "compile_commands.json"
$entries = @()

foreach ($dir in @("lib", "src")) {
    $srcPath = Join-Path $SRC_DIR $dir
    $objSubDir = Join-Path $OBJ_DIR $dir
    Get-ChildItem "$srcPath\*.c" | ForEach-Object {
        $srcFile = $_.FullName
        $basename = $_.BaseName
        $objFile = Join-Path $objSubDir "$basename.o"

        $cmdArgs = $CFLAGS + @("-c", $srcFile, "-o", $objFile)
        $cmdLine = "$CC $($cmdArgs -join ' ')"

        Write-Host "  Compiling $srcFile ..."
        & $CC $cmdArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Error "ERROR: Compilation failed for $srcFile"
            exit 1
        }

        $entries += @{
            directory = $SRC_DIR
            file      = $srcFile
            command   = $cmdLine
        }
        $OBJ_FILES += $objFile
    }
}

# Write compile_commands.json
$entries | ConvertTo-Json | Set-Content -Path $CC_JSON -Encoding ASCII

# Step 2: Link
Write-Host "`n  Linking ..."
$linkArgs = $OBJ_FILES + $LDFLAGS + @("-o", "$BIN_DIR\$TARGET.elf")
& $CC $linkArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Link failed"
    exit 1
}

# Step 3: Post-process
Write-Host "  Generating binary ..."
& $OBJCOPY -O binary --only-section .vectors --only-section .text --only-section .data "$BIN_DIR\$TARGET.elf" "$BIN_DIR\$TARGET.bin"
& $OBJCOPY -O ihex   "$BIN_DIR\$TARGET.elf" "$BIN_DIR\$TARGET.hex"

# Step 4: Show size
Write-Host "`n  Section sizes:"
& $SIZE "$BIN_DIR\$TARGET.elf"

Write-Host "======================================================="
Write-Host " Build complete!"
Write-Host "   ELF: $BIN_DIR\$TARGET.elf"
Write-Host "   MAP: $BIN_DIR\$TARGET.map"
Write-Host "   BIN: $BIN_DIR\$TARGET.bin"
Write-Host "   HEX: $BIN_DIR\$TARGET.hex"
Write-Host "   CC : $BUILD_DIR\compile_commands.json"
Write-Host "   OBJ: $OBJ_DIR\{lib,src}\*.o"
Write-Host "======================================================="