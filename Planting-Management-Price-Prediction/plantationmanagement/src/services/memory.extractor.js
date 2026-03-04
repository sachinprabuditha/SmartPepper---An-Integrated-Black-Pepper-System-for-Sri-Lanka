import OpenAI from "openai";
import "dotenv/config";

const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
});

/**
 * Extract long-term farmer memory from message
 * Returns NULL if nothing important
 */
export const extractMemory = async (message) => {

    if (!message || message.length < 10) return null;

    const completion =
        await openai.chat.completions.create({
            model: "gpt-4o-mini",
            temperature: 0,
            messages: [
                {
                    role: "system",
                    content: `
You extract LONG-TERM agricultural memory.

ONLY extract facts that remain useful later.

KEEP if message contains:
- farm location
- crop stage
- planting dates
- problems/diseases
- farmer decisions
- farming practices

IGNORE:
- greetings
- thanks
- short questions
- temporary chat

Return JSON ONLY:

{
  "memory": "short factual statement"
}

If nothing important:
{
  "memory": null
}
`
                },
                {
                    role: "user",
                    content: message
                }
            ]
        });

    try {
        const parsed =
            JSON.parse(
                completion.choices[0].message.content
            );

        return parsed.memory || null;

    } catch {
        return null;
    }
};