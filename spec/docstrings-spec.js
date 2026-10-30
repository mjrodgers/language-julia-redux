// Docstring support (lib/main.js, lib/docstrings.js, highlights.scm): recognising docstrings, Markdown and Julia
// inside them, the toggle commands, and the line markers behind the background and guide.
const path = require('path');

describe('Julia docstrings', () => {
  let editor, languageMode, main;
  const text = [
    '"""',          // 0
    '    f(x)',     // 1
    '',             // 2
    'Does f.',      // 3
    '"""',          // 4
    'f(x) = x',     // 5
    '',             // 6
    '"""',          // 7
    'A type.',      // 8
    '"""',          // 9
    'struct T end', // 10
    '',             // 11
    'g("""',        // 12  not a docstring: an argument
    'text',         // 13
    '""")'          // 14
  ].join('\n');

  beforeEach(async () => {
    atom.config.set('core.useTreeSitterParsers', true);
    main = (await atom.packages.activatePackage(path.join(__dirname, '..'))).mainModule;
    editor = await atom.workspace.open();
    editor.setGrammar(atom.grammars.grammarForScopeName('source.julia'));
    languageMode = editor.getBuffer().getLanguageMode();
    await languageMode.ready;
    editor.setText(text);
    await languageMode.atTransactionEnd();
  });

  const run = (command) => atom.commands.dispatch(atom.views.getView(editor), command);

  const scopesAt = (row, column = 1) => editor.scopeDescriptorForBufferPosition([row, column]).getScopesArray();

  it('scopes only the quotes of a docstring as a string, so its text can be Markdown', () => {
    expect(scopesAt(3)).toContain('meta.docstring.julia');
    expect(scopesAt(3).some((scope) => scope.startsWith('string.'))).toBe(false);
    expect(scopesAt(8)).toContain('meta.docstring.julia');
    expect(scopesAt(0, 0)).toContain('string.quoted.triple.docstring.julia');
    expect(scopesAt(0, 0)).toContain('punctuation.definition.string.begin.julia');
    expect(scopesAt(4, 0)).toContain('string.quoted.triple.docstring.julia');
    expect(scopesAt(4, 0)).toContain('punctuation.definition.string.end.julia');
    // An ordinary string argument is not a docstring.
    expect(scopesAt(13)).not.toContain('meta.docstring.julia');
    expect(scopesAt(13)).toContain('string.quoted.triple.double.julia');
  });

  it('scopes a whole docstring as a string when Markdown highlighting is off', async () => {
    atom.config.set('language-julia-redux.markdownInDocstrings', false);
    editor.setText(text);
    await languageMode.atTransactionEnd();
    expect(scopesAt(3)).toContain('string.quoted.triple.docstring.julia');
    expect(scopesAt(3)).not.toContain('meta.docstring.julia');
  });

  it('recognises the string given to @doc, including raw strings', async () => {
    editor.setText('@doc raw"""\n    g(x)\n\nMath ``\\Omega``.\n"""\ng(x) = x');
    await languageMode.atTransactionEnd();
    expect(scopesAt(3)).toContain('meta.docstring.julia');
    expect(scopesAt(3).some((scope) => scope.startsWith('string.'))).toBe(false);
    expect(scopesAt(0, 5)).toContain('storage.type.string.julia');
    expect(scopesAt(4, 0)).toContain('string.quoted.triple.docstring.julia');
  });

  it('folds and unfolds the docstring under the cursor', () => {
    editor.setCursorBufferPosition([3, 0]);
    run('language-julia:toggle-docstrings');
    expect(editor.isFoldedAtBufferRow(1)).toBe(true);
    expect(editor.isFoldedAtBufferRow(4)).toBe(false);
    run('language-julia:toggle-docstrings');
    expect(editor.isFoldedAtBufferRow(1)).toBe(false);
  });

  it('folds all docstrings, then unfolds them all', () => {
    run('language-julia:toggle-all-docstrings');
    expect(editor.isFoldedAtBufferRow(1)).toBe(true);
    expect(editor.isFoldedAtBufferRow(8)).toBe(true);
    expect(editor.isFoldedAtBufferRow(13)).toBe(false);
    run('language-julia:toggle-all-docstrings');
    expect(editor.isFoldedAtBufferRow(1)).toBe(false);
    expect(editor.isFoldedAtBufferRow(8)).toBe(false);
  });

  it('recognises docstrings in begin and quote blocks, and every form of @doc', async () => {
    const forms = [
      'begin\n"doc"\na = 1\nend',
      'quote\n"doc"\nq() = 1\nend',
      'Base.@doc "doc" b',
      'Core.@doc raw"doc" c',
      '@doc("doc", d)',
      '@doc "doc" ->\ne(x) = x'
    ];
    for (const form of forms) {
      editor.setText(form);
      await languageMode.atTransactionEnd();
      const row = form.startsWith('begin') || form.startsWith('quote') ? 1 : 0;
      const column = editor.lineTextForBufferRow(row).indexOf('doc"') + 1;
      expect(scopesAt(row, column)).toContain('meta.docstring.julia');
    }
  });

  describe('code in docstrings', () => {
    // Injections are built in stages (Julia → Markdown → Julia), so wait until
    // the scope shows up rather than for a fixed number of updates.
    async function scopesOnceInjected(row, column, scope) {
      for (let i = 0; i < 20; i++) {
        const scopes = scopesAt(row, column);
        if (scopes.includes(scope)) return scopes;
        await new Promise((resolve) => require('timers').setTimeout(resolve, 50));
        await languageMode.atTransactionEnd();
      }
      return scopesAt(row, column);
    }

    beforeEach(async () => {
      await atom.packages.activatePackage('language-gfm');
    });

    it('highlights the indented signature as Julia', async () => {
      editor.setText('"""\n    f(x::Int)\n\nDoes f.\n"""\nf(x) = x');
      await languageMode.atTransactionEnd();
      expect(await scopesOnceInjected(1, 10, 'support.type.builtin.julia')).toContain('support.type.builtin.julia');
    });

    it('highlights unlabelled and Documenter code blocks as Julia', async () => {
      editor.setText('"""\nText.\n\n```\nx::Int = 1\n```\n\n```@example\ny::Int = 2\n```\n"""\nf(x) = x');
      await languageMode.atTransactionEnd();
      expect(await scopesOnceInjected(4, 4, 'support.type.builtin.julia')).toContain('support.type.builtin.julia');
      expect(await scopesOnceInjected(8, 4, 'support.type.builtin.julia')).toContain('support.type.builtin.julia');
    });

    describe('REPL examples', () => {
      const example = [
        '"""',                          // 0
        '```jldoctest',                 // 1
        'julia> x = Int[1, 2,',         // 2
        '               3];',           // 3
        '',                             // 4
        'julia> sum(x)',                // 5
        '6',                            // 6
        '```',                          // 7
        '"""',                          // 8
        'f(x) = x'                      // 9
      ].join('\n');

      it('highlights the input after each prompt as Julia, but not the prompt or the output', async () => {
        editor.setText(example);
        await languageMode.atTransactionEnd();
        expect(await scopesOnceInjected(5, 7, 'support.other.function.julia')).toContain('support.other.function.julia');
        expect(scopesAt(2, 12)).toContain('support.type.builtin.julia');
        expect(scopesAt(3, 15)).toContain('constant.numeric.integer.decimal.julia');
        expect(scopesAt(6, 0)).not.toContain('constant.numeric.integer.decimal.julia');
        expect(scopesAt(5, 0).filter((scope) => scope.endsWith('.julia'))).toEqual(['source.julia', 'meta.docstring.julia']);
      });

      it('marks the prompts', async () => {
        editor.setText(example);
        await languageMode.atTransactionEnd();
        const lines = main.docstringLines.get(editor);
        await lines.update();
        expect(lines.promptRanges().map((r) => [r.start.row, r.start.column, r.end.column])).toEqual([[2, 0, 6], [5, 0, 6]]);
      });

      it('can be turned off', async () => {
        atom.config.set('language-julia-redux.juliaInDoctests', false);
        editor.setText(example);
        await languageMode.atTransactionEnd();
        // Give injections the same time as above to (not) appear.
        await scopesOnceInjected(5, 7, 'support.other.function.julia');
        expect(scopesAt(5, 7)).not.toContain('support.other.function.julia');
      });
    });
  });

  it('marks the lines of each docstring, for the background and guide', async () => {
    const lines = main.docstringLines.get(editor);
    await lines.update();
    const rows = lines.ranges().map((range) => [range.start.row, range.end.row]);
    expect(rows).toEqual([[0, 4], [7, 9]]);
  });
});
