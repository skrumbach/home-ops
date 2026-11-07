// Node: "Audio language filter (English + German)"
// Place: AFTER Conform streams for mkv, BEFORE Set Video Encoder (encode paths)
//        or BEFORE Execute (AV1 remux path).
// Output 1 -> dropped at least one audio track (continue)
// Output 2 -> nothing to drop (encode paths: continue; remux path: dead end, file untouched)
// Output 3 -> FAIL (dead end, nothing written)
//
// Why this exists: the captain keeps English (primary) and German (secondary)
// audio. Plex decodes every audio track for loudness analysis, and 4K files
// with 10-20 dubbed tracks OOM-killed it nightly (2026-11). Audio only:
// subtitle tracks are never touched here. Untagged tracks (und, empty, mul,
// zxx) always stay. Nothing is dropped unless at least one kept track is a
// main soundtrack (not commentary or audio description, by disposition or
// title): a French film with only an English commentary keeps every track.
// If the default-flagged track is dropped, the first kept English main track
// (else the first kept main track) becomes the default.

const KEEP = { eng: true, ger: true };
const KEEP_UNTAGGED = ['', 'und', 'unk', 'mul', 'zxx'];
const ALIASES = {
  en: 'eng', eng: 'eng', english: 'eng',
  de: 'ger', ger: 'ger', deu: 'ger', german: 'ger',
};

// Commentary / audio description (EN + DE titles); never counted as a main track.
const NOT_MAIN = /comment|kommentar|descri|deskript|h\u00f6rfilm|horfilm|narrat|\bad\b|\bdvs\b/i;

function isMain(s) {
  const d = s.disposition || {};
  if (Number(d.comment || 0) === 1 || Number(d.visual_impaired || 0) === 1) return false;
  return !NOT_MAIN.test(String((s.tags || {}).title || (s.tags || {}).TITLE || ''));
}

function langOf(s) {
  const tags = s.tags || {};
  const raw = String(tags.language || tags.LANGUAGE || '').trim().toLowerCase();
  const base = raw.split(/[-_]/)[0];
  if (KEEP_UNTAGGED.indexOf(base) !== -1) return '';
  return ALIASES[base] || base;
}

module.exports = async (args) => {
  const cmd = args.variables && args.variables.ffmpegCommand;
  if (!cmd || !Array.isArray(cmd.streams)) {
    args.jobLog('Audio language filter: ffmpegCommand not initialised - FAIL (will not write)');
    return { outputFileObj: args.inputFileObj, outputNumber: 3, variables: args.variables };
  }

  const audio = cmd.streams.filter((s) => !s.removed && String(s.codec_type || '') === 'audio');
  const keep = audio.filter((s) => {
    const l = langOf(s);
    return l === '' || KEEP[l] === true;
  });
  const langs = audio.map((s) => langOf(s) || 'und').join(',');

  const count = (type) => cmd.streams.filter((s) => !s.removed && String(s.codec_type || '') === type).length;
  args.variables.user = args.variables.user || {};
  const user = args.variables.user;

  const keepMain = keep.filter(isMain);
  if (audio.length === 0 || keepMain.length === 0 || keep.length === audio.length) {
    const why = audio.length === 0 ? 'no audio'
      : keep.length === audio.length ? 'nothing to drop'
        : keep.length === 0 ? 'no English/German/untagged audio, kept all'
          : 'kept tracks are only commentary/description, kept all';
    args.jobLog('Audio language filter: in a=' + audio.length + ' [' + langs + '] | ' + why);
    user.expectAudio = audio.length;
    user.expectVideo = count('video');
    user.expectSubtitle = count('subtitle');
    return { outputFileObj: args.inputFileObj, outputNumber: 2, variables: args.variables };
  }

  let dropped = 0;
  for (const s of audio) {
    if (keep.indexOf(s) === -1) {
      s.removed = true;
      dropped += 1;
    }
  }
  const isDefault = (s) => Number((s.disposition || {}).default || 0) === 1;
  let defaultNote = '';
  if (audio.some(isDefault) && !keep.some(isDefault)) {
    const pick = keepMain.find((s) => langOf(s) === 'eng') || keepMain[0];
    pick.outputArgs.push('-disposition:{outputIndex}', 'default');
    defaultNote = ' default->' + (langOf(pick) || 'und');
  }

  args.jobLog(
    'Audio language filter: in a=' + audio.length + ' [' + langs + '] | kept=' + keep.length +
      ' dropped=' + dropped + defaultNote,
  );
  user.expectAudio = keep.length;
  user.expectVideo = count('video');
  user.expectSubtitle = count('subtitle');
  return { outputFileObj: args.inputFileObj, outputNumber: 1, variables: args.variables };
};
