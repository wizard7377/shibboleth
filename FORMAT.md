# Formatting

Update the formatting such that the following is true:

## Whitespace 

1. Seqeuences of more than one charecter of whitespace should only occur at the begining of the line
2. Every infix operator should be surronded by whitespace. This should *include* it occuring parenthisized prefix (ie, `( ++ )` is prefrable to `(++)`).
3. The `:` in a type binding should always have a space after it 

## Alignment 

1. `*` (in types and constructor declerations), `->` (in types), `|` (in all cases), `&&`, `||` should all either all be aligned in a single group or should all be on a single line. 
Never should you have a decleration like the following:
```A * B *
C```
2. `;` (as a sequence) should always occur at the end of a line. Sequences should always be indented.
3. Pattern cases should occur on seperate lines

