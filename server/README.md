# Հոգևոր ԱԲ backend

OpenAI բանալին այստեղ է, ոչ թե հավելվածում։ Սերվերը հրապարակային է, որ հեռախոսը ցանկացած ինտերնետից աշխատի։

## Render (խորհուրդ է տրվում)

1. GitHub push արեք `server/` պանակը (`.env` ֆայլը չի մտնում git)։
2. [render.com](https://render.com) — գրանցվեք GitHub-ով։
3. **New +** → **Web Service** → ընտրեք `my_flutter_app` ռեպոն։
4. Կարգավորումներ.
   - **Root Directory:** `server`
   - **Runtime:** Node
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
5. **Environment** բաժնում ավելացրեք.
   - `OPENAI_API_KEY` = ձեր OpenAI բանալին
   - `SPIRITUAL_AI_GATE` = `ararat-bible-local-gate`
   - `OPENAI_MODEL` = `gpt-4o-mini`
6. Deploy։ Պատրաստ հասցեն պետք է լինի.
   `https://ararat-bible-spiritual-ai.onrender.com`
7. Առաջին հարցը կարող է տևել մինչև 1 րոպե (անվճար պլանը քնում է)։

## Նկարների գեներացիա

Տեքստային ԱԲ-ն մնում է OpenAI-ով։ Նկարները գալիս են **ուրիշ API**-ից.

- Լռելյայն՝ [Pollinations](https://pollinations.ai) (բանալի պետք չէ)։
- Ավելի որակով՝ Google Gemini Image։ Render Environment-ում դրեք.
  - `GEMINI_API_KEY` = Gemini բանալին ([aistudio.google.com](https://aistudio.google.com/apikey))
  - `IMAGE_PROVIDER` = `gemini`
  - `IMAGE_MODEL` = `gemini-2.5-flash-image`

Հավելվածում գրեք նկարագրությունը և սեղմեք նկարի կոճակը։

## Telegram բոտ

Սա նույն ԱԲ-ն է, ոչ առանձին մոդել։ «Սովորեցնել» նշանակում է `server/knowledge.txt` ֆայլում գրել ձեր հարց-պատասխանները, հետո նորից deploy անել։

1. Telegram-ում բացեք [@BotFather](https://t.me/BotFather) → `/newbot` → վերցրեք token-ը։
2. Render → Environment ավելացրեք.
   - `TELEGRAM_BOT_TOKEN` = BotFather-ի token
   - `PUBLIC_URL` = `https://ararat-bible-spiritual-ai.onrender.com`
3. Save and deploy։
4. Գրեք `server/knowledge.txt`-ում այն, ինչ պետք է պատասխանի, commit/deploy։
5. Բոտին Telegram-ում `/start`։

### Սովորեցնել Telegram-ից

1. Երեք հոգի բոտին գրեք `/myid` և երեք թվերը դրեք Render-ում մեկ տողով.

`TELEGRAM_ADMIN_IDS=111111111,222222222,333333333`

Երեքն էլ կարող են reply-ով ուղղել պատասխանը։ Առաջին ուսուցիչը կարող է նաև գրել `/addteacher 123456789`։
2. Որ դասերը չկորչեն սերվերի քնելուց, ավելացրեք `GITHUB_TOKEN` (GitHub Personal Access Token, `repo` contents գրելու իրավունքով)
3. Բոտում հարցրեք, հետո **reply արեք բոտի պատասխանին** և գրեք ձեր ուզած տարբերակը։
   Կամ՝ `/fix ուղղված պատասխանը`
   `/lessons` — տեսնել սովորվածը

Token-ը հավելվածում և GitHub-ում մի դրեք։

Հավելվածում այս URL-ն արդեն դրված է որպես լռելյայն։ Հեռախոսին տեղադրեք **նոր** build։
