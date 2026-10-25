# Gizlilik: teknik veri envanteri

Bu dosya **hukuki tavsiye degildir.** Datenschutzerklaerung ve Impressum icin ne gerektigine kullanici karar verir (SPEC 16). Burada sadece uygulamanin teknik olarak ne topladigi yazar; politikayi yazacak kisi icin girdidir. Son guncelleme: 2026-10-25.

## Toplanan veriler

| Veri | Nerede | Not |
|---|---|---|
| E-posta, parola (hash'li) | Supabase `auth.users` | Giris icin. Parolayi Supabase Auth yonetir, kodda duz metin yok. |
| Gorunen ad | `profiles.display_name` | Gruptaki herkes gorur. Kayitta zorunlu; bos gelirse e-postanin `@` oncesi kullanilir (`handle_new_user`). |
| Ad, soyad, telefon numarasi | `profile_private` (ayrica kayit aninda `auth.users.raw_user_meta_data`) | **2026-10-25'ten itibaren kayitta zorunlu**, eski hesaplarda bos olabilir. **Sadece kisinin kendisi gorur** (RLS: `id = auth.uid()`); grup uyeleri dahil kimse goremez. Telefon ulke kodlu saklanir (`+491512345678`), dogrulanmaz (SMS yok). **Su an uygulamada hicbir islevde kullanilmiyor (kullanici karari: "sadece sakli kalsin").** Datenschutzerklaerung icin acik nokta: bu verilerin hangi amacla toplandigi ve zorunlu olmasinin gerekcesi yazilmali; amac yoksa veri azaltma acisindan istege bagli yapmak ya da hic toplamamak yeniden dusunulmeli. |
| Dil tercihi | `profiles.locale` | `de` / `en` / `tr`. |
| Grup uyeligi, rol, katilma/ayrilma zamani | `memberships` | Ayrilinca kayit silinmez, `left_at` dolar. |
| Alisveris listesi, harcamalar, paylar, odemeler | `shopping_entries`, `expenses`, `expense_items`, `expense_shares`, `settlements` | Kim ekledi / kim odedi / ne zaman bilgisiyle. |
| Davet kodlari | `invites` | 7 gun gecerli, olusturan kisi kayitli. |
| Oturum | Tarayici deposu (Supabase oturumu) | Ucuncu taraf analitik/izleme yok. |

## Ucuncu taraf istekleri

- **Supabase** (veritabani, auth): tum veri burada. Proje bolgesi ve veri isleme sozlesmesi kullanici tarafindan kontrol edilecek.
- **Google CDN (2026-10-24'te denendi):** `flutter build web` varsayilan olarak CanvasKit'i `www.gstatic.com/flutter-canvaskit` ve yedek fontlari `fonts.gstatic.com` adresinden ceker; ziyaretci IP'si Google'a gider. `--no-web-resources-cdn` ile derlenince CanvasKit ve Roboto yedek fontu kendi alan adindan gelir (`useLocalCanvasKit: true`, `assets/fonts/fallback/Roboto-Regular.ttf`). **Kalan istisna:** Inter/Roboto'nun karsilamadigi bir karakter (ornek: urun adina yazilan emoji) gorunurse Flutter eksik yedek fontu `fonts.gstatic.com/s/` adresinden indirir. Karar: Datenschutzerklaerung'da bir cumleyle belirtilir. Build ciktisinin statik incelemesi yapildi; canli adreste tarayici Network sekmesiyle dogrulanmali.
- Uygulama fontu (Inter) pakete gomulu, dis istek yok.

## Hesap silme (karar, uygulama sonra)

- **Karar:** hesap silinince gorunen ad anonimlestirilir ("Geloeschter Nutzer" / "Deleted user", tek etiket), harcamalar ve odemeler kalir, bakiyeler bozulmaz.
- **Tek admin kurali:** silinen kisi bir grupta tek adminse ve grupta baska aktif uye varsa, admin rolu en eski aktif uyeye (`joined_at`) otomatik devredilir.
- **Teknik tasarim (V2, iOS magaza surumunden once zorunlu):**
  1. `profiles.id` -> `auth.users` FK'si kaldirilir, `profiles.deleted_at` eklenir (neden: `paid_by`, `created_by`, `added_by`, `from_user`, `to_user`, `expense_shares.user_id` kolonlari `profiles`'a `on delete` kuralsiz bagli; cascade silme FK hatasi verir).
  2. `delete_my_account()` RPC'si (`security definer`, sabit `search_path`): aktif uyelikleri kapatir, tek admin ise rolu devreder, profili anonimlestirir, `auth.users` satirini siler. Gercek Supabase projesinde `auth.users` silmenin calistigi denenecek; olmazsa yedek yol Edge Function.
  3. Ayarlar ekraninda "Konto loeschen" dugmesi, onay penceresi, acik bakiye varsa mevcut "hesap kapanmadi" uyarisi; basarili olunca oturum kapatilir.
  4. Silinmis kullanici adi l10n'dan gelir (iki dilde); `display_name` okunan yerler `deleted_at`'e gore ayarlanir.
  5. Gecici PostgreSQL'de test: harcamalar kalir, bakiyeler tutar, diger uyeler anonim profili okuyabilir (`profiles_read` bunu zaten saglar).
