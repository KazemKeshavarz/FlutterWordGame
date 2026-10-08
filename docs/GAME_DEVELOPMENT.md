# مستندات توسعه بازی کلمات فارسی

این پروژه یک بازی کلمات فارسی برای Android است که با Flutter ساخته شده و در نسخه فعلی به‌صورت Offline اجرا می‌شود.

## امکانات پیاده‌سازی‌شده
- بازی مرحله‌ای آفلاین
- تعریف مراحل در JSON
- انتخاب حروف با لمس و Drag / Swipe
- نمایش مسیر انتخاب حروف
- انیمیشن Scale و Shadow هنگام انتخاب
- امکان برگشت روی حرف قبلی هنگام Drag
- ثبت دستی و خودکار کلمه
- تشخیص کلمات صحیح و غلط
- Haptic Feedback و صدای سیستمی
- سیستم سکه و Hint
- ذخیره دائمی پیشرفت با SharedPreferences
- باز شدن مرحله بعد
- نقشه مراحل
- سیستم امتیاز و Combo
- انیمیشن پایان مرحله
- نرمال‌سازی اولیه متن فارسی

## ساختار مهم پروژه
```text
lib/
├── core/
│   ├── audio/game_feedback.dart
│   ├── storage/
│   ├── theme/app_theme.dart
│   └── utils/persian_text_normalizer.dart
├── features/
│   ├── home/presentation/home_page.dart
│   └── game/
│       ├── data/local_stage_repository.dart
│       ├── domain/stage.dart
│       └── presentation/
│           ├── game_page.dart
│           ├── stage_map_page.dart
│           └── widgets/letter_board.dart
└── assets/data/stages.json
```

## معماری
مرحله‌ها از `assets/data/stages.json` خوانده می‌شوند. `LocalStageRepository` عمداً جداست تا در آینده با `ApiStageRepository` جایگزین شود.

مسیر آینده:
```text
Flutter → StageRepository → ApiStageRepository → ASP.NET Core API → Database
```

## اقتصاد بازی
- شروع بازی: 100 سکه
- تکمیل هر مرحله: 20 سکه
- Hint: 10 سکه
- جایزه تکمیل هر مرحله فقط یک بار پرداخت می‌شود.

## امتیاز و Combo
- هر کلمه صحیح حداقل 10 امتیاز دارد.
- کلمات صحیح پشت‌سرهم Combo ایجاد می‌کنند.
- کلمه اشتباه یا تکراری Combo را قطع می‌کند.
- در آینده می‌توان امتیاز طول کلمه، زمان، ستاره و رکورد شخصی را اضافه کرد.

## سیستم صدا
فعلاً از Haptic Feedback و صدای داخلی سیستم استفاده می‌شود. برای نسخه حرفه‌ای پیشنهاد می‌شود `AudioService` مستقل ایجاد شود و فایل‌های صوتی زیر اضافه شوند:
```text
assets/audio/
├── letter_select.mp3
├── word_correct.mp3
├── word_wrong.mp3
├── hint.mp3
├── combo.mp3
└── stage_complete.mp3
```

## نرمال‌سازی فارسی
`PersianTextNormalizer` حروف عربی/فارسی را یکسان می‌کند و برخی حرکات، کشیده و نیم‌فاصله را هنگام مقایسه حذف می‌کند.

## دیتای مراحل
داده مراحل در `assets/data/stages.json` قرار دارد. کلمات باید رایج، معتبر، بدون تکرار و سازگار با حروف همان مرحله باشند. سختی مراحل نیز باید به‌تدریج افزایش پیدا کند.

## نقشه توسعه
- [x] MVP آفلاین
- [x] بازی مرحله‌ای
- [x] ذخیره پیشرفت
- [x] سکه و Hint
- [x] Drag حروف
- [x] Feedback
- [x] Score و Combo
- [x] انیمیشن پایان مرحله
- [ ] صدای اختصاصی
- [ ] Confetti حرفه‌ای
- [ ] انیمیشن باز شدن مرحله
- [ ] ستاره و رتبه مرحله
- [ ] بازبینی و افزایش دیتای کلمات
- [ ] Daily Challenge
- [ ] Backend و حساب کاربری

## اجرای پروژه
```bash
flutter pub get
flutter run
flutter build apk --release
```

این مستندات باید همزمان با تغییرات مهم معماری و قابلیت‌های بازی به‌روزرسانی شود.