-- WG App: Supabase / PostgreSQL schema
-- Supabase Dashboard > SQL Editor'e yapistirip calistir.
-- Tutarlar daima cent (tam sayi) olarak saklanir: 23,50 EUR -> 2350

-- ============================================================
-- 1) TABLOLAR
-- ============================================================

create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  locale       text not null default 'de' check (locale in ('de', 'en')),
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

-- Gruptan ayril (kayit silinmez, left_at doldurulur)
create or replace function public.leave_group(gid uuid)
returns void
language sql security definer set search_path = public
as $$
  update public.memberships set left_at = now()
  where group_id = gid and user_id = auth.uid();
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
create policy "shopping_all" on public.shopping_entries for all
  using (public.is_group_member(group_id)) with check (public.is_group_member(group_id));

-- expenses
create policy "expenses_all" on public.expenses for all
  using (public.is_group_member(group_id)) with check (public.is_group_member(group_id));

-- expense_items / expense_shares: harcamanin grubuna gore
create policy "expense_items_all" on public.expense_items for all
  using (exists (select 1 from public.expenses e where e.id = expense_id and public.is_group_member(e.group_id)))
  with check (exists (select 1 from public.expenses e where e.id = expense_id and public.is_group_member(e.group_id)));

create policy "expense_shares_all" on public.expense_shares for all
  using (exists (select 1 from public.expenses e where e.id = expense_id and public.is_group_member(e.group_id)))
  with check (exists (select 1 from public.expenses e where e.id = expense_id and public.is_group_member(e.group_id)));

-- settlements
create policy "settlements_all" on public.settlements for all
  using (public.is_group_member(group_id)) with check (public.is_group_member(group_id));

-- ============================================================
-- 4) GERCEK ZAMANLI SENKRON (liste anlik guncellensin)
-- ============================================================
alter publication supabase_realtime add table public.shopping_entries;
alter publication supabase_realtime add table public.expenses;

-- ============================================================
-- 5) ORNEK KATALOG (baslangic icin; sonra genislet)
-- ============================================================
insert into public.catalog_items (name_de, name_en, category) values
  ('Milch', 'Milk', 'food'),
  ('Brot', 'Bread', 'food'),
  ('Eier', 'Eggs', 'food'),
  ('Butter', 'Butter', 'food'),
  ('Nudeln', 'Pasta', 'food'),
  ('Reis', 'Rice', 'food'),
  ('Kaffee', 'Coffee', 'food'),
  ('Tee', 'Tea', 'food'),
  ('Toilettenpapier', 'Toilet paper', 'household'),
  ('Küchenrolle', 'Paper towels', 'household'),
  ('Spülmittel', 'Dish soap', 'household'),
  ('Spülmaschinentabs', 'Dishwasher tabs', 'household'),
  ('Waschmittel', 'Laundry detergent', 'household'),
  ('Müllbeutel', 'Trash bags', 'household'),
  ('Schwämme', 'Sponges', 'household'),
  ('Allzweckreiniger', 'All-purpose cleaner', 'household'),
  ('Glühbirne', 'Light bulb', 'household'),
  ('Batterien', 'Batteries', 'household'),
  ('Salz', 'Salt', 'food'),
  ('Öl', 'Cooking oil', 'food')
on conflict do nothing;
