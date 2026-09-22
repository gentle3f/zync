# Zync — USA Spanish + Hong Kong Alias Pack V3

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write. Vercel remains disabled
for this branch. Keep GitHub Actions, Production, Play and image generation
closed unless genuinely required.

## Baseline

- runtime canonical interests: 4,053
- display labels: complete in all 8 supported locales
- alias V1: 163 id-locale rows / 294 terms
- alias V2: 19 id-locale rows / 34 terms
- V1+V2: 182 id-locale rows / 328 terms
- localized alias ambiguity hard gate already includes all localized aliases

## V3 scope

V3 deliberately expands beyond the top-97 launch-priority set into five
high-value launch areas:

1. cars / transport
2. pets
3. social activities
4. fitness / wellness
5. food

New file:

`mobile/lib/core/interest_locale_aliases_launch_v3.dart`

V3 additions:
- Spanish: 24 id-locale rows
- Hong Kong Traditional Chinese: 16 id-locale rows
- total rows: **40**
- total alias terms: **56**

Combined V1+V2+V3:
- **222 id-locale rows**
- **384 localized search terms**

## Representative Spanish additions

Cars / transport:
- `carros / autos / automóviles` -> Cars
- `autos clásicos / carros clásicos` -> Classic Cars
- `autos deportivos / carros deportivos` -> Sports Cars
- `autos eléctricos / carros eléctricos` -> Electric Cars
- `tuning de autos / autos modificados` -> Car Modification
- `motos` -> Motorcycles
- `ver aviones` -> Planespotting

Pets:
- `adiestramiento canino / entrenar perros` -> Pet Training
- `sacar al perro / pasear al perro` -> Dog Walking
- `rescate animal` -> Animal Rescue

Social / food / fitness:
- `salir de fiesta / ir de fiesta` -> Nightlife
- `noche de trivia / trivia en bares` -> Pub Quizzes
- `parques de diversiones` -> Theme Parks
- `noche de cita / cita en pareja` -> Date Nights
- `mariscos` -> Seafood
- `fideos` -> Noodles
- `buscar restaurantes / buscar comida` -> Food Hunting
- `levantar pesas` -> Weightlifting
- `fisicoculturismo` -> Bodybuilding
- `entrenamiento con peso corporal` -> Calisthenics
- `clase de spinning` -> Spin Class
- `meditar` -> Meditation

## Representative Hong Kong additions

Cars / transport:
- `揸車` -> Driving
- `老爺車` -> Classic Cars
- `洗車美容` -> Car Detailing
- `鐵路迷 / 火車迷` -> Railways & Trains
- `高卡` -> Karting

Pets:
- `狗狗` -> Dogs
- `貓貓` -> Cats
- `雀仔` -> Birds
- `訓狗` -> Pet Training
- `放狗` -> Dog Walking

Social / food / wellness:
- `掃街` -> Street Food
- `蒲 / 夜蒲` -> Nightlife
- `樂園` -> Theme Parks
- `行博物館` -> Museums
- `拍拖 / 約會` -> Date Nights
- `靜坐` -> Meditation

## QA

V3 candidate:
- id-locale rows: 40
- alias terms: 56
- duplicate id-locale rows: 0

Catalog source audit:
- Parts 1–8 same-category collisions: 0
- Parts 9–16 same-category collisions: 0

Localized display / alias audit:
- first localization half + V1/V2/Part16 aliases: 0 collisions
- second localization half: 0 collisions

Regression search cases were added for representative V3 terms.

## Infrastructure before checkpoint

- branch HEAD: `828f9e4f8166f37e47ef60ea99e00090bb46bedd`
- GitHub Actions for that HEAD: 0
- Vercel deployment for this branch: disabled
- Production / Play / image generation untouched

## Next recommended work

Search-language coverage is now strong enough that the next work should not be
blind alias expansion.

Next useful directions:
1. add failed-search telemetry / search-result analytics so future alias work is
   evidence-driven;
2. audit onboarding/discovery ranking using the finalized USA + HK sector model;
3. review whether the 4,053-interest catalog is too deep in some clusters and
   whether onboarding should progressively reveal long-tail concepts;
4. keep rights-gated brands/platforms/sports ecosystems separate from generic
   interests until partner/rights policy is satisfied.
