import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl     = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const resendApiKey    = Deno.env.get("RESEND_API_KEY")!;
const fromEmail       = Deno.env.get("FROM_EMAIL") ?? "noreply@yourdomain.com";

Deno.serve(async () => {
  const sb = createClient(supabaseUrl, serviceRoleKey);

  // Fetch all overdue tasks with owner emails via the helper function
  const { data: rows, error } = await sb.rpc("get_overdue_tasks_with_emails");
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  if (!rows?.length) return new Response("No overdue tasks.", { status: 200 });

  // Group tasks by user email
  const byUser = new Map<string, typeof rows>();
  for (const row of rows) {
    if (!byUser.has(row.user_email)) byUser.set(row.user_email, []);
    byUser.get(row.user_email)!.push(row);
  }

  const results: string[] = [];

  for (const [email, tasks] of byUser) {
    const taskLines = tasks.map((t) => {
      const due = new Date(t.deadline + "T00:00:00").toLocaleDateString("en-GB", {
        day: "2-digit", month: "short", year: "numeric",
      });
      const who = t.responsible ? ` — ${t.responsible}` : "";
      return `• ${t.task_text}${who} (due ${due})`;
    });

    const html = `
      <p>Hi,</p>
      <p>You have <strong>${tasks.length} overdue task${tasks.length > 1 ? "s" : ""}</strong> on your Follow Up list:</p>
      <ul style="padding-left:20px;line-height:1.8">
        ${tasks.map((t) => {
          const due = new Date(t.deadline + "T00:00:00").toLocaleDateString("en-GB", {
            day: "2-digit", month: "short", year: "numeric",
          });
          const who = t.responsible ? ` <span style="color:#7c8b9b">— ${t.responsible}</span>` : "";
          return `<li><strong>${t.task_text}</strong>${who} <span style="color:#d6453f">(due ${due})</span></li>`;
        }).join("")}
      </ul>
      <p><a href="https://omayemre.github.io/todo-app/" style="color:#46a784">Open your task list →</a></p>
      <hr style="border:none;border-top:1px solid #e4eaf1;margin:24px 0">
      <p style="color:#7c8b9b;font-size:12px">You're receiving this because you have overdue tasks in Follow Up / To Do list.</p>
    `;

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromEmail,
        to: email,
        subject: `⚠️ You have ${tasks.length} overdue task${tasks.length > 1 ? "s" : ""}`,
        html,
        text: taskLines.join("\n"),
      }),
    });

    results.push(`${email}: ${res.ok ? "sent" : await res.text()}`);
  }

  return new Response(results.join("\n"), { status: 200 });
});
