import sys

sys.dont_write_bytecode = True

import json
from pathlib import Path
import re
import xml.etree.ElementTree as element_tree


MATHML_NAMESPACE = "http://www.w3.org/1998/Math/MathML"
UNRESOLVED_COMMAND = re.compile(r"\\(?:[A-Za-z]+|[^\\\s])")


def validate_visible_math(node):
    local_name = node.tag.rsplit("}", 1)[-1]
    if local_name == "merror":
        raise ValueError("converter produced merror")
    if local_name in {"annotation", "annotation-xml"}:
        return
    if node.text and UNRESOLVED_COMMAND.search(node.text):
        raise ValueError("unresolved TeX command in visible MathML")
    for child in node:
        validate_visible_math(child)
        if child.tail and UNRESOLVED_COMMAND.search(child.tail):
            raise ValueError("unresolved TeX command in visible MathML")


def main():
    if len(sys.argv) != 2:
        raise ValueError("usage: mathml.py ABSOLUTE_UNPACKED_DEPENDENCY_DIRECTORY")
    dependency_directory = Path(sys.argv[1])
    if not dependency_directory.is_absolute() or not dependency_directory.is_dir():
        raise ValueError("dependency directory must be an existing absolute path")
    sys.path.insert(0, str(dependency_directory))
    from latex2mathml import converter

    entries = json.load(sys.stdin)
    if not isinstance(entries, list):
        raise ValueError("stdin must be a JSON array")
    element_tree.register_namespace("", MATHML_NAMESPACE)
    results = []
    for entry_index, entry in enumerate(entries):
        if not isinstance(entry, dict) or set(entry) != {"tex", "display"}:
            raise ValueError(f"entry {entry_index} must contain tex and display")
        if not isinstance(entry["tex"], str) or not isinstance(entry["display"], bool):
            raise ValueError(f"entry {entry_index} requires string tex and boolean display")
        display = "block" if entry["display"] else "inline"
        try:
            math = element_tree.fromstring(
                converter.convert(entry["tex"], xmlns=MATHML_NAMESPACE, display=display)
            )
            if math.tag != f"{{{MATHML_NAMESPACE}}}math" or math.get("display") != display:
                raise ValueError("incorrect MathML root namespace or display role")
            validate_visible_math(math)
            semantics = element_tree.Element(f"{{{MATHML_NAMESPACE}}}semantics")
            for child in list(math):
                math.remove(child)
                semantics.append(child)
            annotation = element_tree.SubElement(
                semantics,
                f"{{{MATHML_NAMESPACE}}}annotation",
                {"encoding": "application/x-tex"},
            )
            annotation.text = entry["tex"]
            math.append(semantics)
            results.append(element_tree.tostring(math, encoding="unicode"))
        except Exception as error:
            raise ValueError(f"entry {entry_index}: {error}") from error
    sys.stdout.write(json.dumps(results, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"mathml: {error}", file=sys.stderr)
        sys.exit(1)
