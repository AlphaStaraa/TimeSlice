"""读取HEVC SPS的实际位深，防止只声明Main10却输出8位序列。"""

import re


class Bits:
    def __init__(self, data):
        """建立有边界检查的位读取器，不信任媒体中的长度。"""
        self.data, self.position = data, 0

    def read(self, count):
        """读取固定数量的比特，截断数据明确报错。"""
        if count < 0 or self.position + count > len(self.data) * 8:
            raise ValueError("HEVC SPS数据不完整")
        value = 0
        for _ in range(count):
            value = (value << 1) | ((self.data[self.position // 8] >> (7 - self.position % 8)) & 1)
            self.position += 1
        return value

    def ue(self):
        """读取无符号Exp-Golomb值并限制前导零数量。"""
        zeros = 0
        while self.read(1) == 0:
            zeros += 1
            if zeros > 31:
                raise ValueError("HEVC SPS数值无效")
        return (1 << zeros) - 1 + self.read(zeros)


def sequence_info(data):
    """从Annex-B参数集读取真实亮度/色度位深与画布大小。"""
    marker = data.find(b"hvcC")
    if marker >= 0:
        config = data[marker + 4 :]
        if len(config) < 23:
            raise ValueError("HEVC配置记录不完整")
        cursor, units = 23, []
        for _ in range(config[22]):
            if cursor + 3 > len(config):
                raise ValueError("HEVC参数集数组不完整")
            count = int.from_bytes(config[cursor + 1 : cursor + 3], "big")
            cursor += 3
            for _ in range(count):
                size = int.from_bytes(config[cursor : cursor + 2], "big")
                cursor += 2
                if not size or cursor + size > len(config):
                    raise ValueError("HEVC参数集长度无效")
                units.append(b"\x00\x00\x00\x01" + config[cursor : cursor + size])
                cursor += size
        data = b"".join(units)
    for nal in re.split(b"\x00\x00\x00?\x01", data):
        if len(nal) < 4 or (nal[0] >> 1) & 63 != 33:
            continue
        rbsp = nal[2:].replace(b"\x00\x00\x03", b"\x00\x00")
        reader = Bits(rbsp)
        reader.read(4)
        layers = reader.read(3)
        reader.read(1)
        profile = reader.read(8) & 31
        reader.read(88)
        present = [(reader.read(1), reader.read(1)) for _ in range(layers)]
        if layers:
            reader.read((8 - layers) * 2)
        for subprofile, sublevel in present:
            if subprofile:
                reader.read(88)
            if sublevel:
                reader.read(8)
        reader.ue()
        chroma = reader.ue()
        if chroma == 3:
            reader.read(1)
        width, height = reader.ue(), reader.ue()
        if reader.read(1):
            crop = [reader.ue() for _ in range(4)]
            width -= (crop[0] + crop[1]) * (2 if chroma in (1, 2) else 1)
            height -= (crop[2] + crop[3]) * (2 if chroma == 1 else 1)
        return dict(
            profile=profile,
            width=width,
            height=height,
            lumaBits=8 + reader.ue(),
            chromaBits=8 + reader.ue(),
        )
    raise ValueError("没有找到HEVC序列参数集")
