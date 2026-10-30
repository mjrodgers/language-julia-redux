// Code folding (grammars/tree-sitter-julia/folds.scm).
const fs = require('fs');
const path = require('path');

describe('Julia folding (modern Tree-sitter)', () => {
  let editor, languageMode;

  beforeEach(async () => {
    atom.config.set('core.useTreeSitterParsers', true);
    // Markdown injected into docstrings could add folds of its own.
    atom.config.set('language-julia-redux.markdownInDocstrings', false);
    await atom.packages.activatePackage(path.join(__dirname, '..'));
    editor = await atom.workspace.open();
    editor.displayLayer.reset({ foldCharacter: '…' });
    editor.setGrammar(atom.grammars.grammarForScopeName('source.julia'));
    languageMode = editor.getBuffer().getLanguageMode();
    await languageMode.ready;
  });

  async function setText(text) {
    editor.setText(text);
    await languageMode.atTransactionEnd();
  }

  it('offers a fold for each block, branch, bracket list, long string and block comment', async () => {
    await setText(fs.readFileSync(path.join(__dirname, 'fixtures', 'folding', 'folds.jl'), 'utf8'));
    // [first line, last line] of each fold, 1-based. A fold starts at the end of its first line.
    const expected = [
      [1, 2], [4, 12], [5, 6], [7, 8], [9, 10], [14, 25], [18, 19], [20, 21], [22, 23], [27, 30], [31, 33],
      [34, 35], [37, 38], [40, 42], [43, 45], [46, 48], [49, 51], [52, 54], [55, 57], [58, 60], [61, 63],
      [64, 66], [68, 81], [69, 72], [70, 72], [73, 74], [76, 77], [78, 79], [82, 83], [84, 86], [87, 88]
    ];
    const actual = languageMode.getFoldableRanges().map((r) => [r.start.row + 1, r.end.row + 1]);
    expect(actual).toEqual(expected);
  });

  it('folds each branch of an if statement separately', async () => {
    await setText('if a\n    1\nelseif b\n    2\nelse\n    3\nend');
    editor.foldBufferRow(0);
    editor.foldBufferRow(2);
    editor.foldBufferRow(4);
    expect(editor.displayLayer.getText()).toBe('if a…\nelseif b…\nelse…\nend');
  });

  it('folds a try block up to its catch', async () => {
    await setText('try\n    f()\ncatch err\n    g()\nfinally\n    h()\nend');
    editor.foldBufferRow(0);
    editor.foldBufferRow(2);
    editor.foldBufferRow(4);
    expect(editor.displayLayer.getText()).toBe('try…\ncatch err…\nfinally…\nend');
  });

  it('folds a call or array up to its closing bracket', async () => {
    await setText('v = [\n    1,\n    2,\n]');
    editor.foldBufferRow(0);
    expect(editor.displayLayer.getText()).toBe('v = […]');
  });

  it('folds a docstring, leaving its closing quotes visible', async () => {
    await setText('"""\n    f(x)\n\nDoes f.\n"""\nf(x) = x');
    editor.foldBufferRow(0);
    expect(editor.displayLayer.getText()).toBe('"""…\n"""\nf(x) = x');
  });
});
