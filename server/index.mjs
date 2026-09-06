import http from "node:http";

const SYSTEM_PROMPT = `Դու «Հոգևոր ԱԲ» ես՝ Ararat Bible հավելվածի խորհրդատուն։

Կանոններ.
1. Պատասխանիր միայն հայերենով՝ հանգիստ, հարգալից և հոգևոր ձևով։
2. Հիմնվիր ՄԻԱՅՆ օգտատիրոջ հարցի և հաղորդագրության մեջ տրված «Տրված հատվածներ»-ի վրա։ Դա հավելվածի Աստվածաշնչյան տեքստն է։
3. Երբեք մի հորինիր Աստվածաշնչյան համարներ, մեջբերումներ, գրքերի անուններ կամ բառացի տեքստ։
4. Եթե մեջբերում ես, օգտագործիր միայն տրված հատվածների ճշգրիտ տեքստը և նշիր համարը այնպես, ինչպես տրված է (օրինակ՝ Յովհաննէս 3:16)։
5. Եթե տրված հատվածները բավարար չեն կոնկրետ համար նշելու համար, ասա ազնվորեն, որ այս պատասխանում չես կարող հաստատել կոնկրետ համարը, և տուր ընդհանուր հոգևոր խորհուրդ առանց կեղծ մեջբերումների։
6. Բժշկական, իրավական կամ արտակարգ իրավիճակներում խորհուրդ տուր դիմել համապատասխան մասնագետի։
7. Մի երկարիր անտեղի։ Պատասխանը լինի պարզ և օգտակար։`;

const hits = new Map();
const PORT = Number(process.env.PORT || 8787);

function json(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, X-Spiritual-Ai-Gate",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  });
  res.end(body);
}

function clientIp(req) {
  const forwarded = req.headers["x-forwarded-for"];
  if (typeof forwarded === "string" && forwarded.length > 0) {
    return forwarded.split(",")[0].trim();
  }
  return req.socket?.remoteAddress || "unknown";
}

function rateLimited(ip, limit = 20, windowMs = 10 * 60 * 1000) {
  const now = Date.now();
  const recent = (hits.get(ip) || []).filter((t) => now - t < windowMs);
  recent.push(now);
  hits.set(ip, recent);
  return recent.length > limit;
}

function asString(value, max) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, max);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (chunk) => {
      chunks.push(chunk);
      if (chunks.reduce((n, c) => n + c.length, 0) > 200_000) {
        reject(new Error("Body too large"));
      }
    });
    req.on("end", () => {
      const raw = Buffer.concat(chunks).toString("utf8");
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch {
        reject(new Error("Invalid JSON"));
      }
    });
    req.on("error", reject);
  });
}

const server = http.createServer(async (req, res) => {
  if (req.method === "OPTIONS") {
    json(res, 204, {});
    return;
  }

  if (req.method === "GET") {
    json(res, 200, {ok: true, service: "spiritual-ai"});
    return;
  }

  if (req.method !== "POST") {
    json(res, 405, {error: "Method not allowed"});
    return;
  }

  const expectedGate = process.env.SPIRITUAL_AI_GATE || "";
  if (expectedGate) {
    const provided = String(req.headers["x-spiritual-ai-gate"] || "");
    if (provided !== expectedGate) {
      json(res, 401, {error: "Unauthorized"});
      return;
    }
  }

  const ip = clientIp(req);
  if (rateLimited(ip)) {
    json(res, 429, {error: "Too many requests"});
    return;
  }

  const openaiKey = process.env.OPENAI_API_KEY || "";
  if (!openaiKey) {
    json(res, 500, {error: "Server is not configured"});
    return;
  }

  let body;
  try {
    body = await readBody(req);
  } catch (error) {
    json(res, 400, {error: error.message || "Invalid body"});
    return;
  }

  const message = asString(body.message, 2000);
  if (!message) {
    json(res, 400, {error: "Missing message"});
    return;
  }

  const history = Array.isArray(body.history) ? body.history.slice(-8) : [];
  const passages = Array.isArray(body.passages) ? body.passages.slice(0, 12) : [];
  const passageBlock = passages
    .map((p) => {
      const ref = asString(p.ref, 80);
      const text = asString(p.text, 900);
      if (!ref || !text) return "";
      return `[${ref}] ${text}`;
    })
    .filter(Boolean)
    .join("\n");

  const messages = [{role: "system", content: SYSTEM_PROMPT}];
  for (const turn of history) {
    const role = turn.role === "assistant" ? "assistant" : "user";
    const content = asString(turn.content, 2500);
    if (!content) continue;
    messages.push({role, content});
  }
  messages.push({
    role: "user",
    content:
      `Օգտատիրոջ հարցը:\n${message}\n\n` +
      (passageBlock
        ? `Տրված հատվածներ (միայն սրանցից մեջբերիր):\n${passageBlock}`
        : "Տրված հատվածներ չկան։ Կոնկրետ համարներ մի նշիր։"),
  });

  try {
    const openaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL || "gpt-4o-mini",
        temperature: 0.35,
        max_tokens: 800,
        messages,
      }),
    });

    if (!openaiRes.ok) {
      const errText = await openaiRes.text();
      console.error("OpenAI error", openaiRes.status, errText.slice(0, 500));
      json(res, 502, {error: "Upstream error"});
      return;
    }

    const data = await openaiRes.json();
    const reply = data.choices?.[0]?.message?.content?.trim() || "";
    if (!reply) {
      json(res, 502, {error: "Empty upstream reply"});
      return;
    }
    json(res, 200, {reply});
  } catch (error) {
    console.error(error);
    json(res, 500, {error: "Server error"});
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Spiritual AI server listening on port ${PORT}`);
});
