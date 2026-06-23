-- Add professional task-tracking fields.
alter table public.todos
  add column if not exists deadline    date,
  add column if not exists responsible text,
  add column if not exists remarks     text;

-- Rename existing RLS policies to English for clarity.
alter policy "Kendi gorevleri - okuma"      on public.todos rename to "Users can read own todos";
alter policy "Kendi gorevleri - ekleme"     on public.todos rename to "Users can insert own todos";
alter policy "Kendi gorevleri - guncelleme" on public.todos rename to "Users can update own todos";
alter policy "Kendi gorevleri - silme"      on public.todos rename to "Users can delete own todos";
