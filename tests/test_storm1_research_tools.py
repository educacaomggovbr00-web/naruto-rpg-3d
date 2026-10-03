import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def load_module(name: str, relative_path: str):
    spec = importlib.util.spec_from_file_location(name, REPO_ROOT / relative_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


bridge = load_module("storm1_command_chart_bridge", "tools/storm1_command_chart_bridge.py")
probe = load_module("storm1_file_probe", "tools/storm1_file_probe.py")


class Storm1ResearchToolsTest(unittest.TestCase):
    def test_command_chart_bridge_preserves_text_and_numeric_context(self):
        source = {
            "cmd1nrt": [
                {"index": 0, "kind": "num", "value": 17},
                {"index": 1, "kind": "text", "value": "Rasengan"},
                {"index": 2, "kind": "num", "value": 9},
                {"index": 3, "kind": "text", "value": "Naruto Uzumaki Barrage"},
            ],
            "cmd1zzz": [
                {"index": 0, "kind": "text", "value": "Unknown"},
            ],
        }

        result = bridge.normalize_command_chart(source)

        naruto = result["characters"]["naruto"]
        self.assertEqual(naruto["source_chunk"], "cmd1nrt")
        self.assertEqual(naruto["text_fields"], 2)
        self.assertEqual(naruto["numeric_fields"], 2)
        rasengan = naruto["fields"][1]
        self.assertEqual(rasengan["text"], "Rasengan")
        self.assertEqual(rasengan["numeric_context"]["before"][0]["value"], 17)
        self.assertEqual(rasengan["numeric_context"]["after"][0]["value"], 9)
        self.assertIn("cmd1zzz", result["unknown_chunks"])

    def test_character_map_can_extend_known_chunks(self):
        source = {
            "cmd1kks": [
                {"index": 0, "kind": "text", "value": "Lightning Blade"},
            ]
        }
        result = bridge.normalize_command_chart(source, {"cmd1kks": "kakashi"})
        self.assertEqual(
            result["characters"]["kakashi"]["fields"][0]["text"],
            "Lightning Blade",
        )

    def test_file_probe_detects_model_texture_and_command_chart(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "CommandChartData.xfbin").write_bytes(b"header" + b"NDP3" + b"tail")
            (root / "sample.nut").write_bytes(b"xxNTP3yy")
            (root / "archive.cpk").write_bytes(b"CPK " + bytes(32))

            result = probe.inventory(root)

            self.assertEqual(result["file_count"], 3)
            records = {item["path"]: item for item in result["files"]}
            self.assertEqual(
                records["CommandChartData.xfbin"]["suggested_role"],
                "command_chart",
            )
            self.assertIn(
                "NDP3 mesh/model payload",
                records["CommandChartData.xfbin"]["magic_hints"],
            )
            self.assertEqual(
                records["sample.nut"]["suggested_role"],
                "texture_research",
            )
            self.assertEqual(
                records["archive.cpk"]["suggested_role"],
                "archive_research",
            )

    def test_inventory_is_json_serializable(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "sample.binary").write_bytes(b"abc")
            result = probe.inventory(root)
            json.dumps(result)


if __name__ == "__main__":
    unittest.main()
