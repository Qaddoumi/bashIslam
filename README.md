# bashIslam


**_bashIslam_** is a bash islamic library, forked from [pyIslam](https://github.com/abougouffa/pyIslam), it can calculates **prayer times**, **qibla** direction, convert between gregorian and **hijri**.

هي مكتبة إسلامية للغة البرمجة باش، متفرعة من [pyIslam](https://github.com/abougouffa/pyIslam) ، توفر امكانية حساب **أوقات الصلاة**، **اتجاه القبلة**، **التقويم الهجري**.

# Original Project
- [pyIslam](https://github.com/abougouffa/pyIslam)

# References
- [References](docs/References.md)

# Example
for Amman, Jordan
```bash
./bashIslam.sh --lat 31.986 --lon 35.898 --timezone 3 --year 2025 --month 12 --day 24 --method 20 --madhab 1 --summer-time 0 --elevation 950
```
outputs:
```json
{
  "prayers": {
    "fajr": "06:07:00",
    "sunrise": "07:29:00",
    "dhuhr": "12:36:00",
    "asr": "15:20:00",
    "maghreb": "17:44:00",
    "ishaa": "19:05:00",
    "midnight": "23:55:00",
    "last_third": "01:59:00"
  },
  "hijri": {
    "day": 3,
    "month": 7,
    "month_name_ar": "رجب",
    "month_name_en": "Rajab",
    "year": 1447,
    "full_ar": "3 رجب 1447",
    "full_en": "3 Rajab 1447",
    "is_last_day": "false"
  },
  "qiblah": {
    "direction": "160.70586844659732",
    "direction_dms": "160° 42' 21''"
  }
}
```