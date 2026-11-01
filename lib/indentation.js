// Detecting the indentation a Julia file uses (2 or 4 spaces, say), from its syntax tree.
//
// Only the bodies of blocks count: for each `function`, `if`, `for`, `let`, `struct`, `begin`, `quote`, `do`, …
// whose body starts on a line of its own, how much further that line is indented than the line the block opens on.
// Continuation lines (arguments lined up under a parenthesis), strings and comments are never looked at, which is
// what makes general-purpose detectors guess wrong. Module bodies are skipped: by convention they are not indented.

// Blocks whose body is not indented by convention.
const UNINDENTED_PARENTS = new Set(['module_definition', 'baremodule_definition', 'source_file']);

const MIN_SAMPLES = 3; // fewer blocks than this: too little to go on
const MIN_SHARE = 0.7; // the winning width must account for this share of the samples
const WIDTHS = new Set([2, 3, 4, 8]);
const MAX_ROWS = 1500; // the first rows are plenty to decide; a huge file need not be read to the end

// The leading whitespace of a line: { width, tab } (width in spaces; tab = it contains a tab).
function leading(line) {
  const ws = /^[ \t]*/.exec(line || '')[0];
  return { width: ws.length, tab: ws.includes('\t'), length: ws.length };
}

// From the syntax tree and the buffer's lines: { softTabs: true, tabLength, samples } for a file indented with spaces,
// { softTabs: false, samples } for one indented with tabs, or null when it cannot tell.
function detectIndentation(rootNode, lineForRow) {
  if (!rootNode) return null;
  const counts = new Map(); // width -> number of blocks
  let spaceSamples = 0;
  let tabSamples = 0;
  const blocks = rootNode.descendantsOfType('block', { row: 0, column: 0 }, { row: MAX_ROWS, column: 0 });
  for (const block of blocks) {
    const parent = block.parent;
    if (!parent || UNINDENTED_PARENTS.has(parent.type)) continue;
    const bodyRow = block.startPosition.row;
    const openRow = parent.startPosition.row;
    if (bodyRow <= openRow) continue; // a one-line block: `if x y end`
    const body = leading(lineForRow(bodyRow));
    if (block.startPosition.column !== body.length) continue; // the body does not start its line
    const open = leading(lineForRow(openRow));
    if (body.tab || open.tab) {
      if (body.tab) tabSamples++;
      continue;
    }
    const delta = body.width - open.width;
    if (delta <= 0) continue;
    spaceSamples++;
    counts.set(delta, (counts.get(delta) || 0) + 1);
  }

  if (tabSamples >= MIN_SAMPLES && tabSamples > spaceSamples) return { softTabs: false, samples: tabSamples };
  if (spaceSamples < MIN_SAMPLES) return null;
  let best = null;
  for (const [width, count] of counts) if (!best || count > best.count) best = { width, count };
  if (!best || !WIDTHS.has(best.width) || best.count / spaceSamples < MIN_SHARE) return null;
  return { softTabs: true, tabLength: best.width, samples: spaceSamples };
}

// Detects the editor's indentation and applies it to that editor only. Returns what was found (or null).
async function applyDetectedIndentation(editor) {
  const buffer = editor.getBuffer();
  const languageMode = buffer.getLanguageMode();
  await Promise.resolve(languageMode.ready);
  await languageMode.atTransactionEnd?.();
  if (editor.isDestroyed?.()) return null;
  const tree = languageMode.rootLanguageLayer?.tree;
  const found = detectIndentation(tree?.rootNode, (row) => buffer.lineForRow(row));
  if (!found) return null;
  editor.setSoftTabs(found.softTabs);
  if (found.softTabs && editor.getTabLength() !== found.tabLength) editor.setTabLength(found.tabLength);
  return found;
}

module.exports = { detectIndentation, applyDetectedIndentation };
