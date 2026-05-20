# AirScript

AirScript, Flutter kullanılarak geliştirilmiş hareket tabanlı akıllı çizim ve harf tanıma uygulamasıdır. Proje kapsamında kullanıcılar cihaz hareketlerini kullanarak havada çizim yapabilmekte, oluşturdukları çizimleri kaydedebilmekte ve yapay zeka destekli tahmin sistemi ile çizilen şekillerin hangi harfe benzediğini analiz edebilmektedir.

Uygulama içerisinde kullanıcı doğrulama işlemleri klasik şifre yapısı yerine imza tabanlı kimlik doğrulama sistemi ile gerçekleştirilmiştir. Kullanıcılar kayıt olurken kendi imzalarını oluşturarak sisteme kaydolmakta, giriş yaparken ise yeniden çizdikleri imza ile doğrulanmaktadır. Böylece biyometrik doğrulamaya benzer alternatif bir giriş sistemi geliştirilmiştir.

Projede çizim verileri SQLite veritabanında kullanıcı bazlı olarak saklanmakta, Firebase altyapısı ile bulut tabanlı veri yönetimi desteklenmektedir. Harf tanıma sistemi kullanıcı geri bildirimleri ile öğrenebilen bir yapıya sahiptir. Sistem başlangıçta temel şekil analizleri ile tahmin üretirken, kullanıcı düzeltmeleri sayesinde zamanla daha doğru sonuçlar vermeye başlamaktadır.

Uygulama modern Flutter arayüz bileşenleri kullanılarak geliştirilmiş olup katmanlı yazılım mimarisi yaklaşımı benimsenmiştir. Ayrıca proje kapsamında yazılım sınama ve doğrulama süreçleri için unit testler gerçekleştirilmiş ve sistemin temel işlevleri test edilmiştir.

## Özellikler

- Hareket tabanlı çizim sistemi
- Yapay zeka destekli harf tahmini
- İmza tabanlı kullanıcı doğrulama sistemi
- Çok kullanıcılı yapı
- SQLite tabanlı yerel veritabanı
- Firebase entegrasyonu
- Öğrenebilen harf tanıma sistemi
- Çizim kaydetme ve görüntüleme
- Unit test desteği

## Kullanılan Teknolojiler

- Flutter
- Dart
- SQLite
- Firebase Firestore
- SharedPreferences

## Yazılım Mimarisi

Projede katmanlı yazılım mimarisi kullanılmıştır.

- Presentation Layer (UI)
- Service Layer (İş mantığı)
- Data Layer (Veri yönetimi)

## Testler

Projede aşağıdaki sistemler için unit testler gerçekleştirilmiştir:

- Harf tanıma sistemi
- İmza doğrulama sistemi
- Çizim modeli veri dönüşümleri

## Geliştirici

Hayrünisa Güneş
