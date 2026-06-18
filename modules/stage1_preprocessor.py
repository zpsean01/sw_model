"""
Stage 1 — Source Preprocessor

Uses compile_commands.json to invoke the compiler in preprocess-only mode (-E),
preserving line-number markers so the output can be used for AST analysis.
"""

import json
import logging
import subprocess
from pathlib import Path
from typing import Any, Dict, List

from modules.base import BaseStage

logger = logging.getLogger(__name__)


class Stage1Preprocessor(BaseStage):
    """Preprocess source files using compile_commands.json."""

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        params = self.config["params"]
        cc_path = Path(params["compile_commands"])
        output_dir = self.setup_output_dir(params["output_dir"])
        compiler = params.get("compiler", "arm-none-eabi-gcc")

        if not cc_path.exists():
            raise FileNotFoundError(f"compile_commands.json not found: {cc_path}")

        with open(cc_path, "r", encoding="utf-8") as f:
            entries = json.load(f)

        manifest = []
        for entry in entries:
            src_file = entry.get("file", "")
            file_dir = entry.get("directory", ".")
            command = entry.get("command", "")
            arguments = entry.get("arguments", [])

            if not src_file:
                continue

            # Determine output filename (.i for C, .ii for C++)
            src_path = Path(src_file)
            ext = ".ii" if src_path.suffix in (".cpp", ".cxx", ".cc") else ".i"
            out_name = src_path.with_suffix(ext).name
            out_path = output_dir / out_name

            # Build preprocess command
            if arguments:
                # Prefer "arguments" list form
                cmd = self._build_from_arguments(arguments, src_file, compiler)
            else:
                cmd = self._build_from_command(command, src_file, compiler)

            cmd.extend(["-o", str(out_path)])

            logger.info("Preprocessing: %s -> %s", src_file, out_name)
            try:
                subprocess.run(
                    cmd,
                    cwd=file_dir,
                    check=True,
                    capture_output=True,
                    text=True,
                )
            except subprocess.CalledProcessError as e:
                logger.warning("Preprocess failed for %s:\n%s", src_file, e.stderr)
                continue

            manifest.append({
                "source": src_file,
                "preprocessed": str(out_path),
                "directory": file_dir,
            })

        # Save manifest
        manifest_path = output_dir / "manifest.json"
        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2)

        return {
            "stage1": {
                "manifest": str(manifest_path),
                "output_dir": str(output_dir),
                "files_processed": len(manifest),
            }
        }

    def _build_from_arguments(
        self, arguments: List[str], src_file: str, compiler: str
    ) -> List[str]:
        """Extract preprocessor flags from the arguments list."""
        cmd = [compiler, "-E", "-P", "-C"]
        skip_next = False
        src_relative = Path(src_file).name
        for i, arg in enumerate(arguments):
            if skip_next:
                skip_next = False
                continue
            if arg in ("-c", "-o", "-S"):
                skip_next = True
                continue
            if arg == src_file or arg == src_relative or arg.endswith(f"/{src_relative}"):
                cmd.append(arg)
                continue
            if arg.startswith("-") or arg.startswith("-m") or arg.startswith("-f"):
                cmd.append(arg)
                continue
            if arg.startswith("-I") or arg.startswith("-D") or arg.startswith("-idirafter"):
                cmd.append(arg)
                continue
        if src_file not in cmd:
            cmd.append(src_file)
        return cmd

    def _build_from_command(
        self, command: str, src_file: str, compiler: str
    ) -> List[str]:
        """Parse the raw command string and convert to a preprocess command."""
        import shlex
        tokens = shlex.split(command)
        cmd = [compiler, "-E", "-P", "-C"]
        skip_next = False
        for i, tok in enumerate(tokens):
            if skip_next:
                skip_next = False
                continue
            if tok in ("-c", "-o", "-S"):
                skip_next = True
                continue
            if tok.startswith("-") or tok.startswith("-m") or tok.startswith("-f"):
                cmd.append(tok)
                continue
            if tok.startswith("-I") or tok.startswith("-D") or tok.startswith("-idirafter"):
                cmd.append(tok)
                continue
        cmd.append(src_file)
        return cmd