// Composes a single generation prompt from the layered recipe system:
// GLOBAL ZYNC STYLE + ARCHETYPE + HOBBY RECIPE + REFERENCE STYLE + GLOBAL RESTRICTIONS

export function buildPrompt({ hobbiesDoc, archetypesDoc, hobby }) {
  const archetype = archetypesDoc.archetypes[hobby.archetype];
  if (!archetype) {
    throw new Error(`Unknown archetype "${hobby.archetype}" for hobby "${hobby.id}"`);
  }

  const parts = [
    `GLOBAL STYLE: ${hobbiesDoc.global_style}`,
    `SCENE ARCHETYPE (${archetype.label}): ${archetype.composition} Emotional tone: ${archetype.emotion}.`,
    `SUBJECT: ${hobby.subject}`,
    `KEY OBJECTS TO INCLUDE: ${hobby.key_objects}`,
    `REFERENCE STYLE: ${hobbiesDoc.reference_instruction}`,
    `RESTRICTIONS: ${hobbiesDoc.global_restrictions}`,
  ];

  return parts.join('\n\n');
}
