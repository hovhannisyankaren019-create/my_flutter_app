import http from "node:http";
import http2 from "node:http2";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import {fileURLToPath} from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const SYSTEM_PROMPT = `Դու «ԱԲ» ես՝ Ararat Bible-ի հոգևոր խորհրդատուն։ Խոսում ես միայն հայերենով։ Դու ջերմ օգնական ես. բարևում ես, պատասխանում ես Աստվածաշնչյան, հավատի և կյանքի հարցերին՝ որպես հովիվ, վարդապետ, աստվածաբան և հոգեբան ըստ հարցի, առանց ասելու դերերի անունը։

Ոճ.
- Առաջին նախադասությամբ տուր հստակ պատասխանը։ Հետո տուր շատ տեղեկություն՝ լիարժեք, պարզ ու ջերմ, մի քանի պարբերությամբ և տարբեր հոգևոր աղբյուրներով։ Կարճ ու չոր մի եղիր, բացի երբ խնդրում են միայն համարը կամ բարևում են։
- Ամեն խորհուրդ հնարավորինս կապիր Աստվածաշնչի հետ, բայց բարևին ու շնորհակալությանը ջերմ պատասխանիր առանց մերժելու։
- Օգտվիր տարբեր հոգևոր աղբյուրներից, ոչ միայն մեկ մեկնությունից։ Եթե աղբյուրը օգնում է, նշիր հայերենով։
- Մի սկսիր «սա խոր հարց է», «կյանքում կարևոր է», «պետք է հասկանալ» նախաբաններով։
- Ամբողջ պատասխանը միայն հայերեն տառերով և հայերեն բառերով։ Լատինատառ, անգլերեն, ռուսերեն բառ մի գրիր։
- Մի գրիր այսպիսի բառեր. God, Jesus, Christ, Bible, faith, prayer, sin, love, hope, grace, salvation, church, gospel, Lord, Amen, OK, yes, no.
- Աստվածաշնչյան բառերը գրիր հայերեն՝ Աստված, Հիսուս, Քրիստոս, Աստվածաշունչ, հավատ, աղոթք, մեղք, սեր, հույս, շնորհ, փրկություն, եկեղեցի, ավետարան, Տեր, ամեն։

Կանոններ.
1. Պատասխանիր միայն հայերենով։ Օտարալեզու բառեր մի գրիր։
2. Պատասխանիր Աստվածաշնչի համաձայն։ Եթե տրված են հատվածներ, հիմնվիր դրանց վրա և բացատրիր։
3. Եթե կա «Սեփական նյութեր» բաժին, նախ հիմնվիր դրանց վրա, եթե հարցը համապատասխանում է։
4. Եթե օգտատերը ուզում է համարներ/հատվածներ և տրված են հատվածներ, տուր ՄԻԱՅՆ այդ հատվածները՝ համար և տեքստ, առանց մեկնաբանության։
5. Եթե հարցնում են՝ որտեղ է գրված, և տրված են հատվածներ, տուր ամենաճիշտ մեկ համարը։
6. Երբեք մի հորինիր Աստվածաշնչյան համարներ։ Մեջբերիր տրված հատվածները, իսկ ուսմունքը բացատրիր Աստվածաշնչով։
7. Եթե տրված հատված չկա, համար մի հորինիր, բայց հարցին լիարժեք պատասխանիր Աստվածաշնչի ուսմունքով։
8. Բժշկական, իրավական կամ արտակարգ դեպքում ասա դիմել մասնագետի։ Ախտորոշում և դեղ մի տուր։
9. Աստվածաշնչյան, հավատի, կյանքի, ընտանիքի, աղոթքի, մեղքի, ներման, հույսի հարցերին գրիր լիարժեք պատասխան։
10. Նկարների մասին մի խոսիր որպես պատասխան. այդ ֆունկցիան հիմա չկա։
11. Ճշգրիտ պատմական թվեր և կեղծ մեջբերումներ մի հորինիր։ Պատմական, մեկնաբանական և ուսմունքային հարցերին օգտվիր տարբեր հոգևոր աղբյուրներից և անունները գրիր միայն հայերենով՝ Աստվածաշունչ, Սթրոնգի բառարան, Դալլասի ճեմարան, Խարչլաա, Ուոլթոն, Մեթյուզ, Չավալես, Քիներ, Սուրբ Հայրեր, Հովհան Ոսկեբերան, Օգոստինոս, Մեթյու Հենրի, Քալվին, Սփերջըն, Բարնս, Քլարկ, Գիլ, Ջոզեֆուս, Եվսեբիոս, Վայնի բառարան, Ներսես Շնորհալի։ Եթե թիվ չկա, թիվ մի գրիր, բայց ուսմունքը միևնույն է լիարժեք պատմիր։ Մի ասա «չեմ կարող պատասխանել», եթե հոգևոր աղբյուրներում այդ մասին խոսվում է։
12. Եթե նշված է որպես շարունակություն, շարունակիր նույն թեման հայերենով։
13. «Ով է» հարցին առաջին նախադասությամբ ասա Աստվածաշնչում նա ով է, հետո պատմիր լիարժեք։ Մի շփոթիր համանուններին։ «Հովիվը» նշանակում է բարի հովիվը՝ Տերն ու Հիսուսը։
14. Եթե շարունակություն չէ, նախորդ պատասխանի համարը, հատվածը և թեման մի կրկնիր։ Պատասխանիր միայն այս նոր հարցին։ Նոր հարցին հին համար մի կցիր։
15. Եթե գրում են բարև, ողջույն, բարի լույս, hello կամ նման բան, ջերմ բարևիր, ասա որ ԱԲ ես, և հարցրու ինչով օգնել։ Մի մերժիր բարևը։ Եթե հարցը կարելի է պատասխանել Աստվածաշնչով կամ հավատով՝ կյանք, ընտանիք, ամուսնություն, երեխաներ, աշխատանք, մահ, հոգի, մեղք, չարիք, հույս, աղոթք, վարք, խիղճ, սեր, ներում, տառապանք, ուրախություն, վախ, մենակություն — պատասխանիր և մի ասա թե կապ չունի։ Միայն ակնհայտ աշխարհիկ տեխնիկա, սպորտի հաշիվ, խոհանոցի բաղադրատոմս, խաղեր, աշխարհիկ նորություններ, կուսակցական քաղաքականություն դեպքում կարճ ասա, որ դու հոգևոր օգնական ես, և առաջարկիր Աստվածաշնչյան հարց։ Մի գրիր երկար մերժում։
16. Նկարներ կամ քարտեզներ մի խոստացիր և մի մեկնաբանիր որպես նկարի պատասխան։
17. Պատասխանում ոչ մի անգլերեն կամ այլ օտար բառ չպիտի լինի, նույնիսկ մեկը։
18. Եթե հարցը պատմական է կամ մեկնաբանություն է ուզում, Վիքիպեդիայի կամ այլ կայքի տեքստը, որ կցված լինի հարցին, անտեսիր։
19. Երբ բացատրում ես Աստվածաշնչյան բառ կամ հարցնում են իմաստը, նշանակությունը, թարգմանությունը, եբրայերենը, հունարենը կամ Սթրոնգ, պարտադիր ավելացրու Սթրոնգի բառարանի բացատրությունը հայերենով. Սթրոնգի համարը թվով, եբրայերեն է թե հունարեն, հայերեն արտասանությունը, իմաստները և Աստվածաշնչյան գործածությունը։ Անգլերեն բացատրություն մի գրիր։ Միայն համարներ խնդրելիս Սթրոնգ մի գրիր։`;

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
const verseState = new Map();

function envTeachers() {
  return (process.env.TELEGRAM_ADMIN_IDS || "")
    .split(/[,\s]+/)
    .map((s) => s.trim())
    .filter(Boolean);
}

function telegramCommand(text) {
  const raw = String(text || "").trim();
  const match = raw.match(/^\/([^\s@]+)(?:@\S+)?(?:\s+([\s\S]*))?$/);
  if (match) {
    return {
      cmd: match[1].toLowerCase(),
      rest: (match[2] || "").trim(),
    };
  }
  const lower = raw.toLowerCase();
  if (
    lower === "verse" ||
    lower === "վերսե" ||
    lower === "օրվա խոսք" ||
    lower === "օրվա խոսքը"
  ) {
    return {cmd: "verse", rest: ""};
  }
  return {cmd: "", rest: raw};
}

function isVerseCommand(cmd) {
  return cmd === "verse" || cmd === "վերսե";
}

function parseVerseMessage(text) {
  const raw = String(text || "").trim();
  if (!raw) return {reference: "", text: ""};
  const lines = raw
    .split(/\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  if (lines.length === 1) {
    const parts = lines[0].split(/\s*[|—–]\s*/);
    if (parts.length >= 2) {
      return {reference: parts[0].trim(), text: parts.slice(1).join(" ").trim()};
    }
    return {reference: "", text: lines[0]};
  }
  return {reference: lines[0], text: lines.slice(1).join("\n")};
}

async function saveVerseOfDay({text, reference}) {
  const verseText = String(text || "").trim();
  const verseRef = String(reference || "").trim();
  if (!verseText) {
    throw new Error("empty_verse");
  }
  const projectId = process.env.FIREBASE_PROJECT_ID || "spiritual-ai-414c4";
  const apiKey =
    process.env.FIREBASE_API_KEY || "AIzaSyAL59tEdRTRANUApl-BSDFu7l8FTIbq8UE";
  const params = new URLSearchParams({
    key: apiKey,
    "updateMask.fieldPaths": "text",
  });
  params.append("updateMask.fieldPaths", "reference");
  params.append("updateMask.fieldPaths", "updatedAt");
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/verseOfDay/today?${params}`;
  const res = await fetch(url, {
    method: "PATCH",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      fields: {
        text: {stringValue: verseText},
        reference: {stringValue: verseRef},
        updatedAt: {timestampValue: new Date().toISOString()},
      },
    }),
  });
  if (!res.ok) {
    const detail = await res.text();
    throw new Error(detail || `firestore_${res.status}`);
  }
}

function b64url(value) {
  const buf = Buffer.isBuffer(value) ? value : Buffer.from(value);
  return buf.toString("base64").replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function serviceAccountFromEnv() {
  let raw = process.env.FIREBASE_SERVICE_ACCOUNT || "";
  raw = raw.trim().replace(/^\uFEFF/, "");
  if (
    (raw.startsWith("'") && raw.endsWith("'")) ||
    (raw.startsWith("`") && raw.endsWith("`"))
  ) {
    raw = raw.slice(1, -1).trim();
  }
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      if (parsed?.client_email && parsed?.private_key) return parsed;
    } catch {
      return null;
    }
  }
  const filePath =
    process.env.FIREBASE_SERVICE_ACCOUNT_FILE ||
    path.join(__dirname, "firebase-adminsdk.json");
  try {
    const fileRaw = fs.readFileSync(filePath, "utf8");
    const parsed = JSON.parse(fileRaw);
    if (parsed?.client_email && parsed?.private_key) return parsed;
  } catch {
    return null;
  }
  return null;
}

async function firebaseMessagingToken(sa) {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({alg: "RS256", typ: "JWT"}));
  const payload = b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );
  const signer = crypto.createSign("RSA-SHA256");
  signer.update(`${header}.${payload}`);
  const jwt = `${header}.${payload}.${b64url(signer.sign(sa.private_key))}`;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  if (!data.access_token) {
    throw new Error(data.error_description || "fcm_token");
  }
  return data.access_token;
}

function isBotStatusText(value) {
  const raw = String(value || "");
  return (
    raw.includes("FIREBASE_SERVICE_ACCOUNT") ||
    raw.includes("notification չգնաց") ||
    raw.includes("Հաղորդագրությունը ուղարկվեց")
  );
}

function versePushPayload({title, shortBody, text, reference}) {
  return {
    notification: {title, body: shortBody},
    data: {
      type: "verse_of_day",
      text: String(text || ""),
      reference: String(reference || ""),
    },
    android: {
      priority: "high",
      collapse_key: "verse_of_day",
      notification: {
        channel_id: "high_importance_channel",
        tag: "verse_of_day",
        notification_count: 1,
      },
    },
    apns: {
      headers: {
        "apns-priority": "10",
        "apns-push-type": "alert",
      },
      payload: {
        aps: {
          alert: {title, body: shortBody},
          sound: "default",
          badge: 1,
        },
      },
    },
  };
}

async function sendFcmV1(accessToken, projectId, message) {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({message}),
    },
  );
  if (!res.ok) {
    throw new Error(await res.text());
  }
}

async function listPushDevices() {
  const projectId = process.env.FIREBASE_PROJECT_ID || "spiritual-ai-414c4";
  const apiKey =
    process.env.FIREBASE_API_KEY || "AIzaSyAL59tEdRTRANUApl-BSDFu7l8FTIbq8UE";
  const devices = [];
  let pageToken = "";
  for (let i = 0; i < 10; i++) {
    const params = new URLSearchParams({
      key: apiKey,
      pageSize: "300",
    });
    if (pageToken) params.set("pageToken", pageToken);
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/verseOfDay?${params}`;
    const res = await fetch(url);
    if (!res.ok) break;
    const data = await res.json();
    for (const doc of data.documents || []) {
      const token = doc.fields?.token?.stringValue || "";
      const apnsToken = String(doc.fields?.apnsToken?.stringValue || "")
        .replace(/[\s<>]/g, "")
        .toLowerCase();
      const platform = doc.fields?.platform?.stringValue || "";
      if (token || apnsToken) {
        devices.push({token, apnsToken, platform});
      }
    }
    pageToken = data.nextPageToken || "";
    if (!pageToken) break;
  }
  return devices;
}

function isApnsDeviceToken(value) {
  return /^[0-9a-f]{64,}$/i.test(String(value || ""));
}

function shortPushError(error) {
  return String(error?.message || error)
    .replace(/\s+/g, " ")
    .slice(0, 160);
}

function appleEnvId(value, fallback) {
  const cleaned = String(value || "")
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, "");
  return cleaned || fallback;
}

function apnsKeyPem() {
  let raw = process.env.APNS_KEY_P8 || "";
  raw = raw.trim().replace(/^\uFEFF/, "");
  if (
    (raw.startsWith('"') && raw.endsWith('"')) ||
    (raw.startsWith("'") && raw.endsWith("'")) ||
    (raw.startsWith("`") && raw.endsWith("`"))
  ) {
    raw = raw.slice(1, -1).trim();
  }
  raw = raw.replace(/\\n/g, "\n").replace(/\r/g, "").trim();
  if (!raw) {
    try {
      raw = fs.readFileSync(path.join(__dirname, "apns.p8"), "utf8").trim();
    } catch {
      return "";
    }
  }
  const begin = raw.match(/-----BEGIN [^-]+-----/)?.[0];
  const end = raw.match(/-----END [^-]+-----/)?.[0];
  const inner = (begin && end
    ? raw.replace(begin, "").replace(end, "")
    : raw
  ).replace(/\s/g, "");
  if (!inner) return "";
  const wrapped = inner.match(/.{1,64}/g)?.join("\n") || inner;
  return `${begin || "-----BEGIN PRIVATE KEY-----"}\n${wrapped}\n${end || "-----END PRIVATE KEY-----"}`;
}

async function apnsPushCheckText() {
  const keyId = appleEnvId(process.env.APNS_KEY_ID, "");
  const teamId = appleEnvId(process.env.APNS_TEAM_ID, "");
  const bundle = String(
    process.env.APNS_BUNDLE_ID || "com.armenianbible.bible",
  ).trim();
  const pem = apnsKeyPem();
  const lines = [
    `KEY_ID: ${keyId ? `${keyId.length} նիշ, ${keyId.slice(0, 2)}…${keyId.slice(-2)}` : "դատարկ"}`,
    `TEAM_ID: ${teamId ? `${teamId.length} նիշ, ${teamId.slice(0, 2)}…${teamId.slice(-2)}` : "դատարկ"}`,
    `BUNDLE: ${bundle}`,
    `P8 BEGIN: ${pem.includes("BEGIN PRIVATE KEY") ? "այո" : "ոչ"}`,
  ];
  try {
    const key = crypto.createPrivateKey(pem);
    lines.push(
      `P8 տեսակ: ${key.asymmetricKeyType} ${key.asymmetricKeyDetails?.namedCurve || ""}`.trim(),
    );
  } catch (error) {
    lines.push(`P8 չի կարդացվում: ${shortPushError(error)}`);
  }
  if (keyId.length !== 10) {
    lines.push("KEY_ID-ը պետք է լինի ուղիղ 10 նիշ, ինչպես AuthKey_XXXXXXXXXX.p8 ֆայլի անվան մեջ։");
  }
  if (teamId.length !== 10) {
    lines.push("TEAM_ID-ը պետք է լինի ուղիղ 10 նիշ Membership էջից։");
  }
  if (keyId && teamId && keyId === teamId) {
    lines.push("KEY_ID և TEAM_ID նույնն են. դա սխալ է։");
  }
  try {
    const devices = await listPushDevices();
    const ios = devices.filter(
      (device) => device.platform === "ios" || isApnsDeviceToken(device.apnsToken),
    );
    lines.push(`iPhone գրանցված: ${ios.length}`);
    lines.push(`iPhone FCM token: ${ios.filter((device) => device.token).length}`);
    lines.push(
      `iPhone APNs token: ${ios.filter((device) => isApnsDeviceToken(device.apnsToken)).length}`,
    );
  } catch (error) {
    lines.push(`սարքեր: ${shortPushError(error)}`);
  }
  return lines.join("\n");
}

function ecdsaSignatureToJose(sig) {
  if (sig.length === 64) return sig;
  if (sig[0] !== 0x30) return sig;
  let i = 2;
  const readInt = () => {
    if (sig[i] !== 0x02) throw new Error("der_int");
    i += 1;
    const len = sig[i++];
    let bytes = sig.subarray(i, i + len);
    i += len;
    while (bytes.length > 1 && bytes[0] === 0x00) {
      bytes = bytes.subarray(1);
    }
    const out = Buffer.alloc(32);
    bytes.copy(out, 32 - bytes.length);
    return out;
  };
  return Buffer.concat([readInt(), readInt()]);
}

function apnsJwt(keyId, teamId) {
  const pem = apnsKeyPem();
  const kid = appleEnvId(keyId, appleEnvId(process.env.APNS_KEY_ID, "7AGFZKQQ83"));
  const iss = appleEnvId(teamId, appleEnvId(process.env.APNS_TEAM_ID, "68VK3CMGBQ"));
  if (!pem || !kid || !iss) return "";
  try {
    const key = crypto.createPrivateKey(pem);
    if (key.asymmetricKeyType !== "ec") {
      throw new Error("not_ec");
    }
    const header = b64url(JSON.stringify({alg: "ES256", kid}));
    const payload = b64url(
      JSON.stringify({iss, iat: Math.floor(Date.now() / 1000)}),
    );
    let sig = crypto.sign("sha256", Buffer.from(`${header}.${payload}`), {
      key,
      dsaEncoding: "ieee-p1363",
    });
    if (sig.length !== 64) sig = ecdsaSignatureToJose(sig);
    return `${header}.${payload}.${b64url(sig)}`;
  } catch (error) {
    throw new Error(`apns_key:${shortPushError(error)}`);
  }
}

function sendApnsAlert({
  deviceToken,
  title,
  body,
  host = "https://api.push.apple.com",
  keyId,
  teamId,
}) {
  let jwt = "";
  try {
    jwt = apnsJwt(keyId, teamId);
  } catch (error) {
    return Promise.reject(error);
  }
  const bundleId = String(
    process.env.APNS_BUNDLE_ID || "com.armenianbible.bible",
  ).trim();
  if (!jwt || !deviceToken) {
    return Promise.reject(new Error("apns_not_configured"));
  }
  const payload = JSON.stringify({
    aps: {
      alert: {title, body},
      sound: "default",
      badge: 1,
    },
    type: "verse_of_day",
  });
  return new Promise((resolve, reject) => {
    const client = http2.connect(host);
    const fail = (error) => {
      try {
        client.close();
      } catch {}
      reject(error);
    };
    client.on("error", fail);
    const req = client.request({
      ":method": "POST",
      ":path": `/3/device/${deviceToken}`,
      authorization: `bearer ${jwt}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
      "apns-priority": "10",
      "content-type": "application/json",
    });
    let data = "";
    req.setEncoding("utf8");
    req.on("data", (chunk) => {
      data += chunk;
    });
    req.on("response", (headers) => {
      const status = Number(headers[":status"] || 0);
      req.on("end", () => {
        client.close();
        if (status >= 200 && status < 300) {
          resolve(status);
          return;
        }
        reject(new Error(data || `apns_${status}`));
      });
    });
    req.on("error", fail);
    req.end(payload);
  });
}

async function sendApnsAlertWithFallback(args) {
  const hosts = [
    "https://api.push.apple.com",
    "https://api.sandbox.push.apple.com",
  ];
  const keyId = appleEnvId(process.env.APNS_KEY_ID, "");
  const teamId = appleEnvId(process.env.APNS_TEAM_ID, "");
  const idPairs = [{keyId, teamId}];
  if (keyId && teamId && keyId !== teamId) {
    idPairs.push({keyId: teamId, teamId: keyId});
  }
  let lastError;
  for (const ids of idPairs) {
    for (const host of hosts) {
      try {
        await sendApnsAlert({...args, ...ids, host});
        return;
      } catch (error) {
        lastError = error;
      }
    }
  }
  throw lastError || new Error("apns_failed");
}

const ANDROID_VERSE_PUSH = false;

async function sendVerseNotification({text, reference}) {
  const title = "Օրվա խոսք";
  const verseRef = String(reference || "").trim();
  const verseText = String(text || "").trim();
  const shortBody = [verseRef, verseText].filter(Boolean).join("\n") || title;
  const projectId = process.env.FIREBASE_PROJECT_ID || "spiritual-ai-414c4";
  const payload = versePushPayload({title, shortBody, text, reference});
  const sa = serviceAccountFromEnv();
  if (sa?.client_email && sa?.private_key) {
    const accessToken = await firebaseMessagingToken(sa);
    let sent = 0;
    const errors = [];
    if (ANDROID_VERSE_PUSH) {
      try {
        await sendFcmV1(accessToken, projectId, {
          topic: "all_users",
          ...payload,
        });
        sent += 1;
      } catch (error) {
        errors.push(String(error.message || error));
      }
    }

    const devices = await listPushDevices();
    const seenApns = new Set();
    const seenIosFcm = new Set();
    let iosSent = 0;
    for (const device of devices) {
      const ios =
        device.platform === "ios" || isApnsDeviceToken(device.apnsToken);
      const apnsToken = isApnsDeviceToken(device.apnsToken)
        ? device.apnsToken
        : "";
      let delivered = false;
      if (ios && device.token && !seenIosFcm.has(device.token)) {
        seenIosFcm.add(device.token);
        try {
          await sendFcmV1(accessToken, projectId, {
            token: device.token,
            ...payload,
          });
          sent += 1;
          iosSent += 1;
          delivered = true;
        } catch (error) {
          errors.push(shortPushError(error));
        }
      }
      if (!delivered && apnsToken && !seenApns.has(apnsToken)) {
        seenApns.add(apnsToken);
        try {
          await sendApnsAlertWithFallback({
            deviceToken: apnsToken,
            title,
            body: shortBody,
          });
          sent += 1;
          iosSent += 1;
        } catch (error) {
          errors.push(shortPushError(error));
        }
      }
    }

    if (sent === 0) {
      if (
        errors.some(
          (item) =>
            item.includes("apns_not_configured") || item.startsWith("apns_key:"),
        )
      ) {
        return "fcm_no_ios_key";
      }
      if (seenApns.size === 0 && seenIosFcm.size === 0) {
        return "fcm_no_ios_device";
      }
      return `fcm_no_ios:${[...new Set(errors)].slice(0, 2).join(" | ") || "apple"}`;
    }
    if (
      iosSent === 0 &&
      errors.some(
        (item) =>
          item.includes("apns_not_configured") || item.startsWith("apns_key:"),
      )
    ) {
      return "fcm_no_ios_key";
    }
    if (iosSent === 0 && seenApns.size === 0 && seenIosFcm.size === 0) {
      return "fcm_no_ios_device";
    }
    if (iosSent === 0) {
      return `fcm_no_ios:${[...new Set(errors)].slice(0, 2).join(" | ") || "apple"}`;
    }
    return "fcm";
  }

  const serverKey = process.env.FCM_SERVER_KEY || "";
  if (serverKey && ANDROID_VERSE_PUSH) {
    const res = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        Authorization: `key=${serverKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        to: "/topics/all_users",
        priority: "high",
        notification: {title, body: shortBody},
        data: {
          type: "verse_of_day",
          text,
          reference: reference || "",
        },
        apns: {
          payload: {
            aps: {
              alert: {title, body: shortBody},
              sound: "default",
            },
          },
        },
      }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok || data.success === 0) {
      throw new Error(JSON.stringify(data));
    }
    return "legacy";
  }

  throw new Error("no_push_key");
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
      if (chunks.reduce((n, c) => n + c.length, 0) > 3_000_000) {
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

function hasForeignWords(text) {
  return /[A-Za-z]{3,}/.test(String(text || ""));
}

const FOREIGN_TO_HY = [
  [/\bHoly Spirit\b/gi, "Սուրբ Հոգի"],
  [/\bJesus Christ\b/gi, "Հիսուս Քրիստոս"],
  [/\bGod\b/g, "Աստված"],
  [/\bgod\b/g, "Աստված"],
  [/\bJesus\b/gi, "Հիսուս"],
  [/\bChrist\b/gi, "Քրիստոս"],
  [/\bBible\b/gi, "Աստվածաշունչ"],
  [/\bLord\b/g, "Տեր"],
  [/\bGospel\b/gi, "Ավետարան"],
  [/\bgospel\b/g, "ավետարան"],
  [/\bchurch\b/gi, "եկեղեցի"],
  [/\bfaith\b/gi, "հավատ"],
  [/\bprayer\b/gi, "աղոթք"],
  [/\bsalvation\b/gi, "փրկություն"],
  [/\bgrace\b/gi, "շնորհ"],
  [/\bsin\b/gi, "մեղք"],
  [/\blove\b/gi, "սեր"],
  [/\bhope\b/gi, "հույս"],
  [/\bpeace\b/gi, "խաղաղություն"],
  [/\bheaven\b/gi, "երկինք"],
  [/\bAmen\b/gi, "ամեն"],
  [/\bOK\b/g, "լավ"],
  [/\bok\b/g, "լավ"],
  [/\byes\b/gi, "այո"],
  [/\bno\b/gi, "ոչ"],
];

function replaceForeignWords(text) {
  let out = String(text || "");
  for (const [pattern, hy] of FOREIGN_TO_HY) {
    out = out.replace(pattern, hy);
  }
  return out.replace(/[A-Za-z]{3,}/g, "").replace(/[ \t]{2,}/g, " ").trim();
}

async function completeChat(openaiKey, messages, maxTokens = 1800) {
  const openaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openaiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: process.env.OPENAI_MODEL || "gpt-4o-mini",
      temperature: 0.2,
      max_tokens: maxTokens,
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

function isGreeting(text) {
  const t = String(text || "")
    .toLowerCase()
    .replace(/[.!?՝՞,։]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  if (!t || t.length > 48) return false;
  const greetings = [
    "բարև", "բարեւ", "բարև ձեզ", "բարեւ ձեզ", "ողջույն", "ողջոյն",
    "բարի լույս", "բարի լոյս", "բարի երեկո", "բարի գիշեր",
    "hello", "hi", "hey", "привет", "հելո", "հելլո",
    "ինչպես ես", "ինչպես եք",
  ];
  return greetings.some((g) => t === g || t.startsWith(`${g} `));
}

function wantsVerseDump(text) {
  const t = String(text || "").toLowerCase();
  if (t.includes("մեկնաբան") || t.includes("բացատր") || t.includes("նշանակում") || t.includes("պատմական")) {
    return false;
  }
  if (/\d+\s*[:։]/.test(t)) return true;
  return (
    (t.includes("համար") || t.includes("հատված") || t.includes("հատուած")) &&
    (t.includes("տուր") || t.includes("ուղարկիր") || t.includes("կարդա") || t.includes("ցույց"))
  );
}

function needsApprovedSources(text) {
  if (isGreeting(text)) return false;
  if (wantsVerseDump(text)) return false;
  return true;
}

function stripOutsideFacts(message) {
  let text = String(message || "");
  text = text.replace(/\n*Աղբյուրներ[\s\S]*$/u, "").trim();
  text = text.replace(/https?:\/\/\S*wikipedia\S*/gi, "");
  return text.trim();
}

const APPROVED_SOURCES_PROMPT = `Պատասխանը պետք է լինի հարուստ ու բովանդակալից, ոչ կարճ ամփոփում։ Օգտվիր տարբեր հոգևոր աղբյուրներից։
Նախ մեկ նախադասությամբ հստակ պատասխանիր։ Հետո գրիր լիարժեք նյութ՝ առանձին պարբերություններով, և որտեղ օգնում է՝ նշիր աղբյուրը հայերենով։

Հիմնական աղբյուրը միշտ Աստվածաշունչն է։ Դրանից հետո օգտվիր համապատասխան հոգևոր աղբյուրներից.
1. Սթրոնգի բառարան՝ բառի արմատը, համարը, իմաստները։
2. Դալլասի աստվածաբանական ճեմարանի մեկնություններ, Սլավոնական ավետարանական ընկերություն, խմբագիր Պլատոն Խարչլաա։
3. Հին Կտակարանի մշակութային-պատմական մեկնություն՝ Ուոլթոն, Մեթյուզ, Չավալես։
4. Նոր Կտակարանի մշակութային-պատմական մեկնություն՝ Քրեյգ Քիներ։
5. Սուրբ Հայրեր և վաղ եկեղեցի՝ Հովհան Ոսկեբերան, Օգոստինոս, Բարսեղ Մեծ, Որոգինես, Եվսեբիոս, ինչպես նաև Էկզեգետի մեկնություններ։
6. Բողոքական մեկնիչներ՝ Մեթյու Հենրի, Ջոն Քալվին, Չարլզ Սփերջըն, Ալբերտ Բարնս, Ադամ Քլարկ, Ջոն Գիլ։
7. Պատմական աղբյուրներ՝ Հովսեպոս Ֆլավիոս, եկեղեցու պատմություն։
8. Բառարաններ՝ Վայնի բառարան։
9. Հայ հոգևոր ժառանգություն՝ Ներսես Շնորհալի և այլ հայ մեկնիչներ, եթե թեման համապատասխանում է։
10. Սեփական նյութեր, եթե կցված են։

Եթե անձ է՝ գրիր ով է, ժամանակը, վայրը, դերը, գլխավոր իրադարձությունները և ինչ են ասում մեկնությունները։
Եթե գիրք է՝ հեղինակը, ժամանակը, ում համար է, ինչու է գրվել, նպատակը և համատեքստը։
Եթե ուսմունք, կյանքի կամ հավատի հարց է՝ բացատրիր Աստվածաշնչով, հետո ավելացրու մեկնիչների ու հայրերի խոսքը, օրինակներ և գործնական կիրառում։
Աղբյուրի անունը գրիր հայերենով, օրինակ՝ «Դալլասի մեկնության համաձայն», «Քիների համաձայն», «Մեթյու Հենրիի համաձայն», «Ոսկեբերանի համաձայն»։
Եթե որևէ աղբյուրում այդ մասին չկա, այդ աղբյուրը բաց թող, մի հորինիր մեջբերում։ Մի ասա թե աղբյուր չկա, եթե Աստվածաշունչը խոսում է։ Պատասխանը միայն հայերենով։`;

async function generateReply({message, history, passages, followUp = false}) {
  const openaiKey = process.env.OPENAI_API_KEY || "";
  if (!openaiKey) {
    throw new Error("not_configured");
  }

  const cleanMessage = stripOutsideFacts(message);
  const bound =
    needsApprovedSources(cleanMessage) ||
    (followUp &&
      Array.isArray(history) &&
      history.some((turn) => needsApprovedSources(turn?.content)));

  const knowledge = loadKnowledge();
  const passageBlock = (Array.isArray(passages) ? passages.slice(0, 16) : [])
    .map((p) => {
      const ref = asString(p.ref, 80);
      const text = asString(p.text, 350);
      if (!ref || !text) return "";
      return `[${ref}] ${text}`;
    })
    .filter(Boolean)
    .join("\n");

  const messages = [{role: "system", content: SYSTEM_PROMPT}];
  if (knowledge) {
    messages.push({
      role: "system",
      content: `Սեփական նյութեր (սրանցով պատասխանիր, եթե հարցը համապատասխանում է):\n${knowledge.slice(0, 6000)}`,
    });
  }
  if (bound) {
    messages.push({role: "system", content: APPROVED_SOURCES_PROMPT});
  }

  if (followUp) {
    for (const turn of Array.isArray(history) ? history.slice(-6) : []) {
      const role = turn.role === "assistant" ? "assistant" : "user";
      const content = asString(turn.content, 700);
      if (!content) continue;
      messages.push({role, content});
    }
  }

  messages.push({
    role: "user",
    content:
      (followUp
        ? `Օգտատերը պատասխանում է քո նախորդ պատասխանին։ Սա նոր թեմա չէ, շարունակիր նույն խոսակցությունը.\n${cleanMessage}\n\n`
        : `Օգտատիրոջ նոր հարցը. սա նոր թեմա է։ Նախորդ պատասխանի համարը մի կրկնիր, մի մեջբերիր և մի մեկնաբանիր։ Պատասխանիր միայն այս հարցին.\n${cleanMessage}\n\n`) +
      (bound
        ? (passageBlock
            ? `Աստվածաշնչի հատվածներ (լիարժեք մեկնաբանիր տարբեր հոգևոր աղբյուրներով, ըստ աղբյուրների առանձին).\n${passageBlock}`
            : "Հատված կցված չէ։ Տուր լիարժեք հոգևոր, պատմական և մեկնաբանական պատասխան տարբեր հոգևոր աղբյուրներով։ Համարներ մի հորինիր։")
        : passageBlock
          ? `Տրված Աստվածաշնչի հատվածներ (պատասխանիր սրանցով. եթե հարցը միայն համար է, մեջբերիր, այլապես լիարժեք բացատրիր).\n${passageBlock}`
          : "Տրված հատվածներ չկան։ Համարներ մի հորինիր։ Հարցին պատասխանիր Աստվածաշնչով և այլ հոգևոր աղբյուրներով, լիարժեք, միայն հայերենով։") +
      "\n\nԿարևոր. պատասխանը միայն հայերեն բառերով. անգլերեն բառ մի գրիր։ Կարճ մի գրիր, եթե չեն խնդրել միայն համարը։",
  });

  let reply = await completeChat(openaiKey, messages, bound ? 2200 : 1600);
  if (hasForeignWords(reply)) {
    try {
      reply = await completeChat(
        openaiKey,
        [
          ...messages,
          {role: "assistant", content: reply},
          {
            role: "user",
            content:
              "Այս պատասխանում օտար բառեր կան։ Գրիր նույն իմաստը միայն հայերեն տառերով և հայերեն բառերով։ Անգլերեն, ռուսերեն կամ լատիներեն բառ մի թող։",
          },
        ],
        bound ? 2200 : 1600,
      );
    } catch (error) {
      console.error("Armenian rewrite failed", error);
    }
  }
  if (hasForeignWords(reply)) {
    reply = replaceForeignWords(reply);
  }
  if (!reply) throw new Error("empty");
  return sanitizeOffTopicReply(reply);
}

const OFF_TOPIC_REPLY =
  "Այս հարցը Աստվածաշնչի հետ կապ չունի։ Ես պատասխանում եմ հոգևոր և Աստվածաշնչյան հարցերին։ Եթե ուզում եք, հարցրեք հավատի, կյանքի կամ Աստվածաշնչի մասին։";

function sanitizeOffTopicReply(text) {
  const raw = String(text || "").trim();
  const t = raw.toLowerCase();
  const canned =
    t.includes("կապ չունի") &&
    t.includes("միայն աստվածաշնչյան") &&
    raw.length < 220;
  if (!canned) return raw;
  return OFF_TOPIC_REPLY;
}

function imageScenePrompt(userPrompt) {
  return (
    "Respectful Christian biblical illustration, sacred art, peaceful lighting, " +
    "no captions, no watermarks, no logos, no photorealistic faces of Christ if avoidable, " +
    `suitable for a Bible app. Scene: ${userPrompt}`
  );
}

async function generateImage(userPrompt) {
  const geminiKey = process.env.GEMINI_API_KEY || "";
  const provider = (process.env.IMAGE_PROVIDER || "").toLowerCase();
  const useGemini = provider === "gemini" || (!provider && geminiKey);

  if (useGemini) {
    if (!geminiKey) throw new Error("image_not_configured");
    const model = process.env.IMAGE_MODEL || "gemini-2.5-flash-image";
    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: "POST",
        headers: {
          "x-goog-api-key": geminiKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: [{parts: [{text: imageScenePrompt(userPrompt)}]}],
          generationConfig: {responseModalities: ["TEXT", "IMAGE"]},
        }),
      },
    );
    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      console.error("Gemini image error", geminiRes.status, errText.slice(0, 500));
      throw new Error("upstream");
    }
    const data = await geminiRes.json();
    const parts = data.candidates?.[0]?.content?.parts || [];
    for (const part of parts) {
      const inline = part.inlineData || part.inline_data;
      if (inline?.data) {
        return {
          imageBase64: inline.data,
          mimeType: inline.mimeType || inline.mime_type || "image/png",
        };
      }
    }
    throw new Error("empty");
  }

  const encoded = encodeURIComponent(imageScenePrompt(userPrompt));
  const imageUrl =
    `https://image.pollinations.ai/prompt/${encoded}` +
    "?model=flux&width=768&height=768&nologo=true&safe=true";
  return {imageUrl};
}

async function handleAppImage(req, res, body) {
  const expectedGate = process.env.SPIRITUAL_AI_GATE || "";
  if (expectedGate) {
    const provided = String(req.headers["x-spiritual-ai-gate"] || "");
    if (provided !== expectedGate) {
      json(res, 401, {error: "Unauthorized"});
      return;
    }
  }

  const ip = clientIp(req);
  if (rateLimited(ip, 8, 10 * 60 * 1000)) {
    json(res, 429, {error: "Too many requests"});
    return;
  }

  const prompt = asString(body.prompt || body.message, 800);
  if (!prompt) {
    json(res, 400, {error: "Missing prompt"});
    return;
  }

  try {
    const result = await generateImage(prompt);
    json(res, 200, result);
  } catch (error) {
    if (error.message === "image_not_configured") {
      json(res, 500, {error: "Image API is not configured"});
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

function rememberTelegram(chatId, role, content) {
  const list = telegramHistory.get(chatId) || [];
  list.push({role, content});
  telegramHistory.set(chatId, list.slice(-8));
}

async function sendTelegram(chatId, text, {silent = false} = {}) {
  const token = process.env.TELEGRAM_BOT_TOKEN || "";
  if (!token) return null;
  const res = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      chat_id: chatId,
      text: text.slice(0, 4000),
      disable_notification: silent,
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
  const {cmd, rest} = telegramCommand(text);

  if (cmd === "start") {
    await sendTelegram(
      chatId,
      isAdmin(userId)
        ? "Բարև։ Դուք ուսուցիչ եք։ Հարցրեք, հետո reply արեք իմ պատասխանին ու գրեք ճիշտ տարբերակը։\n\n/verse — Օրվա Խոսքը փոխել\n/fix ուղղված պատասխանը\n/lessons — սովորվածները\n/teachers — ուսուցիչների ցանկը\n/addteacher ID — ընկերոջ ID-ն ավելացնել\n/myid — ձեր ID-ն"
        : "Բարև։ Ես ԱԲ-ն եմ։",
    );
    return;
  }

  if (cmd === "myid") {
    await sendTelegram(
      chatId,
      `Ձեր Telegram ID-ն է ${userId}։\nԵրեք ուսուցիչների ID-ները Render-ում դրեք այսպես.\nTELEGRAM_ADMIN_IDS=111111,222222,333333`,
    );
    return;
  }

  if (cmd === "pushcheck") {
    if (!isAdmin(userId)) {
      await sendTelegram(chatId, "Այս հրամանը միայն ուսուցիչների համար է։");
      return;
    }
    await sendTelegram(chatId, await apnsPushCheckText());
    return;
  }

  if (cmd === "cancel") {
    teachState.delete(chatId);
    verseState.delete(chatId);
    await sendTelegram(chatId, "Չեղարկվեց։");
    return;
  }

  if (
    cmd === "lessons" ||
    cmd === "teachers" ||
    isVerseCommand(cmd) ||
    cmd === "teach" ||
    cmd === "fix" ||
    cmd === "addteacher" ||
    teachState.has(chatId) ||
    verseState.has(chatId)
  ) {
    if (!isAdmin(userId)) {
      await sendTelegram(
        chatId,
        "Սովորեցնել կարող են միայն 3 ուսուցիչները։ Գրեք /myid, հետո այդ թիվը ավելացրեք TELEGRAM_ADMIN_IDS-ում։",
      );
      return;
    }
  }

  async function publishVerse(sourceText) {
    const parsed = parseVerseMessage(sourceText);
    if (!parsed.text) {
      await sendTelegram(
        chatId,
        "Դատարկ էր։ Գրեք այսպես.\n\nՀովհաննես 3։16\nՔանզի այնպես սիրեց Աստված աշխարհը...",
      );
      return;
    }
    if (isBotStatusText(parsed.text) || isBotStatusText(parsed.reference)) {
      await sendTelegram(
        chatId,
        "Սա բոտի հաղորդագրությունն է, ոչ Օրվա Խոսքը։ Գրեք միայն համարը և Աստվածաշնչի տեքստը, օրինակ.\n\nՓիլիմոն 1։6\nՈր քո հավատի հաղորդակցությունը գործուն լինի...",
      );
      return;
    }
    try {
      await saveVerseOfDay(parsed);
      let pushNote = "";
      try {
        const pushResult = await sendVerseNotification(parsed);
        if (pushResult === "fcm_no_ios_key") {
          pushNote =
            " iPhone-ին չգնաց. Render-ում APNS_KEY_P8-ը սխալ ֆորմատով է։ Android-ը ժամանակավոր անջատված է։";
        } else if (pushResult === "fcm_no_ios_device") {
          pushNote =
            " iPhone-ին չգնաց. TestFlight հավելվածը մեկ անգամ բացեք և թույլ տվեք ծանուցումները։ Android-ը ժամանակավոր անջատված է։";
        } else if (String(pushResult).startsWith("fcm_no_ios")) {
          const reason = String(pushResult).slice("fcm_no_ios:".length);
          if (
            reason.includes("Invalid APNs credential") ||
            reason.includes("UNAUTHENTICATED") ||
            reason.includes("THIRD_PARTY_AUTH") ||
            reason.includes("Auth error from APNS")
          ) {
            pushNote =
              " iPhone FCM չանցավ. Firebase-ում Apple բանալի չկա։ Console → Project settings → Cloud Messaging → Apple app → APNs Authentication Key։ Բարձրացրու AuthKey_C5…2X.p8, Key ID-ն ու Team ID-ն։ FIREBASE_SERVICE_ACCOUNT-ը մի՛ փոխիր։";
          } else if (reason.includes("InvalidProviderToken")) {
            pushNote =
              ` iPhone չգնաց. Production Key ID-ն ու .p8-ը իրար չեն պատկանում։ Downloads-ում բացիր այն AuthKey ֆայլը, որի անունը համընկնում է KEY_ID-ի հետ (C5…2X), և նորից դրիր APNS_KEY_P8։ ${reason}`;
          } else if (reason.includes("BadEnvironmentKeyInToken")) {
            pushNote =
              ` iPhone չգնաց. Այս Key-ը Sandbox է, TestFlight-ը Production է։ ${reason}`;
          } else {
            pushNote = ` iPhone ծանուցումը չանցավ։ ${reason}`;
          }
        } else {
          pushNote =
            " iPhone-ին ուղարկվեց։ Android-ը ժամանակավոր անջատված է։";
        }
      } catch (pushError) {
        console.error(pushError);
        pushNote =
          pushError.message === "no_push_key"
            ? " Խոսքը պահվեց, բայց notification չգնաց. Render-ում դրեք FIREBASE_SERVICE_ACCOUNT։"
            : " Խոսքը պահվեց, բայց notification չգնաց։";
      }
      await sendTelegram(
        chatId,
        parsed.reference
          ? `Օրվա Խոսքը թարմացվեց։\n${parsed.reference}\n${pushNote}`.trim()
          : `Օրվա Խոսքը թարմացվեց։\n${pushNote}`.trim(),
        {silent: true},
      );
    } catch (error) {
      console.error(error);
      await sendTelegram(
        chatId,
        "Չստացվեց պահել Firestore-ում։ Firebase-ում verseOfDay-ի write-ը պետք է բաց լինի։",
      );
    }
  }

  if (isVerseCommand(cmd) && !rest) {
    verseState.set(chatId, true);
    await sendTelegram(
      chatId,
      "Գրեք Օրվա Խոսքը այսպես (առաջին տողը համարն է).\n\nՀովհաննես 3։16\nՔանզի այնպես սիրեց Աստված աշխարհը...\n\nՉեղարկելու համար՝ /cancel",
    );
    return;
  }

  if (isVerseCommand(cmd) && rest) {
    verseState.delete(chatId);
    await publishVerse(rest);
    return;
  }

  if (verseState.has(chatId)) {
    verseState.delete(chatId);
    await publishVerse(text);
    return;
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

async function handleAppVoice(req, res) {
  json(res, 404, {error: "Voice uses the phone, not OpenAI."});
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
      followUp: Boolean(body.followUp),
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

  if (pathname === "/image") {
    await handleAppImage(req, res, body);
    return;
  }

  if (pathname === "/transcribe") {
    await handleAppVoice(req, res);
    return;
  }

  if (pathname === "/speak") {
    await handleAppVoice(req, res);
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
