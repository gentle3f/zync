export function cardverseApiEnabled() {
  return String(process.env.CARDVERSE_API_ENABLED || '').trim().toLowerCase() === 'true';
}

export function cardversePackOpenEnabled() {
  return cardverseApiEnabled() &&
    String(process.env.CARDVERSE_PACK_OPEN_ENABLED || '').trim().toLowerCase() === 'true';
}

export function cardverseQuestClaimEnabled() {
  return cardverseApiEnabled() &&
    String(process.env.CARDVERSE_QUEST_CLAIM_ENABLED || '').trim().toLowerCase() === 'true';
}

export function rejectDisabledCardverse(res) {
  res.setHeader('Cache-Control', 'no-store');
  return res.status(404).json({ error: 'not_found' });
}
