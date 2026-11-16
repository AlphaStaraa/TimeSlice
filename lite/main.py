"""独立启动轻量版，不加载完整版本的照片和素材处理依赖。"""

import argparse
import json
import os
import sys
from pathlib import Path

ROOT = (
    Path(sys._MEIPASS) / "app" if getattr(sys, "frozen", False) else Path(__file__).resolve().parent
)
sys.path.insert(0, str(ROOT))
from windows_bootstrap import ensure_windows_runtime

ensure_windows_runtime(__file__)
from controller import PreviewProvider
from i18n import EN, Translator
from lite_controller import LiteController
from PySide6.QtCore import QSettings, QStandardPaths, QUrl
from PySide6.QtGui import QFontDatabase, QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine


def main():
    """载入精简工作台，保留系统字体、语言切换和干净退出。"""
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    extra = ROOT / "resources/lite-en.json"
    if extra.exists():
        EN.update(json.loads(extra.read_text(encoding="utf-8")))
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--self-check", type=Path)
    parser.add_argument("--require-gpu", action="store_true")
    parser.add_argument(
        "--self-check-format", choices=("h264", "hevc10", "hdr_pq", "hdr_hlg"), default="h264"
    )
    options, _ = parser.parse_known_args()
    app = QGuiApplication(sys.argv)
    app.setFont(QFontDatabase.systemFont(QFontDatabase.GeneralFont))
    app.setApplicationName("TimeSliceLite")
    app.setOrganizationName("AlphaStar")
    app.setWindowIcon(QIcon(str(ROOT.parent / "assets/app-icon-glass.png")))
    preferences = None
    if options.self_check:
        output = options.self_check.resolve()
        output.mkdir(parents=True, exist_ok=True)
        original_location = QStandardPaths.writableLocation
        QStandardPaths.writableLocation = lambda key: (
            str(output / "cache") if key == QStandardPaths.CacheLocation else original_location(key)
        )
        preferences = QSettings(str(output / "preferences.ini"), QSettings.IniFormat)
        preferences.clear()
    controller = LiteController(PreviewProvider(), preferences)
    engine = QQmlApplicationEngine()
    translator = Translator(controller.language)
    app.installTranslator(translator)

    def language_changed(language):
        """重新翻译可见控件，并更新系统应用名称。"""
        translator.language = language
        engine.retranslate()
        app.setApplicationDisplayName("TimeSlice Lite" if language == "en" else "时刃 Lite")

    controller.languageChanged.connect(language_changed)
    engine.addImageProvider("preview", controller.provider)
    engine.rootContext().setContextProperty("studio", controller)
    engine.load(QUrl.fromLocalFile(str(ROOT / "ui/Main.qml")))
    if not engine.rootObjects():
        controller.shutdown()
        return 1
    language_changed(controller.language)
    app.aboutToQuit.connect(controller.shutdown)
    if options.self_check:
        from self_check import PackageCheck

        check = PackageCheck(
            app,
            controller,
            engine,
            options.self_check.resolve(),
            options.require_gpu,
            options.self_check_format,
        )
        app._package_check = check
    result = app.exec()
    import shiboken6

    for window in engine.rootObjects():
        shiboken6.delete(window)
    shiboken6.delete(engine)
    return result


if __name__ == "__main__":
    raise SystemExit(main())
