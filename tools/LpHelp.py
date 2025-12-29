# Beta Feature: Suchfunktion für Macros und System-Funktionen
# Diese Funktion durchsucht die MacroConfig.lua und eine DOKU.txt nach Stichwörtern
# und gibt die gefundenen Einträge in der Konsole aus. (Nicht Haten Für die Schreckliche Umsetzung)
# Nutzung: python LpHelp.py
# Autor: Aeneas


import re
import os

def load_prosa_docs(file_path):
    """Liest die Prosa-Dokumentation aus einer Textdatei ein."""
    if not os.path.exists(file_path):
        print(f"[!] Prosa-Dokumentation '{file_path}' nicht gefunden.")
        return []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Trennt die Themen anhand von '###'
    sections = re.split(r'###\s*', content)
    prosa_entries = []
    
    for section in sections:
        if section.strip():
            lines = section.strip().split('\n', 1)
            title = lines[0].strip()
            body = lines[1].strip() if len(lines) > 1 else ""
            prosa_entries.append({
                "type": "INTERN",
                "page": "SYSTEM",
                "name": title,
                "help": body
            })
    return prosa_entries

def parse_lua_config(file_path):
    """Extrahiert Daten aus der MacroConfig.lua."""
    if not os.path.exists(file_path):
        return []
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    entries = []
    # Einfaches Regex-Parsing für Seiten und Aktionen
    pages = re.split(r'\["(.*?)"\]\s*=\s*\{', content)
    for i in range(1, len(pages), 2):
        page_name = pages[i]
        page_content = pages[i+1]
        actions = re.split(r'\[\d+\]\s*=\s*\{', page_content)
        for action in actions[1:]:
            name_match = re.search(r'name\s*=\s*"(.*?)"', action)
            help_match = re.search(r'help\s*=\s*"(.*?)"', action)
            if name_match and help_match:
                entries.append({
                    "type": "MACRO",
                    "page": page_name,
                    "name": name_match.group(1),
                    "help": help_match.group(1)
                })
    return entries

def search_all(entries, keyword):
    keyword = keyword.lower()
    results = [e for e in entries if keyword in e['name'].lower() or keyword in e['help'].lower()]
    
    if not results:
        print(f"\n[!] Kein Treffer für '{keyword}'")
        return

    print(f"\n{'='*60}")
    print(f" SUCHGEBNISSE FÜR: {keyword.upper()}")
    print(f"{'='*60}")

    for r in results:
        prefix = "CORE-FUNKTION" if r['type'] == "INTERN" else f"MACRO [{r['page']}]"
        print(f"\n> {prefix}: {r['name']}")
        print(f"  Info: {r['help']}")
    print(f"\n{'='*60}")

def main():
    # Daten aus beiden Quellen laden
    all_data = parse_lua_config("MacroConfig.lua") + load_prosa_docs("DOKU.txt")
    
    print("LivePage AG-Zentrale: Suche nach Macros oder System-Funktionen.")
    while True:
        user_input = input("\nSuche (oder 'exit'): ").strip()
        if user_input.lower() == 'exit': break
        search_all(all_data, user_input)

if __name__ == "__main__":
    main()