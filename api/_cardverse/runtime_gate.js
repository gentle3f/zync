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

export function cardverseProofRedeemEnabled() {
  return cardverseApiEnabled() &&
    String(process.env.CARDVERSE_PROOF_REDEEM_ENABLED || '').trim().toLowerCase() === 'true';
}

export function cardverseAccountLifecycleEnabled() {
  return cardverseApiEnabled() &&
    String(process.env.CARDVERSE_ACCOUNT_LIFECYCLE_ENABLED || '').trim().toLowerCase() === 'true';
}

export function rejectDisabledCardverse(res) {
  res.setHeader('Cache-Control', 'no-store');
  return res.status(404).json({ error: 'not_found' });
}
