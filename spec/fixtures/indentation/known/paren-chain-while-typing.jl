# Known limitation (typing only): inside a bracket that is not closed yet, the parser
# drops a trailing operator from the tree, so the soft continuation indent is not
# applied until the expression is complete. Re-indenting afterwards is correct.
y = (
    a +
        b
)
