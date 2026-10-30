// Syntax highlighting (grammars/tree-sitter-julia/highlights.scm), checked with Pulsar's own grammar-test helper:
// each `# <- scope` / `#   ^ scope` comment in the fixture asserts a scope on the last line above it that is not an
// assertion. `runGrammarTests` is a global in Pulsar's spec runners (spec/helpers/normalize-comments.js).
const path = require('path');

describe('Julia grammar (modern Tree-sitter)', () => {
  beforeEach(async () => {
    atom.config.set('core.useTreeSitterParsers', true);
    await atom.packages.activatePackage(path.join(__dirname, '..'));
  });

  it('applies the expected scopes', async () => {
    await runGrammarTests(path.join(__dirname, 'fixtures', 'grammar', 'syntax_test_julia.jl'), /#/);
  });

  it('is used for .jl files and for "julia" code blocks', () => {
    const grammar = atom.grammars.grammarForScopeName('source.julia');
    expect(grammar.name).toBe('Julia');
    expect(grammar.type).toBe('modern-tree-sitter');
    expect(grammar.fileTypes).toContain('jl');
    expect(new RegExp(grammar.injectionRegex.source ?? grammar.injectionRegex).test('julia')).toBe(true);
  });
});
