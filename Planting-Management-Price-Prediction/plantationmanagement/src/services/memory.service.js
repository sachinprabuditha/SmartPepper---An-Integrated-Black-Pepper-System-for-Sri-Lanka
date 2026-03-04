// src/services/memory.service.js

import OpenAI from "openai";
import "dotenv/config";

const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
});

/**
 * Compress conversation into long-term memory
 */
export const summarizeConversation = async (
    previousMemory,
    newMessages
) => {

    const conversationText = newMessages
        .map(m => `${m.role}: ${m.content}`)
        .join("\n");

    const completion =
        await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [
                {
                    role: "system",
                    content: `
You maintain long-term agricultural memory.

Extract ONLY important persistent facts:
- farm details
- farmer preferences
- problems
- decisions
- conditions

Keep memory SHORT and factual.
`
                },
                {
                    role: "user",
                    content: `
Previous Memory:
${previousMemory || "None"}

New Messages:
${conversationText}

Update the memory summary.
`
                }
            ]
        });

    return completion.choices[0].message.content;
};