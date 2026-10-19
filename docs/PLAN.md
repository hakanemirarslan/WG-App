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
- [x] Klasor yapisi kuruldu (`features/groups`, `shopping_list`, `expenses`, `catalog`, `balances` ilgili haftada acilacak)
- [x] `core/money.dart` + testleri (cent <-> gosterim, parse)
- [x] l10n altyapisi (`app_de.arb`, `app_en.arb`), ilk metinler
- [x] Kayit, giris, cikis; oturum sayfa yenilenince devam ediyor
- [x] Profil: gorunen ad, dil secimi (DE/EN), `profiles.locale`'e kaydediliyor
- [x] go_router ile giris durumuna gore yonlendirme; path-tabanli URL (hash yok)

### Hafta 2: Gruplar **[SPEC 10, 15]**
- [x] Grup olustur (`create_group`), grup secim ekrani
- [x] Davet linki uret/paylas, `/join/<code>` ile katilma (girissiz ise once giris); lokalde sayfa yenilemede calisiyor
- [x] Uye listesi, rol gosterimi
- [x] Gruptan ayrilma (tek admin kurali, bakiye uyarisi hazirligi)
- [x] Iki tarayici profiliyle elle test: baska grubun verisi gorunmuyor
- [x] Sema bosluklari: SPEC 13, madde 4 (kapandi); madde 5 harcama haftasina (Hafta 4) tasindi

### Hafta 3: Eksik listesi + urun secici **[SPEC 6, 7]**
- [x] Katalog verisi okunuyor, kategoriye gore listeleniyor
- [x] Urun secici sheet: arama (DE/EN, umlaut duyarsiz), sik kullanilanlar, serbest ekleme
- [x] `group_items` olusturma + `touch_group_item` sayaci
- [x] Listeye ekleme (not ile), ayni urun tekrari kontrolu
- [x] "Alindi" isaretleme, "Son alinanlar", geri alma
- [x] Realtime: baska tarayicida yenilemeden guncelleniyor
- [x] Sema bosluklari: SPEC 13, madde 3 ve 7

### Hafta 4: Harcamalar **[SPEC 3, 8]**
- [x] Bolusum mantigi (`domain/split.dart`) + testleri: esit, tutar, pay orani, yuvarlama (334/333/333)
- [x] Harcama formu: tutar, odeyen, kimleri kapsiyor, mod secimi
- [x] Opsiyonel kalemler (urun secici cok secimli), otomatik aciklama
- [x] Harcama + paylar + kalemler tek islemde kayit (RPC)
- [x] Harcama listesi, detay, duzenleme/silme (yetki kurali)
- [x] Sema bosluklari: SPEC 13, madde 1 (dogrulanmis acik), 2 ve 5

### Hafta 5: Bakiye ve hesaplasma **[SPEC 4, 5, 9]**
- [x] `domain/debt_simplifier.dart` + 6 zorunlu test senaryosu (once testler)
- [x] Bakiye hesabi (harcama + pay + settlement), toplam = 0 kontrolu
- [x] Bakiye ekrani, onerilen odemeler
- [x] "Odendi" ile settlement kaydi
- [x] Aylik ozet ekrani
- [x] Eski uye bakiyesi gosterimi
- [x] Sema bosluklari: SPEC 13, madde 6

### Hafta 6: Cila ve yayin **[SPEC 15, 16]**
- [ ] Gorsel tasarim (tum ozellikler bittikten sonra, bilincli olarak en sona birakildi): merkezi `lib/core/theme.dart` (renk, yazi tipi, bilesen stilleri, acik/koyu tema), ekranlarda tema disi renk/stil kalmadi
- [x] Bos / hata / yukleniyor durumlari tum ekranlarda
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
- 2026-10-17: Hafta 1 bitti. `core/money.dart` + 11 test; l10n altyapisi (`l10n.yaml`, `app_de.arb`/`app_en.arb`, uretilen dosyalar gitignore'da); `features/auth` (kayit/giris/cikis, Supabase oturum stream'i) ve `features/settings` (gorunen ad + dil, `profiles` tablosuna yaziyor); `core/router.dart` go_router ile oturum durumuna gore yonlendirme, path-tabanli URL (`usePathUrlStrategy`). Riverpod 3'te `StateProvider` icin `package:flutter_riverpod/legacy.dart` import etmek gerekti (v3'te varsayilan export'tan cikarilmis). Gercek Supabase projesinde "Confirm email" baslangicta acik kalmisti, kapatilinca kayit/oturum aninda acildi (bkz. SPEC 15). Tum akis (kayit, sayfa yenileme, ayarlar, cikis, giris) elle web'de denendi, calisiyor. Siradaki adim: Hafta 2 - gruplar (`create_group`, davet linki, `/join/<code>`, ayrilma), sema bosluklari SPEC 13 madde 4-5.
- 2026-10-18: Hafta 2 bitti. `leave_group` (not_a_member, last_admin) guncellendi, `set_member_role` RPC'si eklendi (SPEC 13 madde 4 kapandi). `features/groups`: grup listesi/olusturma, `/group/:id` (uyeler, admin devri, davet linki, ayrilma), `/join/:code`; girissiz kullanici `/login?from=...` ile geri donuyor. Elle denendi, sorunsuz. Madde 5 (paid_by/share uyelik dogrulamasi) Hafta 4'e kaldi. Siradaki adim: Hafta 3 - katalog, urun secici, alisveris listesi, realtime.
- 2026-10-19: Hafta 3 bitti. Alt gezinme kabugu (Liste/Harcamalar/Saldo/Grup; sekmeler `/group/:id` altinda alt rota, cunku go_router StatefulShellBranch varsayilan rotasinda path parametresi istemiyor). `features/catalog` + `features/shopping_list`: urun secici sheet (umlaut duyarsiz arama `domain/text_search.dart`, sik kullanilanlar, serbest urun), `get_or_create_group_item` RPC, tekrar kontrolu, alindi/geri al/sil, Realtime (DELETE olaylari group_id ile filtrelenemedigi icin filtresiz ikinci abonelik). Sema: unique index'ler, `shopping_entries` silme yetkisi ekleyen/admin. Iki kullaniciyla elle denendi. Dersler: Supabase SQL Editor'e yapistirirken eski metin kalintisi sorun cikardi (once Ctrl+A/Delete); Riverpod 3 hata ekraninda `ProviderException` asil hatayi 'A provider threw...' altinda gosteriyor. Siradaki adim: Hafta 4 - `domain/split.dart` + testler, harcama formu, harcama RPC'si, SPEC 13 madde 1, 2, 5.
- 2026-10-19: Hafta 4 bitti. `domain/split.dart` (esit/agirlik/tutar, 334/333/333 yuvarlama) + 22 test; `core/money.dart`'a `parseShareCents` ve `formatCentsPlain`; `save_expense` RPC (atomik kayit, toplam/uyelik/yetki kontrolu) ve expenses/expense_items/expense_shares icin dogrudan yazma policy'leri kaldirildi (SPEC 13 madde 1, 2, 5 kapandi); `features/expenses`: liste (Realtime), form (ekleme/duzenleme, 3 bolusum modu, odeyen, tarih, urunler), detay, silme. Urun secici cok secimli modu (`showProductMultiPicker`); acilama bos birakilirsa baslik gosterimde urun adlarindan uretiliyor. Bolusum modu saklanmiyor: duzenlemede paylar esit bolusumle ayniysa 'Gleich', degilse 'Betraege' acilir. Elle iki kullaniciyla denendi. Siradaki adim: Hafta 5 - `domain/debt_simplifier.dart` + 6 zorunlu test (once testler), bakiye hesabi, bakiye ekrani, 'Odendi' settlement, aylik ozet, SPEC 13 madde 6.
- 2026-10-19: Hafta 5 bitti. `domain/debt_simplifier.dart` (6 zorunlu senaryo + davranis testleri), `domain/balance.dart` ve `domain/monthly_summary.dart` (testli, 67 test toplam); `record_settlement` RPC + settlements icin dogrudan yazma kapali (SPEC 13 madde 6 kapandi; tum sema bosluklari artik kapali); `features/balances`: canli bakiye ekrani (isaretli tutarlar), onerilen odemeler, 'Odendi' onay penceresiyle, aylik ozet (ay sonu bakiyesi o ayin sonuna kadar), gruptan ayrilirken 'hesabin kapanmadi' uyarisi, eski uye '(ehemaliges Mitglied)' etiketiyle. Ayarlar'dan geri donus `push` ile duzeltildi. Elle iki kullaniciyla denendi. Denenmedi: transferin tarafi olmayan ucuncu kullanicida 'Odendi' dugmesinin gizlenmesi (ucuncu hesap yoktu; yetki sunucuda `record_settlement` ile de zorlaniyor) ve gercekten gruptan ayrilip eski uye olarak bakiye gosterimi. Geri alma V1'de yok. Siradaki adim: Hafta 6 - bos/hata/yukleniyor durumlari, telefon genisligi, PWA, deploy, gizlilik karari, gorsel tasarim (en sona), README.
