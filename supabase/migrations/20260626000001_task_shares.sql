create table public.task_shares (
  id                bigserial primary key,
  task_id           bigint not null references public.todos (id) on delete cascade,
  owner_id          uuid   not null references auth.users (id) on delete cascade,
  shared_with_email text   not null,
  access_level      text   not null default 'read' check (access_level in ('read', 'edit')),
  created_at        timestamptz not null default now(),
  unique (task_id, shared_with_email)
);

alter table public.task_shares enable row level security;

-- Task owner can manage all shares for their tasks
create policy "Owner can manage shares" on public.task_shares
  for all to authenticated
  using  (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- Shared user can see shares addressed to them
create policy "Shared user can view their shares" on public.task_shares
  for select to authenticated
  using (shared_with_email = auth.email());

-- Allow reading todos that are shared with the current user
create policy "Users can read shared todos" on public.todos
  for select to authenticated
  using (
    exists (
      select 1 from public.task_shares
      where task_id = public.todos.id
        and shared_with_email = auth.email()
    )
  );

-- Allow editing todos that are shared with edit access
create policy "Users can update shared todos" on public.todos
  for update to authenticated
  using (
    exists (
      select 1 from public.task_shares
      where task_id = public.todos.id
        and shared_with_email = auth.email()
        and access_level = 'edit'
    )
  )
  with check (
    exists (
      select 1 from public.task_shares
      where task_id = public.todos.id
        and shared_with_email = auth.email()
        and access_level = 'edit'
    )
  );
