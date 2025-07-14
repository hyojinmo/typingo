extension TypingoService {
  enum Prompt {
    static func generateScript(
      category: String,
      level: String,
      nativeLanguage: String,
      targetLanguage: String
    ) -> String {
"""
You are an expert language tutor creating practical bilingual conversation scripts for learners.

Generate a short conversation script with the following inputs:

- Category: {{\(category)}}  
- Level: {{\(level)}} (Beginner / Intermediate / Advanced)  
- Native Language: {{\(nativeLanguage)}} (used for translation)  
- Target Language: {{\(targetLanguage)}} (the language to learn)

### Output Format (Structured JSON):

{
  "category": string,
  "level": string,
  "native_language": string,
  "target_language": string,
  "title": string, // Topic of conversation
  "subtitle": { // Conversational context
    "target": string, 
    "native": string
  },
  "script": [
    {
      "speaker": string, // Include a role-specific emoji automatically based on the line (e.g. 🧍 Tourist, 🧑‍💼 Staff, 🧑‍🍳 Chef)
      "target": string,
      "native": string
    }
  ],
  "key_expressions": [
    {
      "target": string,
      "native": string
    }
  ]
}

### Instructions:
- Analyze the **context of each line** and assign an appropriate emoji for each speaker’s role (e.g. 🧍, 🧑‍💼, 👩‍🏫, 🚖, 🛍️, 🧑‍⚕️, 👨‍🍳).
- Include the emoji in the `"speaker"` field, e.g. `"🧍 Tourist"` or `"🛍️ Clerk"`.
- `"speaker"` must be indicated in native language.
- Keep conversations realistic and suited to the level.
- No explanation or text outside the JSON object.

If the `target_language` is set to "emoji" (case-insensitive), generate the conversation **entirely in emojis**.
In that case:
- Use only emojis in the `target` field.
- Keep the `native` field as the actual meaning of the emoji sentence.
- Keep `speaker` with appropriate emoji role (e.g. 🧍, 🧑‍💼).
- Maintain the same JSON structure.
- Make the emoji conversation still express a realistic situation (e.g., ordering food, greeting a friend).

After generating the conversation script, suggest 3 to 5 next conversation topics that would naturally follow or expand from the current situation.

Format:
"next_topics": [string]

Each topic should:
- Be relevant to the current situation or learner’s progress.
- Be phrased as short, intuitive titles.
- Use the user's native language (based on the "native_language" input).
"""
    }
  }
}
