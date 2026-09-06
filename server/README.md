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

Հավելվածում այս URL-ն արդեն դրված է որպես լռելյայն։ Հեռախոսին տեղադրեք **նոր** build։
