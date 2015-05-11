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
    atom.commands.add 'atom-workspace', 'yard:doc-context': => @docFromContext()

  create: ->
    @setEditorAndCursor()
    @documentFunction(@editor, @cursor)

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

  documentFunction: (editor, cursor) ->
    editor.transact =>
      prevDefRow = @findDefStartRow(editor, cursor)
      params = @parseMethodLine(editor.lineTextForBufferRow(prevDefRow))
      snippetString = @buildFunctionSnippetString(params)
      @insertSnippet(editor, cursor, prevDefRow, snippetString)

  docFromContext: ->
    @setEditorAndCursor()
    row = @cursor.getBufferRow()
    if @isFunctionDef(@editor, row)
      @documentFunction(@editor, @cursor)
    else if @isClassDef(@editor, row)
      @documentClass(@editor, @cursor)
    else if @isAttributeDef(@editor, row)
      @documentAttribute(@editor, @cursor)
    else
      # hunt for next matched function or class
      @documentFunction(@editor, @cursor)

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

  insertSnippet: (editor, cursor, prevDefRow, snippetString) ->
    cursor.setBufferPosition([prevDefRow,0])
    editor.moveToFirstCharacterOfLine()
    indentation = cursor.getIndentLevel()
    editor.insertNewlineAbove()
    editor.setIndentationForBufferRow(cursor.getBufferRow(), indentation)
    Snippets.insert(snippetString)

  buildFunctionSnippetString: (params) ->
    snippetString = "# ${1:Description of method}\n#\n"
    index = 2
    for param in params
      snippetString += "# @param [${#{index}:Type}] #{param} ${#{index + 1}:describe #{param}}\n"
      index += 2
    snippetString += "# @return [${#{index}:Type}] ${#{index + 1}:description of returned object}"
    snippetString

  parseMethodLine: (methodLine) ->
    opened_bracket = methodLine.indexOf("(")
    closed_bracket = methodLine.indexOf(")")
    return [] if opened_bracket == -1 and closed_bracket == -1
    params_string = methodLine.substring(opened_bracket + 1, closed_bracket)
    params_string.split(',').map((m) -> m.trim())

  buildAttrString: ->
    @returnSnippet()

  buildClassString: ->
    "##\n# ${1:Description of class}"

  returnSnippet: ->
    "# @return [Type] description of returned object"

  isFunctionDef: (editor, n) ->
    line = @readLine(editor, n)
    (line.indexOf(@methodPattern) > -1)

  isClassDef: (editor, n) ->
    line = @readLine(editor, n)
    (line.indexOf(@classPattern) > -1)

  isAttributeDef: (editor, n) ->
    line = @readLine(editor, n)
    (line.indexOf(@attrPattern) > -1)

  getEditor: ->
    # @editor = atom.workspace.getActivePaneItem()
    @editor = atom.workspace.getActiveEditor()
    return @editor

  getCursor: ->
    @getEditor() unless @editor
    @cursor = @editor.getLastCursor()

  setEditorAndCursor: ->
    @getEditor()
    @getCursor()

  readLine: (editor, n) ->
    editor = @getEditor() unless editor?
    return editor.getCursor()?.getCurrentBufferLine() unless n?
    editor.lineForBufferRow(n)
