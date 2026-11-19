// Supabase Edge Function: delete-object
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { AwsClient } from "https://esm.sh/aws4fetch@1.0.20";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401, headers: { ...cors, "Content-Type": "application/json" } });
    }
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401, headers: { ...cors, "Content-Type": "application/json" } });
    }

    const { path } = await req.json();
    if (!path || typeof path !== "string" || !path.includes(`/${user.id}/`)) {
      return new Response(JSON.stringify({ error: "invalid_path" }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
    }

    const accountId = Deno.env.get("R2_ACCOUNT_ID")!;
    const accessKey = Deno.env.get("R2_ACCESS_KEY")!;
    const secretKey = Deno.env.get("R2_SECRET_KEY")!;
    const bucket = Deno.env.get("R2_BUCKET") || "golpoghor";

    const client = new AwsClient({
      accessKeyId: accessKey,
      secretAccessKey: secretKey,
      region: "auto",
      service: "s3",
    });

    const endpoint = `https://${accountId}.r2.cloudflarestorage.com/${bucket}/${path}`;
    const signed = await client.sign(new Request(endpoint, { method: "DELETE" }), { aws: { signQuery: true } });
    const del = await fetch(signed.url, { method: "DELETE" });

    return new Response(JSON.stringify({ ok: del.ok, status: del.status }), {
      status: 200,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
