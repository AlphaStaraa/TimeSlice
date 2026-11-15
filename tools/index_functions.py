"""生成维护中 Python 函数的中文索引，检查模式可发现过期行号。"""

import argparse
import ast
import csv
import io
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def functions(tree, prefix=""):
    """递归列出类方法、函数和内部函数，并保留可定位的完整名称。"""
    for node in ast.iter_child_nodes(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            name = prefix + node.name
            if not isinstance(node, ast.ClassDef):
                yield name, node
            yield from functions(node, name + ".")
        else:
            yield from functions(node, prefix)


def generate():
    """优先使用文档字符串，其次读取紧邻函数的注释；缺少中文说明时失败。"""
    output = io.StringIO(newline="")
    writer = csv.writer(output, lineterminator="\n")
    writer.writerow(("文件", "行号", "函数", "说明"))
    count = 0
    for folder in ("app", "mac-5.0-redesign", "lite", "tools", "mobile/tools"):
        for path in sorted((ROOT / folder).rglob("*.py")):
            if "__pycache__" in path.parts:
                continue
            source = path.read_text(encoding="utf-8")
            lines = source.splitlines()
            for name, node in functions(ast.parse(source)):
                description = ast.get_docstring(node) or ""
                if not description:
                    comments = []
                    row = min([node.lineno] + [d.lineno for d in node.decorator_list]) - 2
                    while row >= 0 and lines[row].strip().startswith("#"):
                        comments.insert(0, lines[row].strip("# "))
                        row -= 1
                    description = " ".join(comments)
                assert any("\u4e00" <= char <= "\u9fff" for char in description), (path, name)
                writer.writerow((str(path.relative_to(ROOT)), node.lineno, name, description))
                count += 1
    return output.getvalue(), count


def main():
    """按当前源码生成索引，或核对已有索引是否与源码一致。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content, count = generate()
    target = ROOT / "docs/函数索引.csv"
    if args.check:
        with target.open(encoding="utf-8-sig", newline="") as stream:
            assert stream.read() == content, "Run python tools/index_functions.py"
    else:
        target.write_bytes(content.encode("utf-8-sig"))
    print(f"Chinese Python function index: {count} entries")


if __name__ == "__main__":
    main()
