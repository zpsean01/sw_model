"""
Base Stage Interface for the ARM Firmware Analysis Pipeline.

All stages must inherit from BaseStage and implement the `run` method.
"""

import json
import logging
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)


class BaseStage(ABC):
    """Abstract base class for all pipeline stages."""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.stage_id: Optional[str] = None
        self.output_dir: Optional[Path] = None

    @abstractmethod
    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute the stage.

        Args:
            context: Dictionary passed from the pipeline runner, containing
                     outputs and artifacts from previous stages.

        Returns:
            A dictionary with results to be merged into the pipeline context.
        """
        ...

    def setup_output_dir(self, output_dir: str) -> Path:
        """Create and return the output directory path."""
        path = Path(output_dir)
        path.mkdir(parents=True, exist_ok=True)
        self.output_dir = path
        logger.info("Output directory: %s", path.resolve())
        return path

    def save_json(self, filename: str, data: Any, subdir: Optional[str] = None) -> Path:
        """Save data as JSON under the output directory."""
        target = self.output_dir
        if subdir:
            target = target / subdir
            target.mkdir(parents=True, exist_ok=True)
        filepath = target / filename
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        logger.info("Saved: %s", filepath)
        return filepath

    def load_json(self, filepath: str) -> Any:
        """Load a JSON file."""
        with open(filepath, "r", encoding="utf-8") as f:
            return json.load(f)