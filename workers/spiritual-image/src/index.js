const MAX_PROMPT_CHARS = 500;
const RATE_LIMIT = 8;
const RATE_WINDOW_MS = 10 * 60 * 1000;
const TOPIC_ERROR =
  "Այս գործիքը նախատեսված է միայն հոգևոր և աստվածաշնչյան նկարներ ստեղծելու համար։";
const STYLE_SUFFIX =
  "Biblical historical setting, warm natural light, cinematic composition, " +
  "reverent Christian atmosphere, realistic, highly detailed, peaceful and spiritual, " +
  "Biblical atmosphere, reverent Christian artwork, cinematic lighting, " +
  "painterly realism, detailed, peaceful, no text, no watermark, no logos";

const hits = new Map();

const STRONG_TOPICS = [
  "հիսուս",
  "յիսուս",
  "քրիստոս",
  "աստվածաշնչ",
  "աստուածաշնչ",
  "աստվածաշունչ",
  "աստուածաշունչ",
  "աստված",
  "աստուած",
  "տեր աստված",
  "տէր աստուած",
  "սուրբ հոգի",
  "սուրբ գր",
  "ավետարան",
  "աւետարան",
  "քրիստոնե",
  "եկեղեցի",
  "եկեղեցւ",
  "խաչ",
  "խաչելութ",
  "հարություն",
  "հարութիւն",
  "սուրբ ծնունդ",
  "ծնունդ քրիստոս",
  "մովսես",
  "մովսէս",
  "նոյյան",
  "նոյեան",
  "նոյի տապան",
  "նոյ ",
  "տապան",
  "դավիթ",
  "դաւիթ",
  "սողոմոն",
  "առաքյալ",
  "առաքեալ",
  "մարիամ",
  "կույս մարիամ",
  "կոյս մարիամ",
  "հովսեփ",
  "յովսէփ",
  "հովհաննես",
  "յովհաննէս",
  "պետրոս",
  "պողոս",
  "պօղոս",
  "հրեշտակ",
  "դրախտ",
  "եդեմ",
  "երուսաղեմ",
  "երուսաղէմ",
  "բեթղեհեմ",
  "գալիլեա",
  "գալիլիա",
  "երիքով",
  "երիքօ",
  "նազարեթ",
  "կափառնաում",
  "մեռյալ ծով",
  "սուրբ երկիր",
  "քանաան",
  "բաբելոն",
  "նինվե",
  "հեբրոն",
  "գողգոթա",
  "գեթսեմանի",
  "թաբոր",
  "կարմեղոս",
  "holy land",
  "jericho",
  "nazareth",
  "capernaum",
  "canaan",
  "հորդանան",
  "սինա",
  "սինայ",
  "աբրահամ",
  "իսահակ",
  "հակոբ",
  "յակոբ",
  "եղիա",
  "եսայի",
  "երեմիա",
  "դանիել",
  "դանիէլ",
  "հովնան",
  "յովնան",
  "լազարոս",
  "մկրտութ",
  "հաղորդութ",
  "սաղմոս",
  "մարգարե",
  "մարգարէ",
  "քահանա",
  "տաճար",
  "մանանա",
  "հովիվ",
  "հովիւ",
  "բարի հովիվ",
  "աղոթք",
  "աղօթք",
  "հավատք",
  "հաւատք",
  "հոգևոր",
  "հոգեւոր",
  "օրհնութ",
  "պատարագ",
  "մատթեոս",
  "մարկոս",
  "ղուկաս",
  "հայր մեր",
  "jesus",
  "christ",
  "biblical",
  "bible",
  "gospel",
  "apostle",
  "church",
  "calvary",
  "galilee",
  "jerusalem",
  "bethlehem",
  "nativity",
  "resurrection",
  "moses",
  "noah",
  "david",
  "solomon",
  "mary",
  "prayer",
  "crucifix",
  "cross",
  "angel",
  "psalm",
];

const BLOCKED = [
  "մերկ",
  "սեքս",
  "պոռնո",
  "erotic",
  "nude",
  "nsfw",
];

const TRANSLATIONS = [
  ["Նոյյան տապան", "Noah's Ark"],
  ["Նոյեան տապան", "Noah's Ark"],
  ["Նոյի տապան", "Noah's Ark"],
  ["Սուրբ Ծնունդ", "the Nativity of Jesus Christ"],
  ["Գալիլեայի ծով", "the Sea of Galilee"],
  ["Գալիլիայի ծով", "the Sea of Galilee"],
  ["Հիսուս Քրիստոս", "Jesus Christ"],
  ["Յիսուս Քրիստոս", "Jesus Christ"],
  ["Բարի Հովիվ", "Jesus the Good Shepherd"],
  ["Բարի հովիւ", "Jesus the Good Shepherd"],
  ["Սուրբ Հոգի", "the Holy Spirit"],
  ["Հայր մեր", "the Lord's Prayer"],
  ["Աստվածաշունչ", "the Holy Bible"],
  ["Աստուածաշունչ", "the Holy Bible"],
  ["Աստվածաշնչյան", "Biblical"],
  ["Աստուածաշնչեան", "Biblical"],
  ["քրիստոնեական", "Christian"],
  ["քրիստոնէական", "Christian"],
  ["Հիսուսը", "Jesus Christ"],
  ["Յիսուսը", "Jesus Christ"],
  ["Հիսուս", "Jesus Christ"],
  ["Յիսուս", "Jesus Christ"],
  ["Քրիստոսը", "Christ"],
  ["Քրիստոս", "Christ"],
  ["Աստված", "God"],
  ["Աստուած", "God"],
  ["Մովսես", "Moses"],
  ["Մովսէս", "Moses"],
  ["Նոյ", "Noah"],
  ["Դավիթ", "King David"],
  ["Դաւիթ", "King David"],
  ["Սողոմոն", "King Solomon"],
  ["առաքյալներ", "the apostles"],
  ["առաքեալներ", "the apostles"],
  ["առաքյալ", "an apostle"],
  ["առաքեալ", "an apostle"],
  ["Մարիամ", "the Virgin Mary"],
  ["Հովսեփ", "Joseph"],
  ["Յովսէփ", "Joseph"],
  ["Հովհաննես", "John"],
  ["Յովհաննէս", "John"],
  ["Պետրոս", "the apostle Peter"],
  ["Պողոս", "the apostle Paul"],
  ["Պօղոս", "the apostle Paul"],
  ["հրեշտակներ", "angels"],
  ["հրեշտակ", "an angel"],
  ["դրախտ", "Paradise"],
  ["Եդեմ", "the Garden of Eden"],
  ["Երուսաղեմ", "Jerusalem"],
  ["Երուսաղէմ", "Jerusalem"],
  ["Բեթղեհեմ", "Bethlehem"],
  ["Գալիլեա", "Galilee"],
  ["Գալիլիա", "Galilee"],
  ["Երիքով", "Jericho"],
  ["Երիքօ", "Jericho"],
  ["Նազարեթ", "Nazareth"],
  ["Կափառնաում", "Capernaum"],
  ["Մեռյալ ծով", "the Dead Sea"],
  ["Սուրբ երկիր", "the Holy Land"],
  ["Քանաան", "Canaan"],
  ["Բաբելոն", "Babylon"],
  ["Նինվե", "Nineveh"],
  ["Հեբրոն", "Hebron"],
  ["Գողգոթա", "Golgotha"],
  ["Գեթսեմանի", "Gethsemane"],
  ["Թաբոր", "Mount Tabor"],
  ["Կարմեղոս", "Mount Carmel"],
  ["քարտեզ", "map"],
  ["Հորդանան", "the Jordan River"],
  ["Սինա լեռ", "Mount Sinai"],
  ["Սինայ", "Mount Sinai"],
  ["Աբրահամ", "Abraham"],
  ["Իսահակ", "Isaac"],
  ["Հակոբ", "Jacob"],
  ["Յակոբ", "Jacob"],
  ["Եղիա", "Elijah"],
  ["Եսայի", "Isaiah"],
  ["Երեմիա", "Jeremiah"],
  ["Դանիել", "Daniel"],
  ["Դանիէլ", "Daniel"],
  ["Հովնան", "Jonah"],
  ["Յովնան", "Jonah"],
  ["Լազարոս", "Lazarus"],
  ["եկեղեցի", "a Christian church"],
  ["խաչելություն", "the Crucifixion"],
  ["խաչելութիւն", "the Crucifixion"],
  ["Հարություն", "the Resurrection of Jesus Christ"],
  ["Հարութիւն", "the Resurrection of Jesus Christ"],
  ["խաչ", "the Christian cross"],
  ["աղոթք", "prayer"],
  ["աղօթք", "prayer"],
  ["հավատք", "Christian faith"],
  ["հաւատք", "Christian faith"],
  ["հոգևոր", "spiritual Christian"],
  ["հոգեւոր", "spiritual Christian"],
  ["տաճար", "the Temple"],
  ["հովիվ", "a shepherd"],
  ["հովիւ", "a shepherd"],
  ["ոչխարներ", "sheep"],
  ["ոչխար", "sheep"],
  ["մայրամուտին", "at sunset"],
  ["մայրամուտ", "sunset"],
  ["լեռան վրա", "on a mountain"],
  ["լեռան վրայ", "on a mountain"],
  ["լեռ", "mountain"],
  ["ծովի ափին", "beside the sea"],
  ["ափին", "on the shore"],
  ["ծով", "sea"],
  ["անապատ", "desert"],
  ["լույս", "gentle light"],
  ["լոյս", "gentle light"],
  ["խաղաղություն", "peace"],
  ["խաղաղութիւն", "peace"],
];

export default {
  async fetch(request, env) {
    const cors = corsHeaders(request);
    if (request.method === "OPTIONS") {
      return new Response(null, {status: 204, headers: cors});
    }

    const url = new URL(request.url);
    if (request.method === "GET" && url.pathname === "/") {
      return json(200, {ok: true, service: "spiritual-image"}, cors);
    }

    const isGenerate = request.method === "POST" && url.pathname === "/generate-image";
    const isFind = request.method === "POST" && url.pathname === "/find-image";
    if (!isGenerate && !isFind) {
      return json(404, {error: "Not found"}, cors);
    }

    const gate = env.IMAGE_GATE || "";
    if (gate) {
      const provided = request.headers.get("X-Spiritual-Image-Gate") || "";
      if (provided !== gate) {
        return json(401, {error: "Հարցումը մերժվեց սերվերի կողմից։"}, cors);
      }
    }

    const ip = clientIp(request);
    if (rateLimited(ip)) {
      return json(
        429,
        {error: "Շատ հարցումներ եղան։ Խնդրում ենք մի փոքր սպասել։"},
        cors,
      );
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json(400, {error: "Հարցումը սխալ ձևաչափով է։"}, cors);
    }

    // Future: user authentication, daily free quota, paid credits.
    const prompt = asString(body?.prompt, MAX_PROMPT_CHARS + 1);
    if (!prompt) {
      return json(400, {error: "Խնդրում ենք գրել նկարի նկարագրությունը։"}, cors);
    }
    if (prompt.length > MAX_PROMPT_CHARS) {
      return json(400, {error: "Նկարագրությունը չափազանց երկար է։"}, cors);
    }
    if (isBlocked(prompt)) {
      return json(400, {error: "Այս հարցումը չի կարող կատարվել։"}, cors);
    }
    if (isGenerate && !isSpiritualTopic(prompt)) {
      return json(400, {error: TOPIC_ERROR}, cors);
    }

    if (isFind) {
      try {
        const exclude = parseExclude(body);
        const page = parsePage(body, exclude.size);
        const result = await lookupFactsAndImages(prompt, env, {exclude, page});
        if (!result.images.length && !result.facts.length) {
          return json(
            404,
            {error: "Համապատասխան նկար չգտնվեց հավաստի աղբյուրներում։"},
            cors,
          );
        }
        return json(200, {generated: false, ...result}, cors);
      } catch (error) {
        console.error("Lookup error", error);
        return json(
          502,
          {error: "Նկարը չհաջողվեց գտնել հավաստի աղբյուրներում։ Խնդրում ենք նորից փորձել։"},
          cors,
        );
      }
    }

    const imagePrompt = buildImagePrompt(prompt);
    try {
      const result = await env.AI.run("@cf/black-forest-labs/flux-1-schnell", {
        prompt: imagePrompt.slice(0, 2048),
        steps: 4,
      });
      const image = extractBase64(result);
      if (!image) {
        return json(
          502,
          {error: "Նկարը չհաջողվեց ստեղծել։ Խնդրում ենք նորից փորձել։"},
          cors,
        );
      }
      return json(200, {image, mimeType: "image/jpeg"}, cors);
    } catch (error) {
      console.error("Workers AI error", error);
      return json(
        502,
        {error: "Նկարը չհաջողվեց ստեղծել։ Խնդրում ենք նորից փորձել։"},
        cors,
      );
    }
  },
};

function corsHeaders(request) {
  const origin = request.headers.get("Origin") || "*";
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers": "Content-Type, X-Spiritual-Image-Gate",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    Vary: "Origin",
  };
}

function json(status, payload, cors) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...cors,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}

function asString(value, max) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, max);
}

function clientIp(request) {
  return request.headers.get("CF-Connecting-IP") || "unknown";
}

function rateLimited(ip) {
  const now = Date.now();
  const recent = (hits.get(ip) || []).filter((t) => now - t < RATE_WINDOW_MS);
  recent.push(now);
  hits.set(ip, recent);
  return recent.length > RATE_LIMIT;
}

function normalize(text) {
  return text.toLocaleLowerCase("hy-AM").replace(/\s+/g, " ").trim();
}

function isSpiritualTopic(prompt) {
  const n = ` ${normalize(prompt)} `;
  if (isBlocked(prompt)) return false;
  if (STRONG_TOPICS.some((word) => n.includes(word))) return true;
  return false;
}

function isBlocked(prompt) {
  const n = ` ${normalize(prompt)} `;
  return BLOCKED.some((word) => n.includes(word));
}

function buildImagePrompt(armenianPrompt) {
  let scene = armenianPrompt.trim();
  const sorted = [...TRANSLATIONS].sort((a, b) => b[0].length - a[0].length);
  for (const [hy, en] of sorted) {
    scene = scene.replace(new RegExp(escapeRegExp(hy), "giu"), en);
  }
  scene = scene.replace(/\s+/g, " ").trim();
  if (/[\u0531-\u058F]/.test(scene)) {
    scene = `a reverent Biblical Christian scene inspired by this description: ${scene}`;
  }
  return `${scene}, ${STYLE_SUFFIX}`;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function extractBase64(result) {
  if (!result) return "";
  if (typeof result.image === "string" && result.image) return result.image;
  if (typeof result === "string" && result) return result;
  return "";
}

const SEARCH_PLACES = [
  ["երիքով", "Jericho"],
  ["երուսաղեմ", "Jerusalem"],
  ["բեթղեհեմ", "Bethlehem"],
  ["գալիլեա", "Galilee"],
  ["գալիլիա", "Galilee"],
  ["նազարեթ", "Nazareth"],
  ["կափառնաում", "Capernaum"],
  ["մեռյալ ծով", "Dead Sea"],
  ["սուրբ երկիր", "Holy Land"],
  ["քանաան", "Canaan"],
  ["բաբելոն", "Babylon"],
  ["նինվե", "Nineveh"],
  ["հեբրոն", "Hebron"],
  ["գողգոթա", "Golgotha"],
  ["գեթսեմանի", "Gethsemane"],
  ["թաբոր", "Mount Tabor"],
  ["կարմեղոս", "Mount Carmel"],
  ["սինա", "Mount Sinai"],
  ["սինայ", "Mount Sinai"],
  ["հորդանան", "Jordan River"],
  ["եդեմ", "Garden of Eden"],
  ["նոյ", "Noah's Ark"],
];

function armenianWikiTitle(prompt) {
  const n = normalize(prompt);
  const map = {
    երիքով: "Երիքով",
    երուսաղեմ: "Երուսաղեմ",
    բեթղեհեմ: "Բեթղեհեմ",
    գալիլեա: "Գալիլեա",
    գալիլիա: "Գալիլեա",
    նազարեթ: "Նազարեթ",
    հորդանան: "Հորդանան գետ",
    սինա: "Սինա լեռ",
    բաբելոն: "Բաբելոն",
  };
  for (const [key, title] of Object.entries(map)) {
    if (n.includes(key)) return title;
  }
  return "";
}

function placeForSearch(prompt) {
  const n = normalize(prompt);
  const english = englishSearchScene(prompt).toLowerCase();
  for (const [hy, en] of SEARCH_PLACES) {
    if (n.includes(hy) || english.includes(en.toLowerCase())) return en;
  }
  return "";
}

function englishSearchScene(prompt) {
  let scene = prompt.trim();
  const sorted = [...TRANSLATIONS].sort((a, b) => b[0].length - a[0].length);
  for (const [hy, en] of sorted) {
    scene = scene.replace(new RegExp(escapeRegExp(hy), "giu"), en);
  }
  return scene.replace(/\s+/g, " ").trim();
}

function wantsMapQuery(prompt) {
  const n = normalize(prompt);
  return /քարտեզ|քարտէզ|\bmap\b|որտեղ էր|where was|ժամանակաշրջան|chronolog/.test(n);
}

function wantsPhotoQuery(prompt) {
  const n = normalize(prompt);
  return /լուսանկար|հնագիտական|հնավայր|archaeolog|photograph|excavation/.test(n);
}

function sceneSubject(prompt) {
  const place = placeForSearch(prompt);
  if (place) return place;
  return englishSearchScene(prompt)
    .replace(/[\u0531-\u058F]+/g, " ")
    .replace(/[^\x00-\x7F]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function artStyleForPage(page, prompt) {
  if (wantsMapQuery(prompt)) {
    const maps = ["historical biblical atlas map", "19th century Holy Land map", "ancient Near East map"];
    return maps[page % maps.length];
  }
  if (wantsPhotoQuery(prompt)) {
    const photos = [
      "archaeological excavation historical photograph",
      "ancient biblical ruins historical photograph",
      "19th century Holy Land photograph",
    ];
    return photos[page % photos.length];
  }
  const arts = [
    "James Tissot oil painting",
    "Gustave Dore biblical engraving",
    "Renaissance oil on canvas",
    "Byzantine icon mosaic",
    "baroque religious painting",
    "museum masterpiece fresco",
  ];
  return arts[page % arts.length];
}

function buildSearchQuery(prompt, page = 0) {
  const subject = sceneSubject(prompt) || "Bible";
  const style = artStyleForPage(page, prompt);
  return `${subject} historical Bible ${style} -modern -tourist -hotel -logo -flag -clipart filetype:bitmap`
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 200);
}

function usableImageUrl(info) {
  const mime = String(info?.mime || "");
  if (mime.includes("pdf") || mime.includes("djvu") || mime.includes("tiff") || mime.includes("gif")) {
    return "";
  }
  const thumb = info.thumburl || "";
  const original = info.url || "";
  if (mime.includes("svg")) {
    if (thumb && !/\.svg(\?|$)/i.test(thumb)) return thumb;
    return "";
  }
  if (thumb && /\.(jpe?g|png|webp)(\?|$)/i.test(thumb)) return thumb;
  if (mime.startsWith("image/")) return thumb || original;
  return "";
}

function skipTitle(title) {
  return /vermont|oxford|arkansas|tv series|amersfoort|chittenden|crittenden|unincorporated|locator map|location map|outline map|coat of arms|heraldic|logo|flag of|seal of|diagram|flowchart|screenshot|clipart|icon \(computer|emoticon|qr code|barcode|postage stamp|signpost|highway|souvenir|selfie|skyline|modern city|tourist|hotel|restaurant|street view|openstreetmap|google maps|drone|night lights|parking|airport|mall|shop |bus |car |stadium|concert|wedding photo|portrait photography|stock photo/i.test(
    title,
  );
}

function isModernPhoto(blob) {
  return /tourist|hotel|restaurant|skyline|selfie|instagram|tiktok|facebook|street view|openstreetmap|google maps|modern city|today in |night lights|drone|airport|highway|parking|souvenir|stock photo|wedding|concert|stadium|shopping/i.test(
    blob,
  );
}

function isHistoricalArtwork(blob) {
  return /painting|fresco|mosaic|icon|engraving|etching|lithograph|illuminat|manuscript|tapestry|woodcut|oil on|canvas|tissot|dor[eé]|rembrandt|caravaggio|raphael|michelangelo|byzantine|renaissance|baroque|antique|historical|ancient|biblical|bible |nativity|crucifix|gospel|apostle|holy land|archaeolog|excavation|ruins of|19th century|18th century|17th century|museum|masterpiece|old testament|new testament/i.test(
    blob,
  );
}

function isHistoricalMap(blob) {
  return /map|atlas|cartograph/i.test(blob) &&
    /histor|antique|ancient|biblical|bible|holy land|19th|18th|17th|old testament|near east/i.test(blob) &&
    !/locator|blank map|outline map|administrative|google maps|openstreetmap|road map|tourist map|subway|metro/i.test(blob);
}

function isAllowedHistoricalImage(item, mapAsk) {
  const blob = `${item.title || ""} ${item.url || ""} ${item.source || ""}`;
  if (skipTitle(blob) || isModernPhoto(blob)) return false;
  if (/\.(svg|gif)(\?|$)/i.test(item.url || "")) return false;
  if (mapAsk) return isHistoricalMap(blob);
  return isHistoricalArtwork(blob) || isHistoricalMap(blob);
}

function isJunkImage(item, mapAsk) {
  return !isAllowedHistoricalImage(item, mapAsk);
}

function scoreImage(item, {mapAsk = false} = {}) {
  if (!isAllowedHistoricalImage(item, mapAsk)) return -1000;
  const blob = `${item.title || ""} ${item.url || ""}`.toLowerCase();
  let score = 0;
  const w = Number(item.width) || 0;
  const h = Number(item.height) || 0;
  if (w >= 1600 || h >= 1200) score += 28;
  else if (w >= 1000 || h >= 800) score += 18;
  else if (w >= 700) score += 8;
  else if (w > 0 && w < 400) score -= 20;

  if (/upload\.wikimedia\.org|commons\.wikimedia/.test(blob)) score += 22;
  if (/metmuseum|nga\.gov|artic\.edu|rijksmuseum|getty\.edu|si\.edu|britishmuseum|louvre|hermitage|vatican|prado|nationalgallery/i.test(blob)) {
    score += 30;
  }
  if (/tissot|dor[eé]|rembrandt|caravaggio|fresco|mosaic|oil on canvas|illuminat|masterpiece|painting|engraving/.test(blob)) {
    score += 36;
  }
  if (/biblical|bible |holy land|jesus|christ|nativity|crucifix|joshua|moses/.test(blob)) score += 12;
  if (mapAsk && /map|atlas|cartograph/.test(blob)) score += 24;
  if (/pinterest|blogspot|wikia/.test(blob)) score -= 18;
  return score;
}

function pickBestImages(images, {mapAsk = false, limit = 3} = {}) {
  return [...images]
    .filter((item) => isAllowedHistoricalImage(item, mapAsk))
    .map((item) => ({item, score: scoreImage(item, {mapAsk})}))
    .filter((row) => row.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((row) => ({
      url: row.item.url,
      title: row.item.title || "",
      source: row.item.source || "Web",
    }));
}

async function searchCommons(query, offset = 0) {
  if (!query) return [];
  const api = new URL("https://commons.wikimedia.org/w/api.php");
  api.searchParams.set("action", "query");
  api.searchParams.set("format", "json");
  api.searchParams.set("origin", "*");
  api.searchParams.set("generator", "search");
  api.searchParams.set("gsrsearch", query);
  api.searchParams.set("gsrnamespace", "6");
  api.searchParams.set("gsrlimit", "16");
  if (offset > 0) api.searchParams.set("gsroffset", String(offset));
  api.searchParams.set("prop", "imageinfo");
  api.searchParams.set("iiprop", "url|mime|size");
  api.searchParams.set("iiurlwidth", "1920");

  const res = await fetch(api.toString(), {
    headers: {
      "User-Agent": "AraratBible/1.0 (biblical education; historical image lookup)",
      Accept: "application/json",
    },
  });
  if (!res.ok) throw new Error("wikimedia");
  const data = await res.json();
  const pages = data.query?.pages || {};
  const images = [];
  for (const page of Object.values(pages)) {
    const title = String(page.title || "");
    if (skipTitle(title)) continue;
    const info = page.imageinfo?.[0];
    const url = usableImageUrl(info);
    if (!url || !/^https:\/\//.test(url)) continue;
    const item = {
      url,
      title: title.replace(/^File:/i, "").replace(/_/g, " ").trim(),
      source: "Wikimedia Commons",
      width: Number(info.width || info.thumbwidth) || 0,
      height: Number(info.height || info.thumbheight) || 0,
    };
    if (isModernPhoto(`${item.title} ${item.url}`)) continue;
    images.push(item);
    if (images.length >= 16) break;
  }
  return images;
}

async function wikipediaThumb(title) {
  const api = new URL("https://en.wikipedia.org/w/api.php");
  api.searchParams.set("action", "query");
  api.searchParams.set("format", "json");
  api.searchParams.set("origin", "*");
  api.searchParams.set("titles", title);
  api.searchParams.set("prop", "pageimages");
  api.searchParams.set("pithumbsize", "1920");
  const res = await fetch(api.toString(), {
    headers: {
      "User-Agent": "AraratBible/1.0 (biblical education; historical image lookup)",
      Accept: "application/json",
    },
  });
  if (!res.ok) return null;
  const data = await res.json();
  const page = Object.values(data.query?.pages || {})[0];
  const url = page?.thumbnail?.source;
  if (!url || !/^https:\/\//.test(url)) return null;
  return {
    url,
    title: page.title || title,
    source: "Wikipedia",
  };
}

async function wikipediaSummary(title, lang = "en") {
  if (!title || !String(title).trim()) return null;
  const host = lang === "hy" ? "hy.wikipedia.org" : "en.wikipedia.org";
  const res = await fetch(
    `https://${host}/api/rest_v1/page/summary/${encodeURIComponent(title)}`,
    {
      headers: {
        "User-Agent": "AraratBible/1.0 (biblical education; historical lookup)",
        Accept: "application/json",
      },
    },
  );
  if (!res.ok) return null;
  const data = await res.json();
  const extract = String(data.extract || "").trim();
  if (!extract) return null;
  const thumb = data.originalimage?.source || data.thumbnail?.source || "";
  return {
    title: data.title || title,
    extract,
    url: data.content_urls?.desktop?.page || `https://${host}/wiki/${encodeURIComponent(title)}`,
    source: lang === "hy" ? "Wikipedia (hy)" : "Wikipedia",
    image: /^https:\/\//.test(thumb) ? thumb : "",
  };
}

async function googleSearch(env, query, {images = false, start = 1, imgSize = ""} = {}) {
  const key = env.GOOGLE_CSE_KEY || "";
  const cx = env.GOOGLE_CSE_CX || "";
  if (!key || !cx || !query) return [];
  const api = new URL("https://www.googleapis.com/customsearch/v1");
  api.searchParams.set("key", key);
  api.searchParams.set("q", query);
  api.searchParams.set("cx", cx);
  api.searchParams.set("num", "8");
  api.searchParams.set("safe", "active");
  const s = Math.min(91, Math.max(1, start));
  if (s > 1) api.searchParams.set("start", String(s));
  if (images) {
    api.searchParams.set("searchType", "image");
    api.searchParams.set("imgSize", imgSize || "xlarge");
  }
  const res = await fetch(api.toString());
  if (!res.ok) {
    console.error("Google CSE error", res.status, await res.text().then((t) => t.slice(0, 200)));
    return [];
  }
  const data = await res.json();
  return Array.isArray(data.items) ? data.items : [];
}

function imageKey(url) {
  try {
    const u = new URL(url);
    return `${u.host}${u.pathname}`.toLowerCase();
  } catch {
    return String(url || "").split("?")[0].toLowerCase();
  }
}

function parseExclude(body) {
  const raw = body?.exclude;
  if (!Array.isArray(raw)) return new Set();
  return new Set(raw.map((x) => imageKey(String(x))).filter(Boolean));
}

function isExcluded(url, exclude) {
  return Boolean(url) && exclude.has(imageKey(url));
}

function parsePage(body, excludeSize) {
  const n = Number(body?.page);
  if (Number.isFinite(n) && n >= 0) return Math.min(12, Math.floor(n));
  return Math.min(12, Math.floor(excludeSize / 6));
}

function pushUniqueImage(images, item) {
  if (!item?.url || !/^https:\/\//.test(item.url)) return;
  const key = imageKey(item.url);
  if (images.some((x) => imageKey(x.url) === key)) return;
  images.push(item);
}

async function lookupFactsAndImages(prompt, env, {exclude = new Set(), page = 0} = {}) {
  const place = placeForSearch(prompt);
  const english = sceneSubject(prompt);
  const mapAsk = wantsMapQuery(prompt);
  const style = artStyleForPage(page, prompt);
  const start = 1 + page * 8;
  const searchQ = [
    place,
    english,
    mapAsk ? "biblical history map chronology" : "Bible biblical art history encyclopedia",
  ]
    .filter(Boolean)
    .join(" ")
    .slice(0, 180);
  const imageQ = mapAsk
    ? `${place || english} historical biblical antique map -modern -tourist -google`
    : `${place || english} historical biblical painting OR engraving OR fresco -modern -tourist -hotel -logo`;

  const facts = [];
  const images = [];

  const [googleWeb, googleHiRes, wikiEn, wikiHy, commons] = await Promise.all([
    googleSearch(env, searchQ, {images: false, start}),
    googleSearch(env, imageQ, {images: true, start, imgSize: "xlarge"}),
    wikipediaSummary(place),
    wikipediaSummary(armenianWikiTitle(prompt), "hy"),
    findSourcedImages(prompt, {exclude, page}),
  ]);
  let googleImages = googleHiRes;
  if (!googleImages.length) {
    googleImages = await googleSearch(env, imageQ, {images: true, start, imgSize: "large"});
  }

  for (const item of googleWeb) {
    const snippet = String(item.snippet || "").trim();
    if (!snippet) continue;
    facts.push({
      title: item.title || "Google",
      extract: snippet,
      url: item.link || "",
      source: "Google",
    });
  }
  if (wikiEn) {
    facts.push({
      title: wikiEn.title,
      extract: wikiEn.extract,
      url: wikiEn.url,
      source: wikiEn.source,
    });
    if (wikiEn.image && !isExcluded(wikiEn.image, exclude)) {
      const wikiImage = {
        url: wikiEn.image,
        title: wikiEn.title,
        source: "Wikipedia",
        width: 1200,
        height: 900,
      };
      if (isAllowedHistoricalImage(wikiImage, mapAsk)) {
        pushUniqueImage(images, wikiImage);
      }
    }
  }
  if (wikiHy && wikiHy.extract) {
    facts.push({
      title: wikiHy.title,
      extract: wikiHy.extract,
      url: wikiHy.url,
      source: wikiHy.source,
    });
  }
  for (const item of googleImages) {
    const url = item.link || "";
    if (isExcluded(url, exclude)) continue;
    if (!/^https:\/\//.test(url) || /\.(html?|php)(\?|$)/i.test(url)) continue;
    const meta = item.image || {};
    const candidate = {
      url,
      title: item.title || "Google image",
      source: "Google",
      width: Number(meta.width) || 0,
      height: Number(meta.height) || 0,
    };
    if (!isAllowedHistoricalImage(candidate, mapAsk)) continue;
    pushUniqueImage(images, candidate);
  }
  for (const item of commons) {
    if (isExcluded(item.url, exclude)) continue;
    pushUniqueImage(images, item);
  }

  const ranked = pickBestImages(
    images.filter((item) => !isExcluded(item.url, exclude)),
    {mapAsk, limit: 3},
  );
  return {
    images: ranked,
    facts: facts.slice(0, 8),
    query: searchQ,
  };
}

async function findSourcedImages(prompt, {exclude = new Set(), page = 0} = {}) {
  const place = placeForSearch(prompt);
  const english = sceneSubject(prompt);
  const style = artStyleForPage(page, prompt);
  const SCENE_HINTS = {
    Jericho: "Fall of Jericho Joshua walls",
    Bethlehem: "Nativity of Jesus Christ",
    Golgotha: "Crucifixion of Jesus Calvary",
    Gethsemane: "Agony in the Garden of Gethsemane",
    "Garden of Eden": "Adam and Eve Garden of Eden",
    "Noah's Ark": "Noah's Ark flood",
    "Jordan River": "Baptism of Jesus Jordan River",
    "Mount Sinai": "Moses Ten Commandments Mount Sinai",
    Jerusalem: "ancient Jerusalem Temple biblical painting",
    Nazareth: "Holy Family Nazareth",
    Galilee: "Sea of Galilee Jesus biblical painting",
    Capernaum: "Jesus Capernaum synagogue",
  };
  const hint = SCENE_HINTS[place] || "";
  const subject = hint || place || english;
  const queries = [];
  if (wantsMapQuery(prompt) && subject) {
    queries.push(`${subject} historical biblical map filemime:image/jpeg`);
    queries.push(`${subject} antique Holy Land map filetype:bitmap`);
  } else if (subject) {
    queries.push(`${subject} ${style} filetype:bitmap`);
    queries.push(`${subject} Bible oil painting Tissot filetype:bitmap`);
    queries.push(`${subject} biblical masterpiece painting filemime:image/jpeg`);
    if (english && english !== subject) {
      queries.push(`${english} biblical painting filetype:bitmap`);
    }
  }
  queries.push(buildSearchQuery(prompt, page));

  const merged = [];
  const offset = page * 12;
  for (const query of queries) {
    const images = await searchCommons(query, offset);
    for (const item of images) {
      if (isExcluded(item.url, exclude)) continue;
      if (!isAllowedHistoricalImage(item, wantsMapQuery(prompt))) continue;
      pushUniqueImage(merged, item);
    }
    if (merged.length >= 18) break;
  }
  return merged;
}
