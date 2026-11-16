"""从真实QML输入控件验证推荐/自定义码率，供完整版与Lite共用。"""


def check_bitrate_controls(window, studio, qt, app, page):
    """真实触发下拉选择与编辑完成信号，拒绝非法值并保持缓存/预览不重算。"""
    window.setProperty("inspectorPage", page)
    app.processEvents()
    mode = window.findChild(qt.QObject, "exportBitrateMode")
    assert mode is not None
    serial = studio.preview_serial
    mode.setProperty("currentIndex", 1)
    assert qt.QMetaObject.invokeMethod(mode, "activated", qt.Q_ARG(int, 1))
    app.processEvents()
    field = window.findChild(qt.QObject, "exportBitrateInput")
    assert field is not None and field.property("visible")
    field.setProperty("text", "73.5")
    assert qt.QMetaObject.invokeMethod(field, "editingFinished")
    app.processEvents()
    assert studio.state["settings"]["bitrateMbps"] == 73.5
    assert studio.state["exportBitrateMbps"] == 73.5
    assert studio.preview_serial == serial
    for invalid in (-5, 0.5, 501, float("nan"), float("inf"), True):
        studio.setSetting("bitrateMbps", invalid)
        assert studio.state["settings"]["bitrateMbps"] == 73.5
    studio.setActive(100)
    assert studio.state["settings"]["bitrateMbps"] == 73.5
