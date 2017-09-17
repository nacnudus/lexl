#' @title Parse Excel formulas into tokens
#'
#' @description
#' `lex_xl` takes an Excel formula and separates it into tokens.  It returns a
#' dataframe, one row per token, giving the token itself, its type (e.g.
#' `number`, or `error`), and its level.
#'
#' The level is a number to show the depth of a token within nested function
#' calls.  The token `A2` in the formula `IF(A1=1,A2,MAX(A3,A4))` is at level 1.
#' Tokens `A3` and `A4` are at level 2.  The token `IF` is at level 0, which is
#' the outermost level.
#'
#' The output isn't enough to enable computation or validation of formulas, but
#' it is enough to investigate the structure of formulas and spreadsheets.  It
#' has been tested on millions of formulas in the Enron corpus.
#'
#' @param x Character vector of length 1, giving the formula.
#'
#' @details
#' The different types of tokens are:
#'
#' * `ref` A cell reference/address e.g. `A1` or `$B2:C$14`.
#' * `sheet`A sheet name, e.g. `Sheet1!` or `'My Sheet'!`.  If the sheet is
#'   from a different file, then the file is included in this token -- usually
#'   it has been normalized to the form `[0]`.
#' * `name` A named range, or more properly a named formula.
#' * `function` An Excel or user-defined function, e.g. `MAX` or
#'   `_xll.MY_CUSTOM_FUNCTION`.  A complete list of official Excel functions is
#'   available in the vector [`excel_functions`].
#' * `error` An error, e.g. `#N/A` or `#REF!`.
#' * `bool` `TRUE` or `FALSE` -- note that there are also functions `TRUE()` and
#'   `FALSE()`.
#' * `number` All forms of numbers, e.g. `1`, `1.1`, `-1`, `1.2E3`.
#' * `text` Strings inside double quotes, e.g. `"Hello, World!"`.
#' * `operator` The usual infix operators, `+`, `-`, `*`, `/`, `^`, `<`, `<=`,
#'   `<>`, etc.  and also the range operator `:` when it is used with ranges
#'   that aren't cell addresses, e.g. `INDEX(something):A1`. The union operator
#'   `,` is the same symbol that is used to separate function arguments and
#'   array columns, so it is only tagged `operator` when it is inside
#'   parentheses that are not function parentheses or array curly braces (see
#'   the examples).
#' * `paren_open` An open parenthesis `(` indicating an increase in the level
#'   of nesting, but not directly enclosing function arguments.
#' * `paren_close` As `open`, but reducing the level of nesting.
#' * `open_array` An open curly brace '\\{' indicating the start of an array
#'   of constants, and an increase in the level of nesting.
#' * `close_array` As `open_array`, but ending the array of constants
#' * `fun_open` An open parenthesis `(` immediately after a function name,
#'   directly enclosing the function arguments.
#' * `fun_close` As `fun_open` but immediately after the function
#'   arguments.
#' * `separator` A comma `,` separating function arguments or array
#'   columns, or a semicolon `;` separating array rows.
#' * `DDE` A call to a Dynamic Data Exchange server, usually normalized to
#'   the form `[1]!'DDE_parameter=1'`, but the full form is
#'   `'ABCD'|'EFGH'!'IJKL'`.
#' * `space` Some old files haven't stripped formulas of meaningless
#'   spaces. They are returned as `space` tokens so that the original formula
#'   can always be reconstructed by concatenating all tokens.
#' * `other` If you see this, then something has gone wrong -- please
#'   report it at https://github.com/nacnudus/lexl/issues with a
#'   reproducible example (e.g. using the reprex package).
#'
#' Every part of the original formula is returned as a token, so the original
#' formula can be reconstructed by concatenating the tokens.  If that doesn't
#' work, please report it at https://github.com/nacnudus/lexl/issues with a
#' reproducible example (e.g. using the reprex package).
#'
#' The XLParser project was a great help in creating the grammar.
#' https://github.com/spreadsheetlab/XLParser.
#'
#' @return
#' A data frame (a tibble, if you use the tidyverse) one row per token,
#' giving the token itself, its type (e.g.  `number`, or `error`), and its
#' level.
#'
#' @seealso [`plot()`][lexl::lexl_igraph()], [lexl::demo_lexl()]
#' @export
#' @examples
#' # All explicit cell references/addresses are returned as a single 'ref'
#' # token.
#' lex_xl("A1")
#' lex_xl("A$1")
#' lex_xl("$A1")
#' lex_xl("$A$1")
#' lex_xl("A1:B2")
#' lex_xl("1:1") # Whole row
#' lex_xl("A:B") # Whole column
#'
#' # If one part of an address is a name or a function, then the colon ':' is
#' # regarded as a 'range operator', so is tagged 'operator'.
#' lex_xl("A1:SOME.NAME")
#' lex_xl("SOME_FUNCTION():B2")
#' lex_xl("SOME_FUNCTION():SOME.NAME")
#'
#' # Sheet names are recognised by the terminal exclamation mark '!'.
#' lex_xl("Sheet1!A1")
#' lex_xl("'Sheet 1'!A1")       # Quoted names may contain some punctuation
#' lex_xl("'It''s a sheet'!A1") # Quotes are escaped by doubling
#'
#' # Sheets can be ranged together in so-called 'three-dimensional formulas'.
#' # Both sheets are returned in a single 'sheet' token.
#' lex_xl("Sheet1:Sheet2!A1")
#' lex_xl("'Sheet 1:Sheet 2'!A1") # Quotes surround both sheets (not each)
#'
#' # Sheets from other files are prefixed by the filename, which Excel
#' # normalizes the filenames into indexes.  Either way, lex_xl() includes the
#' # file/index in the 'sheet' token.
#' lex_xl("[1]Sheet1!A1")
#' lex_xl("'[1]Sheet 1'!A1") # Quotes surround both the file index and the sheet
#' lex_xl("'C:\\My Documents\\[file.xlsx]Sheet1'!A1")
#'
#' # Function names are recognised by the terminal open-parenthesis '('.  There
#' # is no distinction between custom functions and built-in Excel functions.
#' # The open-parenthesis is tagged 'fun_open', and the corresponding
#' # close-parenthesis at the end of the arguments is tagged 'fun_close'.
#' lex_xl("MAX(1,2)")
#' lex_xl("_xll.MY_CUSTOM_FUNCTION()")
#'
#' # Named ranges (properly called 'named formulas') are a last resort after
#' # attempting to match a function (ending in an open parenthesis '(') or a
#' # sheet (ending in an exclamation mark '!')
#' lex_xl("MY_NAMED_RANGE")
#'
#' # Some cell addresses/references, functions and names can look alike, but
#' # lex_xl() should always make the right choice.
#' lex_xl("XFD1")     # A cell in the maximum column in Excel
#' lex_xl("XFE1")     # Beyond the maximum column, must be a named range/formula
#' lex_xl("A1048576") # A cell in the maximum row in Excel
#' lex_xl("A1048577") # Beyond the maximum row, must be a named range/formula
#' lex_xl("LOG10")    # A cell address
#' lex_xl("LOG10()")  # A log function
#' lex_xl("LOG:LOG")  # The whole column 'LOG'
#' lex_xl("LOG")      # Not a cell address, must be a named range/formula
#' lex_xl("LOG()")    # Another log function
#' lex_xl("A1.2!A1")  # A sheet called 'A1.2'
#'
#' # Text is surrounded by double-quotes.
#' lex_xl("\"Some text\"")
#' lex_xl("\"Some \"\"text\"\"\"") # Double-quotes within text are escaped by
#'
#' # Numbers are signed where it makes sense, and can be scientific
#' lex_xl("1")
#' lex_xl("1.2")
#' lex_xl("-1")
#' lex_xl("-1-1")
#' lex_xl("-1+-1")
#' lex_xl("MAX(-1-1)")
#' lex_xl("-1.2E-3")
#'
#' # Booleans can be constants or functions, and names can look like booleans,
#' # but lex_xl() should always make the right choice.
#' lex_xl("TRUE")
#' lex_xl("TRUEISH")
#' lex_xl("TRUE!A1")
#' lex_xl("TRUE()")
#'
#' # Errors are tagged 'error'
#' lex_xl("#DIV/0!")
#' lex_xl("#N/A")
#' lex_xl("#NAME?")
#' lex_xl("#NULL!")
#' lex_xl("#NUM!")
#' lex_xl("#REF!")
#' lex_xl("#VALUE!")
#'
#' # Operators with more than one character are treated as single tokens
#' lex_xl("1<>2")
#' lex_xl("1<=2")
#' lex_xl("1<2")
#' lex_xl("1=2")
#' lex_xl("1&2")
#' lex_xl("1 2")
#' lex_xl("(1,2)")
#' lex_xl("1%")   # postfix operator
#'
#' # The union operator is a comma ',', which is the same symbol that is used
#' # to separate function arguments or array columns.  It is tagged 'operator'
#' # only when it is inside parentheses that are not function parentheses or
#' # array curly braces.  The curly braces are tagged 'array_open' and
#' # 'array_close'.
#' lex_xl("A1,B2") # invalid formula, defaults to 'union' to avoid a crash
#' lex_xl("(A1,B2)")
#' lex_xl("MAX(A1,B2)")
#' lex_xl("SMALL((A1,B2),1)")
#'
#' # Function arguments are separated by commas ',', which are tagged
#' # 'separator'.
#' lex_xl("MAX(1,2)")
#'
#' # Nested functions are marked by an increase in the 'level'.  The level
#' # increases inside parentheses, rather than at the parentheses.  Curly
#' # braces, for arrays, have the same behaviour, as do subexpressions inside
#' # ordinary parenthesis, tagged 'paren_open' and 'paren_close'.
#' lex_xl("MAX(MIN(1,2),3)")
#' lex_xl("{1,2;3,4}")
#' lex_xl("1*(2+3)")
#'
#' # Arrays are marked by opening and closing curly braces, with comma ','
#' # between columns, and semicolons ';' between rows  Commas and semicolons are
#' # both tagged 'separator'.  Arrays contain only constants, which are
#' # booleans, numbers, text, and errors.
#' lex_xl("MAX({1,2;3,4})")
#' lex_xl("=MAX({-1E-2,TRUE;#N/A,\"Hello, World!\"})")
#'
#' # Structured references are surrounded by square brackets.  Subexpressions
#' # may also be surrounded by square brackets, but lex_xl() returns the whole
#' # expression in a single 'structured_ref' token.
#' lex_xl("[@col2]")
#' lex_xl("SUM([col22])")
#' lex_xl("Table1[col1]")
#' lex_xl("Table1[[col1]:[col2]]")
#' lex_xl("Table1[#Headers]")
#' lex_xl("Table1[[#Headers],[col1]]")
#' lex_xl("Table1[[#Headers],[col1]:[col2]]")
#'
#' # DDE calls (Dynamic Data Exchange) are normalized by Excel into indexes.
#' # Either way, lex_xl() includes everything in one token.
#' lex_xl("[1]!'DDE_parameter=1'")
#' lex_xl("'Quote'|'NYSE'!ZAXX")
#' # Meaningless spaces that appear in some old files are returned as 'space'
#' # tokens, so that the original formula can still be recovered by
#' # concatenating all the tokens.  Spaces between function names and their open
#' # parenthesis have not been observed, so are not permitted.
#' lex_xl(" MAX( A1 ) ")
lex_xl <- function(x) {
  if (length(x) != 1) {
    stop("'x' must be a character vector of length 1")
  }
  if (!is.character(x)) {
    stop("'x' must be a character vector of length 1")
  }
  lex_xl_(x)
}
