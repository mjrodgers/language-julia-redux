const { CompositeDisposable } = require('atom');
const { SCOPE, CONFIG, isDocstring, docstringNodes, foldRangeFor, DocstringLines } = require('./docstrings');
const { transcriptLanguage, transcriptInputs } = require('./doctests');
const { applyDetectedIndentation } = require('./indentation');

// Non-standard string literals whose contents are another language, by prefix:
// md"# Title", html"<b>bold</b>". The value is the name the other grammar
// answers to (its `injectionRegex`).
const PREFIXED_STRING_LANGUAGES = {
  md: 'markdown',
  html: 'html'
};

const markdownInDocstrings = () => atom.config.get(`${CONFIG}.markdownInDocstrings`);

const contentOf = (node) => node.children.filter((child) => child.type === 'content');

// Whether a buffer is a Julia file. Used to treat code in Markdown as Julia
// only inside Julia docstrings, not in Markdown files.
const isJuliaBuffer = (buffer) => buffer?.getLanguageMode?.()?.getGrammar?.()?.scopeName === SCOPE;

const isFolded = (editor, node) => editor.isFoldedAtBufferRow(node.startPosition.row + 1);

module.exports = {
  activate() {
    this.subscriptions = new CompositeDisposable();
    this.docstringLines = new Map();

    this.subscriptions.add(
      atom.commands.add('atom-text-editor', {
        'language-julia:toggle-docstrings': (event) => this.toggleDocstring(event),
        'language-julia:toggle-all-docstrings': () => this.toggleAllDocstrings(),
        'language-julia:detect-indentation': () => this.detectIndentation({ report: true })
      }),
      atom.workspace.observeTextEditors((editor) => this.watchEditor(editor))
    );

    if (atom.grammars.addInjectionPoint) this.addInjectionPoints();
  },

  deactivate() {
    this.subscriptions?.dispose();
    for (const lines of this.docstringLines?.values() ?? []) lines.destroy();
    this.docstringLines?.clear();
  },

  addInjectionPoints() {
    // Docstrings are Markdown. (highlights.scm scopes docstrings to match: with
    // this setting on, their text is not scoped as a string.)
    atom.grammars.addInjectionPoint(SCOPE, {
      type: 'string_literal',
      language(node) {
        return markdownInDocstrings() && isDocstring(node) ? 'markdown' : null;
      },
      content: contentOf,
      languageScope: null
    });

    atom.grammars.addInjectionPoint(SCOPE, {
      type: 'prefixed_string_literal',
      language(node) {
        if (markdownInDocstrings() && isDocstring(node)) return 'markdown';
        const prefix = node.childForFieldName('prefix')?.text;
        return PREFIXED_STRING_LANGUAGES[prefix] ?? null;
      },
      content: contentOf,
      languageScope: null
    });

    // Code in a docstring is Julia: the indented signature at the top, and
    // code blocks without a language. (Blocks marked `julia`, `@example`,
    // `@repl`, `@setup` or `@eval` are Julia everywhere, through the grammar's
    // `injectionRegex`.) Only in Julia files: in a Markdown file such a block
    // could be anything.
    atom.grammars.addInjectionPoint('source.gfm', {
      type: 'indented_code_block',
      language: () => 'julia',
      content: (node, buffer) => (isJuliaBuffer(buffer) ? node : []),
      includeChildren: true
    });
    atom.grammars.addInjectionPoint('source.gfm', {
      type: 'fenced_code_block',
      language: (node) => (node.descendantsOfType('info_string').length === 0 ? 'julia' : null),
      content: (node, buffer) => (isJuliaBuffer(buffer) ? node.descendantsOfType('code_fence_content') : []),
      includeChildren: true
    });

    // REPL transcripts (```jldoctest, ```julia-repl), in docstrings and in
    // Markdown files: the input after each `julia>` prompt is Julia; the
    // prompts and the output are left alone.
    atom.grammars.addInjectionPoint('source.gfm', {
      type: 'fenced_code_block',
      language: (node) => (atom.config.get(`${CONFIG}.juliaInDoctests`) ? transcriptLanguage(node) : null),
      content: transcriptInputs,
      includeChildren: true,
      newlinesBetween: true
    });
  },

  // Mark the lines of docstrings in Julia editors (for the background and guide).
  watchEditor(editor) {
    const stop = () => {
      this.docstringLines.get(editor)?.destroy();
      this.docstringLines.delete(editor);
    };
    const subscriptions = new CompositeDisposable(
      editor.observeGrammar((grammar) => {
        stop();
        if (grammar.scopeName !== SCOPE) return;
        this.docstringLines.set(editor, new DocstringLines(editor));
        // Once, when the file opens (or becomes Julia): its own indentation, if it clearly has one.
        if (atom.config.get(`${CONFIG}.detectIndentation`) && !atom.packages.isPackageActive('editorconfig')) {
          applyDetectedIndentation(editor).catch(() => {});
        }
      }),
      editor.onDidDestroy(() => {
        stop();
        subscriptions.dispose();
        this.subscriptions.remove(subscriptions);
      })
    );
    this.subscriptions.add(subscriptions);
  },

  // The command: detect the active Julia file's indentation again (after pasting in code, say) and say what it found.
  async detectIndentation({ report = false } = {}) {
    const editor = atom.workspace.getActiveTextEditor();
    if (!editor || editor.getGrammar().scopeName !== SCOPE) return null;
    const found = await applyDetectedIndentation(editor);
    if (report) {
      const what = !found ? null : found.softTabs ? `${found.tabLength} spaces` : 'tabs';
      if (what) atom.notifications.addInfo(`Julia: this file is indented with ${what}; using that here.`);
      else atom.notifications.addInfo('Julia: this file does not clearly use one indentation; your settings apply.');
    }
    return found;
  },

  // Fold or unfold the docstring under the cursor. When the cursor is not in a
  // docstring the key binding is passed on, so this can share a key (Tab, say).
  toggleDocstring(event) {
    const editor = atom.workspace.getActiveTextEditor();
    if (!editor || editor.getGrammar().scopeName !== SCOPE) return event.abortKeyBinding();
    const row = editor.getCursorBufferPosition().row;
    const node = docstringNodes(editor).find(
      (n) => n.startPosition.row <= row && row <= n.endPosition.row
    );
    const range = node && foldRangeFor(node);
    if (!range) return event.abortKeyBinding();
    if (isFolded(editor, node)) {
      editor.unfoldBufferRow(node.startPosition.row + 1);
    } else {
      editor.foldBufferRange(range);
    }
  },

  // Fold every docstring in the file, or unfold them all if they are all folded.
  toggleAllDocstrings() {
    const editor = atom.workspace.getActiveTextEditor();
    if (!editor || editor.getGrammar().scopeName !== SCOPE) return;
    const nodes = docstringNodes(editor).filter(foldRangeFor);
    const fold = nodes.some((node) => !isFolded(editor, node));
    for (const node of nodes) {
      if (fold && !isFolded(editor, node)) editor.foldBufferRange(foldRangeFor(node));
      if (!fold) editor.unfoldBufferRow(node.startPosition.row + 1);
    }
  },

  consumeHyperlinkInjection(hyperlink) {
    hyperlink.addInjectionPoint(SCOPE, {
      types: ['line_comment', 'block_comment', 'content']
    });
  },

  consumeTodoInjection(todo) {
    todo.addInjectionPoint(SCOPE, { types: ['line_comment', 'block_comment'] });
  }
};
