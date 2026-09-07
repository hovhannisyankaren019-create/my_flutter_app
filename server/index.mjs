import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const SYSTEM_PROMPT = `Դու «Հոգևոր ԱԲ» ես՝ Ararat Bible-ի խորհրդատուն։

Կանոններ.
1. Պատասխանիր միայն հայերենով՝ հանգիստ, հարգալից և հոգևոր ձևով։
2. Եթե կա «Սեփական նյութեր» բաժին, նախ հիմնվիր դրանց վրա և պատասխանիր այնպես, ինչպես այնտեղ է գրված։
3. Համար առաջարկիր ՄԻԱՅՆ եթե «Տրված հատվածներ»-ում կա հատված, որն ուղղակիորեն նույն թեմային է, ինչ հարցը։ Պատահական համընկնող բառով համար մի նշիր։
4. Երբեք մի հորինիր Աստվածաշնչյան համարներ։ Մեջբերիր միայն տրված հատվածներից։
5. Եթե համապատասխան համար չկա, համարներ մի առաջարկիր. ասա, որ այս պատասխանում հաստատված համար չունես, և տուր կարճ հոգևոր խորհուրդ։
6. Բժշկական, իրավական կամ արտակարգ իրավիճակներում խորհուրդ տուր դիմել մասնագետի։
7. Մի երկարիր անտեղի։`;

const hits = new Map();
const telegramHistory = new Map();
const teachState = new Map();
const lastByChat = new Map();
const lastByBotMsg = new Map();
const PORT = Number(process.env.PORT || 8787);
const PUBLIC_URL =
  process.env.PUBLIC_URL || "https://ararat-bible-spiritual-ai.onrender.com";
const GITHUB_REPO =
  process.env.GITHUB_REPO || "hovhannisyankaren019-create/my_flutter_app";
const GITHUB_BRANCH = process.env.GITHUB_BRANCH || "main";
const LEARNED_FILE = "server/knowledge-learned.txt";
const TEACHERS_FILE = "server/teachers.txt";

let learnedCache = "";
const extraTeachers = new Set();

function envTeachers() {
  return (process.env.TELEGRAM_ADMIN_IDS || "")
    .split(/[,\s]+/)
    .map((s) => s.trim())
    .filter(Boolean);
}

function parseTeacherIds(text) {
  return String(text || "")
    .split(/[\s,;]+/)
    .map((s) => s.trim())
    .filter((s) => /^\d+$/.test(s));
}

function isAdmin(userId) {
  const id = String(userId);
  return envTeachers().includes(id) || extraTeachers.has(id);
}

function allTeacherIds() {
  return [...new Set([...envTeachers(), ...extraTeachers])];
}

function loadBaseKnowledge() {
  try {
    return fs.readFileSync(path.join(__dirname, "knowledge.txt"), "utf8").trim();
  } catch {
    return "";
  }
}

function loadKnowledge() {
  const parts = [loadBaseKnowledge(), learnedCache].filter(Boolean);
  return parts.join("\n\n");
}

async function refreshLearned() {
  try {
    const local = fs.readFileSync(
      path.join(__dirname, "knowledge-learned.txt"),
      "utf8",
    );
    if (local.trim()) learnedCache = local.trim();
  } catch {
    /* optional file */
  }
  const token = process.env.GITHUB_TOKEN || "";
  const url = token
    ? `https://api.github.com/repos/${GITHUB_REPO}/contents/${LEARNED_FILE}?ref=${GITHUB_BRANCH}`
    : `https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/${LEARNED_FILE}`;
  const headers = token
    ? {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "User-Agent": "ararat-spiritual-ai",
      }
    : {"User-Agent": "ararat-spiritual-ai"};
  const res = await fetch(url, {headers});
  if (!res.ok) return;
  if (token) {
    const data = await res.json();
    if (data.content) {
      learnedCache = Buffer.from(data.content, "base64").toString("utf8").trim();
    }
    return;
  }
  const text = (await res.text()).trim();
  if (text && !text.startsWith("404")) learnedCache = text;
}

async function refreshTeachers() {
  extraTeachers.clear();
  try {
    const local = fs.readFileSync(path.join(__dirname, "teachers.txt"), "utf8");
    for (const id of parseTeacherIds(local)) extraTeachers.add(id);
  } catch {
    /* optional */
  }
  const token = process.env.GITHUB_TOKEN || "";
  const url = token
    ? `https://api.github.com/repos/${GITHUB_REPO}/contents/${TEACHERS_FILE}?ref=${GITHUB_BRANCH}`
    : `https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/${TEACHERS_FILE}`;
  const headers = token
    ? {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "User-Agent": "ararat-spiritual-ai",
      }
    : {"User-Agent": "ararat-spiritual-ai"};
  const res = await fetch(url, {headers});
  if (!res.ok) return;
  let text = "";
  if (token) {
    const data = await res.json();
    if (data.content) {
      text = Buffer.from(data.content, "base64").toString("utf8");
    }
  } else {
    text = await res.text();
  }
  for (const id of parseTeacherIds(text)) extraTeachers.add(id);
}

async function saveTeachers() {
  const body = `${allTeacherIds().join("\n")}\n`;
  const token = process.env.GITHUB_TOKEN || "";
  if (!token) {
    fs.writeFileSync(path.join(__dirname, "teachers.txt"), body, "utf8");
    return "memory";
  }
  const metaRes = await fetch(
    `https://api.github.com/repos/${GITHUB_REPO}/contents/${TEACHERS_FILE}?ref=${GITHUB_BRANCH}`,
    {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "User-Agent": "ararat-spiritual-ai",
      },
    },
  );
  let sha;
  if (metaRes.ok) {
    const meta = await metaRes.json();
    sha = meta.sha;
  }
  const putRes = await fetch(
    `https://api.github.com/repos/${GITHUB_REPO}/contents/${TEACHERS_FILE}`,
    {
      method: "PUT",
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "User-Agent": "ararat-spiritual-ai",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Update Spiritual AI teachers",
        content: Buffer.from(body).toString("base64"),
        branch: GITHUB_BRANCH,
        sha,
      }),
    },
  );
  if (!putRes.ok) {
    const err = await putRes.text();
    console.error("GitHub teachers save failed", putRes.status, err.slice(0, 300));
    throw new Error("github");
  }
  return "github";
}

async function saveLearned(text) {
  learnedCache = text.trim();
  const token = process.env.GITHUB_TOKEN || "";
  if (!token) {
    fs.writeFileSync(
      path.join(__dirname, "knowledge-learned.txt"),
      `${learnedCache}\n`,
      "utf8",
    );
    return "memory";
  }
  const metaRes = await fetch(
    `https://api.github.com/repos/${GITHUB_REPO}/contents/${LEARNED_FILE}?ref=${GITHUB_BRANCH}`,
    {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "User-Agent": "ararat-spiritual-ai",
      },
    },
  );
  let sha;
  if (metaRes.ok) {
    const meta = await metaRes.json();
    sha = meta.sha;
  }
  const putRes = await fetch(
    `https://api.github.com/repos/${GITHUB_REPO}/contents/${LEARNED_FILE}`,
    {
      method: "PUT",
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "User-Agent": "ararat-spiritual-ai",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Update Spiritual AI Telegram lessons",
        content: Buffer.from(`${learnedCache}\n`).toString("base64"),
        branch: GITHUB_BRANCH,
        sha,
      }),
    },
  );
  if (!putRes.ok) {
    const err = await putRes.text();
    console.error("GitHub save failed", putRes.status, err.slice(0, 300));
    throw new Error("github");
  }
  return "github";
}

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

function pathnameOf(req) {
  try {
    return new URL(req.url || "/", "http://localhost").pathname;
  } catch {
    return "/";
  }
}

async function generateReply({message, history, passages}) {
  const openaiKey = process.env.OPENAI_API_KEY || "";
  if (!openaiKey) {
    throw new Error("not_configured");
  }

  const knowledge = loadKnowledge();
  const passageBlock = (Array.isArray(passages) ? passages.slice(0, 12) : [])
    .map((p) => {
      const ref = asString(p.ref, 80);
      const text = asString(p.text, 900);
      if (!ref || !text) return "";
      return `[${ref}] ${text}`;
    })
    .filter(Boolean)
    .join("\n");

  const messages = [{role: "system", content: SYSTEM_PROMPT}];
  if (knowledge) {
    messages.push({
      role: "system",
      content: `Սեփական նյութեր (սրանցով պատասխանիր, եթե հարցը համապատասխանում է):\n${knowledge.slice(0, 12000)}`,
    });
  }

  for (const turn of Array.isArray(history) ? history.slice(-8) : []) {
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
        ? `Տրված հատվածներ (միայն սրանցից մեջբերիր, և միայն եթե հատվածը ուղղակիորեն համապատասխանում է հարցի թեմային):\n${passageBlock}`
        : "Տրված հատվածներ չկան։ Կոնկրետ համարներ մի նշիր և համարներ մի առաջարկիր։"),
  });

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
    throw new Error("upstream");
  }

  const data = await openaiRes.json();
  const reply = data.choices?.[0]?.message?.content?.trim() || "";
  if (!reply) throw new Error("empty");
  return reply;
}

function rememberTelegram(chatId, role, content) {
  const list = telegramHistory.get(chatId) || [];
  list.push({role, content});
  telegramHistory.set(chatId, list.slice(-8));
}

async function sendTelegram(chatId, text) {
  const token = process.env.TELEGRAM_BOT_TOKEN || "";
  if (!token) return null;
  const res = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      chat_id: chatId,
      text: text.slice(0, 4000),
    }),
  });
  const data = await res.json().catch(() => ({}));
  return data.result || null;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function upsertLearned(question, answer) {
  const q = question.trim();
  const a = answer.trim();
  const re = new RegExp(
    `(^|\\n\\n)Հարց\\.\\s*${escapeRegExp(q)}\\nՊատասխան\\.[\\s\\S]*?(?=\\n\\nՀարց\\. |$)`,
    "g",
  );
  const cleaned = learnedCache.replace(re, "\n\n").replace(/\n{3,}/g, "\n\n").trim();
  return `${cleaned}\n\nՀարց. ${q}\nՊատասխան. ${a}`.trim();
}

async function saveLesson(chatId, question, answer) {
  const q = asString(question, 500);
  const a = asString(answer, 2000);
  if (!q || !a) {
    await sendTelegram(chatId, "Հարցը կամ պատասխանը դատարկ էր։");
    return;
  }
  const next = upsertLearned(q, a);
  try {
    const where = await saveLearned(next);
    await sendTelegram(
      chatId,
      where === "github"
        ? "Պահեցի ձևափոխված պատասխանը։ Հաջորդ անգամ այս հարցին այդպես կպատասխանեմ, նաև հավելվածում։"
        : "Պահեցի այս պահին։ Որ մնա ընդմիշտ, Render-ում ավելացրեք GITHUB_TOKEN։",
    );
  } catch (error) {
    console.error(error);
    await sendTelegram(
      chatId,
      "Չստացվեց պահել դասը։ Ստուգեք GITHUB_TOKEN-ը Render-ում։",
    );
  }
}

async function handleTelegram(req, res, body) {
  const expected = process.env.SPIRITUAL_AI_GATE || "";
  if (expected) {
    const got = String(req.headers["x-telegram-bot-api-secret-token"] || "");
    if (got !== expected) {
      json(res, 401, {error: "Unauthorized"});
      return;
    }
  }

  json(res, 200, {ok: true});

  const message = body?.message;
  const chatId = message?.chat?.id;
  const userId = message?.from?.id;
  const text = asString(message?.text, 2000);
  if (!chatId || !text) return;

  if (text === "/start") {
    await sendTelegram(
      chatId,
      isAdmin(userId)
        ? "Բարև։ Դուք ուսուցիչ եք։ Հարցրեք, հետո reply արեք իմ պատասխանին ու գրեք ճիշտ տարբերակը։\n\n/fix ուղղված պատասխանը\n/lessons — սովորվածները\n/teachers — ուսուցիչների ցանկը\n/addteacher ID — ընկերոջ ID-ն ավելացնել\n/myid — ձեր ID-ն"
        : "Բարև։ Ես Հոգևոր ԱԲ-ն եմ։ Հարցրեք հայերենով Աստվածաշնչի կամ հոգևոր թեմաներով։",
    );
    return;
  }

  if (text === "/myid") {
    await sendTelegram(
      chatId,
      `Ձեր Telegram ID-ն է ${userId}։\nԵրեք ուսուցիչների ID-ները Render-ում դրեք այսպես.\nTELEGRAM_ADMIN_IDS=111111,222222,333333`,
    );
    return;
  }

  if (text === "/cancel") {
    teachState.delete(chatId);
    await sendTelegram(chatId, "Սովորեցնելը չեղարկվեց։");
    return;
  }

  if (
    text === "/lessons" ||
    text === "/teachers" ||
    text.startsWith("/teach") ||
    text.startsWith("/fix") ||
    text.startsWith("/addteacher") ||
    teachState.has(chatId)
  ) {
    if (!isAdmin(userId)) {
      await sendTelegram(
        chatId,
        "Սովորեցնել կարող են միայն 3 ուսուցիչները։ Գրեք /myid, հետո այդ թիվը ավելացրեք TELEGRAM_ADMIN_IDS-ում։",
      );
      return;
    }
  }

  if (text === "/teachers") {
    const ids = allTeacherIds();
    await sendTelegram(
      chatId,
      ids.length ? `Ուսուցիչներ (${ids.length}).\n${ids.join("\n")}` : "Դեռ ուսուցիչ չկա։",
    );
    return;
  }

  if (text.startsWith("/addteacher")) {
    const id = parseTeacherIds(text.replace(/^\/addteacher/, ""))[0];
    if (!id) {
      await sendTelegram(chatId, "Օրինակ՝ /addteacher 123456789\nԸնկերը թող գրի /myid ու տա թիվը։");
      return;
    }
    extraTeachers.add(id);
    try {
      await saveTeachers();
      await sendTelegram(chatId, `Ավելացվեց ուսուցիչ ${id}։ Հիմա կարող է reply-ով ձևափոխել պատասխանները։`);
    } catch (error) {
      console.error(error);
      await sendTelegram(chatId, "Ավելացրի հիմա, բայց չպահվեց GitHub-ում։ Դրեք նաև Render-ի TELEGRAM_ADMIN_IDS-ում։");
    }
    return;
  }

  if (isAdmin(userId)) {
    const replyTo = message.reply_to_message;
    if (replyTo?.from?.is_bot && replyTo?.message_id && !text.startsWith("/")) {
      const mapped = lastByBotMsg.get(`${chatId}:${replyTo.message_id}`);
      const question = mapped?.question || lastByChat.get(chatId)?.question;
      if (question) {
        await saveLesson(chatId, question, text);
        return;
      }
    }
    if (text.startsWith("/fix")) {
      const corrected = text.replace(/^\/fix\s*/, "").trim();
      const last = lastByChat.get(chatId);
      if (!last?.question || !corrected) {
        await sendTelegram(
          chatId,
          "Reply արեք իմ պատասխանին ու գրեք ուղղված տեքստը, կամ՝ /fix նոր պատասխանը",
        );
        return;
      }
      await saveLesson(chatId, last.question, corrected);
      return;
    }
  }

  if (text === "/lessons") {
    const shown = learnedCache.trim() || "Դեռ դաս չկա։";
    await sendTelegram(chatId, shown.slice(0, 4000));
    return;
  }

  if (text === "/teach") {
    teachState.set(chatId, {step: "question"});
    await sendTelegram(
      chatId,
      "Ի՞նչ հարցի համար սովորեմ։ Գրեք հարցը։\nՉեղարկելու համար՝ /cancel",
    );
    return;
  }

  const oneLine = text.match(/^\/teach\s+(.+?)\s*(?:=>|→|->|—|–)\s*(.+)$/s);
  if (oneLine) {
    teachState.delete(chatId);
    await saveLesson(chatId, oneLine[1].trim(), oneLine[2].trim());
    return;
  }

  const pending = teachState.get(chatId);
  if (pending?.step === "question") {
    teachState.set(chatId, {step: "answer", question: text});
    await sendTelegram(chatId, "Լավ։ Հիմա գրեք, թե այդ հարցին ինչ պատասխանեմ։");
    return;
  }
  if (pending?.step === "answer") {
    teachState.delete(chatId);
    await saveLesson(chatId, pending.question, text);
    return;
  }

  try {
    const history = telegramHistory.get(chatId) || [];
    const reply = await generateReply({
      message: text,
      history,
      passages: [],
    });
    rememberTelegram(chatId, "user", text);
    rememberTelegram(chatId, "assistant", reply);
    const sent = await sendTelegram(chatId, reply);
    lastByChat.set(chatId, {question: text, answer: reply});
    if (sent?.message_id) {
      lastByBotMsg.set(`${chatId}:${sent.message_id}`, {question: text});
    }
  } catch (error) {
    console.error(error);
    await sendTelegram(
      chatId,
      "Հիմա չհաջողվեց պատասխանել։ Խնդրում ենք մի փոքրից նորից փորձել։",
    );
  }
}

async function handleAppChat(req, res, body) {
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

  const message = asString(body.message, 2000);
  if (!message) {
    json(res, 400, {error: "Missing message"});
    return;
  }

  try {
    const reply = await generateReply({
      message,
      history: body.history,
      passages: body.passages,
    });
    json(res, 200, {reply});
  } catch (error) {
    if (error.message === "not_configured") {
      json(res, 500, {error: "Server is not configured"});
      return;
    }
    if (error.message === "upstream" || error.message === "empty") {
      json(res, 502, {error: "Upstream error"});
      return;
    }
    console.error(error);
    json(res, 500, {error: "Server error"});
  }
}

async function registerTelegramWebhook() {
  const token = process.env.TELEGRAM_BOT_TOKEN || "";
  if (!token) {
    console.log("Telegram bot is off (no TELEGRAM_BOT_TOKEN)");
    return;
  }
  const webhookUrl = `${PUBLIC_URL.replace(/\/$/, "")}/telegram`;
  const payload = {url: webhookUrl};
  const gate = process.env.SPIRITUAL_AI_GATE || "";
  if (gate) payload.secret_token = gate;
  const res = await fetch(`https://api.telegram.org/bot${token}/setWebhook`, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify(payload),
  });
  const data = await res.json();
  console.log("Telegram webhook:", data.ok ? webhookUrl : JSON.stringify(data));
}

const server = http.createServer(async (req, res) => {
  const pathname = pathnameOf(req);

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

  let body;
  try {
    body = await readBody(req);
  } catch (error) {
    json(res, 400, {error: error.message || "Invalid body"});
    return;
  }

  if (pathname === "/telegram") {
    await handleTelegram(req, res, body);
    return;
  }

  await handleAppChat(req, res, body);
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Spiritual AI server listening on port ${PORT}`);
  refreshLearned().catch((error) => {
    console.error("Failed to load lessons", error);
  });
  refreshTeachers().catch((error) => {
    console.error("Failed to load teachers", error);
  });
  registerTelegramWebhook().catch((error) => {
    console.error("Telegram webhook setup failed", error);
  });
});
