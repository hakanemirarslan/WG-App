# WG App: Proje Plani

**Konumlandirma:** WG icin: eksikleri listele, alisverisi yap, masrafi otomatik bol.
**Teknoloji:** Flutter (Dart) + Supabase. Once web, sonra ayni koddan Android/iOS.
**Gelistirme ortami:** Windows. Web ve Android burada derlenir; iOS derlenemez (bkz. Platform stratejisi).

> **Bu dosya "ne zaman, ne yapilacak" sorusunu cevaplar.** Nasil calisacagi (bakiye hesabi, bolusum kurallari, ekranlar, kenar durumlar, yayin) icin `SPEC.md`, veritabani icin `../supabase/schema.sql`.
> Her hafta basliginin yanindaki **[SPEC Bolum X]** o haftanin kurallarinin yazili oldugu yerdir. Bir sey bitince kutuyu isaretle: `- [x]`.

## Temel urun kararlari

1. **Liste ve harcama ayri.** Liste sadece "neye ihtiyacimiz var" (fiyat/odeme yok). Harcamayi odeyen yazar: ne aldi, ne kadar odedi, kimleri kapsiyor.
2. **Opsiyonel baglanti:** Harcama girerken listedeki kalemler secilebilir ama zorunlu degil.
3. **Direkt harcama girisi** listesiz de mumkun.
4. **Hizli urun secici:** Hazir katalog + arama + grubun sik kullandiklari yukarida. Harcamada sadece fiyat girilir. Katalogda yoksa serbest yaz.
5. **Diller:** Almanca ve Ingilizce, kullanici profilden secer.
6. **Para:** Cent olarak tam sayi sakla.
7. **Tasinma:** `memberships.left_at`. Ayrilan gecmiste kalir, yenilere dahil edilmez.
8. **Python nerede?** V1'de yok, borc algoritmasi Dart'ta. V2'de sadece fis okuma icin FastAPI servisi.
9. **Kitle:** Ev arkadaslari (WG). Gezi/etkinlik gruplari V1 disi; veri modeli ileride "grup turu" eklenebilecek kadar esnek.

## Platform stratejisi

| Hedef | Windows'ta derlenir mi | Plan |
|---|---|---|
| Web (Chrome, masaustu) | Evet | V1'in ana hedefi |
| iPhone (Safari, PWA: "Ana Ekrana Ekle") | Evet (web olarak) | V1'de WG'dekiler bu sekilde kullanir |
| Android | Evet | V1 sonrasi, istege bagli: emulator/telefonda test, sonra Play Store |
| iOS mağaza uygulamasi | **Hayir** (Xcode/macOS gerekir) | V2+: bulutta macOS derleme (Codemagic / GitHub Actions) + Apple Developer Program (~99 USD/yil, guncel fiyati dogrula) |

Karar: iOS mağaza surumu icin simdi hicbir sey yapilmaz. Kod tabani degismeyecegi icin bu karar ertelenebilir.

## Haftalik MVP plani (4-6 hafta)

### Hafta 0: Kurulum (1-2 gun) **[SPEC 15]**
- [x] Proje klasoru OneDrive disinda bir yerde (ornek `C:\dev\wg-app`); senkronize klasorler build dosyalariyla sorun cikarir
- [x] Supabase projesi acildi, `supabase/schema.sql` SQL Editor'de calistirildi (hata cikarsa mesaji kaydet)
- [x] Supabase'de gelistirme icin e-posta dogrulamasi kapatildi (Authentication > Providers > Email > "Confirm email"; arayuz degismis olabilir), yoksa test kayitlari dogrulama maili bekler
- [x] Flutter SDK kuruldu (`flutter doctor` temiz; Windows icin Chrome ve Android Studio/cmdline-tools kontrolu)
- [x] Proje bu klasorun icinde olusturuldu: `flutter create . --project-name wg_app --platforms web,android`
- [x] Paketler eklendi: `supabase_flutter`, `go_router`, `flutter_riverpod`, `intl`
- [x] `env.example.json` -> `env.json` kopyalandi, URL + **anon** key dolduruldu; `.gitignore` `env.json`'u iceriyor
- [x] Bos uygulama `flutter run -d chrome --dart-define-from-file=env.json` ile aciliyor, Supabase'e bir sorgu atiliyor
- [x] Git deposu ve ilk commit (commit oncesi gizli anahtar kontrolu)

### Hafta 1: Dart'a alisma + Auth + dil **[SPEC 11, 12, 13]**
- [ ] Klasor yapisi kuruldu
- [ ] `core/money.dart` + testleri (cent <-> gosterim, parse)
- [ ] l10n altyapisi (`app_de.arb`, `app_en.arb`), ilk metinler
- [ ] Kayit, giris, cikis; oturum sayfa yenilenince devam ediyor
- [ ] Profil: gorunen ad, dil secimi (DE/EN), `profiles.locale`'e kaydediliyor
- [ ] go_router ile giris durumuna gore yonlendirme; path-tabanli URL (hash yok)

### Hafta 2: Gruplar **[SPEC 10, 15]**
- [ ] Grup olustur (`create_group`), grup secim ekrani
- [ ] Davet linki uret/paylas, `/join/<code>` ile katilma (girissiz ise once giris); lokalde sayfa yenilemede calisiyor
- [ ] Uye listesi, rol gosterimi
- [ ] Gruptan ayrilma (tek admin kurali, bakiye uyarisi hazirligi)
- [ ] Iki tarayici profiliyle elle test: baska grubun verisi gorunmuyor
- [ ] Sema bosluklari: SPEC 13, madde 4 ve 5

### Hafta 3: Eksik listesi + urun secici **[SPEC 6, 7]**
- [ ] Katalog verisi okunuyor, kategoriye gore listeleniyor
- [ ] Urun secici sheet: arama (DE/EN, umlaut duyarsiz), sik kullanilanlar, serbest ekleme
- [ ] `group_items` olusturma + `touch_group_item` sayaci
- [ ] Listeye ekleme (not ile), ayni urun tekrari kontrolu
- [ ] "Alindi" isaretleme, "Son alinanlar", geri alma
- [ ] Realtime: baska tarayicida yenilemeden guncelleniyor
- [ ] Sema bosluklari: SPEC 13, madde 3 ve 7

### Hafta 4: Harcamalar **[SPEC 3, 8]**
- [ ] Bolusum mantigi (`domain/split.dart`) + testleri: esit, tutar, pay orani, yuvarlama (334/333/333)
- [ ] Harcama formu: tutar, odeyen, kimleri kapsiyor, mod secimi
- [ ] Opsiyonel kalemler (urun secici cok secimli), otomatik aciklama
- [ ] Harcama + paylar + kalemler tek islemde kayit (RPC)
- [ ] Harcama listesi, detay, duzenleme/silme (yetki kurali)
- [ ] Sema bosluklari: SPEC 13, madde 1 (dogrulanmis acik), 2 ve 5

### Hafta 5: Bakiye ve hesaplasma **[SPEC 4, 5, 9]**
- [ ] `domain/debt_simplifier.dart` + 6 zorunlu test senaryosu (once testler)
- [ ] Bakiye hesabi (harcama + pay + settlement), toplam = 0 kontrolu
- [ ] Bakiye ekrani, onerilen odemeler
- [ ] "Odendi" ile settlement kaydi
- [ ] Aylik ozet ekrani
- [ ] Eski uye bakiyesi gosterimi
- [ ] Sema bosluklari: SPEC 13, madde 6

### Hafta 6: Cila ve yayin **[SPEC 15, 16]**
- [ ] Bos / hata / yukleniyor durumlari tum ekranlarda
- [ ] Telefon genisliginde (iPhone Safari dahil) kullanilabilirlik; PWA manifest + ikon, "Ana Ekrana Ekle" denendi
- [ ] `flutter build web` + deploy (Firebase Hosting / Vercel / Netlify) ve **tum yollari `index.html`'e yonlendirme kurali**; `/join/<code>` canlida sayfa yenilemede calisiyor
- [ ] Kalici alan adi secildi (davet linkleri `/join/<code>` ileride mobil uygulamada da calisacak, adres sonradan degismemeli; SPEC 15)
- [ ] Supabase Auth: Site URL + Redirect URL canli adres; e-posta dogrulama karari
- [ ] Supabase ucretsiz katman durdurma/yedek durumu kontrol edildi
- [ ] Gizlilik: Datenschutzerklaerung / Impressum konusunda kullanici arastirma yapti ve karar verdi (SPEC 16); hesap silme davranisi netlesti
- [ ] WG'de en az 2 kisiyle gercek kullanim, geri bildirim notlari
- [ ] README: neden bu proje, Splitwise'dan farki, mimari, ekran goruntuleri, canli link
- [ ] Sema bosluklari listesi (SPEC 13) tamamen kapandi

## Sonraki surumler (V2+)

- Tekrarlayan giderler (kira, internet, elektrik, Rundfunkbeitrag)
- **Python servisi (FastAPI): fis fotografindan kalem okuma.** OCR/LLM cagrilari Flutter'da yapilmaz, bu yuzden Python'un dogal yeri burasi. Akis: Flutter fotografi yukler -> FastAPI servisi Supabase token'ini dogrular -> OCR/LLM ile kalemleri cikarir -> kalemler harcama formuna taslak olarak gelir. Barindirma: Fly.io / Render / Railway. `expense_items` tablosu buna hazir.
- PayPal.me / IBAN odeme linkleri
- Hatirlatmalar ve bildirimler
- Android Play Store surumu (Windows'ta derlenir)
- iOS App Store surumu (bulutta macOS derleme + Apple Developer Program, bkz. Platform stratejisi). On kosullar:
  - [ ] iOS platformu eklenir: `flutter create . --platforms ios` (Windows'ta klasor olusur, derleme macOS'ta olur)
  - [ ] Bulutta macOS derleme kurulur (Codemagic veya GitHub Actions macOS runner), Apple Developer Program uyeligi alinir (guncel fiyat/kosullari Apple'dan dogrula)
  - [ ] **Davet linkleri:** `/join/<code>` adresinin uygulamada acilmasi icin iOS universal links (ve Android app links) ayari; web'de ek is yok
  - [ ] **Uygulama icinden hesap silme** (Apple, hesap olusturan uygulamalardan bunu istiyor; guncel kurali Apple'dan dogrula). Davranis icin SPEC 16'ya bak. Bu madde mağaza surumunden once zorunlu
  - [ ] TestFlight ile gercek iPhone'da test, sonra App Store incelemesi (gizlilik politikasi ve App Privacy bilgileri hazir olmali)
- Gezi/etkinlik grup turu

## Portfoy icin not

README'de sunlari anlat: neden Splitwise yerine bu (liste + harcama akisi, WG'ye ozel tasinma mantigi), neden Supabase RLS (ve gecici bir PostgreSQL'de yapilan izolasyon testi), borc sadelestirme algoritmasi, para icin cent kullanimi, canli link ve ekran goruntuleri.

## Calisma notlari (kendin icin)

<!-- Her oturum sonunda buraya 1-2 satir: ne bitti, nerede kaldin, siradaki adim. -->
- 2026-10-17: Hafta 0 bitti. Git repo + ilk commit, Flutter projesi olusturuldu (web+android), paketler eklendi, `lib/core/supabase_client.dart` ile baglanti kuruldu, `flutter run -d chrome` ile acilip `catalog_items` sorgusu atildi (RLS nedeniyle 0 satir, beklenen). `flutter analyze` temiz. Henuz domain kodu yok, `flutter test` icin test dosyasi yok (Hafta 1'de `money.dart` ile baslayacak). Siradaki adim: Hafta 1 - klasor yapisi, `core/money.dart` + testleri, l10n, auth (kayit/giris/cikis), dil secimi.
