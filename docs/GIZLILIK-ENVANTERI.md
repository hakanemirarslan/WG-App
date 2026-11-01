# Gizlilik: teknik veri envanteri

Bu dosya **hukuki tavsiye degildir.** Datenschutzerklaerung ve Impressum icin ne gerektigine kullanici karar verir (SPEC 16). Burada sadece uygulamanin teknik olarak ne topladigi yazar; politikayi yazacak kisi icin girdidir. Son guncelleme: 2026-11-01.

## Toplanan veriler

| Veri | Nerede | Not |
|---|---|---|
| E-posta, parola (hash'li) | Supabase `auth.users` | Giris icin. Parolayi Supabase Auth yonetir, kodda duz metin yok. |
| Gorunen ad | `profiles.display_name` | Gruptaki herkes gorur. Kayitta zorunlu; bos gelirse e-postanin `@` oncesi kullanilir (`handle_new_user`). |
| Ad, soyad, telefon numarasi | `profile_private` | Kayitta **istege bagli (opsiyonel)**; kullanici rizasina dayali (Art. 6 Abs. 1 lit. a DSGVO) olarak saklanir (2026-11-01 karari). **Sadece kisinin kendisi gorur** (RLS: `id = auth.uid()`); grup uyeleri dahil kimse goremez. Bos birakilirsa NULL. Ayarlarda alan bosaltilip kaydedilince deger silinir (riza geri alma). 2026-11-01'den itibaren `auth.users.raw_user_meta_data`'ya **yazilmaz** (kayittan sonra dogrudan `profile_private`'a); 2026-10-25 ile 2026-11-01 arasi kayit olanlarda eski bir kopya metadata'da kalmis olabilir (temizleme SQL'i ayri). Telefon ulke kodlu saklanir (`+491512345678`), dogrulanmaz (SMS yok). Su an uygulamada baska bir islevde kullanilmiyor. |
| Dil tercihi | `profiles.locale` | `de` / `en` / `tr`. |
| Grup uyeligi, rol, katilma/ayrilma zamani | `memberships` | Ayrilinca kayit silinmez, `left_at` dolar. |
| Alisveris listesi, harcamalar, paylar, odemeler | `shopping_entries`, `expenses`, `expense_items`, `expense_shares`, `settlements` | Kim ekledi / kim odedi / ne zaman bilgisiyle. |
| Davet kodlari | `invites` | 7 gun gecerli, olusturan kisi kayitli. |
| Oturum | Tarayici deposu (Supabase oturumu) | Ucuncu taraf analitik/izleme yok. |
| Tema tercihi (Sistem/Acik/Koyu) | Tarayici deposu (`localStorage`, `shared_preferences`), cihaz basina | Kisisel veri degil, sunucuya gitmez (2026-10-26). |

## Ucuncu taraf istekleri

- **Barindirma (web uygulamasi):** Cloudflare Workers, statik dosyalar (Cloudflare, Inc., ABD). Adres `<proje>.<alt-alan>.workers.dev` (gecici; ileride kendi alan adi). Uygulama dosyalari buradan sunulur; Cloudflare erisim sirasinda baglanti verisi (IP vb.) isler. 2026-11-01 itibariyla henuz yuklenmedi (Datenschutz/Impressum bekleniyor).
- **Supabase** (veritabani, auth): tum veri burada. Proje bolgesi ve veri isleme sozlesmesi kullanici tarafindan kontrol edilecek.
- **Google CDN (2026-10-24'te denendi):** `flutter build web` varsayilan olarak CanvasKit'i `www.gstatic.com/flutter-canvaskit` ve yedek fontlari `fonts.gstatic.com` adresinden ceker; ziyaretci IP'si Google'a gider. `--no-web-resources-cdn` ile derlenince CanvasKit ve Roboto yedek fontu kendi alan adindan gelir (`useLocalCanvasKit: true`, `assets/fonts/fallback/Roboto-Regular.ttf`). **Kalan istisna:** Inter/Roboto'nun karsilamadigi bir karakter (ornek: urun adina yazilan emoji) gorunurse Flutter eksik yedek fontu `fonts.gstatic.com/s/` adresinden indirir. Karar: Datenschutzerklaerung'da bir cumleyle belirtilir. Build ciktisinin statik incelemesi yapildi; canli adreste tarayici Network sekmesiyle dogrulanmali.
- Uygulama fontu (Inter) pakete gomulu, dis istek yok.

## Hesap silme (V1'de uygulandi, 2026-11-01)

- **Uygulamada:** Ayarlar > "Hesabi sil" -> acik bir onay penceresi -> `delete_my_account()` RPC'si -> oturum kapanir, giris ekranina donulur.
- **Ne olur (sirayla, tek islemde):** 1) aktif gruplardan ayrilir (`leave_group`: tek admin ise rol en eski aktif uyeye devredilir, son uye ise grup tum verisiyle silinir); 2) `profile_private` (ad, soyad, telefon) silinir; 3) `profiles` anonimlestirilir: gorunen ad sabit "Gelöschter Nutzer", dil `de`; 4) `auth.users` satiri silinir (e-posta, sifre hash'i, oturumlar).
- **Kalanlar:** gecmis harcamalar, paylar, odemeler, liste kayitlari ve uyelik kaydi (ayrilma zamaniyla) anonim profile bagli kalir; diger uyelerin bakiyeleri bozulmaz. Anonim profilde kisiye ait bilgi kalmaz (ad sabit etiket).
- **Sema:** `profiles.id` -> `auth.users` yabanci anahtari kaldirildi (yoksa giris hesabi silinince profil de silinmeye calisilir ve harcamalara bagli oldugu icin hata verir).
- **Tasarimdan sapmalar:** `profiles.deleted_at` sutunu ve dile gore degisen etiket yerine veritabaninda sabit "Gelöschter Nutzer" (Datenschutz metni bu etiketi kullaniyor). Acik bakiye uyarisi henuz yok.
- **Dogrulama:** gecici PostgreSQL'de (Supabase auth taklidi) denendi: giris hesabi ve ozel bilgiler siliniyor, profil anonim, harcama ve iki pay duruyor, diger uye harcamayi "Gelöschter Nutzer" olarak goruyor, yonetici devri ve son uyede grup silme calisiyor, girissiz cagri reddediliyor. Gercek Supabase'de `delete from auth.users`'in calistigi migration'dan sonra elle denenmeli.
