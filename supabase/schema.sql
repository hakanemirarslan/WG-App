-- WG App: Supabase / PostgreSQL schema
-- Supabase Dashboard > SQL Editor'e yapistirip calistir.
-- Tutarlar daima cent (tam sayi) olarak saklanir: 23,50 EUR -> 2350

-- ============================================================
-- 1) TABLOLAR
-- ============================================================

create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  locale       text not null default 'de' check (locale in ('de', 'en', 'tr')),
  created_at   timestamptz not null default now()
);

create table public.groups (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  currency    text not null default 'EUR',
  created_by  uuid not null references public.profiles(id),
  created_at  timestamptz not null default now()
);

-- joined_at / left_at: biri tasininca gecmis harcamalarda kalir, yenilere dahil edilmez
create table public.memberships (
  group_id   uuid not null references public.groups(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  role       text not null default 'member' check (role in ('admin', 'member')),
  joined_at  timestamptz not null default now(),
  left_at    timestamptz,
  primary key (group_id, user_id)
);

create table public.invites (
  code        text primary key default substr(md5(random()::text || clock_timestamp()::text), 1, 10),
  group_id    uuid not null references public.groups(id) on delete cascade,
  created_by  uuid not null references public.profiles(id),
  expires_at  timestamptz not null default now() + interval '7 days',
  created_at  timestamptz not null default now()
);

-- Genel, hazir urun katalogu (herkes okur, sadece admin/seed ekler)
create table public.catalog_items (
  id        uuid primary key default gen_random_uuid(),
  name_de   text not null,
  name_en   text not null,
  name_tr   text,  -- Turkce ad; bos ise uygulama Ingilizce adi gosterir
  category  text not null,
  unique (name_de)
);

-- Gruba ozel urunler: katalogdan secilenler veya serbest yazilanlar.
-- use_count arttikca "sik kullanilanlar" listesinde yukari cikar.
create table public.group_items (
  id               uuid primary key default gen_random_uuid(),
  group_id         uuid not null references public.groups(id) on delete cascade,
  catalog_item_id  uuid references public.catalog_items(id),
  custom_name      text,
  use_count        integer not null default 0,
  last_used_at     timestamptz,
  check (catalog_item_id is not null or custom_name is not null)
);

-- Ayni urun bir grupta tek kez: katalog urunu id ile, serbest urun buyuk/kucuk harf duyarsiz isimle
create unique index group_items_catalog_unique
  on public.group_items (group_id, catalog_item_id) where catalog_item_id is not null;
create unique index group_items_custom_unique
  on public.group_items (group_id, lower(custom_name)) where custom_name is not null;

-- Eksik listesi: fiyat/odeme YOK, sadece "neye ihtiyacimiz var"
create table public.shopping_entries (
  id             uuid primary key default gen_random_uuid(),
  group_id       uuid not null references public.groups(id) on delete cascade,
  group_item_id  uuid not null references public.group_items(id),
  note           text,
  added_by       uuid not null references public.profiles(id),
  status         text not null default 'open' check (status in ('open', 'bought')),
  bought_by      uuid references public.profiles(id),
  bought_at      timestamptz,
  created_at     timestamptz not null default now()
);

-- Harcama: listeden bagimsiz. Odeyen ne aldigini ve ne kadar odedigini yazar.
create table public.expenses (
  id            uuid primary key default gen_random_uuid(),
  group_id      uuid not null references public.groups(id) on delete cascade,
  paid_by       uuid not null references public.profiles(id),
  amount_cents  integer not null check (amount_cents > 0),
  description   text,
  expense_date  date not null default current_date,
  created_by    uuid not null references public.profiles(id),
  created_at    timestamptz not null default now()
);

-- Listeden fiyatla "alindi" yapilinca olusan harcama. "Alindi" geri alinirken bu harcama da
-- silinir; harcama baska yoldan silinirse baglanti kendiliginden bosalir. (expenses'tan sonra
-- eklenir, cunku shopping_entries ondan once tanimli. Var olan veritabaninda ayni satir bir
-- kez calistirilir.)
alter table public.shopping_entries
  add column if not exists expense_id uuid references public.expenses(id) on delete set null;

-- Opsiyonel: harcamaya bagli kalemler (listeden veya katalogdan)
create table public.expense_items (
  id             uuid primary key default gen_random_uuid(),
  expense_id     uuid not null references public.expenses(id) on delete cascade,
  group_item_id  uuid references public.group_items(id),
  free_text      text,
  check (group_item_id is not null or free_text is not null)
);

-- Kim ne kadar oder. Toplam = expenses.amount_cents olmali (uygulama tarafinda dogrulanir)
create table public.expense_shares (
  expense_id   uuid not null references public.expenses(id) on delete cascade,
  user_id      uuid not null references public.profiles(id),
  share_cents  integer not null check (share_cents >= 0),
  primary key (expense_id, user_id)
);

-- Odemeler (hesaplasma): "Ali Veli'ye 20 EUR odedi"
create table public.settlements (
  id           uuid primary key default gen_random_uuid(),
  group_id     uuid not null references public.groups(id) on delete cascade,
  from_user    uuid not null references public.profiles(id),
  to_user      uuid not null references public.profiles(id),
  amount_cents integer not null check (amount_cents > 0),
  created_at   timestamptz not null default now()
);

create index on public.memberships (user_id);
create index on public.shopping_entries (group_id, status);
create index on public.expenses (group_id, expense_date desc);
create index on public.group_items (group_id, use_count desc);

-- ============================================================
-- 2) YARDIMCI FONKSIYONLAR
-- ============================================================

-- Kullanici bu grubun aktif uyesi mi? (RLS kurallarinin temeli)
create or replace function public.is_group_member(gid uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.memberships
    where group_id = gid and user_id = auth.uid() and left_at is null
  );
$$;

-- Yeni kullanici kaydolunca otomatik profil olustur
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Grup olustur + olusturani admin yap (tek islemde)
create or replace function public.create_group(group_name text)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare gid uuid;
begin
  insert into public.groups (name, created_by) values (group_name, auth.uid()) returning id into gid;
  insert into public.memberships (group_id, user_id, role) values (gid, auth.uid(), 'admin');
  return gid;
end;
$$;

-- Davet koduyla gruba katil
create or replace function public.join_group(invite_code text)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare gid uuid;
begin
  select group_id into gid from public.invites
  where code = invite_code and expires_at > now();
  if gid is null then
    raise exception 'invalid_or_expired_invite';
  end if;
  insert into public.memberships (group_id, user_id)
  values (gid, auth.uid())
  on conflict (group_id, user_id) do update set left_at = null;
  return gid;
end;
$$;

-- Ayrilma (SPEC 10). Son aktif uye ayrilirsa grup tum verisiyle silinir ('deleted');
-- tek admin ayrilirsa rol en eski aktif uyeye (joined_at) devredilir. Donus: 'left' | 'deleted'.
-- Kayit silinmez, left_at dolar; rol 'member'a duser (geri donen eski admin otomatik admin olmaz).
-- Hata kodu: not_a_member
create or replace function public.leave_group(gid uuid)
returns text
language plpgsql security definer set search_path = public
as $$
declare
  my_role text;
  successor uuid;
begin
  select role into my_role from public.memberships
  where group_id = gid and user_id = auth.uid() and left_at is null
  for update;
  if my_role is null then
    raise exception 'not_a_member';
  end if;

  if not exists (
    select 1 from public.memberships
    where group_id = gid and left_at is null and user_id <> auth.uid()
  ) then
    -- Nobody would be left: delete the group; every table cascades from groups.
    delete from public.groups where id = gid;
    return 'deleted';
  end if;

  if my_role = 'admin' and not exists (
    select 1 from public.memberships
    where group_id = gid and role = 'admin' and left_at is null and user_id <> auth.uid()
  ) then
    select user_id into successor from public.memberships
    where group_id = gid and left_at is null and user_id <> auth.uid()
    order by joined_at, user_id
    limit 1;
    update public.memberships set role = 'admin'
    where group_id = gid and user_id = successor;
  end if;

  update public.memberships set left_at = now(), role = 'member'
  where group_id = gid and user_id = auth.uid();
  return 'left';
end;
$$;

-- Bir uyenin rolunu degistir (admin devri). Sadece aktif admin cagirabilir.
-- Hata kodlari: invalid_role, not_admin, target_not_member, last_admin
create or replace function public.set_member_role(gid uuid, target uuid, new_role text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if new_role not in ('admin', 'member') then
    raise exception 'invalid_role';
  end if;
  if not exists (
    select 1 from public.memberships
    where group_id = gid and user_id = auth.uid() and role = 'admin' and left_at is null
  ) then
    raise exception 'not_admin';
  end if;
  if not exists (
    select 1 from public.memberships
    where group_id = gid and user_id = target and left_at is null
  ) then
    raise exception 'target_not_member';
  end if;
  if new_role = 'member' and not exists (
    select 1 from public.memberships
    where group_id = gid and role = 'admin' and left_at is null and user_id <> target
  ) then
    raise exception 'last_admin';
  end if;
  update public.memberships set role = new_role
  where group_id = gid and user_id = target;
end;
$$;

-- Grubun urun kaydini bul ya da olustur (yarisa dayanikli). Ya katalog id'si ya serbest isim verilir.
-- Hata kodlari: not_a_member, invalid_item
create or replace function public.get_or_create_group_item(gid uuid, cat_id uuid, custom text)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare item_id uuid; clean_name text := nullif(btrim(custom), '');
begin
  if not public.is_group_member(gid) then
    raise exception 'not_a_member';
  end if;
  if (cat_id is null) = (clean_name is null) then
    raise exception 'invalid_item';
  end if;
  if cat_id is not null then
    insert into public.group_items (group_id, catalog_item_id) values (gid, cat_id)
    on conflict (group_id, catalog_item_id) where catalog_item_id is not null do nothing;
    select id into item_id from public.group_items
    where group_id = gid and catalog_item_id = cat_id;
  else
    insert into public.group_items (group_id, custom_name) values (gid, clean_name)
    on conflict (group_id, lower(custom_name)) where custom_name is not null do nothing;
    select id into item_id from public.group_items
    where group_id = gid and lower(custom_name) = lower(clean_name);
  end if;
  return item_id;
end;
$$;

-- Harcama + paylar + kalemler TEK islemde kaydet (yeni: eid null, duzenleme: eid dolu).
-- share_list: [{"user_id": "...", "share_cents": 334}, ...]   item_list: ["<group_item_id>", ...]
-- Hata kodlari: not_a_member, invalid_amount, invalid_shares, shares_mismatch,
--   expense_not_found, not_allowed, invalid_participant, invalid_item
create or replace function public.save_expense(
  gid uuid, eid uuid, payer uuid, amount integer, descr text, exp_date date,
  share_list jsonb, item_list jsonb default '[]'
)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  old_payer uuid;
  old_creator uuid;
  result_id uuid := eid;
  share_count integer;
  share_total bigint;
begin
  if not public.is_group_member(gid) then
    raise exception 'not_a_member';
  end if;
  if amount is null or amount < 1 or amount > 10000000 then
    raise exception 'invalid_amount';
  end if;

  if share_list is null or jsonb_typeof(share_list) <> 'array' or jsonb_array_length(share_list) = 0 then
    raise exception 'invalid_shares';
  end if;
  select count(*), coalesce(sum((s->>'share_cents')::integer), 0)
    into share_count, share_total
    from jsonb_array_elements(share_list) s;
  if share_count <> (select count(distinct s->>'user_id') from jsonb_array_elements(share_list) s)
     or exists (select 1 from jsonb_array_elements(share_list) s where (s->>'share_cents')::integer < 0) then
    raise exception 'invalid_shares';
  end if;
  if share_total <> amount then
    raise exception 'shares_mismatch';
  end if;

  if eid is not null then
    select paid_by, created_by into old_payer, old_creator
      from public.expenses where id = eid and group_id = gid;
    if not found then
      raise exception 'expense_not_found';
    end if;
    if old_creator <> auth.uid() and not exists (
      select 1 from public.memberships m
      where m.group_id = gid and m.user_id = auth.uid() and m.role = 'admin' and m.left_at is null
    ) then
      raise exception 'not_allowed';
    end if;
  end if;

  -- Payer and participants must be active members; when editing, people who
  -- already were on this expense may stay even if they left the group since.
  if exists (
    select 1
    from (
      select payer as uid
      union
      select (s->>'user_id')::uuid from jsonb_array_elements(share_list) s
    ) p
    where not exists (
            select 1 from public.memberships m
            where m.group_id = gid and m.user_id = p.uid and m.left_at is null)
      and not (eid is not null and (
            p.uid = old_payer
            or exists (select 1 from public.expense_shares es
                       where es.expense_id = eid and es.user_id = p.uid)))
  ) then
    raise exception 'invalid_participant';
  end if;

  if exists (
    select 1 from jsonb_array_elements_text(coalesce(item_list, '[]'::jsonb)) i
    where not exists (
      select 1 from public.group_items gi
      where gi.id = i::uuid and gi.group_id = gid)
  ) then
    raise exception 'invalid_item';
  end if;

  if eid is null then
    insert into public.expenses (group_id, paid_by, amount_cents, description, expense_date, created_by)
    values (gid, payer, amount, nullif(btrim(descr), ''), coalesce(exp_date, current_date), auth.uid())
    returning id into result_id;
  else
    update public.expenses
    set paid_by = payer, amount_cents = amount,
        description = nullif(btrim(descr), ''), expense_date = coalesce(exp_date, current_date)
    where id = eid;
    delete from public.expense_shares where expense_id = eid;
    delete from public.expense_items where expense_id = eid;
  end if;

  insert into public.expense_shares (expense_id, user_id, share_cents)
  select result_id, (s->>'user_id')::uuid, (s->>'share_cents')::integer
  from jsonb_array_elements(share_list) s;

  insert into public.expense_items (expense_id, group_item_id)
  select result_id, i::uuid from jsonb_array_elements_text(coalesce(item_list, '[]'::jsonb)) i;

  -- Only new expenses count as "usage" for the frequently-used list (SPEC 7).
  if eid is null then
    update public.group_items
    set use_count = use_count + 1, last_used_at = now()
    where id in (select i::uuid from jsonb_array_elements_text(coalesce(item_list, '[]'::jsonb)) i);
  end if;

  return result_id;
end;
$$;

-- "Odendi" kaydi (SPEC 9). Cagiran aktif uye ve odeyen ya da alan taraflardan biri olmali.
-- Ikisi de grubun uyesi olmali (ayrilmis olsa da: eski uyenin borcu kapanabilsin).
-- Hata kodlari: not_a_member, invalid_settlement, invalid_amount, not_allowed, invalid_participant
create or replace function public.record_settlement(gid uuid, from_id uuid, to_id uuid, amount integer)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare new_id uuid;
begin
  if not public.is_group_member(gid) then
    raise exception 'not_a_member';
  end if;
  if from_id = to_id then
    raise exception 'invalid_settlement';
  end if;
  if amount is null or amount < 1 or amount > 10000000 then
    raise exception 'invalid_amount';
  end if;
  if auth.uid() <> from_id and auth.uid() <> to_id then
    raise exception 'not_allowed';
  end if;
  if (select count(*) from public.memberships
      where group_id = gid and user_id in (from_id, to_id)) <> 2 then
    raise exception 'invalid_participant';
  end if;

  insert into public.settlements (group_id, from_user, to_user, amount_cents)
  values (gid, from_id, to_id, amount)
  returning id into new_id;
  return new_id;
end;
$$;

-- Urun kullanildikca siklik sayacini artir
create or replace function public.touch_group_item(item_id uuid)
returns void
language sql security definer set search_path = public
as $$
  update public.group_items
  set use_count = use_count + 1, last_used_at = now()
  where id = item_id and public.is_group_member(group_id);
$$;

-- ============================================================
-- 3) ROW LEVEL SECURITY: sadece grup uyeleri gorur
-- ============================================================

alter table public.profiles         enable row level security;
alter table public.groups           enable row level security;
alter table public.memberships      enable row level security;
alter table public.invites          enable row level security;
alter table public.catalog_items    enable row level security;
alter table public.group_items      enable row level security;
alter table public.shopping_entries enable row level security;
alter table public.expenses         enable row level security;
alter table public.expense_items    enable row level security;
alter table public.expense_shares   enable row level security;
alter table public.settlements      enable row level security;

-- profiles: kendi profilin + ayni gruptaki insanlarin profili
create policy "profiles_read" on public.profiles for select using (
  id = auth.uid() or exists (
    select 1 from public.memberships m1
    join public.memberships m2 on m1.group_id = m2.group_id
    where m1.user_id = auth.uid() and m2.user_id = profiles.id and m1.left_at is null
  )
);
create policy "profiles_update_own" on public.profiles for update using (id = auth.uid());

-- groups
create policy "groups_read" on public.groups for select using (public.is_group_member(id));
create policy "groups_update_admin" on public.groups for update using (
  exists (select 1 from public.memberships
          where group_id = groups.id and user_id = auth.uid() and role = 'admin' and left_at is null)
);

-- memberships: ayni grubun uyelerini gor
create policy "memberships_read" on public.memberships for select using (public.is_group_member(group_id));

-- invites: sadece uyeler davet olusturur/gorur
create policy "invites_read" on public.invites for select using (public.is_group_member(group_id));
create policy "invites_insert" on public.invites for insert with check (
  public.is_group_member(group_id) and created_by = auth.uid()
);

-- catalog: herkes (girisli) okur
create policy "catalog_read" on public.catalog_items for select using (auth.role() = 'authenticated');

-- group_items
create policy "group_items_all" on public.group_items for all
  using (public.is_group_member(group_id)) with check (public.is_group_member(group_id));

-- shopping_entries
-- Okuma, ekleme, durum guncelleme: tum aktif uyeler. Silme: ekleyen veya admin (SPEC 6).
create policy "shopping_select" on public.shopping_entries for select
  using (public.is_group_member(group_id));
create policy "shopping_insert" on public.shopping_entries for insert
  with check (public.is_group_member(group_id) and added_by = auth.uid());
create policy "shopping_update" on public.shopping_entries for update
  using (public.is_group_member(group_id)) with check (public.is_group_member(group_id));
create policy "shopping_delete" on public.shopping_entries for delete using (
  public.is_group_member(group_id) and (
    added_by = auth.uid() or exists (
      select 1 from public.memberships
      where group_id = shopping_entries.group_id and user_id = auth.uid()
        and role = 'admin' and left_at is null
    )
  )
);

-- expenses / expense_items / expense_shares: yazma SADECE save_expense RPC'siyle
-- (toplam, uyelik ve yetki kontrolleri orada). Dogrudan insert/update policy'si yok.
-- Silme: harcamayi olusturan veya admin (paylar/kalemler cascade ile silinir).
create policy "expenses_select" on public.expenses for select
  using (public.is_group_member(group_id));
create policy "expenses_delete" on public.expenses for delete using (
  public.is_group_member(group_id) and (
    created_by = auth.uid() or exists (
      select 1 from public.memberships m
      where m.group_id = expenses.group_id and m.user_id = auth.uid()
        and m.role = 'admin' and m.left_at is null
    )
  )
);

create policy "expense_items_select" on public.expense_items for select
  using (exists (select 1 from public.expenses e where e.id = expense_id and public.is_group_member(e.group_id)));

create policy "expense_shares_select" on public.expense_shares for select
  using (exists (select 1 from public.expenses e where e.id = expense_id and public.is_group_member(e.group_id)));

-- settlements: yazma SADECE record_settlement RPC'siyle, burada sadece okuma
create policy "settlements_select" on public.settlements for select
  using (public.is_group_member(group_id));

-- ============================================================
-- 4) GERCEK ZAMANLI SENKRON (liste anlik guncellensin)
-- ============================================================
alter publication supabase_realtime add table public.shopping_entries;
alter publication supabase_realtime add table public.expenses;
alter publication supabase_realtime add table public.settlements;

-- ============================================================
-- 5) KATALOG: WG'de ortak alinan esyalar (yiyecek yok; kategoriler: household, cleaning, bathroom)
-- ============================================================
insert into public.catalog_items (name_de, name_en, name_tr, category) values
  ('Küchenrolle', 'Paper towels', 'Kağıt havlu', 'household'),
  ('Müllbeutel', 'Trash bags', 'Çöp poşeti', 'household'),
  ('Alufolie', 'Aluminium foil', 'Alüminyum folyo', 'household'),
  ('Frischhaltefolie', 'Cling film', 'Streç film', 'household'),
  ('Backpapier', 'Baking paper', 'Pişirme kağıdı', 'household'),
  ('Gefrierbeutel', 'Freezer bags', 'Buzluk poşeti', 'household'),
  ('Kaffeefilter', 'Coffee filters', 'Filtre kahve kağıdı', 'household'),
  ('Glühbirne', 'Light bulb', 'Ampul', 'household'),
  ('Batterien', 'Batteries', 'Pil', 'household'),
  ('Mehrfachsteckdose', 'Power strip', 'Çoklu priz', 'household'),
  ('Kerzen', 'Candles', 'Mum', 'household'),
  ('Streichhölzer', 'Matches', 'Kibrit', 'household'),
  ('Feuerzeug', 'Lighter', 'Çakmak', 'household'),
  ('Klebeband', 'Adhesive tape', 'Bant', 'household'),
  ('Wäscheklammern', 'Clothes pegs', 'Çamaşır mandalı', 'household'),
  ('Staubsaugerbeutel', 'Vacuum bags', 'Süpürge torbası', 'household'),
  ('Taschentücher', 'Tissues', 'Kağıt mendil', 'household'),
  ('Spülmittel', 'Dish soap', 'Bulaşık deterjanı', 'cleaning'),
  ('Spülmaschinentabs', 'Dishwasher tabs', 'Bulaşık makinesi tableti', 'cleaning'),
  ('Spülmaschinensalz', 'Dishwasher salt', 'Bulaşık makinesi tuzu', 'cleaning'),
  ('Klarspüler', 'Rinse aid', 'Parlatıcı', 'cleaning'),
  ('Waschmittel', 'Laundry detergent', 'Çamaşır deterjanı', 'cleaning'),
  ('Weichspüler', 'Fabric softener', 'Çamaşır yumuşatıcı', 'cleaning'),
  ('Schwämme', 'Sponges', 'Sünger', 'cleaning'),
  ('Putztücher', 'Cleaning cloths', 'Temizlik bezi', 'cleaning'),
  ('Spülbürste', 'Dish brush', 'Bulaşık fırçası', 'cleaning'),
  ('Allzweckreiniger', 'All-purpose cleaner', 'Çok amaçlı temizleyici', 'cleaning'),
  ('Glasreiniger', 'Glass cleaner', 'Cam temizleyici', 'cleaning'),
  ('Badreiniger', 'Bathroom cleaner', 'Banyo temizleyici', 'cleaning'),
  ('WC-Reiniger', 'Toilet cleaner', 'Tuvalet temizleyici', 'cleaning'),
  ('Entkalker', 'Descaler', 'Kireç çözücü', 'cleaning'),
  ('Rohrreiniger', 'Drain cleaner', 'Gider açıcı', 'cleaning'),
  ('Gummihandschuhe', 'Rubber gloves', 'Temizlik eldiveni', 'cleaning'),
  ('Wischmopp', 'Mop', 'Paspas', 'cleaning'),
  ('Eimer', 'Bucket', 'Kova', 'cleaning'),
  ('Besen', 'Broom', 'Süpürge', 'cleaning'),
  ('Kehrschaufel', 'Dustpan', 'Faraş', 'cleaning'),
  ('Toilettenpapier', 'Toilet paper', 'Tuvalet kağıdı', 'bathroom'),
  ('Handseife', 'Hand soap', 'El sabunu', 'bathroom'),
  ('Lufterfrischer', 'Air freshener', 'Oda kokusu', 'bathroom'),
  ('WC-Duftstein', 'Toilet freshener', 'Tuvalet bloğu', 'bathroom')
on conflict (name_de) do update set
  name_en = excluded.name_en, name_tr = excluded.name_tr, category = excluded.category;
