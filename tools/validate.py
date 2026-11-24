#!/usr/bin/env python3
"""Static package validation for z_uwucafe. Does not replace live FiveM testing."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

# Node syntax check when Node is available.
try:
    subprocess.run(["node", "--check", str(ROOT / "web/app.js")], check=True, capture_output=True, text=True)
except FileNotFoundError:
    print("WARN: Node was not found; JavaScript syntax check skipped.")
except subprocess.CalledProcessError as exc:
    errors.append(exc.stderr.strip() or "JavaScript syntax check failed")

# Lua compilation through texlua when available. FiveM backtick syntax is confined to the install snippet.
lua_files = [p for p in ROOT.rglob("*.lua") if p != ROOT / "install/ox_inventory_items.lua"]
checker = ROOT / "tools/.check_lua.lua"
checker.write_text("""local failed=false\nfor i=1,#arg do local f,e=loadfile(arg[i]); if not f then io.stderr:write(arg[i]..': '..tostring(e)..'\\n'); failed=true end end\nif failed then os.exit(1) end\n""")
try:
    subprocess.run(["texlua", str(checker), *map(str, lua_files)], check=True, capture_output=True, text=True)
except FileNotFoundError:
    print("WARN: texlua was not found; Lua syntax check skipped.")
except subprocess.CalledProcessError as exc:
    errors.append(exc.stderr.strip() or "Lua syntax check failed")
finally:
    checker.unlink(missing_ok=True)

# Internal event and ox_lib callback cross-reference.
registrations, triggers, callbacks, awaits = set(), set(), set(), set()
for path in lua_files:
    text = path.read_text(errors="ignore")
    registrations.update(re.findall(r"RegisterNetEvent\(['\"]([^'\"]+)", text))
    triggers.update(re.findall(r"(?:TriggerServerEvent|TriggerClientEvent)\(['\"]([^'\"]+)", text))
    callbacks.update(re.findall(r"lib\.callback\.register\(['\"]([^'\"]+)", text))
    awaits.update(re.findall(r"lib\.callback\.await\(['\"]([^'\"]+)", text))
for name in sorted(triggers):
    if name.startswith("z_uwucafe") and name not in registrations:
        errors.append(f"Triggered event has no registration: {name}")
for name in sorted(awaits):
    if name.startswith("z_uwucafe") and name not in callbacks:
        errors.append(f"Awaited callback has no registration: {name}")

# NUI callback cross-reference.
js = (ROOT / "web/app.js").read_text()
client = (ROOT / "client/orders.lua").read_text()
nui_calls = set(re.findall(r"nui\(['\"]([^'\"]+)", js))
nui_regs = set(re.findall(r"RegisterNUICallback\(['\"]([^'\"]+)", client))
for name in sorted(nui_calls - nui_regs):
    errors.append(f"NUI action has no client callback: {name}")

# Database table coverage.
sql = (ROOT / "sql/install.sql").read_text()
defined = set(re.findall(r"CREATE TABLE IF NOT EXISTS\s+`?([A-Za-z0-9_]+)", sql, re.I))
used = set()
for path in (ROOT / "server").glob("*.lua"):
    used.update(re.findall(r"\b(?:FROM|INTO|UPDATE|JOIN)\s+`?([A-Za-z0-9_]+)", path.read_text(), re.I))
for table in sorted(t for t in used if t.startswith("z_uwucafe_") and t not in defined):
    errors.append(f"Referenced database table is not defined: {table}")

# Item/recipe/supply/contract coverage and icons.
item_text = (ROOT / "install/ox_inventory_items.lua").read_text()
items = set(re.findall(r"\['([^']+)'\]\s*=", item_text))
products = set(re.findall(r"^\s*(uwu_[a-z0-9_]+)\s*=\s*\{", (ROOT / "shared/products.lua").read_text(), re.M))
recipe_text = (ROOT / "shared/recipes.lua").read_text()
results = set(re.findall(r"result\s*=\s*\{\s*item\s*=\s*'([^']+)'", recipe_text))
ingredients = set()
for block in re.findall(r"ingredients\s*=\s*\{([^}]*)\}", recipe_text):
    ingredients.update(re.findall(r"(uwu_[a-z0-9_]+)\s*=", block))
referenced = products | results | ingredients
for source in [ROOT / "config.lua", ROOT / "shared/contracts.lua"]:
    for block in re.findall(r"items\s*=\s*\{([^}]*)\}", source.read_text()):
        referenced.update(re.findall(r"(uwu_[a-z0-9_]+)\s*=", block))
for item in sorted(referenced - items):
    errors.append(f"Referenced item lacks ox_inventory definition: {item}")
for product in sorted(products - results):
    errors.append(f"Menu product lacks a recipe: {product}")
for item in sorted(items):
    if not (ROOT / "install/images" / f"{item}.png").exists():
        errors.append(f"Inventory icon is missing: {item}.png")

if errors:
    print("VALIDATION FAILED")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print(f"VALIDATION PASSED: {len(lua_files)} Lua files, {len(callbacks)} callbacks, {len(items)} items, {len(defined)} custom tables.")
