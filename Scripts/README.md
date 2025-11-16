# Quran Data Fetcher Script

## 📖 Purpose
Fetch complete Juz Amma (Juz 30) data from Quran.com API and generate `juz_amma_data.json` with all 37 surahs and their verses.

## 🚀 Usage

### Prerequisites
```bash
# Install Python 3 (should be pre-installed on macOS)
python3 --version

# Install requests library
pip3 install requests
```

### Run Script
```bash
cd /Users/febbyrg/Documents/BC/projects/JuzAmma/Scripts
python3 fetch_quran_data.py
```

### Expected Output
```
🕌 Juz Amma Data Fetcher
   Quran.com API → juz_amma_data.json
============================================================

🌙 Starting Juz Amma data generation...
📊 Total surahs to fetch: 37
============================================================
📖 Fetching Surah 78...
   ✅ Fetched 40 verses
📈 Progress: 1/37 (2.7%)
------------------------------------------------------------
📖 Fetching Surah 79...
   ✅ Fetched 46 verses
📈 Progress: 2/37 (5.4%)
------------------------------------------------------------
...
(continues for all 37 surahs)
...

💾 Saving to ../JuzAmma/Resources/juz_amma_data.json...
✅ Successfully saved

📊 Statistics:
   - Total Surahs: 37
   - Total Verses: 564
   - File size: ~500 KB

============================================================
✅ DONE! Juz Amma data generation complete!
============================================================
```

## 📦 What It Does

1. **Fetches from Quran.com API:**
   - Arabic text (Uthmani script)
   - English translation (Sahih International)
   - Indonesian translation (Ministry of Religious Affairs)

2. **Generates JSON:**
   - All 37 surahs (78-114)
   - Complete verses with:
     - Arabic text
     - English translation
     - Indonesian translation
     - (Transliteration left empty - API doesn't provide)

3. **Saves to:**
   - `JuzAmma/Resources/juz_amma_data.json`

## ⚙️ Configuration

Edit script to customize:

```python
# Change translation editions
ENGLISH_TRANSLATION = 131  # Sahih International
INDONESIAN_TRANSLATION = 33  # Indonesian Ministry

# Other English translations:
# 20 - Yusuf Ali
# 84 - Pickthall
# 85 - Dr. Mustafa Khattab

# Rate limiting (seconds between requests)
time.sleep(0.5)  # Adjust if needed
```

## 🐛 Troubleshooting

### Error: "Module 'requests' not found"
```bash
pip3 install requests
```

### Error: "API rate limit"
- Increase `time.sleep()` value in script
- Wait a few minutes and retry

### Error: "Connection timeout"
- Check internet connection
- Try again later
- Increase timeout value

## 📝 Notes

- **Transliteration**: Not provided by API, left as empty string
  - Can be added manually later for specific surahs
  - Or use separate transliteration library

- **Rate Limiting**: Script includes 0.5s delay between requests
  - Total time: ~2-3 minutes for all 37 surahs
  - Be respectful to Quran.com servers

- **Data Authenticity**: All text from Quran.com verified sources

## 🔄 Re-run Anytime

Safe to re-run script:
- Overwrites existing file
- Fetches fresh data from API
- Updates translations if API updated

## 📚 API Documentation

Quran.com API: https://api-docs.quran.com/docs/category/quran

Endpoints used:
- `/quran/verses/uthmani` - Arabic text
- `/quran/translations/{id}` - Translations
