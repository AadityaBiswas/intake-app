const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const admin = require("firebase-admin");

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const geminiKey = defineSecret("GEMINI_API_KEY");

const MAX_DAILY_CALLS = 20;
const MAX_DAILY_RECALCS = 3;

/**
 * aiInterpretFood — HTTPS callable Cloud Function.
 *
 * Input:  { name: string, location?: string }
 * Output: { name, nutrition_per_100g: {calories, protein, carbs, fat},
 *           estimatedDefaultServingGrams, confidence,
 *           thoughtProcess, sources, defaultUnit, validUnits }
 */
exports.aiInterpretFood = onCall(
  { secrets: [geminiKey] },
  async (request) => {
    // Authentication guard
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required. Please sign in to use this feature.",
      );
    }

    const uid = request.auth.uid;
    const foodName = request.data ? request.data.name : null;
    const location = request.data ? request.data.location : null;
    const isRecalculation = request.data ? request.data.isRecalculation === true : false;

    if (!foodName || typeof foodName !== "string" || foodName.trim().length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "A non-empty 'name' string is required.",
      );
    }

    // ── Rate Limiting ──────────────────────────────────────────────
    const today = new Date().toISOString().slice(0, 10); // "YYYY-MM-DD"
    const usageRef = db.collection("usage").doc(uid);
    const usageSnap = await usageRef.get();
    let usage = usageSnap.exists ? usageSnap.data() : {};

    // Reset counters if it's a new day
    if (usage.date !== today) {
      usage = { date: today, calls: 0, recalcs: 0 };
    }

    if (usage.calls >= MAX_DAILY_CALLS) {
      throw new HttpsError(
        "resource-exhausted",
        `Daily limit of ${MAX_DAILY_CALLS} AI searches reached. Try again tomorrow.`,
      );
    }
    if (isRecalculation && usage.recalcs >= MAX_DAILY_RECALCS) {
      throw new HttpsError(
        "resource-exhausted",
        `Daily limit of ${MAX_DAILY_RECALCS} recalculations reached. You can still edit macros manually.`,
      );
    }

    // Increment counters
    usage.calls += 1;
    if (isRecalculation) usage.recalcs += 1;
    await usageRef.set(usage);
    // ────────────────────────────────────────────────────────────────

    const apiKey = geminiKey.value();
    if (!apiKey) {
      console.error("No API key found. Set GEMINI_KEY secret via: firebase functions:secrets:set GEMINI_KEY");
      throw new HttpsError(
        "failed-precondition",
        "Gemini API key is not configured.",
      );
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      tools: [{ googleSearch: {} }],
    });

    const locationContext = location && typeof location === "string" && location.trim().length > 0 ?
      `\nIMPORTANT LOCATION CONTEXT: The user is located in ${location.trim()}.
You MUST tailor your response to this specific location:
1. If the food name includes or resembles a restaurant name, ACTIVELY SEARCH for that restaurant in ${location.trim()} and use their specific menu item's nutritional data. Look for the restaurant's website, Zomato, Swiggy, Google Maps listings, or food delivery platforms in that area.
2. If the food could be a local dish or regional specialty, use the preparation style specific to ${location.trim()}.
3. If it's a generic food name, consider how it would typically be prepared and served in ${location.trim()} — portion sizes, cooking oils, spice profiles, and accompaniments differ by region.
4. For chain restaurants, use the specific outlet's menu data if available. Different locations may have different recipes.
5. Always prioritize area-specific data over generic/global nutritional databases.` :
      "";

    const recalcContext = isRecalculation ?
      `\nIMPORTANT RECALCULATION NOTICE: The user has flagged the previous nutritional estimation as inaccurate. You MUST:
1. Re-evaluate the food deeply — do NOT reuse your previous answer.
2. Search for alternative preparations, restaurant-specific variants, or regional differences.
3. Cross-reference at least 3 different reliable sources.
4. If previously estimated values seem off, provide corrected values with explanation.
5. Be more conservative and accurate — accuracy is more important than confidence here.` :
      "";

    const prompt = `You are a nutrition database expert with web search access. Given the food name below, search the web for accurate, up-to-date nutritional data and return ONLY a valid JSON object.
  ${locationContext}${recalcContext}

Food: "${foodName.trim()}"

Required JSON structure:
{
  "name": "<standardized canonical food name>",
  "nutrition_per_100g": {
    "calories": <number>,
    "protein": <number>,
    "carbs": <number>,
    "fat": <number>
  },
  "estimatedDefaultServingGrams": <number>,
  "confidence": <number between 0 and 1>,
  "thoughtProcess": "<2-4 sentences explaining your reasoning: what the food is, how you identified it, what data sources you cross-referenced, and any assumptions made about preparation method or regional variant>",
  "sources": ["<source 1 name or URL>", "<source 2 name or URL>"],
  "defaultUnit": "<single most natural unit for this food>",
  "validUnits": ["<unit1>", "<unit2>"]
}

Rules:
- Use web search to find the most accurate and recent nutritional data. Cross-reference multiple sources.
- "name" must be a clean, standardized food name (e.g. "paneer butter masala" not "Paneer Butter Masala Recipe").
- All macro values must be realistic per 100g.
- "estimatedDefaultServingGrams" is the typical single-serving weight in grams (must represent a typical portion for ONE person's eating capacity, do not give excess or family-size quantities) (e.g. 150 for a bowl of curry, 30 for a slice of bread).
- confidence: 0.9-1.0 for common well-known foods with consistent data, 0.7-0.89 for portion-ambiguous foods, 0.4-0.69 for uncommon/vague, below 0.4 for highly ambiguous.
- "thoughtProcess" should explain: what the food is, how you identified its nutritional profile, which sources you used, and any assumptions (e.g. "assumed restaurant-style preparation", "used USDA standard reference values").
- "sources" should list 2-4 real references (website names, database names, or URLs) you used. Examples: "USDA FoodData Central", "nutritionvalue.org", "CalorieKing", "Indian Food Composition Table (NIN)".
- "defaultUnit": the single most natural unit for measuring this food. Use exactly one of: "g", "ml", "bowl", "cup", "plate", "piece", "tbsp", "tsp", "slice", "serving". Use "piece" for discrete countable foods (e.g. bread, puri, idli, egg, biscuit, fruit). Use "g" for grains, powders, loose ingredients (e.g. rice, flour, sugar). Use "ml" for pure liquids. Use "cup" or "bowl" for dishes served in a container.
- "validUnits": a JSON array of 2-5 strings listing only the units that realistically apply to this food. Choose from: ["g", "ml", "bowl", "cup", "plate", "piece", "tbsp", "tsp", "slice", "serving"]. Examples — puri: ["piece", "serving", "g"], rice: ["g", "cup", "bowl", "serving"], olive oil: ["ml", "tbsp", "tsp"], dal: ["bowl", "cup", "serving", "g"].
- Return ONLY the JSON object. No markdown. No explanation.`;

    try {
      const result = await model.generateContent({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.1 },
      });

      let text = result.response.text().trim();

      // Strip markdown code fencing if present
      if (text.startsWith("```")) {
        text = text.replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/, "").trim();
      }

      const parsed = JSON.parse(text);

      // Validate required fields
      const n = parsed.nutrition_per_100g;
      if (
        typeof parsed.name !== "string" ||
        !n ||
        typeof n.calories !== "number" ||
        typeof n.protein !== "number" ||
        typeof n.carbs !== "number" ||
        typeof n.fat !== "number" ||
        typeof parsed.confidence !== "number" ||
        typeof parsed.estimatedDefaultServingGrams !== "number"
      ) {
        throw new Error("Missing or invalid fields in AI response.");
      }

      return {
        name: parsed.name,
        nutrition_per_100g: {
          calories: n.calories,
          protein: n.protein,
          carbs: n.carbs,
          fat: n.fat,
        },
        estimatedDefaultServingGrams: parsed.estimatedDefaultServingGrams,
        confidence: parsed.confidence,
        thoughtProcess: typeof parsed.thoughtProcess === "string" ?
          parsed.thoughtProcess :
          "Nutritional data estimated based on standard food databases.",
        sources: Array.isArray(parsed.sources) ?
          parsed.sources.filter((s) => typeof s === "string").slice(0, 5) :
          ["AI estimation"],
        defaultUnit: typeof parsed.defaultUnit === "string" ? parsed.defaultUnit : null,
        validUnits: Array.isArray(parsed.validUnits) ?
          parsed.validUnits.filter((u) => typeof u === "string") :
          null,
      };
    } catch (err) {
      console.error("AI interpretation failed:", err);
      throw new HttpsError(
        "internal",
        "Failed to interpret food with AI: " + err.message,
      );
    }
  },
);

/**
 * aiRefineFood — HTTPS callable Cloud Function.
 *
 * Validates a DB/USDA reference food against the user's typed name.
 * Decides if the reference is accurate or needs modification.
 *
 * Input:  { userQuery, referenceName, referenceSource, referenceNutrition,
 *           referenceServingGrams, location? }
 * Output: { referenceAccepted, name?, nutrition_per_100g?, confidence?,
 *           estimatedDefaultServingGrams?, thoughtProcess, sources,
 *           defaultUnit?, validUnits? }
 */
exports.aiRefineFood = onCall(
  { secrets: [geminiKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required.",
      );
    }

    const uid = request.auth.uid;

    // ── Rate Limiting (shared counter with aiInterpretFood) ──
    const today = new Date().toISOString().slice(0, 10);
    const usageRef = db.collection("usage").doc(uid);
    const usageSnap = await usageRef.get();
    let usage = usageSnap.exists ? usageSnap.data() : {};
    if (usage.date !== today) {
      usage = { date: today, calls: 0, recalcs: 0 };
    }
    if (usage.calls >= MAX_DAILY_CALLS) {
      throw new HttpsError(
        "resource-exhausted",
        `Daily limit of ${MAX_DAILY_CALLS} AI searches reached. Try again tomorrow.`,
      );
    }
    usage.calls += 1;
    await usageRef.set(usage);
    // ────────────────────────────────────────────────────────────────

    const {
      userQuery,
      referenceName,
      referenceSource,
      referenceNutrition,
      referenceServingGrams,
      location,
    } = request.data || {};

    if (!userQuery || !referenceName || !referenceNutrition) {
      throw new HttpsError(
        "invalid-argument",
        "'userQuery', 'referenceName', and 'referenceNutrition' are required.",
      );
    }

    const apiKey = geminiKey.value();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Gemini API key is not configured.",
      );
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      tools: [{ googleSearch: {} }],
    });

    const locationCtx = location && typeof location === "string" && location.trim().length > 0 ?
      `\nThe user is located in ${location.trim()}. Consider regional preparation differences. If the user's query mentions or implies a specific restaurant in this area, the reference data may NOT match — search for that restaurant's specific version.` :
      "";

    const prompt = `You are a nutrition accuracy validator. A user typed a food name, and we found a reference in our database. Your job is to decide if the reference is accurate for what the user actually meant.
${locationCtx}

User typed: "${userQuery.trim()}"
Reference found (source: ${referenceSource}): "${referenceName}"
Reference nutrition per 100g: calories=${referenceNutrition.calories}, protein=${referenceNutrition.protein}g, carbs=${referenceNutrition.carbs}g, fat=${referenceNutrition.fat}g
Reference serving size: ${referenceServingGrams}g

Analyze and return ONLY a JSON object:

If the reference is a good match (same food, similar preparation, nutrition values are reasonable):
{
  "referenceAccepted": true,
  "thoughtProcess": "<explain why the reference matches>",
  "sources": ["<source used to verify>"]
}

If the reference is NOT a good match (different food, significantly different preparation style, restaurant-specific version, or the nutrition values seem wrong):
{
  "referenceAccepted": false,
  "name": "<corrected standardized food name>",
  "nutrition_per_100g": { "calories": <number>, "protein": <number>, "carbs": <number>, "fat": <number> },
  "estimatedDefaultServingGrams": <number>,
  "confidence": <0-1>,
  "thoughtProcess": "<explain why the reference was rejected and what the correct food/values are>",
  "sources": ["<source 1>", "<source 2>"],
  "defaultUnit": "<most natural unit>",
  "validUnits": ["<unit1>", "<unit2>"]
}

Decision rules:
- Accept the reference if: it's the same core food, nutrition values are within ~20% of what you'd expect, and the preparation style is reasonable.
- Reject the reference if: the user clearly meant a different item (e.g. a specific restaurant's version vs generic), or the nutrition values are significantly off (>30% deviation from multiple reliable sources).
- If the user's query includes a restaurant name, ALWAYS search for that restaurant and compare their specific item.
- When rejecting, provide the corrected nutrition using the same schema as aiInterpretFood.
- Return ONLY the JSON object. No markdown. No explanation outside the JSON.`;

    try {
      const result = await model.generateContent({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.1 },
      });

      let text = result.response.text().trim();
      if (text.startsWith("```")) {
        text = text.replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/, "").trim();
      }

      const parsed = JSON.parse(text);

      // Validate base structure
      if (typeof parsed.referenceAccepted !== "boolean") {
        throw new Error("Missing 'referenceAccepted' field.");
      }

      const response = {
        referenceAccepted: parsed.referenceAccepted,
        thoughtProcess: typeof parsed.thoughtProcess === "string" ?
          parsed.thoughtProcess : "Reference validation completed.",
        sources: Array.isArray(parsed.sources) ?
          parsed.sources.filter((s) => typeof s === "string").slice(0, 5) :
          ["AI validation"],
      };

      // If rejected, include the corrected food data
      if (!parsed.referenceAccepted) {
        const n = parsed.nutrition_per_100g;
        if (
          typeof parsed.name === "string" && n &&
          typeof n.calories === "number" &&
          typeof n.protein === "number" &&
          typeof n.carbs === "number" &&
          typeof n.fat === "number"
        ) {
          response.name = parsed.name;
          response.nutrition_per_100g = {
            calories: n.calories,
            protein: n.protein,
            carbs: n.carbs,
            fat: n.fat,
          };
          response.confidence = typeof parsed.confidence === "number" ?
            parsed.confidence : 0.7;
          response.estimatedDefaultServingGrams =
            typeof parsed.estimatedDefaultServingGrams === "number" ?
              parsed.estimatedDefaultServingGrams : 100;
          if (typeof parsed.defaultUnit === "string") {
            response.defaultUnit = parsed.defaultUnit;
          }
          if (Array.isArray(parsed.validUnits)) {
            response.validUnits = parsed.validUnits.filter((u) => typeof u === "string");
          }
        } else {
          // Couldn't parse modified food — fall back to accepting reference
          response.referenceAccepted = true;
          response.thoughtProcess = "Reference accepted (modification parsing failed).";
        }
      }

      return response;
    } catch (err) {
      console.error("AI refinement failed:", err);
      // On failure, accept the reference as-is
      return {
        referenceAccepted: true,
        thoughtProcess: "Reference accepted (AI refinement failed).",
        sources: [referenceSource || "database"],
      };
    }
  },
);

/**
 * aiCompareFood — HTTPS callable Cloud Function.
 *
 * Lightweight AI comparison: asks Gemini if a USDA food description
 * matches what the user intended by their query.
 *
 * Input:  { userQuery: string, usdaDescription: string }
 * Output: { isSame: boolean }
 */
exports.aiCompareFood = onCall(
  { secrets: [geminiKey] },
  async (request) => {
    // Authentication guard
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required. Please sign in to use this feature.",
      );
    }

    const userQuery = request.data ? request.data.userQuery : null;
    const usdaDescription = request.data ? request.data.usdaDescription : null;

    if (!userQuery || !usdaDescription) {
      throw new HttpsError(
        "invalid-argument",
        "Both 'userQuery' and 'usdaDescription' are required.",
      );
    }

    const apiKey = geminiKey.value();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Gemini API key is not configured.",
      );
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
    });

    const prompt = `A user searched for food: "${userQuery.trim()}"
A database returned: "${usdaDescription.trim()}"

Is the database result the SAME food the user is looking for? Consider:
- Ignore cooking methods (raw, cooked, grilled, etc.) and color qualifiers (white, brown, etc.)
- Focus on whether the core food item is the same
- "Chicken, breast, tenders" is NOT the same as "chicken breast" (tenders are a different cut)
- "Rice, white, cooked" IS the same as "rice"
- "Crackers, rice" is NOT the same as "rice"

Reply with ONLY a JSON object: {"isSame": true} or {"isSame": false}`;

    try {
      const result = await model.generateContent({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.0 },
      });

      let text = result.response.text().trim();
      if (text.startsWith("```")) {
        text = text.replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/, "").trim();
      }

      const parsed = JSON.parse(text);
      return { isSame: parsed.isSame === true };
    } catch (err) {
      console.error("AI comparison failed:", err);
      // On failure, default to rejecting (safer — falls through to full AI)
      return { isSame: false };
    }
  },
);

