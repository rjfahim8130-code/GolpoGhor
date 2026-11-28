// Supabase Edge Function: create-upload-url
// Secrets: R2_ACCESS_KEY, R2_SECRET_KEY, R2_ACCOUNT_ID, R2_BUCKET, R2_PUBLIC_BASE_URL
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
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        status: 401,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: userErr } = await supabase.auth.getUser();
    if (userErr || !user) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        status: 401,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const path = String(body.path || "");
    const contentType = String(body.contentType || "application/octet-stream");
    if (!path || path.includes("..") || !path.startsWith(`${body.folder || path.split("/")[0]}/`) && !path.includes(`/${user.id}/`)) {
      // must contain uid segment
      if (!path.includes(`/${user.id}/`)) {
        return new Response(JSON.stringify({ error: "invalid_path" }), {
          status: 400,
          headers: { ...cors, "Content-Type": "application/json" },
        });
      }
    }

    const accountId = Deno.env.get("R2_ACCOUNT_ID")!;
    const accessKey = Deno.env.get("R2_ACCESS_KEY")!;
    const secretKey = Deno.env.get("R2_SECRET_KEY")!;
    const bucket = Deno.env.get("R2_BUCKET") || "golpoghor";
    const publicBase = Deno.env.get("R2_PUBLIC_BASE_URL") || "";

    const client = new AwsClient({
      accessKeyId: accessKey,
      secretAccessKey: secretKey,
      region: "auto",
      service: "s3",
    });

    const endpoint = `https://${accountId}.r2.cloudflarestorage.com/${bucket}/${path}`;
    // Presign PUT for 10 minutes
    const signed = await client.sign(
      new Request(endpoint, {
        method: "PUT",
        headers: { "Content-Type": contentType },
      }),
      { aws: { signQuery: true } },
    );

    // aws4fetch signQuery puts signature in URL
    const uploadUrl = signed.url;
    const publicUrl = publicBase ? `${publicBase.replace(/\/$/, "")}/${path}` : "";

    return new Response(
      JSON.stringify({ uploadUrl, publicUrl, path }),
      { status: 200, headers: { ...cors, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
