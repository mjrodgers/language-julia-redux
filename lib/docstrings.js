// Finding docstrings in the syntax tree, and marking their lines in the editor.
//
// highlights.scm recognises the same docstrings with Tree-sitter queries; keep
// the two in step.
const { CompositeDisposable, Range } = require('atom');
const { promptsWithin } = require('./doctests');

const SCOPE = 'source.julia';
const CONFIG = 'language-julia-redux';

const STRING_TYPES = ['string_literal', 'prefixed_string_literal'];

// What a string just before it documents.
const DOCUMENTABLE = new Set([
  'function_definition', 'macro_definition', 'struct_definition',
  'abstract_definition', 'primitive_definition', 'module_definition',
  'const_statement', 'assignment', 'identifier', 'macrocall_expression',
  'call_expression', 'field_expression'
]);

// Blocks whose statements can have docstrings, besides the file itself.
const DOCUMENTED_BLOCKS = new Set(['module_definition', 'compound_statement', 'quote_statement']);

const isFirstNamedChild = (node, parent) => parent?.firstNamedChild?.id === node.id;

// `@doc`, `Base.@doc` or `Core.@doc`.
function isDocMacro(macrocall) {
  if (macrocall?.type !== 'macrocall_expression') return false;
  let head = macrocall.firstChild;
  if (head?.type === 'field_expression') head = head.lastChild;
  return head?.type === 'macro_identifier' && head.text === '@doc';
}

// A docstring is a string just before something it documents, at the top level
// of a file or of a module, `begin` or `quote` block; or the string given to
// `@doc`: `@doc "..." f`, `@doc raw"""...""" f`, `@doc("...", f)`, `@doc "..." ->`.
function isDocstring(node) {
  if (!STRING_TYPES.includes(node.type)) return false;
  let parent = node.parent;
  if (!parent) return false;

  // `@doc "..." ->` parses as a binary expression that starts with the string.
  if (parent.type === 'binary_expression' && isFirstNamedChild(node, parent)) {
    if (parent.parent?.type !== 'macro_argument_list' || !isFirstNamedChild(parent, parent.parent)) return false;
    return isDocMacro(parent.parent.parent);
  }
  if (parent.type === 'macro_argument_list' || parent.type === 'argument_list') {
    return isFirstNamedChild(node, parent) && isDocMacro(parent.parent);
  }

  if (node.type !== 'string_literal') return false;
  const placed = parent.type === 'source_file' ||
    (parent.type === 'block' && DOCUMENTED_BLOCKS.has(parent.parent?.type));
  if (!placed) return false;
  const next = node.nextNamedSibling;
  return Boolean(next && DOCUMENTABLE.has(next.type));
}

function docstringNodes(editor) {
  const tree = editor.getBuffer().getLanguageMode()?.rootLanguageLayer?.tree;
  if (!tree) return [];
  return tree.rootNode.descendantsOfType(STRING_TYPES).filter(isDocstring);
}

// The rows a docstring folds over: from the end of its first row to the end of
// the row before its closing quotes, the same range as its fold in folds.scm.
function foldRangeFor(node) {
  const start = node.startPosition.row;
  const end = node.endPosition.row - 1;
  return end > start ? new Range([start, Infinity], [end, Infinity]) : null;
}

// Marks the lines of every docstring in one editor with a line decoration, so
// that styles/docstrings.less can give them a background and a guide, and the
// `julia>` prompts of the REPL examples in them. Rescanned whenever the user
// stops typing.
class DocstringLines {
  constructor(editor) {
    this.editor = editor;
    this.markers = editor.addMarkerLayer();
    this.promptMarkers = editor.addMarkerLayer();
    this.decoration = null;
    this.promptDecoration = null;
    this.subscriptions = new CompositeDisposable(
      editor.getBuffer().onDidStopChanging(() => this.update()),
      atom.config.observe(`${CONFIG}.docstringBackground`, () => this.decorate()),
      atom.config.observe(`${CONFIG}.docstringGuide`, () => this.decorate()),
      atom.config.observe(`${CONFIG}.juliaInDoctests`, () => this.decorate()),
      atom.config.observe(`${CONFIG}.markdownInDocstrings`, () => this.decorate())
    );
    const languageMode = editor.getBuffer().getLanguageMode();
    Promise.resolve(languageMode.ready).then(() => this.update());
  }

  classes() {
    const classes = [];
    if (atom.config.get(`${CONFIG}.docstringBackground`)) classes.push('julia-docstring-background');
    if (atom.config.get(`${CONFIG}.docstringGuide`)) classes.push('julia-docstring-guide');
    return classes;
  }

  decorate() {
    this.decoration?.destroy();
    this.decoration = null;
    this.promptDecoration?.destroy();
    this.promptDecoration = null;
    const classes = this.classes();
    if (classes.length > 0) {
      this.decoration = this.editor.decorateMarkerLayer(this.markers, {
        type: 'line',
        class: ['julia-docstring', ...classes].join(' ')
      });
    }
    if (atom.config.get(`${CONFIG}.juliaInDoctests`) && atom.config.get(`${CONFIG}.markdownInDocstrings`)) {
      this.promptDecoration = this.editor.decorateMarkerLayer(this.promptMarkers, {
        type: 'text',
        class: 'julia-repl-prompt'
      });
    }
  }

  async update() {
    const languageMode = this.editor.getBuffer().getLanguageMode();
    await languageMode.atTransactionEnd?.();
    if (this.destroyed) return;
    this.markers.clear();
    this.promptMarkers.clear();
    const buffer = this.editor.getBuffer();
    for (const node of docstringNodes(this.editor)) {
      const firstRow = node.startPosition.row;
      const lastRow = node.endPosition.row;
      this.markers.markBufferRange(
        [[firstRow, 0], [lastRow, buffer.lineLengthForRow(lastRow)]],
        { invalidate: 'never', exclusive: true }
      );
      for (const prompt of promptsWithin(buffer, firstRow, lastRow)) {
        this.promptMarkers.markBufferRange(prompt, { invalidate: 'touch' });
      }
    }
  }

  // The marked ranges, for specs.
  ranges() {
    return this.markers.getMarkers().map((marker) => marker.getBufferRange());
  }

  promptRanges() {
    return this.promptMarkers.getMarkers().map((marker) => marker.getBufferRange());
  }

  destroy() {
    this.destroyed = true;
    this.subscriptions.dispose();
    this.decoration?.destroy();
    this.promptDecoration?.destroy();
    this.markers.destroy();
    this.promptMarkers.destroy();
  }
}

module.exports = { SCOPE, CONFIG, isDocstring, docstringNodes, foldRangeFor, DocstringLines };
