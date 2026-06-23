-- Her görevi bir kullanıcıya bağla.
-- Önce kolonu eklenebilir (nullable) olarak ekliyoruz.
alter table public.todos
  add column user_id uuid default auth.uid()
    references auth.users (id) on delete cascade;

-- Auth eklenmeden önce oluşmuş, sahibi olmayan (anonim) satırlar yeni
-- kullanıcı bazlı modele taşınamaz; bu yüzden temizleniyorlar.
delete from public.todos where user_id is null;

-- Artık her satırın sahibi var; kolonu zorunlu yap.
alter table public.todos alter column user_id set not null;

-- Kullanıcı bazlı sorgular hızlansın diye index.
create index if not exists todos_user_id_idx on public.todos (user_id);

-- Eski "herkese açık" kuralları kaldır.
drop policy if exists "Anonim erisim - okuma" on public.todos;
drop policy if exists "Anonim erisim - ekleme" on public.todos;
drop policy if exists "Anonim erisim - guncelleme" on public.todos;
drop policy if exists "Anonim erisim - silme" on public.todos;

-- Yeni kurallar: kullanıcı yalnızca KENDİ satırlarına erişebilir.
-- auth.uid() = giriş yapmış kullanıcının kimliği.
create policy "Kendi gorevleri - okuma" on public.todos
  for select to authenticated using (auth.uid() = user_id);

create policy "Kendi gorevleri - ekleme" on public.todos
  for insert to authenticated with check (auth.uid() = user_id);

create policy "Kendi gorevleri - guncelleme" on public.todos
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Kendi gorevleri - silme" on public.todos
  for delete to authenticated using (auth.uid() = user_id);
