-- Returns overdue incomplete top-level tasks grouped with their owner's email.
-- security definer lets it read auth.users without exposing it via RLS.
create or replace function public.get_overdue_tasks_with_emails()
returns table (
  user_email  text,
  task_text   text,
  deadline    date,
  responsible text
)
language sql
security definer
stable
as $$
  select
    u.email::text,
    t.text,
    t.deadline,
    t.responsible
  from public.todos t
  join auth.users u on u.id = t.user_id
  where t.deadline < current_date
    and t.done     = false
    and t.parent_id is null
  order by u.email, t.deadline;
$$;
