#!/usr/bin/env python3
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
marker = "# voltageos: keep only GRUB modules available for arm64-efi."
if marker in text:
    raise SystemExit(0)

lines = text.splitlines()
start = next(
    (index for index, line in enumerate(lines) if re.match(r"\s*grubmodules=\(", line)),
    None,
)
if start is None:
    raise SystemExit(f"Could not find the GRUB module list in {path}")

end = next(
    (index for index in range(start, len(lines)) if lines[index].rstrip().endswith(")")),
    None,
)
if end is None:
    raise SystemExit(f"Could not find the end of the GRUB module list in {path}")

lines[end + 1:end + 1] = [
    f"    {marker}",
    '    _voltageos_grub_modules=()',
    '    for _voltageos_grub_module in "${grubmodules[@]}"; do',
    '        if [[ -f "/usr/lib/grub/${grub_target}/${_voltageos_grub_module}.mod" ]]; then',
    '            _voltageos_grub_modules+=("$_voltageos_grub_module")',
    "        fi",
    "    done",
    '    for _voltageos_required in configfile fat iso9660 normal part_gpt search_fs_uuid; do',
    '        if [[ ! -f "/usr/lib/grub/${grub_target}/${_voltageos_required}.mod" ]]; then',
    '            _msg_error "Required GRUB module missing: ${_voltageos_required}" 1',
    "        fi",
    "    done",
    '    grubmodules=("${_voltageos_grub_modules[@]}")',
    "    unset _voltageos_grub_modules _voltageos_grub_module _voltageos_required",
]
path.write_text("\n".join(lines) + "\n")
