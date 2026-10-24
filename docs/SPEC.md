# WG App: Spesifikasyon (V1)

Bu dosya **nasil calisacak** sorusunun cevabidir. Takvim icin `PLAN.md`, tablo yapisi icin `supabase/schema.sql`.

## 1. Kavramlar

- **Grup:** Bir WG. Uyeleri vardir, bir para birimi vardir (V1: sadece EUR).
- **Aktif uye:** `memberships.left_at IS NULL`. Eski uye: `left_at` dolu, gecmis harcamalarda gorunmeye devam eder.
- **Eksik listesi (shopping list):** "Neye ihtiyacimiz var" notlari. Listenin kendisinde fiyat, odeme ve bolusum yoktur; "Alindi" isaretlenirken opsiyonel fiyat girilirse ayri bir harcama kaydedilir (Bolum 6).
- **Harcama (expense):** Birinin odedigi bir tutar. Listeden bagimsizdir. Odeyen ne aldigini (opsiyonel) ve ne kadar odedigini yazar.
- **Settlement:** "A, B'ye X odedi" kaydi (gercek hayattaki geri odeme). Bakiyeyi dusurur.
- **Urun (group item):** Gruba ait urun kaydi. Ya katalogdan (`catalog_item_id`) ya da serbest yazilmis (`custom_name`).

## 2. Para kurallari

- Tum tutarlar `int` cent. UI'da `core/money.dart` ile gosterilir (`2350` -> "23,50 €" / "€23.50", dile gore).
- Kullanici girdisi: virgul ve nokta kabul edilir ("23,5", "23.50", "23"). En fazla 2 ondalik. Sifir veya negatif tutar kabul edilmez.
- Ust sinir: tek harcama en fazla 100.000,00 € (hatali girisi onlemek icin).

## 3. Bolusum kurallari

Bir harcama icin `expense_shares` satirlari olusturulur. **Toplam paylar = `amount_cents`** olmak zorunda (uygulama kaydetmeden once dogrular).

**Bolusum modlari (V1):**

| Mod | Girdi | Not |
|---|---|---|
| Esit | Katilimci secimi | Varsayilan: tum aktif uyeler secili |
| Tutar | Her katilimci icin cent | Toplam tutara esit olmali, degilse kaydedilemez |
| Pay orani | Her katilimci icin agirlik (ornek 2:1:1) | Esit mantikla, agirliga gore dagitilir |

Yuzde modu V1'de yok (pay orani ayni isi gorur).

**Yuvarlama (esit ve pay orani):**
1. Her katilimciya `floor(amount * agirlik / toplam_agirlik)` verilir.
2. Kalan cent'ler (`kalan = amount - dagitilan`) tek tek, **katilimcilar `user_id`'ye gore siralanip bastan** dagitilir.
3. Sonuc deterministiktir: ayni girdi her zaman ayni paylari uretir.

Ornek: 10,00 € (1000 cent), 3 kisi esit -> 334 / 333 / 333.

Katilimci olarak odeyen de secilebilir (cogu zaman secilir). Odeyen katilimci degilse ("ben ode, sen kullan") gecerlidir.

## 4. Bakiye hesabi

Bakiyeler **saklanmaz**, her seferinde hesaplanir (veri kucuk, hata kaynagi az).

Bir kullanici icin (bir grupta):

```
bakiye = SUM(odedigi harcamalar)            -- expenses.paid_by = user
       - SUM(payi)                          -- expense_shares.share_cents
       + SUM(gonderdigi settlement'lar)     -- from_user = user
       - SUM(aldigi settlement'lar)         -- to_user = user
```

- **Pozitif bakiye** = grup ona borclu (alacakli). **Negatif** = o gruba borclu.
- Tum uyelerin bakiyelerinin toplami **her zaman 0**. Degilse bu bir hatadir (testle yakalanir).
- Eski uyeler bakiye hesabina dahildir, ta ki bakiyeleri 0 olana kadar.

## 5. Borc sadelestirme (`domain/debt_simplifier.dart`)

Girdi: `Map<UserId, int>` bakiyeler (toplam 0). Cikti: `List<Transfer(from, to, cents)>`.

Algoritma (greedy):
1. Alacaklilari ve borclulari ayri listelere ayir, buyukten kucuge sirala (esitlikte `user_id`).
2. En buyuk borclu ile en buyuk alacakliyi eslestir, `min(borc, alacak)` kadar transfer olustur.
3. Kalanlari guncelle, sifirlananlari listeden cikar, bitene kadar tekrarla.

Garantiler: en fazla `n - 1` transfer, transferlerin toplami bakiyeleri tam sifirlar. (Mutlak minimum transfer sayisi NP-zor bir problemdir, greedy pratikte yeterli.)

**Zorunlu test senaryolari:**
1. Bos / herkes 0 -> transfer yok.
2. Iki kisi, tek borc.
3. Uc kisi, zincir (A->B, B->C) tek transfere iner.
4. Bir alacakli, uc borclu.
5. Cent yuvarlama kalintilari (334/333/333 durumu) toplami bozmuyor.
6. Buyuk rastgele set: toplam 0, transfer sayisi <= n-1, uygulandiginda tum bakiyeler 0.

## 6. Eksik listesi

- Giris: urun secici ile (bkz. Bolum 7) + opsiyonel kisa not ("2 paket", "laktozsuz").
- Ayni urun zaten acikta varsa tekrar eklemek yerine mevcut kaydi gosterir ("Zaten listede, Ali ekledi").
- **Durum:** `open` -> `bought`. "Alindi" isaretleyen `bought_by`/`bought_at` olarak kaydedilir. Alinan kalem acik listeden duser, "Son alinanlar" bolumunde 7 gun gorunur, geri alinabilir (`open`'a doner).
- **Gercek zamanli:** Biri ekleyince/isaretleyince tum uyelerde aninda guncellenir (Supabase Realtime, `shopping_entries`).
- Liste kaleminde fiyat saklanmaz. **"Alindi" opsiyonel fiyat (2026-10-24 karari):** "Alindi"ya basinca kucuk bir pencere "Preis (optional)" sorar. Bos birakilirsa yalnizca "alindi" isaretlenir. Doldurulursa ayrica bir harcama kaydedilir: odeyen = isaretleyen kisi, tutar = girilen fiyat, bolusum = tum aktif uyeler arasinda esit, kalem = o urun, tarih = bugun. Pencere iptal edilirse kalem acik kalir. Once "alindi" yazilir, sonra harcama; harcama kaydedilemezse "alindi" geri alinir (kalem listede acik kalir) ve kullaniciya hata gosterilir, yeniden denenebilir. Geri alma da basarisiz olursa kalem alinmis kalir ve kullanici uyarilir, harcama elle eklenir.
- Silme: kalemi ekleyen veya admin silebilir.

## 7. Urun secici (hizli giris)

Hem listeye ekleme hem harcama girisinde ayni bilesen. Alttan acilan sheet.

Siralama ve bolumler:
1. **Arama kutusu** (ustte, otomatik odakli). Hem Almanca hem Ingilizce isimlerde arar, buyuk/kucuk harf ve umlaut duyarsiz ("Spulmittel" -> "Spülmittel").
2. **Sik kullanilanlar:** Grubun `group_items` kayitlari, `use_count` azalan, esitlikte `last_used_at` yeni olan. Ilk 12.
3. **Katalog:** Kategoriye gore gruplu (food, household, ...). Isimler kullanicinin diline gore (`name_de` / `name_en`).
4. Arama sonucu yoksa: **"'xyz' ekle"** secenegi -> grubun kendi urunu olur (`group_items.custom_name`). Bu urun ayni grubun sonraki aramalarinda ve "sik kullanilanlar"da cikar. (Genel kataloga eklenmez, o admin/seed isidir.)

Bir urun secildiginde `touch_group_item` cagrilir (sayac artar). Katalogdan ilk kez secilen urun icin once `group_items` kaydi olusturulur (ayni `(group, catalog_item)` ciftinde tekrar olusturulmaz).

Harcama girisinde secici **cok secimlidir** ve **opsiyoneldir**: hic urun secmeden sadece tutar girilip kaydedilebilir.

## 8. Harcama girisi

Hizli akis (tek ekran):
1. **Tutar** (buyuk sayi girisi, ilk odak).
2. **Odeyen:** varsayilan ben, degistirilebilir.
3. **Kimleri kapsiyor:** varsayilan tum aktif uyeler, mod secimi (Esit / Tutar / Pay orani).
4. **Ne alindi (opsiyonel):** urun secici ile bir veya daha fazla kalem + serbest yazi. Bos birakilabilir.
5. **Aciklama (opsiyonel):** bos ise secilen kalemlerin adlarindan otomatik uretilir, o da yoksa "Ausgabe/Expense".
6. **Tarih:** varsayilan bugun.

Duzenleme/silme: **sadece harcamayi olusturan veya grup admin'i.** Bakiyeler hesaplandigi icin duzenleme otomatik yansir. Silme kalicidir (onay ister).

## 9. Hesaplasma (settle up)

- **Bakiye ekrani:** Her uyenin bakiyesi + "Onerilen odemeler" (debt_simplifier ciktisi).
- **Kisi detayi (2026-10-24):** Bakiye ekraninda bir uyeye dokununca acilir. O kisinin **ikili borclari**: "kime net ne kadar borclu" ve "kimden ne alacakli". Her satir acilinca o tutari olusturan harcamalar ve odemeler (settlement) listelenir; harcamaya dokunmak detayina gider. Hesap (`domain/pair_debts.dart`): bir harcamada payi olan herkes odeyene payi kadar borclanir (odeyenin kendi payi borc degildir), odemeler borcu azaltir, iki yondeki borclar cift basina netlesir, net 0 olan ciftler gosterilmez. Kural: bir kisinin tum ikili borclarinin toplami onun bakiyesinin eksilisine esittir (Bolum 4). "Onerilen odemeler" (Bolum 5) sadelestirilmis ve farkli bir seydir: en az sayida odemeyi onerir, gercek ikili borclari degil.
- Bir transfer satirinda "Odendi olarak isaretle" -> `settlements` kaydi olusturulur. Hem odeyen hem alan isaretleyebilir.
- **Aylik ozet:** Secilen ay icin harcamalar toplami, kisi basi odenen ve pay, ay sonu bakiyesi. (Bakiye hesabi tum zamanlari kapsar, ozet ekrani sadece goruntuleme filtresidir.)
- Odeme entegrasyonu V1'de yok. Sadece kayit.

## 10. Gruplar ve uyelik

- **Olusturma:** `create_group(name)` RPC. Olusturan admin olur.
- **Davet:** Uyeler davet kodu/linki uretir (`invites`), 7 gun gecerli, suresi icinde birden fazla kisi kullanabilir. Link: `/join/<code>`. Giris yapmamis kisi linke girerse once giris/kayit, sonra otomatik katilim.
- **Katilma:** `join_group(code)` RPC. Gecersiz/suresi dolmus kod -> anlasilir hata mesaji.
- **Ayrilma:** `leave_group(group_id)`. Kayit silinmez, `left_at` dolar. Ayrilan kisi grubu artik gormez, ama diger uyeler gecmis harcamalarda onun adini gormeye devam eder.
  - Bakiyesi 0 degilse UI uyarir: "Hesabin kapanmadi (X €)". Yine de ayrilabilir; bakiye, sifirlanana kadar bakiye ekraninda "Eski uye" olarak kalir.
  - Grubun tek admin'i ayrilamaz, once baska birini admin yapmali.
- **Yeniden katilma:** Eski uye yeni davetle donerse `left_at` temizlenir, eski gecmisi geri gelir.
- **Roller:** `admin` (uye yonetimi, grup adi, baskasinin harcamasini silme), `member`.

## 11. Ekranlar

1. **Giris / Kayit:** e-posta + sifre, gorunen ad, dil secimi (ilk acilista cihaz diline gore onerilir).
2. **Grup secimi:** Gruplarim, "Grup olustur", "Davet koduyla katil".
3. **Ana ekran (grup icinde), alt gezinme:**
   - **Liste:** acik kalemler (ustte), "Son alinanlar", ekleme butonu (+).
   - **Harcamalar:** kronolojik liste (tarih, odeyen, tutar, kalemler), ekleme butonu.
   - **Bakiye:** uye bakiyeleri, onerilen odemeler, aylik ozet.
   - **Grup:** uyeler, davet linki olustur/paylas, ayril.
4. **Urun secici** (sheet), **Harcama formu**, **Harcama detayi** (duzenle/sil).
5. **Ayarlar:** dil (DE/EN), gorunen ad, cikis.

Bos durumlar (ornek: henuz kalem yok) ve hata/yukleniyor durumlari her ekranda tasarlanir.

## 12. Cok dillilik

- Diller: `de`, `en`. Tercih `profiles.locale`'de saklanir, degisince hemen uygulanir.
- UI metinleri `lib/l10n/*.arb`. Tarih, sayi, para formati `intl` ile dile gore.
- Katalog urunleri `name_de` / `name_en`. Kullanicinin serbest yazdigi urunler tek dilde kalir, cevrilmez.

## 13. Guvenlik

- Uygulama sadece `anon` key kullanir. `service_role` asla istemcide olmaz.
- Veri erisimi RLS ile: sadece **aktif** grup uyeleri o grubun verisini gorur/degistirir.
- `join_group`, `create_group`, `leave_group` `security definer` fonksiyonlaridir, `search_path` sabit.
- Davet kodlari tahmin edilemez uzunlukta (10 hex) ve sureli.

### Bilinen sema bosluklari (kodlamaya baslarken ele alinacak)

`schema.sql` yuklenebildi ve temel izolasyon gecici bir PostgreSQL'de denendi (grup olusturma, davetle katilma, baska grubun verisinin gorunmemesi, disaridakinin harcama ekleyememesi calisiyor). Madde 1 **dogrulandi**: baska bir uye, baskasinin harcamasini degistirebiliyor. Asagidakiler V1 bitmeden kapatilmali (once kullaniciya sor, sonra sema + bu listeyi guncelle):

1. ~~**Harcama duzenleme/silme yetkisi**~~ **Kapandi (Hafta 4):** `expenses` icin dogrudan insert/update policy'si yok; yazma `save_expense` RPC'siyle (duzenleme: olusturan veya admin, hata `not_allowed`). Silme policy'si: olusturan veya admin.
2. ~~**Pay toplami dogrulamasi**~~ **Kapandi (Hafta 4):** `save_expense(gid, eid, payer, amount, descr, exp_date, share_list, item_list)` harcama + paylar + kalemleri tek islemde yazar; `SUM(share_cents) = amount` degilse `shares_mismatch`, tutar 1..10.000.000 cent disindaysa `invalid_amount`. Diger hatalar: `not_a_member`, `invalid_shares`, `expense_not_found`, `invalid_participant`, `invalid_item`. Dogrudan yazma yolu kapali oldugu icin ayri trigger gerekmedi.
3. ~~**`group_items` tekilligi**~~ **Kapandi (Hafta 3):** kismi unique index'ler (katalog: `group_id, catalog_item_id`; serbest: `group_id, lower(custom_name)`) + `get_or_create_group_item(gid, cat_id, custom)` RPC'si (hatalar: `not_a_member`, `invalid_item`). Ek: `shopping_entries` silme yetkisi ekleyen veya admin'e kisitlandi (Bolum 6), `shopping_all` policy'si select/insert/update/delete olarak bolundu.
4. ~~**`join_group` / `leave_group` kurallari**~~ **Kapandi (Hafta 2):** `leave_group` uye olmayana `not_a_member`, tek admin'e `last_admin` hatasi verir. Admin devri icin `set_member_role(gid, target, new_role)` RPC'si eklendi (hatalar: `invalid_role`, `not_admin`, `target_not_member`, `last_admin`). `join_group` hata kodu `invalid_or_expired_invite`.
5. ~~**Katilimci/odeyen aktif uye mi**~~ **Kapandi (Hafta 4):** `save_expense` odeyen ve tum paylasanlarin aktif uye olmasini ister (`invalid_participant`). Duzenlemede o harcamada zaten bulunan, sonradan ayrilmis uyeler korunabilir.
6. ~~**Settlement dogrulamasi**~~ **Kapandi (Hafta 5):** `settlements` icin dogrudan yazma policy'si yok; `record_settlement(gid, from_id, to_id, amount)` RPC'si: cagiran aktif uye ve taraflardan biri (`not_allowed`), `from <> to` (`invalid_settlement`), ikisi de grubun uyesi, ayrilmis olsa da (`invalid_participant`), tutar 1..10.000.000 cent (`invalid_amount`). Geri alma V1'de yok.
7. ~~**`shopping_entries` realtime**~~ **Kapandi (Hafta 3):** INSERT/UPDATE olaylari `group_id` filtresiyle ve RLS ile gelir; DELETE olaylari `group_id` ile filtrelenemez (eski satir sadece PK tasir), bu yuzden ayri, filtresiz bir abonelik sadece "listeyi yeniden yukle" tetikler. Iki tarayicida denendi.

## 14. Test ve "bitti" olcutleri

Genel: `flutter analyze` temiz, `flutter test` gecer, ilgili ozellik web'de elle denendi.

| Hafta | Bitti sayilir, eger |
|---|---|
| 0 | Bos uygulama `flutter run -d chrome` ile aciliyor, Supabase'e baglanip bir sorgu atabiliyor. |
| 1 | Kayit, giris, cikis calisiyor; sayfa yenilenince oturum devam ediyor; dil DE/EN degisiyor ve profile kaydediliyor. |
| 2 | Iki ayri tarayici profiliyle: biri grup kuruyor, digeri linkle katiliyor, ikisi de uyeleri goruyor; ayrilma calisiyor; baska grubun verisi gorunmuyor. |
| 3 | Biri kalem ekleyince digerinde yenilemeden gorunuyor; "alindi" geri alinabiliyor; urun secici arama + sik kullanilanlar + serbest ekleme calisiyor. |
| 4 | Uc modda harcama kaydediliyor, paylar toplami tutara esit (10,00 €/3 -> 334/333/333); duzenleme/silme yetkisi calisiyor. |
| 5 | `debt_simplifier` 6 senaryonun hepsinde gecer; bakiye ekrani toplam 0 gosteriyor; "odendi" bakiyeyi dogru dusuruyor. |
| 6 | Canli bir web adresi var; WG'de en az 2 kisi gercekten kullanmis; README ve ekran goruntuleri hazir. |

## 15. Yayin, altyapi ve platform

- **Hedef platform V1:** Web. Gelistirme Windows'ta; web ve Android Windows'ta derlenir. **iOS Windows'ta derlenemez.** iPhone kullanicilari siteyi Safari'den "Ana Ekrana Ekle" ile PWA olarak kullanir. iOS mağaza surumu V2+ (bulutta macOS derleme + Apple Developer Program uyeligi; guncel fiyat/kosullari Apple'dan dogrula).
- **Mobil uygulamada davet linkleri (V2+):** `/join/<code>` linkinin mobil uygulamada acilmasi icin iOS universal links ve Android app links ayarlanir (alan adinda dogrulama dosyalari gerekir). Web/PWA'da ek is yok. Bu yuzden V1'de de kalici, tek bir alan adi ve sabit `/join/<code>` yol bicimi kullanilir; sonradan degistirilmez.
- **Davet linkleri ve yonlendirme:** `/join/<code>` gibi adresler Flutter web'de sayfa yenilenince 404 verir. Yayin ortaminda tum yollar `index.html`'e yonlendirilmeli (Firebase Hosting `rewrites`, Netlify `_redirects`, Vercel `rewrites`). Router tarafinda path-tabanli URL stratejisi (hash `#` olmadan) kullanilir. Hafta 2'de lokalde, Hafta 6'da yayinda denenir.
- **Supabase Auth ayarlari:** E-posta dogrulamasi gelistirmede kapali olabilir, yayinda acik ya da kapali karari bilincli verilir. "Site URL" ve izinli "Redirect URL" listesi canli adresi icermeli, yoksa dogrulama/sifre sifirlama linkleri calismaz.
- **Supabase ucretsiz katman:** Uzun sure kullanilmayan projeler durdurulabilir (bildigim kadariyla yaklasik 1 hafta; guncel kurali Supabase'den dogrula). WG'nin kullanimini bozmamak icin yayindan once kontrol edilir.
- **Anahtarlar:** `env.json` (gitignore'da) ile `--dart-define-from-file`. Sablon `env.example.json`. Yayin ortaminin (Netlify vb.) build adiminda ayni degerler ortam degiskeni olarak verilir; sadece `anon` key.
- **Yedek:** Yayina cikmadan once Supabase'in otomatik yedekleme/export durumu kontrol edilir; `schema.sql` repoda oldugu icin sema yeniden kurulabilir.

## 16. Gizlilik ve yasal (Almanya)

Hukuki tavsiye degildir; Hafta 6'dan once kullanicinin kendisi arastirmali:
- Hesabi olan, herkese acik bir site icin **Datenschutzerklaerung** (gizlilik politikasi) gerekir. Uygulama su verileri toplar: e-posta, gorunen ad, dil tercihi, grup uyeligi, harcama/liste verisi. Bu liste politikanin teknik temelidir.
- **Impressum** gerekliligi sitenin amacina (tamamen kisisel/ticari olmayan mi) gore degisir; kullanici bunu kendisi arastirip karar verir.
- Hesap silme: kullanici hesabini silmek isterse harcama gecmisinin ne olacagi (diger uyeleri etkiler) V1'de tanimlanmalidir. Oneri: gorunen ad "Silinmis kullanici" olarak anonimlestirilir, harcamalar kalir. Uygulama icinden yapilabilmelidir (Ayarlar ekrani). V1 web'de en azindan davranis kararlastirilir; **iOS App Store surumunden once uygulama icinden hesap silme zorunlu** (Apple, hesap olusturan uygulamalardan bunu istiyor; guncel kurali Apple'dan dogrula), bu yuzden en gec V2'de implemente edilir. **Karar (2026-10-19):** anonimlestirme tek bir etiketle yapilir ("Geloeschter Nutzer" / "Deleted user"); silinen kisi bir grupta tek adminse rol en eski aktif uyeye (`joined_at`) otomatik devredilir; uygulama V2'de, tasarim `docs/GIZLILIK-ENVANTERI.md`'de. Teknik not: Supabase'de auth kullanicisini silmek `service_role` gerektirir, istemciden yapilamaz; bu is guvenli bir sunucu tarafi fonksiyonla (Supabase Edge Function ya da `security definer` RPC + yonetici islemi) cozulur ve anahtar istemciye girmez.
- Cerez/yerel depolama: Supabase oturumu icin tarayici deposu kullanilir, ucuncu taraf izleme/analitik eklenmez.

## 17. V1 kapsam disi (bilerek yapilmiyor)

- Fis okuma / OCR / Python servisi (V2)
- Tekrarlayan giderler (kira, fatura) (V2)
- Odeme linkleri, banka/PayPal entegrasyonu
- Push bildirimleri ve hatirlatmalar
- Coklu para birimi
- Yuzde bolusum modu
- Harcama yorumlari, fotograf/ek dosya
- Mobil uygulama paketleme ve mağaza yayini (Android Play Store, iOS App Store): web bitince, V2+
- iOS platform klasoru / iOS derlemesi (Windows'ta yapilamaz)
- Ev tipi dışındaki grup turleri (gezi/etkinlik)
- Genel katalogu kullanicilarin duzenlemesi
