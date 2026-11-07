// Node: "Snapshot source metadata (remux)"
// Place: AFTER rx_dv on the AV1 remux path, BEFORE Begin.
// Output 1 -> continue
// Purpose: records what remux_verify.js compares the output against: source
//          size, the VIDEO track's duration, and which HDR side data the source
//          really carries. The encode-path snapshot uses the container duration
//          (the longest stream, which can be a dropped audio track) and its HDR
//          guard demands mastering + content light level even when the source
//          had no CLL; both failed correct remuxes (Super Mario Bros., Spectre).

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
    // Stream-level side data only; remux_verify applies the same probe to the output.
  }
  return {
    master: types.some((t) => t.includes('mastering')),
    cll: types.some((t) => t.includes('content light')),
  };
}

module.exports = async (args) => {
  const probe = args.inputFileObj.ffProbeData || {};
  const streams = probe.streams || [];
  const fmt = probe.format || {};
  args.variables = args.variables || {};
  args.variables.user = args.variables.user || {};
  const u = args.variables.user;

  u.sourceSize = args.inputFileObj.file_size;
  u.sourceDuration = parseFloat(fmt.duration || 0);
  u.sourceVideoDuration = videoDuration(streams);
  const hdr = hdrKinds(args.inputFileObj._id, streams);
  u.sourceHdrMaster = hdr.master;
  u.sourceHdrCll = hdr.cll;

  args.jobLog(
    'Remux snapshot: size=' + (u.sourceSize / 1024).toFixed(2) + 'GiB videoDuration=' +
      u.sourceVideoDuration.toFixed(1) + 's container=' + u.sourceDuration.toFixed(1) +
      's hdr master=' + hdr.master + ' cll=' + hdr.cll,
  );
  return { outputFileObj: args.inputFileObj, outputNumber: 1, variables: args.variables };
};
