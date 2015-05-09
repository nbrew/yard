{CompositeDisposable} = require 'atom'
Snippets = require atom.packages.resolvePackagePath('snippets') + '/lib/snippets.js'

module.exports = Yard =

  methodPattern: 'def '
  classPattern: 'class '
  attrPattern: 'attr_'

  editor: null
  cursor: null

  activate: (state) ->
    atom.commands.add 'atom-workspace', 'yard:create': => @create()
    atom.commands.add 'atom-workspace', 'yard:doc-class': => @docClass()
    atom.commands.add 'atom-workspace', 'yard:doc-attr': => @docAttr()
    atom.commands.add 'atom-text-editor', 'yard:doc-context': => @docFromContext()

  create: ->
    @setEditorAndCursor()
    @documentMethod(@editor, @cursor)

  docClass: ->
    @setEditorAndCursor()
    @documentClass(@editor, @cursor)

  docAttr: ->
    @setEditorAndCursor()
    @documentAttribute(@editor, @cursor)

  documentAttribute: (editor, cursor) ->
    editor.transact =>
      attrRow = @findAttrRow(editor, cursor)
      snippetString = @buildAttrString()
      @insertSnippet(editor, cursor, attrRow, snippetString)

  documentClass: (editor, cursor) ->
    editor.transact =>
      prevClassRow = @findClassRow(editor, cursor)
      snippetString = @buildClassString()
      @insertSnippet(editor, cursor, prevClassRow, snippetString)

  documentMethod: (editor, cursor) ->
    editor.transact =>
      prevDefRow = @findDefStartRow(editor, cursor)
      params = @parseMethodLine(editor.lineTextForBufferRow(prevDefRow))
      snippet_string = @buildSnippetString(params)
      @insertSnippet(editor, cursor, prevDefRow, snippet_string)

  docFromContext: ->
    @setEditorAndCursor()
    row = @cursor.getBufferRow()
    line = @editor.buffer.lines[row]
    if (line.indexOf(@methodPattern) > -1)
      @documentMethod(@editor, @cursor)
    else if (line.indexOf(@classPattern) > -1)
      @documentClass(@editor, @cursor)
    else if (line.indexOf(@attrPattern) > -1)
      @documentAttribute(@editor, @cursor)
    else
      @documentMethod(@editor, @cursor)


  findDefStartRow: (editor, cursor) ->
    @findPatternInRow(@methodPattern, editor, cursor)

  findClassRow: (editor, cursor) ->
    @findPatternInRow(@classPattern, editor, cursor)

  findAttrRow: (editor, cursor) ->
    @findPatternInRow(@attrPattern, editor, cursor)

  findPatternInRow: (pattern, editor, cursor) ->
    row = cursor.getBufferRow()
    while (editor.buffer.lines[row].indexOf(pattern) == -1)
      break if row == 0
      row -= 1
    row

  insertSnippet: (editor, cursor, prevDefRow, snippet_string) ->
    cursor.setBufferPosition([prevDefRow,0])
    editor.moveToFirstCharacterOfLine()
    indentation = cursor.getIndentLevel()
    editor.insertNewlineAbove()
    editor.setIndentationForBufferRow(cursor.getBufferRow(), indentation)
    Snippets.insert(snippet_string)

  buildSnippetString: (params) ->
    snippet_string = "# ${1:Description of method}\n#\n"
    index = 2
    for param in params
      snippet_string += "# @param [${#{index}:Type}] #{param} ${#{index + 1}:describe #{param}}\n"
      index += 2
    snippet_string += "# @return [${#{index}:Type}] ${#{index + 1}:description of returned object}"
    snippet_string

  parseMethodLine: (methodLine) ->
    opened_bracket = methodLine.indexOf("(")
    closed_bracket = methodLine.indexOf(")")
    return [] if opened_bracket == -1 and closed_bracket == -1
    params_string = methodLine.substring(opened_bracket + 1, closed_bracket)
    params_string.split(',').map((m) -> m.trim())

  buildAttrString: ->
    snippet_string = @returnSnippet()
    snippet_string

  buildClassString: ->
    snippet_string = "##\n# ${1:Description of class}"
    snippet_string

  parseAttributes: (editor, cursor) ->
    row = cursor.getBufferRow()
    attribute_lines = []
    while (editor.buffer.lines[row].indexOf('attr_') == -1)
      break if row == 0
      row
    return []

  returnSnippet: ->
    "# @return [Type] description of returned object"

  setEditorAndCursor: ->
    @editor = atom.workspace.getActivePaneItem()
    @cursor = @editor.getLastCursor()
