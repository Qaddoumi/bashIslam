# bashIslam


**_bashIslam_** is a bash islamic library, forked from [pyIslam](https://github.com/abougouffa/pyIslam), it can calculates **prayer times**, **qibla** direction, convert between gregorian and **hijri**.

هي مكتبة إسلامية للغة البرمجة باش، متفرعة من [pyIslam](https://github.com/abougouffa/pyIslam) ، توفر امكانية حساب **أوقات الصلاة**، **اتجاه القبلة**، **التقويم الهجري**.

# Original Project
- [pyIslam](https://github.com/abougouffa/pyIslam)

# References
- [References](docs/References.md)

# Example Usage
for Amman, Jordan
```bash
./bashIslam.sh --lat 31.986 --lon 35.898 --timezone 3 --year 2025 --month 12 --day 28 --method 20 --madhab 1 --summer-time 0 --elevation 950
```
outputs:
```json
{
  "prayers": {
    "fajr": "06:09:00",
    "sunrise": "07:30:00",
    "dhuhr": "12:38:00",
    "asr": "15:22:00",
    "maghreb": "17:46:00",
    "ishaa": "19:08:00",
    "midnight": "23:57:00",
    "last_third": "02:01:00",
    "current_prayer": "Isha",
    "next_prayer": "Fajr",
    "left_till_next_prayer": "09:06:00"
  },
  "hijri": {
    "day": 7,
    "month": 7,
    "month_name_ar": "رجب",
    "month_name_en": "Rajab",
    "year": 1447,
    "full_ar": "7 رجب 1447",
    "full_en": "7 Rajab 1447",
    "is_last_day": "false"
  },
  "qiblah": {
    "direction": "160.70586844659732",
    "direction_dms": "160° 42' 21''"
  },
  "islamic_calendars": [
    {
      "calendar": "ummalqura_dat",
      "gregorian_date": "2025-12-28",
      "weekday": 1,
      "julian_day": 2461038,
      "hijri_date": "1447-7-8",
      "solar_hijri_date": "1404-3-7",
      "islamic_lunation_num": 17359,
      "islamic_month_length": 30
    },
    {
      "calendar": "arabian_dat",
      "gregorian_date": "2025-12-28",
      "weekday": 1,
      "julian_day": 2461038,
      "hijri_date": "1355-12--938932",
      "solar_hijri_date": "1404-3-7",
      "islamic_lunation_num": 16260,
      "islamic_month_length": -128104
    },
    {
      "calendar": "diyanet_dat",
      "gregorian_date": "2025-12-28",
      "weekday": 1,
      "julian_day": 2461038,
      "hijri_date": "1485-7-8",
      "solar_hijri_date": "1404-3-7",
      "islamic_lunation_num": 17815,
      "islamic_month_length": 30
    },
    {
      "calendar": "mabims_id_dat",
      "gregorian_date": "2025-12-28",
      "weekday": 1,
      "julian_day": 2461038,
      "hijri_date": "1372-11-3788",
      "solar_hijri_date": "1404-3-7",
      "islamic_lunation_num": 16463,
      "islamic_month_length": 30
    },
    {
      "calendar": "mabims_my_dat",
      "gregorian_date": "2025-12-28",
      "weekday": 1,
      "julian_day": 2461038,
      "hijri_date": "1377-8-3699",
      "solar_hijri_date": "1404-3-7",
      "islamic_lunation_num": 16520,
      "islamic_month_length": 30
    },
    {
      "calendar": "mabims_si_dat",
      "gregorian_date": "2025-12-28",
      "weekday": 1,
      "julian_day": 2461038,
      "hijri_date": "1367-7-4053",
      "solar_hijri_date": "1404-3-7",
      "islamic_lunation_num": 16399,
      "islamic_month_length": 29
    }
  ],
  "moon_data": [
    {
      "julian_day": 2461038.3770833332,
      "moon_position": {
        "longitude": 21.187335344322033,
        "latitude": 3.2858681269917756,
        "distance_au": 0.0024793587581687098
      },
      "sun_position": {
        "longitude": 277.38690924126843,
        "distance_au": 0.98337827402819811
      },
      "phase": {
        "elongation": 103.80042610305361,
        "angle": 76.082492817800457,
        "illumination": 0.620,
        "name": "Waxing Gibbous",
        "emoji": "🌓"
      }
    }
  ]
}
```