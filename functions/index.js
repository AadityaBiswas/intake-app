const functions = require("firebase-functions");
const { GoogleGenerativeAI } = require("@google/generative-ai");

/**
 * aiInterpretFood — HTTPS callable Cloud Function.
 *
 * Input:  { name: string }
 * Output: { name, nutrition_per_100g: {calories, protein, carbs, fat},
 *           estimatedDefaultServingGrams, confidence,
 *           thoughtProcess, sources }
 */
exports.aiInterpretFood = functions.https.onCall(async (request) => {
  const foodName = request.data?.name;

  if (!foodName || typeof foodName !== "string" || foodName.trim().length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A non-empty 'name' string is required.",
    );
  }

  // Read API key — try environment variable first (2nd Gen), fallback to runtime config (1st Gen)
  const apiKey = process.env.GEMINI_KEY || functions.config().gemini?.key;
  if (!apiKey) {
    console.error("No API key found. Set GEMINI_KEY env var or functions config.");
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Gemini API key is not configured.",
    );
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: "gemini-2.5-flash",
    tools: [{ googleSearch: {} }],
  });

  const prompt = `You are a nutrition database expert with web search access. Given the food name below, search the web for accurate, up-to-date nutritional data and return ONLY a valid JSON object.

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
  "sources": ["<source 1 name or URL>", "<source 2 name or URL>"]
}

Rules:
- Use web search to find the most accurate and recent nutritional data. Cross-reference multiple sources.
- "name" must be a clean, standardized food name (e.g. "paneer butter masala" not "Paneer Butter Masala Recipe").
- All macro values must be realistic per 100g.
- "estimatedDefaultServingGrams" is the typical single-serving weight in grams (must represent a typical portion for ONE person's eating capacity, do not give excess or family-size quantities) (e.g. 150 for a bowl of curry, 30 for a slice of bread).
- confidence: 0.9-1.0 for common well-known foods with consistent data, 0.7-0.89 for portion-ambiguous foods, 0.4-0.69 for uncommon/vague, below 0.4 for highly ambiguous.
- "thoughtProcess" should explain: what the food is, how you identified its nutritional profile, which sources you used, and any assumptions (e.g. "assumed restaurant-style preparation", "used USDA standard reference values").
- "sources" should list 2-4 real references (website names, database names, or URLs) you used. Examples: "USDA FoodData Central", "nutritionvalue.org", "CalorieKing", "Indian Food Composition Table (NIN)".
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
      thoughtProcess: typeof parsed.thoughtProcess === "string"
        ? parsed.thoughtProcess
        : "Nutritional data estimated based on standard food databases.",
      sources: Array.isArray(parsed.sources)
        ? parsed.sources.filter((s) => typeof s === "string").slice(0, 5)
        : ["AI estimation"],
    };
  } catch (err) {
    console.error("AI interpretation failed:", err);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to interpret food with AI: " + err.message,
    );
  }
});
