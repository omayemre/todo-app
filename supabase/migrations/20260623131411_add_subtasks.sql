-- Allow tasks to have sub-tasks via a self-referencing parent.
-- A NULL parent_id means a top-level task; otherwise it is a sub-task.
-- Deleting a parent task cascades to its sub-tasks.
alter table public.todos
  add column if not exists parent_id bigint
    references public.todos (id) on delete cascade;

create index if not exists todos_parent_id_idx on public.todos (parent_id);
