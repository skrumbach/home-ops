// Node: "Remux guard: streams and size"
// Place: AFTER Execute on the AV1 remux path, BEFORE the duration and HDR guards.
// Output 1 -> Pass
// Output 2 -> Fail (dead end, source NOT replaced)
// Purpose: a copy-only remux that drops audio must keep every video and
//          subtitle stream, end with exactly the audio count the language
//          filter kept, still be AV1, and be no larger than the source. The
//          encode-path size check (>=95% fails) does not fit a remux, where
//          the saving is only the dropped audio.

module.exports = async (args) => {
  const snap = (args.variables && args.variables.user) || {};
  const streams = (args.inputFileObj.ffProbeData || {}).streams || [];
  // Cover art probes as video with disposition.attached_pic; the filter counted it as an attachment.
  const isArt = (s) => Number((s.disposition || {}).attached_pic || 0) === 1;
  const count = (type) => streams.filter((s) => String(s.codec_type || '') === type && !isArt(s)).length;
  const out = { video: count('video'), audio: count('audio'), subtitle: count('subtitle') };
  const want = { video: snap.expectVideo, audio: snap.expectAudio, subtitle: snap.expectSubtitle };
  const inputBytes = snap.sourceSize;
  const outputBytes = args.inputFileObj.file_size;
  const fail = (why) => {
    args.jobLog('Remux guard: FAIL - ' + why + ' (will not replace)');
    return { outputFileObj: args.inputFileObj, outputNumber: 2, variables: args.variables };
  };

  if (!inputBytes || want.audio === undefined || want.video === undefined || want.subtitle === undefined) {
    return fail('no source snapshot or language-filter expectation');
  }

  args.jobLog(
    'Remux guard: v=' + out.video + '/' + want.video + ' a=' + out.audio + '/' + want.audio +
      ' s=' + out.subtitle + '/' + want.subtitle + ' size=' + (inputBytes / 1024).toFixed(2) +
      'GiB -> ' + (outputBytes / 1024).toFixed(2) + 'GiB',
  );

  if (out.video !== want.video || out.audio !== want.audio || out.subtitle !== want.subtitle) {
    return fail('stream counts differ from the expectation');
  }
  if (out.audio < 1) return fail('output has no audio');
  const video = streams.find((s) => String(s.codec_type || '') === 'video' && !isArt(s)) || {};
  if (String(video.codec_name || '').toLowerCase() !== 'av1') return fail('output video is not AV1');
  if (!outputBytes || outputBytes > inputBytes) return fail('output larger than source');
  if (outputBytes < inputBytes * 0.1) return fail('output suspiciously small (<10% of source)');

  return { outputFileObj: args.inputFileObj, outputNumber: 1, variables: args.variables };
};
