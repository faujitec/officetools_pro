import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

export async function extractTextFromImage(base64Data: string, mimeType: string): Promise<string> {
  try {
    const response = await ai.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: {
        parts: [
          {
            inlineData: {
              data: base64Data,
              mimeType: mimeType,
            },
          },
          {
            text: "Please extract all readable text from this document. Format it clearly as plain text. If there are tables, try to represent them simply. Focus on numerical values and titles.",
          },
        ],
      },
      config: {
        temperature: 0.1,
      }
    });

    return response.text || "No text could be extracted.";
  } catch (error) {
    console.error("OCR Error:", error);
    throw new Error("Failed to extract text. Please check your image and try again.");
  }
}
