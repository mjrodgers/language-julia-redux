// Indentation with the modern Tree-sitter grammar (grammars/tree-sitter-julia/indents.scm).
//
// Every file in fixtures/indentation is correctly indented Julia (Runic style: four spaces, module bodies not
// indented, one "soft" level for continuation lines). Each file is checked two ways:
//
//   * re-indent: the file with all indentation removed, then Edit > Lines > Auto Indent over everything;
//   * typing: the file typed from the top, one character at a time, pressing Enter at the end of each line, so the
//     indentation comes from what Pulsar suggests on Enter and from the dedent it applies while typing (`end`, `else`).
//
// Rows that start inside a multi-line string or comment are not checked: their indentation is the text's own.
// Files in fixtures/indentation/known describe known limitations; they are only checked by re-indenting.
const fs = require('fs');
const path = require('path');

const FIXTURES = path.join(__dirname, 'fixtures', 'indentation');
const TAB = 4;
const fixtureFiles = (dir) => fs.readdirSync(dir).filter((f) => f.endsWith('.jl')).map((f) => path.join(dir, f));
const levelOf = (line) => (/\S/.test(line) ? line.match(/^ */)[0].length / TAB : null);

describe('Julia indentation (modern Tree-sitter)', () => {
  let editor, languageMode;

  beforeEach(async () => {
    atom.config.set('core.useTreeSitterParsers', true);
    atom.config.set('editor.autoIndent', true);
    await atom.packages.activatePackage(path.join(__dirname, '..'));
    editor = await atom.workspace.open();
    editor.setGrammar(atom.grammars.grammarForScopeName('source.julia'));
    editor.setSoftTabs(true);
    editor.setTabLength(TAB);
    languageMode = editor.getBuffer().getLanguageMode();
    await languageMode.ready;
  });

  const settle = () => languageMode.atTransactionEnd();

  // Rows whose first character is inside a string or comment that began on an earlier row.
  function rowsInsideStrings(text) {
    const tree = languageMode.rootLanguageLayer.tree;
    const skip = new Set();
    text.split('\n').forEach((line, row) => {
      const column = line.search(/\S/);
      if (column < 0) return;
      for (let node = tree.rootNode.descendantForPosition({ row, column }); node; node = node.parent) {
        if (/string|comment|command/.test(node.type) && node.startPosition.row < row) { skip.add(row); break; }
      }
    });
    return skip;
  }

  // The rows (1-based) whose indentation differs, as "line N: want X, got Y | text" strings.
  function differences(expected, actual, skip) {
    const want = expected.split('\n');
    const got = actual.split('\n');
    const out = [];
    want.forEach((line, row) => {
      if (skip.has(row) || levelOf(line) === null) return;
      const level = levelOf(got[row] ?? '');
      if (level !== levelOf(line)) out.push(`line ${row + 1}: want ${levelOf(line)}, got ${level} | ${line.trim()}`);
    });
    return out;
  }

  async function reindented(text) {
    editor.setText(text.split('\n').map((l) => l.trimStart()).join('\n'));
    await settle();
    editor.setSelectedBufferRange([[0, 0], [Infinity, Infinity]]);
    editor.autoIndentSelectedRows();
    await settle();
    return editor.getText();
  }

  async function typed(text) {
    editor.setText('');
    await settle();
    const lines = text.split('\n');
    for (let row = 0; row < lines.length; row++) {
      if (row > 0) {
        editor.insertText('\n');
        await settle();
      }
      for (const character of lines[row].trimStart()) {
        editor.insertText(character);
        await settle();
      }
    }
    return editor.getText();
  }

  for (const file of fixtureFiles(FIXTURES)) {
    const name = path.basename(file);
    const text = fs.readFileSync(file, 'utf8').replace(/\n+$/, '');

    it(`re-indents ${name}`, async () => {
      const result = await reindented(text);
      editor.setText(text);
      await settle();
      expect(differences(text, result, rowsInsideStrings(text))).toEqual([]);
    });

    it(`indents ${name} while it is typed`, async () => {
      const result = await typed(text);
      editor.setText(text);
      await settle();
      expect(differences(text, result, rowsInsideStrings(text))).toEqual([]);
    });
  }

  for (const file of fixtureFiles(path.join(FIXTURES, 'known'))) {
    const name = path.basename(file);
    const text = fs.readFileSync(file, 'utf8').replace(/\n+$/, '');
    it(`re-indents ${name} (typing it is a known limitation)`, async () => {
      const result = await reindented(text);
      editor.setText(text);
      await settle();
      expect(differences(text, result, rowsInsideStrings(text))).toEqual([]);
    });
  }
});
