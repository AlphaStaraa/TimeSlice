"""默认效果参数和持久列表模型，保持勾选及拖拽位置。"""

from copy import deepcopy

from model import default_settings
from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt


# 设定 Mac 冻结效果的默认片数和单侧阴影。
def mac_defaults(effect):
    values = default_settings(effect)
    values.update(shadowStrength=0.25, shadowWidth=0.50, dayNightSplit=False, discardRatio=0.60)
    if effect["id"] in (0, 104):
        values.update(rotationStartAngle=0.0, origin=-1)
    if effect["family"] == 0:
        values.update(
            sliceMode=0,
            sliceCount=60,
            recommendedSlices=60,
            shadowEnabled=True,
            shadowStrength=0.25,
            shadowWidth=0.50,
            shadowSoftness=1.0,
            shadowSide=0,
        )
    return values


class EffectListModel(QAbstractListModel):
    """Update rows in place so a checkbox never changes GridView's scroll origin."""

    entryRole = Qt.UserRole + 1

    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self, parent=None):
        super().__init__(parent)
        self.rows = []

    # 声明列表模型供 QML 读取的角色名称。
    def roleNames(self):
        return {self.entryRole: b"entry"}

    # 返回当前父节点下的有效条目数。
    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self.rows)

    # 返回指定列表角色的数据，忽略无效索引。
    def data(self, index, role):
        return self.rows[index.row()] if index.isValid() and role == self.entryRole else None

    # 更新当前任务状态并把进度通知上层。
    def update(self, rows):
        if [r["catalogueKey"] for r in rows] != [r["catalogueKey"] for r in self.rows]:
            self.beginResetModel()
            self.rows = deepcopy(rows)
            self.endResetModel()
            return
        for i, (old, new) in enumerate(zip(self.rows, rows)):
            if old != new:
                self.rows[i] = deepcopy(new)
                self.dataChanged.emit(self.index(i), self.index(i), [self.entryRole])


class SelectionListModel(EffectListModel):
    def update(self, rows):
        """以插入、删除和移动事件保持拖拽委托及滚动位置，不重新创建整个队列。"""
        wanted = {row["id"] for row in rows}
        for index in range(len(self.rows) - 1, -1, -1):
            if self.rows[index]["id"] not in wanted:
                self.beginRemoveRows(QModelIndex(), index, index)
                self.rows.pop(index)
                self.endRemoveRows()
        for target, row in enumerate(rows):
            ids = [entry["id"] for entry in self.rows]
            if row["id"] not in ids:
                self.beginInsertRows(QModelIndex(), target, target)
                self.rows.insert(target, deepcopy(row))
                self.endInsertRows()
            else:
                source = ids.index(row["id"])
                if source != target:
                    self.beginMoveRows(
                        QModelIndex(),
                        source,
                        source,
                        QModelIndex(),
                        target if target < source else target + 1,
                    )
                    entry = self.rows.pop(source)
                    self.rows.insert(target, entry)
                    self.endMoveRows()
                if self.rows[target] != row:
                    self.rows[target] = deepcopy(row)
                    self.dataChanged.emit(self.index(target), self.index(target), [self.entryRole])
