// Detecting a Julia file's indentation from its code blocks (lib/indentation.js).
const path = require('path');

describe('Julia indentation detection', () => {
  let main;

  beforeEach(async () => {
    atom.config.set('core.useTreeSitterParsers', true);
    atom.config.set('language-julia-redux.detectIndentation', true);
    main = (await atom.packages.activatePackage(path.join(__dirname, '..'))).mainModule;
  });

  const open = async (text) => {
    const editor = await atom.workspace.open();
    editor.setText(text);
    editor.setGrammar(atom.grammars.grammarForScopeName('source.julia'));
    await editor.getBuffer().getLanguageMode().ready;
    return editor;
  };

  const twoSpaces = [
    'module M',
    'function f(x,',
    '           y)', // lined up under the parenthesis: not counted
    '  if x > 0',
    '    return y',
    '  else',
    '    z = 1',
    '  end',
    '  for i in 1:3',
    '    println(i)',
    '  end',
    'end',
    'end',
  ].join('\n');

  it('uses the width the code blocks are indented by', async () => {
    const editor = await open(twoSpaces);
    atom.workspace.getActivePane().activateItem(editor);
    expect(await main.detectIndentation()).toEqual({ softTabs: true, tabLength: 2, samples: 4 });
    expect(editor.getTabLength()).toBe(2);
    expect(editor.getSoftTabs()).toBe(true);
  });

  it('recognises tabs', async () => {
    const editor = await open('function f(x)\n\tif x\n\t\treturn 1\n\tend\n\tfor i in 1:2\n\t\tprintln(i)\n\tend\nend');
    atom.workspace.getActivePane().activateItem(editor);
    expect((await main.detectIndentation()).softTabs).toBe(false);
    expect(editor.getSoftTabs()).toBe(false);
  });

  it('leaves the settings alone when the file does not clearly use one width', async () => {
    const editor = await open('function f(x)\n  if x\n      return 1\n  end\n    for i in 1:2\n        g(i)\n    end\nend');
    atom.workspace.getActivePane().activateItem(editor);
    const before = editor.getTabLength();
    expect(await main.detectIndentation()).toBe(null);
    expect(editor.getTabLength()).toBe(before);
  });

  it('ignores module bodies, which are not indented by convention', async () => {
    const editor = await open('module A\nf(x) = 1\ng(x) = 2\nh(x) = 3\nend');
    atom.workspace.getActivePane().activateItem(editor);
    expect(await main.detectIndentation()).toBe(null);
  });
});
