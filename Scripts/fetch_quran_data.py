#!/usr/bin/env python3
"""
Fetch Juz Amma data (Arabic text only) from Quran.com API

Translations are now downloaded on-demand via the app's TranslationService.

Usage:
    python3 fetch_quran_data.py

Output:
    JuzAmma/Resources/juz_amma_data.json
"""

import requests
import json
import time

BASE_URL = "https://api.quran.com/api/v4"

SURAH_METADATA = {
    78: {"name": "النبإ", "transliteration": "An-Naba'", "translation": "The Tidings", "ayahs": 40, "revelation": "Makkah"},
    79: {"name": "النازعات", "transliteration": "An-Nazi'at", "translation": "Those Who Pull Out", "ayahs": 46, "revelation": "Makkah"},
    80: {"name": "عبس", "transliteration": "'Abasa", "translation": "He Frowned", "ayahs": 42, "revelation": "Makkah"},
    81: {"name": "التكوير", "transliteration": "At-Takwir", "translation": "The Overthrowing", "ayahs": 29, "revelation": "Makkah"},
    82: {"name": "الانفطار", "transliteration": "Al-Infitar", "translation": "The Cleaving", "ayahs": 19, "revelation": "Makkah"},
    83: {"name": "المطففين", "transliteration": "Al-Mutaffifin", "translation": "The Defrauding", "ayahs": 36, "revelation": "Makkah"},
    84: {"name": "الانشقاق", "transliteration": "Al-Inshiqaq", "translation": "The Splitting Asunder", "ayahs": 25, "revelation": "Makkah"},
    85: {"name": "البروج", "transliteration": "Al-Buruj", "translation": "The Stars", "ayahs": 22, "revelation": "Makkah"},
    86: {"name": "الطارق", "transliteration": "At-Tariq", "translation": "The Nightcomer", "ayahs": 17, "revelation": "Makkah"},
    87: {"name": "الأعلى", "transliteration": "Al-A'la", "translation": "The Most High", "ayahs": 19, "revelation": "Makkah"},
    88: {"name": "الغاشية", "transliteration": "Al-Ghashiyah", "translation": "The Overwhelming", "ayahs": 26, "revelation": "Makkah"},
    89: {"name": "الفجر", "transliteration": "Al-Fajr", "translation": "The Dawn", "ayahs": 30, "revelation": "Makkah"},
    90: {"name": "البلد", "transliteration": "Al-Balad", "translation": "The City", "ayahs": 20, "revelation": "Makkah"},
    91: {"name": "الشمس", "transliteration": "Ash-Shams", "translation": "The Sun", "ayahs": 15, "revelation": "Makkah"},
    92: {"name": "الليل", "transliteration": "Al-Layl", "translation": "The Night", "ayahs": 21, "revelation": "Makkah"},
    93: {"name": "الضحى", "transliteration": "Ad-Duha", "translation": "The Forenoon", "ayahs": 11, "revelation": "Makkah"},
    94: {"name": "الشرح", "transliteration": "Ash-Sharh", "translation": "The Opening Forth", "ayahs": 8, "revelation": "Makkah"},
    95: {"name": "التين", "transliteration": "At-Tin", "translation": "The Fig", "ayahs": 8, "revelation": "Makkah"},
    96: {"name": "العلق", "transliteration": "Al-'Alaq", "translation": "The Clot", "ayahs": 19, "revelation": "Makkah"},
    97: {"name": "القدر", "transliteration": "Al-Qadar", "translation": "The Night of Decree", "ayahs": 5, "revelation": "Makkah"},
    98: {"name": "البينة", "transliteration": "Al-Bayyinah", "translation": "The Clear Evidence", "ayahs": 8, "revelation": "Madinah"},
    99: {"name": "الزلزلة", "transliteration": "Az-Zalzalah", "translation": "The Earthquake", "ayahs": 8, "revelation": "Madinah"},
    100: {"name": "العاديات", "transliteration": "Al-'Adiyat", "translation": "The Courser", "ayahs": 11, "revelation": "Makkah"},
    101: {"name": "القارعة", "transliteration": "Al-Qari'ah", "translation": "The Striking Hour", "ayahs": 11, "revelation": "Makkah"},
    102: {"name": "التكاثر", "transliteration": "At-Takathur", "translation": "The Rivalry", "ayahs": 8, "revelation": "Makkah"},
    103: {"name": "العصر", "transliteration": "Al-'Asr", "translation": "The Time", "ayahs": 3, "revelation": "Makkah"},
    104: {"name": "الهمزة", "transliteration": "Al-Humazah", "translation": "The Slanderer", "ayahs": 9, "revelation": "Makkah"},
    105: {"name": "الفيل", "transliteration": "Al-Fil", "translation": "The Elephant", "ayahs": 5, "revelation": "Makkah"},
    106: {"name": "قريش", "transliteration": "Quraysh", "translation": "Quraysh", "ayahs": 4, "revelation": "Makkah"},
    107: {"name": "الماعون", "transliteration": "Al-Ma'un", "translation": "The Small Kindnesses", "ayahs": 7, "revelation": "Makkah"},
    108: {"name": "الكوثر", "transliteration": "Al-Kawthar", "translation": "The Abundance", "ayahs": 3, "revelation": "Makkah"},
    109: {"name": "الكافرون", "transliteration": "Al-Kafirun", "translation": "The Disbelievers", "ayahs": 6, "revelation": "Makkah"},
    110: {"name": "النصر", "transliteration": "An-Nasr", "translation": "The Help", "ayahs": 3, "revelation": "Madinah"},
    111: {"name": "المسد", "transliteration": "Al-Masad", "translation": "The Palm Fiber", "ayahs": 5, "revelation": "Makkah"},
    112: {"name": "الإخلاص", "transliteration": "Al-Ikhlas", "translation": "The Sincerity", "ayahs": 4, "revelation": "Makkah"},
    113: {"name": "الفلق", "transliteration": "Al-Falaq", "translation": "The Daybreak", "ayahs": 5, "revelation": "Makkah"},
    114: {"name": "الناس", "transliteration": "An-Nas", "translation": "Mankind", "ayahs": 6, "revelation": "Makkah"},
}

def fix_diacritic_order(text):
    chars = list(text)
    i = 0
    while i < len(chars) - 1:
        if ord(chars[i]) == 0x0651 and ord(chars[i+1]) == 0x0650:
            chars[i], chars[i+1] = chars[i+1], chars[i]
            i += 2
        else:
            i += 1
    return ''.join(chars)

def fetch_surah_verses(surah_number):
    url = f"{BASE_URL}/quran/verses/uthmani?chapter_number={surah_number}"
    response = requests.get(url, timeout=15)
    response.raise_for_status()
    data = response.json()
    
    verses = []
    for i, verse in enumerate(data.get("verses", [])):
        verse_key = verse.get("verse_key", "")
        verse_number = int(verse_key.split(":")[-1]) if ":" in verse_key else i + 1
        arabic_text = fix_diacritic_order(verse.get("text_uthmani", ""))
        
        verses.append({
            "number": verse_number,
            "textArabic": arabic_text
        })
    
    print(f"   ✅ Fetched {len(verses)} verses")
    return verses

def main():
    print("\n🚀 Fetching Juz Amma (Arabic text only)...")
    print("📝 Translations are downloaded on-demand via the app\n")
    
    juz_amma_data = {"juzAmma": []}
    
    for surah_num in range(78, 115):
        metadata = SURAH_METADATA[surah_num]
        print(f"📖 Surah {surah_num} - {metadata['transliteration']}")
        
        verses = fetch_surah_verses(surah_num)
        
        juz_amma_data["juzAmma"].append({
            "number": surah_num,
            "nameArabic": metadata["name"],
            "nameTransliteration": metadata["transliteration"],
            "nameTranslation": metadata["translation"],
            "ayahCount": metadata["ayahs"],
            "revelation": metadata["revelation"],
            "ayahs": verses
        })
        
        time.sleep(0.5)
    
    output_file = "../JuzAmma/Resources/juz_amma_data.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(juz_amma_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ Saved to {output_file}")

if __name__ == "__main__":
    main()
