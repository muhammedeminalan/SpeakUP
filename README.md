# SpeakUP 🗣️

İngilizce kelime ve cümle öğrenme uygulaması — **SwiftUI** ile geliştirilmiştir.
Flutter ile yazılmış [SozTrail] uygulamasının native iOS portudur.

## Özellikler

- 📚 **6 bölümlük içerik** — 650+ kelime, 370+ cümle (bundle JSON)
- ❓ **Kelime Quiz** — 4 şıklı test, yanlış yapılan kelimeler daha sık sorulur (ağırlıklı seçim)
- 🧩 **Cümle Kur** — kelimelere tıklayarak doğru cümleyi dizme
- 🔄 **TR ↔ EN yön seçimi** — her iki yönde de çalışma
- 📊 **İlerleme takibi** — öğrenilen / tekrar edilecek ayrımı, donut grafik
- 🔊 **Sesli okuma (TTS)** — İngiliz / Amerikan / Türkçe aksan, ayarlanabilir hız
- ⏸️ **Ara ver & devam et** — yarım kalan quiz kaldığı yerden sürer
- 👈 **Swipe ile geçmiş** — cevaplanan sorulara geri dönüp bakma
- 🌗 **Açık / koyu tema** — dinamik renklerle tam uyum
- 🔤 **Ayarlanabilir metin boyutu** — 14–32 pt

## Teknolojiler

| Konu | Tercih |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Mimari | MVVM + Clean Architecture |
| State | `@Observable` (Observation framework) |
| Navigasyon | Router + `NavigationPath` |
| Kalıcılık | SwiftData + UserDefaults |
| Ses | AVSpeechSynthesizer |

## Kurulum

```bash
git clone https://github.com/muhammedeminalan/SpeakUP.git
open SpeakUP/SpeakUP.xcodeproj
```

Xcode 16+ ile derleyin, ek bağımlılık yoktur.

## Geliştirici

**Muhammed Emin Alan** — [GitHub](https://github.com/muhammedeminalan)
