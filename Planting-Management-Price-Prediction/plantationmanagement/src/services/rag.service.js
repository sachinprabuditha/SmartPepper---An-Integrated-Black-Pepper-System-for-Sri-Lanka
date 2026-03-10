import OpenAI from "openai";
import { QdrantClient } from "@qdrant/js-client-rest";
import "dotenv/config";

const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
});

const qdrant = new QdrantClient({
    url: process.env.QDRANT_URL,
    apiKey: process.env.QDRANT_API_KEY,
    checkCompatibility: false,
});

/**
 * Generate follow-up questions
 */
const generateSuggestions = async (answer, question) => {

    const completion =
        await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [
                {
                    role: "system",
                    content: `
You create follow-up questions for Sri Lankan pepper farmers.

Base questions on:
- the assistant answer
- the agricultural topic discussed

Rules:
- practical farm actions
- farmer-friendly language
- max 8 words
- avoid repetition
- return ONLY JSON array

Good examples:
["When should I fertilize next?",
 "How much shade is needed?",
 "Common diseases at this stage?"]
`
                },
                {
                    role: "user",
                    content: `
Farmer Question:
${question}

Assistant Answer:
${answer}
`
                }
            ]
        });

    try {
        const raw =
            completion.choices[0].message.content;

        const jsonMatch = raw.match(/\[.*\]/s);

        if (!jsonMatch) return [];

        return JSON.parse(jsonMatch[0]);
    } catch {
        return [];
    }
};

/**
 * Convert Firestore messages → OpenAI format
 */
const buildHistoryMessages = (history = []) => {
    return history
        .filter(m => m.content)
        .map(m => ({
            role: m.role === "assistant" ? "assistant" : "user",
            content: m.content
        }));
};

/**
 * Keyword lexical scoring
 */
const keywordScore = (text, query) => {
    if (!text) return 0;

    const qWords = query.toLowerCase().split(/\s+/);

    let score = 0;

    qWords.forEach(word => {
        if (text.includes(word)) score += 1;
    });

    return score / qWords.length;
};


/**
 * =============================
 * HYBRID + MEMORY RAG
 * =============================
 */
export const askPepperRAG = async ({
    question,
    history = [],
    memory = "",
    semanticMemories = []
}) => {

    // =============================
    // 1️⃣ Embedding
    // =============================
    const embedding = await openai.embeddings.create({
        model: "text-embedding-3-small",
        input: question,
    });

    // =============================
    // 2️⃣ Vector Search
    // =============================
    let vectorResults = [];
    try {
        vectorResults = await qdrant.search(
            "pepper_knowledge",
            {
                vector: {
                    name: "dense",   // ⭐ REQUIRED
                    vector: embedding.data[0].embedding,
                },
                limit: 12,
                with_payload: true
            }
        );
    } catch (err) {
        console.error("❌ Qdrant vector search error:", err.message);
        return {
            reply: "The agriculture knowledgebase is currently unreachable (Qdrant cluster is suspended). Please log into your Qdrant Cloud Console and wake up the cluster. I can still chat based on your history though!",
            sources: [],
            suggestions: []
        };
    }

    // =============================
    // 3️⃣ Hybrid rerank
    // =============================
    const reranked = vectorResults
        .map(r => {

            const lexical =
                keywordScore(
                    r.payload.keyword_text,
                    question
                );

            const vectorScore = r.score;

            return {
                ...r,
                hybridScore:
                    (0.7 * vectorScore) +
                    (0.3 * lexical)
            };
        })
        .sort((a, b) => b.hybridScore - a.hybridScore)
        .slice(0, 4);

    // =============================
    // 4️⃣ Context
    // =============================
    const context = reranked
        .map(r => r.payload.text)
        .join("\n\n");

    const historyMessages =
        buildHistoryMessages(history);

    // =============================
    // 5️⃣ LLM
    // =============================
    const completion =
        await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [

                {
                    role: "system",
                    content: `
You are a Sri Lankan black pepper agricultural assistant.

RULES:
- Use retrieved knowledge first.
- Use farmer memory for personalization.
- Use history for follow-ups.
- Never invent agronomy advice.
- If unknown say:
"No official recommendation available."
- Give short farmer-friendly bullet answers.
`
                },

                // ⭐ LONG TERM SUMMARY MEMORY
                memory
                    ? {
                        role: "system",
                        content: `Conversation Memory:\n${memory}`
                    }
                    : null,

                // ⭐ SEMANTIC MEMORY (ChatGPT-style recall)
                ...(semanticMemories.length
                    ? [{
                        role: "system",
                        content:
                            `Farmer Long-Term Facts:\n${semanticMemories.join("\n")}`
                    }]
                    : []),

                ...historyMessages,

                {
                    role: "user",
                    content: `
Knowledge Context:
${context}

Question:
${question}
`
                }
            ].filter(Boolean),
        });

    const reply =
        completion?.choices?.[0]?.message?.content ??
        "No official recommendation available.";

    // run suggestions async (faster UX)
    const suggestionsPromise =
        generateSuggestions(reply, question)
            .catch(() => []);

    const suggestions = await suggestionsPromise;

    return {
        reply,
        sources: [...new Set(
            reranked.map(r =>
                r.payload.source
                    .replace("_chunk_", " — section ")
                    .replace(".txt", "")
                    .replaceAll("_", " ")
            )
        )],
        suggestions
    };
};