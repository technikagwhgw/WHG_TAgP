# Beta Feature: Suchfunktion für Macros und System-Funktionen
# Diese Funktion durchsucht die MacroConfig.lua und eine DOKU.txt nach Stichwörtern
# und gibt die gefundenen Einträge in der Konsole aus. (Nicht Haten Für die Schreckliche Umsetzung)
# Nutzung: python LpHelp.py
# Autor: Aeneas


import re
import os

def load_prosa_docs(file_path):
    if not os.path.exists(file_path):
        base_dir = os.path.dirname(__file__)
        file_path = os.path.join(base_dir, "..", "DOKU.txt") # Pfad korrektur

    if not os.path.exists(file_path):
        print(f"[!] Prosa-Dokumentation '{file_path}' nicht gefunden.")
        return []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Trennt anhand von ### und entfernt leere Ergebnisse
    sections = [s.strip() for s in re.split(r'###\s*', content) if s.strip()]
    prosa_entries = []
    
    for section in sections:
        # Trenne den Titel (erste Zeile) vom Rest des Textes
        parts = section.split('\n', 1)
        title = parts[0].strip()
        body = parts[1].strip() if len(parts) > 1 else ""
        
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
    # Pfad relativ zum Speicherort des Skripts ermitteln
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Gehe einen Ordner hoch, falls das Skript im /tools/ Ordner liegt
    root_dir = os.path.join(base_dir) 
    
    doku_path = os.path.join(root_dir, "DOKU.txt")
    #config_path = os.path.join(root_dir, "MacroConfig.lua")

    # Daten laden
    prosa_data = load_prosa_docs(doku_path)
    #lua_data = parse_lua_config(config_path) - Zukunft fix 
    all_data = prosa_data #+ lua_data

    if not all_data:
        print("[!] Keine Daten geladen. Prüfe Pfade!")
        return
    
    while True:
        user_input = input("\nSuche (oder 'exit'): ").strip()
        if user_input.lower() == 'exit': break
        search_all(all_data, user_input)

if __name__ == "__main__":
    main()