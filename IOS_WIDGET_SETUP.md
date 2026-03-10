# iOS Widget Extension - Інструкції з налаштування

## 🎯 Завдання
Налаштувати iOS Widget Extension для показу розкладу пар прямо на Home Screen або Lock Screen.

## 📋 Вимоги
- macOS 12+ та Xcode 14+
- iOS 14.0+
- Flutter SDK

## 🛠️ Кроки налаштування

### 1. Відкрити проект в Xcode

```bash
cd ios
open Runner.xcworkspace
```

> ⚠️ **Важливо:** Використовуйте `.xcworkspace`, а не `.xcodeproj`!

---

### 2. Додати Widget Target в Xcode

1. У Xcode виберіть **File → New → Target**
2. Оберіть **Widget Extension**
3. Введіть назву: **ScheduleWidget**
4. Переконайтесь, що **Embed in Application** = **Runner**
5. Натисніть **Create**

---

### 3. Налаштувати App Groups

#### Для основного App (Runner target):

1. Виберіть **Runner** target
2. Перейдіть на вкладку **Signing & Capabilities**
3. Натисніть **+ Capability**
4. Додайте **App Groups**
5. Введіть identifier: `group.com.uni-helper.app`

#### Для Widget Extension (ScheduleWidget target):

1. Виберіть **ScheduleWidget** target
2. Перейдіть на вкладку **Signing & Capabilities**
3. Натисніть **+ Capability**
4. Додайте **App Groups**
5. Введіть той самий identifier: `group.com.uni-helper.app`

---

### 4. Замінити файли Widget Extension

Widget Extension код вже підготовлені. Вам потрібно:

1. В Xcode видаліть умовні файли Widget Extension (якщо вони були)
2. Скопіюйте файли з папки `ios/ScheduleWidget/`:
   - `ScheduleWidget.swift`
   - `ScheduleDataManager.swift`
   - `Info.plist`

3. Переконайтесь, що всі файли додані до **ScheduleWidget** target

---

### 5. Налаштувати Build Settings

#### Для обох targets (Runner та ScheduleWidget):

1. **Build Settings** → Пошук `DEVELOPMENT_TEAM`
2. Встановіть теж саме значення для обох targets

1. **Build Settings** → Пошук `BUNDLE_ID`
   - Runner: `com.uni-helper.app`
   - ScheduleWidget: `com.uni-helper.app.ScheduleWidget`

---

### 6. Оновити Podfile (якщо потрібно)

Переконайтесь, що в `ios/Podfile` Widget target має правильне налаштування:

```ruby
post_install do |installer|
  # ... інші налаштування ...
  
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'FLUTTER_ROOT=\(flutter_root)',
      ]
    end
  end
end
```

---

### 7. Побудувати та протестувати

#### Побудувати Widget Extension:

```bash
# З папки проекту
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme ScheduleWidget \
  -configuration Debug \
  -derivedDataPath build
```

або просто натисніть **Cmd+B** в Xcode для лівого плану.

#### Запустити на пристрої/симуляторі:

```bash
flutter run
```

---

### 8. Перевірити Widget на пристрої

1. На iPhone/iPad натисніть та утримуйте на Home Screen
2. Натисніть **+ (додати)**
3. Пошук **Розклад** або **ScheduleWidget**
4. Виберіть розмірWidget (**Small** або **Medium**)
5. Натисніть **Add Widget**

---

## ✨ Функціональність Widget

Widget показує:
- ✅ Назву групи
- ✅ Кількість пар на день
- ✅ Час кожної пари (початок-кінець)
- ✅ Тип пари (лекція, практика, лаб, екзамен)
- ✅ Автоматичне оновлення кожні 15 хвилин

---

## 🔌 Інтеграція з Flutter кодом

Коли користувач завантажує розклад, додайте цей код до сторінки розкладу:

```dart
import 'package:uni_helper/services/widget_data_service.dart';

// У місці, де ви отримуєте розклад пар:
await WidgetDataService.updateScheduleWidget(
  lessons: lessons, // List<Lesson>
  groupName: groupName, // String
);
```

---

## 🐛 Можливі проблеми та рішення

### Problem: Widget не з'являється в списку
**Рішення:**
- Переконайтесь, що ScheduleWidget target має правильне `Bundle ID`
- Перевбудуйте проект (**Cmd+Shift+K**, потім **Cmd+B**)

### Problem: App Groups не работають
**Рішення:**
- Переконайтесь, що Bundle IDs однакові для обох targets
- Перевбудуйте обидва targets

### Problem: Widget показує placeholder
**Рішення:**
- Вберіть Widget з Home Screen
- Перезавантажте структуру Widget:
```dart
await WidgetDataService.updateScheduleWidget(
  lessons: lessons,
  groupName: groupName,
);
```

---

## 📚 Додаткові ресурси

- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/WidgetKit)
- [App Groups Documentation](https://developer.apple.com/documentation/foundation/userdefaults/appgroupscontainer)
- [Flutter Platform Channels](https://flutter.dev/docs/development/platform-integration/platform-channels)

---

## 🎉 Готово!

Ваш iOS Widget Extension готов до роботи! Тепер користувачі можуть бачити свій розклад прямо на екрані блокування.
