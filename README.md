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
./bashIslam.sh --lat 31.986 --lon 35.898 --timezone 3 --year 2025 --month 12 --day 25 --method 20 --madhab 1 --summer-time 0 --elevation 950
```
outputs:
```json
{
  "prayers": {
    "fajr": "06:07:00",
    "sunrise": "07:29:00",
    "dhuhr": "12:37:00",
    "asr": "15:20:00",
    "maghreb": "17:44:00",
    "ishaa": "19:06:00",
    "midnight": "23:56:00",
    "last_third": "02:00:00"
  },
  "hijri": {
    "day": 4,
    "month": 7,
    "month_name_ar": "رجب",
    "month_name_en": "Rajab",
    "year": 1447,
    "full_ar": "4 رجب 1447",
    "full_en": "4 Rajab 1447",
    "is_last_day": "false"
  },
  "qiblah": {
    "direction": "160.70586844659732",
    "direction_dms": "160° 42' 21''"
  },
  "islamic_calendars": [
    {
      "calendar": "ummalqura_dat",
      "gregorian_date": "2025-12-25",
      "weekday": 5,
      "julian_day": 2461035,
      "hijri_date": "1447-7-5",
      "solar_hijri_date": "1404-3-4",
      "islamic_lunation_num": 17359,
      "islamic_month_length": 30
    },
    {
      "calendar": "arabian_dat",
      "gregorian_date": "2025-12-25",
      "weekday": 5,
      "julian_day": 2461035,
      "hijri_date": "1355-12--938935",
      "solar_hijri_date": "1404-3-4",
      "islamic_lunation_num": 16260,
      "islamic_month_length": -128104
    },
    {
      "calendar": "diyanet_dat",
      "gregorian_date": "2025-12-25",
      "weekday": 5,
      "julian_day": 2461035,
      "hijri_date": "1485-7-5",
      "solar_hijri_date": "1404-3-4",
      "islamic_lunation_num": 17815,
      "islamic_month_length": 30
    },
    {
      "calendar": "mabims_id_dat",
      "gregorian_date": "2025-12-25",
      "weekday": 5,
      "julian_day": 2461035,
      "hijri_date": "1372-11-3785",
      "solar_hijri_date": "1404-3-4",
      "islamic_lunation_num": 16463,
      "islamic_month_length": 30
    },
    {
      "calendar": "mabims_my_dat",
      "gregorian_date": "2025-12-25",
      "weekday": 5,
      "julian_day": 2461035,
      "hijri_date": "1377-8-3696",
      "solar_hijri_date": "1404-3-4",
      "islamic_lunation_num": 16520,
      "islamic_month_length": 30
    },
    {
      "calendar": "mabims_si_dat",
      "gregorian_date": "2025-12-25",
      "weekday": 5,
      "julian_day": 2461035,
      "hijri_date": "1367-7-4050",
      "solar_hijri_date": "1404-3-4",
      "islamic_lunation_num": 16399,
      "islamic_month_length": 29
    }
  ],
  "moon_data": [
    {
      "julian_day": 2461035.3340277779,
      "moon_position": {
        "longitude": 340.10661544085542,
        "latitude": -0.092124726270654031,
        "distance_au": 0.0025734987037475234
      },
      "sun_position": {
        "longitude": 274.28607050438029,
        "distance_au": 0.98349302691636931
      },
      "phase": {
        "elongation": 65.82054493647513,
        "angle": 114.04250325916789,
        "illumination": 0.296,
        "name": "First Quarter",
        "emoji": "🌒"
      }
    }
  ]
}
```