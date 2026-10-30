// REPL transcripts in Markdown code blocks: ```jldoctest and ```julia-repl.
//
//     julia> x = [1, 2,
//                 3];          <- continuation: indented to line up after the prompt
//
//     julia> sum(x)
//     6                        <- output
//
// Only the input after each `julia>` prompt is Julia; prompts and output are
// not. A Tree-sitter injection can be given any ranges, so the Julia layer
// gets just the inputs. jldoctests can also be written without prompts, as a
// script followed by `# output` and the expected output.
const { Point } = require('atom');

const TRANSCRIPT_LANGUAGES = new Set(['jldoctest', 'julia-repl']);
const PROMPT = /^(\s*)(julia>) ?/;
const OUTPUT_MARKER = /^\s*# output\s*$/;
const OPENING_FENCE = /^\s*(`{3,}|~{3,})\s*([\w-]+)?/;

// The rows of a transcript, `firstRow` up to (not including) `endRow`:
// `inputs` are the ranges of Julia input, `prompts` the ranges of the
// `julia>` prompts.
function scanTranscript(buffer, firstRow, endRow) {
  const inputs = [];
  const prompts = [];
  const line = (row) => buffer.lineForRow(row) ?? '';
  const endOfRow = (row) => (row + 1 < buffer.getLineCount() ? new Point(row + 1, 0) : new Point(row, line(row).length));

  let hasPrompt = false;
  for (let row = firstRow; row < endRow; row++) {
    if (PROMPT.test(line(row))) { hasPrompt = true; break; }
  }

  if (!hasPrompt) {
    // Script style: everything before `# output` is the input.
    let last = firstRow - 1;
    for (let row = firstRow; row < endRow && !OUTPUT_MARKER.test(line(row)); row++) last = row;
    if (last >= firstRow) inputs.push([new Point(firstRow, 0), endOfRow(last)]);
    return { inputs, prompts };
  }

  for (let row = firstRow; row < endRow; row++) {
    const match = line(row).match(PROMPT);
    if (!match) continue;
    const indent = match[1].length;
    prompts.push([new Point(row, indent), new Point(row, indent + match[2].length)]);
    // Continuation lines are indented to line up after `julia> `.
    const continuation = ' '.repeat(indent + 7);
    let last = row;
    while (last + 1 < endRow && line(last + 1).startsWith(continuation) && /\S/.test(line(last + 1))) last++;
    inputs.push([new Point(row, match[0].length), endOfRow(last)]);
    row = last;
  }
  return { inputs, prompts };
}

// A range in the form Pulsar's injections take (like a Tree-sitter node's).
function rangeSpec(buffer, [start, end]) {
  return {
    startIndex: buffer.characterIndexForPosition(start),
    endIndex: buffer.characterIndexForPosition(end),
    startPosition: { row: start.row, column: start.column },
    endPosition: { row: end.row, column: end.column }
  };
}

// For the injection on Markdown's `fenced_code_block`.
function transcriptLanguage(fencedCodeBlock) {
  const language = fencedCodeBlock.descendantsOfType('language')[0]?.text;
  return TRANSCRIPT_LANGUAGES.has(language) ? 'julia' : null;
}

function transcriptInputs(fencedCodeBlock, buffer) {
  const content = fencedCodeBlock.descendantsOfType('code_fence_content')[0];
  if (!content) return [];
  const endRow = content.endPosition.column === 0 ? content.endPosition.row : content.endPosition.row + 1;
  return scanTranscript(buffer, content.startPosition.row, endRow).inputs.map((range) => rangeSpec(buffer, range));
}

// The `julia>` prompts in the transcripts within rows `firstRow`…`lastRow`
// (a docstring), found by scanning for fences.
function promptsWithin(buffer, firstRow, lastRow) {
  const prompts = [];
  for (let row = firstRow; row <= lastRow; row++) {
    const open = (buffer.lineForRow(row) ?? '').match(OPENING_FENCE);
    if (!open) continue;
    const fence = open[1];
    let close = row + 1;
    while (close <= lastRow && !(buffer.lineForRow(close) ?? '').trim().startsWith(fence)) close++;
    if (TRANSCRIPT_LANGUAGES.has(open[2])) prompts.push(...scanTranscript(buffer, row + 1, close).prompts);
    row = close;
  }
  return prompts;
}

module.exports = { scanTranscript, transcriptLanguage, transcriptInputs, promptsWithin };
