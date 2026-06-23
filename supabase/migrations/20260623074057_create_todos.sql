-- todos tablosu: görevleri saklar
create table if not exists public.todos (
  id          bigint generated always as identity primary key,
  text        text not null,
  done        boolean not null default false,
  created_at  timestamptz not null default now()
);

-- Row Level Security'i etkinleştir (Supabase'de zorunlu güvenlik katmanı)
alter table public.todos enable row level security;

-- Bu basit uygulamada giriş (login) yok. Bu yüzden anonim kullanıcıya
-- tam erişim veriyoruz. NOT: Bu tabloyu herkes okuyup yazabilir.
-- Kişisel/öğrenme amaçlı yeterli; gerçek uygulamada kullanıcı girişi eklenmeli.
create policy "Anonim erisim - okuma" on public.todos
  for select to anon, authenticated using (true);

create policy "Anonim erisim - ekleme" on public.todos
  for insert to anon, authenticated with check (true);

create policy "Anonim erisim - guncelleme" on public.todos
  for update to anon, authenticated using (true) with check (true);

create policy "Anonim erisim - silme" on public.todos
  for delete to anon, authenticated using (true);
