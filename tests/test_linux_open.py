import importlib.machinery
import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).resolve().parents[1] / "bin" / "linux-open"
loader = importlib.machinery.SourceFileLoader("linux_open", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class RoutingTests(unittest.TestCase):
    def setUp(self):
        self.commands = {
            "texstudio": "/usr/bin/texstudio",
            "kate": "/usr/bin/kate",
            "xdg-open": "/usr/bin/xdg-open",
            "eog": "/usr/bin/eog",
            "evince": "/usr/bin/evince",
        }
        self.which = mock.patch.object(module.shutil, "which", side_effect=self.commands.get)
        self.which.start()

    def tearDown(self):
        self.which.stop()

    def test_tex_uses_texstudio(self):
        command, category = module.command_for("paper.tex")
        self.assertEqual((Path(command[0]).name, category), ("texstudio", "tex"))

    def test_code_uses_kate(self):
        command, category = module.command_for("analysis.py")
        self.assertEqual((Path(command[0]).name, category), ("kate", "text"))

    def test_images_and_pdf_use_desktop_viewer(self):
        for filename in ("plot.png", "photo.jpeg"):
            command, category = module.command_for(filename)
            self.assertEqual(Path(command[0]).name, "eog")
            self.assertEqual(category, "image")
        for filename in ("paper.pdf", "figure.eps"):
            command, category = module.command_for(filename)
            self.assertEqual(Path(command[0]).name, "evince")
            self.assertEqual(category, "document")

    def test_extensionless_ascii_uses_kate(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "NOTES"
            path.write_text("plain ASCII notes\n", encoding="utf-8")
            command, category = module.command_for(str(path))
            self.assertEqual((Path(command[0]).name, category), ("kate", "text"))

    def test_binary_uses_desktop_opener(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sample.bin"
            path.write_bytes(b"abc\0def")
            command, category = module.command_for(str(path))
            self.assertEqual((Path(command[0]).name, category), ("xdg-open", "desktop"))

    def test_missing_file_is_created(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "new-analysis.py"
            usable, created = module.ensure_local_target(str(path))
            self.assertTrue(usable)
            self.assertTrue(created)
            self.assertTrue(path.is_file())
            self.assertEqual(path.read_bytes(), b"")

    def test_missing_parent_is_not_created(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "missing" / "new.txt"
            usable, created = module.ensure_local_target(str(path))
            self.assertFalse(usable)
            self.assertFalse(created)
            self.assertFalse(path.exists())

    def test_dry_run_does_not_create_file(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "preview.tex"
            result = module.main(["--dry-run", str(path)])
            self.assertEqual(result, 0)
            self.assertFalse(path.exists())

    def test_help_lists_dependencies(self):
        help_text = module.build_parser().format_help()
        self.assertIn("Dependencies by file type", help_text)
        self.assertIn("texstudio", help_text)
        self.assertIn("kate", help_text)
        self.assertIn("xdg-utils", help_text)

    def test_current_version(self):
        self.assertEqual(module.VERSION, "1.3.0")

    def test_image_batch_uses_one_gallery_process(self):
        groups = module.build_launch_groups(["one.png", "two.jpg", "three.jpeg"])
        self.assertEqual(len(groups), 1)
        command, category, arguments = groups[0]
        self.assertEqual(command[:2], ["/usr/bin/eog", "--single-window"])
        self.assertEqual(category, "image")
        self.assertEqual(len(arguments), 3)

    def test_code_batch_uses_one_kate_process(self):
        groups = module.build_launch_groups(["one.py", "two.c", "three.txt"])
        self.assertEqual(len(groups), 1)
        command, category, arguments = groups[0]
        self.assertEqual(command[0], "/usr/bin/kate")
        self.assertEqual(category, "text")
        self.assertEqual(len(arguments), 3)


if __name__ == "__main__":
    unittest.main()
