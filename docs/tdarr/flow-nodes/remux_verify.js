// Node: "Remux guard: streams, size, video duration, HDR vs source"
// Place: AFTER Execute on the AV1 remux path, BEFORE Replace Original File.
// Output 1 -> Pass
// Output 2 -> Fail (dead end, source NOT replaced)
// Purpose: a copy-only remux that drops audio must keep every video and
//          subtitle stream, end with exactly the audio count the language
//          filter kept, still be AV1, be no larger than the source, keep the
//          VIDEO track's duration (within 0.5%), and keep every kind of HDR side
//          data the SOURCE had (remux_snapshot.js). The encode-path guards
//          compare the container duration (a dropped longer audio track
//          shortens it legitimately) and demand CLL even when the source had none.

const { execSync } = require('child_process');

function isArt(s) {
  return Number((s.disposition || {}).attached_pic || 0) === 1 || String(s.codec_name || '') === 'mjpeg';
}

function hms(v) {
  const m = /^(\d+):(\d+):(\d+(?:\.\d+)?)$/.exec(String(v || '').trim());
  return m ? Number(m[1]) * 3600 + Number(m[2]) * 60 + Number(m[3]) : NaN;
}

function videoDuration(streams) {
  const v = streams.find((s) => s.codec_type === 'video' && !isArt(s)) || {};
  const tags = v.tags || {};
  const key = Object.keys(tags).find((k) => /^DURATION(-|$)/i.test(k));
  const fromTag = key ? hms(tags[key]) : NaN;
  if (fromTag > 0) return fromTag;
  const d = parseFloat(v.duration || 0);
  return d > 0 ? d : 0;
}

function hdrKinds(file, streams) {
  const v = streams.find((s) => s.codec_type === 'video' && !isArt(s)) || {};
  const types = (v.side_data_list || []).map((x) => String(x.side_data_type || '').toLowerCase());
  try {
    const out = execSync(
      'ffprobe -v error -select_streams v:0 -read_intervals "%+#5" -show_frames ' +
        '-show_entries frame=side_data_list -of json "' + file + '"',
      { maxBuffer: 10 * 1024 * 1024 },
    ).toString();
    for (const f of JSON.parse(out).frames || []) {
      for (const x of f.side_data_list || []) types.push(String(x.side_data_type || '').toLowerCase());
    }
  } catch (e) {
    // Stream-level side data only, same as the source snapshot.
  }
  return {
    master: types.some((t) => t.includes('mastering')),
    cll: types.some((t) => t.includes('content light')),
  };
}

module.exports = async (args) => {
  const snap = (args.variables && args.variables.user) || {};
  const streams = (args.inputFileObj.ffProbeData || {}).streams || [];
  // Cover art probes as video with disposition.attached_pic; the filter counted it as an attachment.
  const isPic = (s) => Number((s.disposition || {}).attached_pic || 0) === 1;
  const count = (type) => streams.filter((s) => String(s.codec_type || '') === type && !isPic(s)).length;
  const out = { video: count('video'), audio: count('audio'), subtitle: count('subtitle') };
  const want = { video: snap.expectVideo, audio: snap.expectAudio, subtitle: snap.expectSubtitle };
  const inputBytes = snap.sourceSize;
  const outputBytes = args.inputFileObj.file_size;
  const fail = (why) => {
    args.jobLog('Remux guard: FAIL - ' + why + ' (will not replace)');
    return { outputFileObj: args.inputFileObj, outputNumber: 2, variables: args.variables };
  };

  if (!inputBytes || want.audio === undefined || want.video === undefined || want.subtitle === undefined ||
      !(snap.sourceVideoDuration > 0) || snap.sourceHdrMaster === undefined || snap.sourceHdrCll === undefined) {
    return fail('no remux snapshot or language-filter expectation');
  }

  const outDur = videoDuration(streams);
  const hdr = (snap.sourceHdrMaster || snap.sourceHdrCll)
    ? hdrKinds(args.inputFileObj._id, streams) : { master: false, cll: false };

  args.jobLog(
    'Remux guard: v=' + out.video + '/' + want.video + ' a=' + out.audio + '/' + want.audio +
      ' s=' + out.subtitle + '/' + want.subtitle + ' size=' + (inputBytes / 1024).toFixed(2) +
      'GiB -> ' + (outputBytes / 1024).toFixed(2) + 'GiB videoDuration=' +
      snap.sourceVideoDuration.toFixed(1) + 's -> ' + outDur.toFixed(1) + 's hdr master=' +
      snap.sourceHdrMaster + '->' + hdr.master + ' cll=' + snap.sourceHdrCll + '->' + hdr.cll,
  );

  if (out.video !== want.video || out.audio !== want.audio || out.subtitle !== want.subtitle) {
    return fail('stream counts differ from the expectation');
  }
  if (out.audio < 1) return fail('output has no audio');
  const video = streams.find((s) => String(s.codec_type || '') === 'video' && !isArt(s)) || {};
  if (String(video.codec_name || '').toLowerCase() !== 'av1') return fail('output video is not AV1');
  if (!outputBytes || outputBytes > inputBytes) return fail('output larger than source');
  if (outputBytes < inputBytes * 0.1) return fail('output suspiciously small (<10% of source)');
  const ratio = outDur / snap.sourceVideoDuration;
  if (!(ratio >= 0.995 && ratio <= 1.005)) return fail('video duration drift > 0.5%');
  if (snap.sourceHdrMaster && !hdr.master) return fail('mastering display metadata lost');
  if (snap.sourceHdrCll && !hdr.cll) return fail('content light level lost');

  return { outputFileObj: args.inputFileObj, outputNumber: 1, variables: args.variables };
};
