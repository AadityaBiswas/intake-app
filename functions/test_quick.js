const { GoogleGenerativeAI } = require("@google/generative-ai");

async function test() {
    const genAI = new GoogleGenerativeAI("AIzaSyDn2VbauqF8bRepdS_01XQWQNCCEIhjrwk");
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const prompt = `You are a nutrition expert. Given the food name below, return ONLY a valid JSON object with the estimated nutritional values per 100 grams.

Food: "butter chicken"

Required JSON structure:
{
  "name": "<canonical food name>",
  "calories": <number>,
  "protein": <number>,
  "carbs": <number>,
  "fat": <number>,
  "confidence": <number between 0 and 1>
}

Return ONLY the JSON object. No markdown. No explanation.`;

    const result = await model.generateContent({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.2 },
    });

    let text = result.response.text().trim();
    console.log("Raw response:", text);

    if (text.startsWith("```")) {
        text = text.replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/, "").trim();
    }

    const parsed = JSON.parse(text);
    console.log("Parsed:", JSON.stringify(parsed, null, 2));
}

test().catch((e) => console.error("ERROR:", e.message));
