import argparse
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
from i18n import Translator
from next_controller import NextController as MacController
from PySide6.QtCore import QSettings, QStandardPaths, QUrl
from PySide6.QtGui import QFontDatabase, QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine


# 组织此入口的初始化、主流程和退出清理。
def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--self-check", type=Path)
    parser.add_argument("--self-check-source", type=Path)
    parser.add_argument("--require-gpu", action="store_true")
    parser.add_argument(
        "--self-check-format", choices=("h264", "hevc10", "hdr_pq", "hdr_hlg"), default="h264"
    )
    options, _ = parser.parse_known_args()
    if options.self_check and (
        not options.self_check_source or not options.self_check_source.is_file()
    ):
        parser.error("self-check requires an existing source fixture")
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    if sys.platform == "win32":
        import ctypes

        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID("studio.timeslice.windows")
    app = QGuiApplication(sys.argv)
    app.setFont(QFontDatabase.systemFont(QFontDatabase.GeneralFont))
    app.setApplicationName("时刃")
    app.setOrganizationName("AlphaStar")
    app.setApplicationDisplayName("时刃 · 延时切片工作室")
    app.setWindowIcon(QIcon(str(ROOT.parent / "assets/app-icon-glass.png")))
    provider = PreviewProvider()
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
    controller = MacController(provider, preferences)
    engine = QQmlApplicationEngine()
    translator = Translator(controller.language)
    app.installTranslator(translator)

    # 更新翻译器和 Qt 绑定，并切换应用显示名称。
    def change_language(language):
        translator.language = language
        engine.retranslate()
        app.setApplicationDisplayName(
            "TimeSlice · Timelapse Studio" if language == "en" else "时刃 · 延时切片工作室"
        )

    controller.languageChanged.connect(change_language)
    engine.addImageProvider("preview", provider)
    engine.rootContext().setContextProperty("studio", controller)
    warnings = []
    if options.self_check:
        engine.warnings.connect(lambda items: warnings.extend(str(x) for x in items))
    engine.load(QUrl.fromLocalFile(str(ROOT / "ui/Main.qml")))
    if not engine.rootObjects():
        return 1
    change_language(controller.language)
    app.aboutToQuit.connect(controller.shutdown)
    if options.self_check:
        from desktop_self_check import FullPackageCheck

        app._package_check = FullPackageCheck(
            app,
            controller,
            engine,
            output,
            options.self_check_source.resolve(),
            options.require_gpu,
            warnings,
            options.self_check_format,
        )
    result = app.exec()
    import shiboken6

    for window in engine.rootObjects():
        shiboken6.delete(window)
    shiboken6.delete(engine)
    return result


if __name__ == "__main__":
    sys.exit(main())
