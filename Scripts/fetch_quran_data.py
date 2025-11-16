#!/usr/bin/env python3
"""
Fetch complete Juz Amma data from Quran.com API

This script fetches all 37 surahs of Juz Amma (surahs 78-114) with:
- Arabic text (Uthmani script)
- English translation (Sahih International) 
- Indonesian translation (Ministry of Religious Affairs)

Usage:
    python3 fetch_quran_data_fixed.py

Output:
    JuzAmma/Resources/juz_amma_data.json
"""

import requests
import json
import time
import re
from typing import Dict, Any, List

# API Configuration
BASE_URL = "https://api.quran.com/api/v4"
ENGLISH_TRANSLATION = 20  # Saheeh International
INDONESIAN_TRANSLATION = 33  # Indonesian Ministry of Religious Affairs

# Juz Amma metadata (Surahs 78-114)
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
    102: {"name": "التكاثر", "transliteration": "At-Takathur", "translation": "The Rivalry in World Increase", "ayahs": 8, "revelation": "Makkah"},
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


def clean_html_tags(text: str) -> str:
    """
    Remove HTML tags from translation text
    
    Args:
        text: Text that may contain HTML tags
    
    Returns:
        Cleaned text without HTML tags
    """
    # Remove <sup> tags with foot_note attributes
    text = re.sub(r'<sup foot_note=[^>]*>.*?</sup>', '', text)
    # Remove any remaining HTML tags
    text = re.sub(r'<[^>]+>', '', text)
    return text.strip()


def fix_diacritic_order(text: str) -> str:
    """
    Fix Arabic diacritic order for better iOS rendering.
    Swaps SHADDA+KASRA to KASRA+SHADDA for proper display.
    
    Args:
        text: Arabic text with diacritics
    
    Returns:
        Text with corrected diacritic order
    """
    chars = list(text)
    i = 0
    while i < len(chars) - 1:
        # If SHADDA (U+0651) followed by KASRA (U+0650), swap them
        if ord(chars[i]) == 0x0651 and ord(chars[i+1]) == 0x0650:
            chars[i], chars[i+1] = chars[i+1], chars[i]
            i += 2
        else:
            i += 1
    return ''.join(chars)


def fetch_surah_verses(surah_number: int) -> Dict[str, Any]:
    """
    Fetch all verses for a surah with Arabic text and translations
    
    Args:
        surah_number: Surah number (78-114)
    
    Returns:
        Dict with verses array
    """
    try:
        # Fetch Arabic text
        arabic_url = f"{BASE_URL}/quran/verses/uthmani"
        arabic_params = {"chapter_number": surah_number}
        arabic_response = requests.get(arabic_url, params=arabic_params, timeout=15)
        arabic_response.raise_for_status()
        arabic_data = arabic_response.json()
        
        # Small delay to avoid rate limiting
        time.sleep(0.3)
        
        # Fetch English translation (131 = Sahih International)
        english_url = f"{BASE_URL}/quran/translations/{ENGLISH_TRANSLATION}"
        english_params = {"chapter_number": surah_number}
        english_response = requests.get(english_url, params=english_params, timeout=15)
        english_response.raise_for_status()
        english_data = english_response.json()
        
        # Small delay to avoid rate limiting
        time.sleep(0.3)
        
        # Fetch Indonesian translation (33 = Ministry of Religious Affairs)
        indonesian_url = f"{BASE_URL}/quran/translations/{INDONESIAN_TRANSLATION}"
        indonesian_params = {"chapter_number": surah_number}
        indonesian_response = requests.get(indonesian_url, params=indonesian_params, timeout=15)
        indonesian_response.raise_for_status()
        indonesian_data = indonesian_response.json()
        
        # Combine data
        arabic_verses = arabic_data.get("verses", [])
        english_verses = english_data.get("translations", [])
        indonesian_verses = indonesian_data.get("translations", [])
        
        verses = []
        for i, arabic_verse in enumerate(arabic_verses):
            # Extract verse number from verse_key (e.g., "112:1" -> 1)
            verse_key = arabic_verse.get("verse_key", "")
            verse_number = int(verse_key.split(":")[-1]) if ":" in verse_key else i + 1
            
            # Get translations and clean HTML tags
            english_text = english_verses[i].get("text", "") if i < len(english_verses) else ""
            indonesian_text = indonesian_verses[i].get("text", "") if i < len(indonesian_verses) else ""
            
            # Clean HTML tags from translations
            english_text = clean_html_tags(english_text)
            indonesian_text = clean_html_tags(indonesian_text)
            
            # Get Arabic text and fix diacritic order for iOS rendering
            arabic_text = arabic_verse.get("text_uthmani", "")
            arabic_text = fix_diacritic_order(arabic_text)
            
            verse = {
                "number": verse_number,
                "textArabic": arabic_text,
                "textTransliteration": "",  # API doesn't provide transliteration
                "translationEnglish": english_text,
                "translationIndonesian": indonesian_text
            }
            verses.append(verse)
        
        print(f"   ✅ Fetched {len(verses)} verses")
        return {"verses": verses}
        
    except requests.RequestException as e:
        print(f"   ❌ Error fetching Surah {surah_number}: {e}")
        return {"verses": []}
    except Exception as e:
        print(f"   ❌ Unexpected error for Surah {surah_number}: {e}")
        import traceback
        traceback.print_exc()
        return {"verses": []}


def generate_juz_amma_data() -> Dict[str, Any]:
    """
    Generate complete Juz Amma data with all surahs and verses
    
    Returns:
        Dict containing complete Juz Amma data
    """
    juz_amma_data = {"juzAmma": []}
    total_verses = 0
    
    print("\n🚀 Starting Juz Amma data fetch from Quran.com API...")
    print(f"📚 Fetching surahs 78-114 with translations...")
    print("-" * 60)
    
    for surah_num in range(78, 115):
        metadata = SURAH_METADATA[surah_num]
        print(f"📖 Fetching Surah {surah_num} - {metadata['transliteration']}...")
        
        # Fetch verses
        result = fetch_surah_verses(surah_num)
        verses = result.get("verses", [])
        
        # Build surah object
        surah = {
            "number": surah_num,
            "nameArabic": metadata["name"],
            "nameTransliteration": metadata["transliteration"],
            "nameTranslation": metadata["translation"],
            "ayahCount": metadata["ayahs"],
            "revelation": metadata["revelation"],
            "ayahs": verses
        }
        
        juz_amma_data["juzAmma"].append(surah)
        total_verses += len(verses)
        
        # Progress indicator
        progress = (surah_num - 77) / 37 * 100
        print(f"   📊 Progress: {surah_num - 77}/37 surahs ({progress:.1f}%)\n")
        
        # Rate limiting
        time.sleep(1)
    
    print("-" * 60)
    print(f"✅ Fetch complete!")
    print(f"📊 Total surahs: {len(juz_amma_data['juzAmma'])}")
    print(f"📊 Total verses: {total_verses}\n")
    
    return juz_amma_data


def save_json(data: Dict[str, Any], output_file: str):
    """
    Save data to JSON file with pretty formatting
    
    Args:
        data: Data to save
        output_file: Output file path
    """
    try:
        print(f"💾 Saving to {output_file}...")
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        # Calculate file size
        import os
        file_size = os.path.getsize(output_file)
        size_kb = file_size / 1024
        
        print(f"✅ Successfully saved!")
        print(f"📊 File size: {size_kb:.2f} KB")
        print(f"📊 Surahs: {len(data['juzAmma'])}")
        
        total_verses = sum(len(surah['ayahs']) for surah in data['juzAmma'])
        print(f"📊 Total verses: {total_verses}")
        
        print("\n🚀 Next steps:")
        print("   1. Verify the JSON file in Xcode")
        print("   2. Build and run the app (Cmd+R)")
        print("   3. Test viewing all surahs with complete ayahs")
        
    except Exception as e:
        print(f"❌ Error saving file: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    # Generate data
    data = generate_juz_amma_data()
    
    # Save to file
    output_file = "JuzAmma/Resources/juz_amma_data.json"
    save_json(data, output_file)
