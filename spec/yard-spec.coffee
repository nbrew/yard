Yard = require '../lib/yard'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Yard", ->
  [workspaceElement, activationPromise, editor, buffer] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('yard')
    # Open a sample Ruby class file
    waitsForPromise ->
      atom.workspace.open().then (o) ->
        editor = o
        buffer = editor.buffer

  describe "when the yard:create event is triggered", ->
    it "writes a default multiline YARD doc", ->
      waitsForPromise ->
        activationPromise

      editor.insertText """class UndocumentedClass
          def undocumented_multiline_method(param1, param2 = 3, opts = {})
            'Not documented!'
            'Noot documented!'
            'Noooot documented!!!'
          end
        end
      """
      editor.getLastCursor().setBufferPosition([2,0])
      atom.commands.dispatch workspaceElement, 'yard:create'

      expected_output = """class UndocumentedClass
                             # Description of method
                             #
                             # @param [Type] param1 describe param1
                             # @param [Type] param2 = 3 describe param2 = 3
                             # @param [Type] opts = {} describe opts = {}
                             # @return [Type] description of returned object
                             def undocumented_multiline_method(param1, param2 = 3, opts = {})
                               'Not documented!'
                               'Noot documented!'
                               'Noooot documented!!!'
                             end
                           end
                           """
      output = buffer.getText()
      expect(output).toContain(expected_output)

    it "with single line method writes a default YARD doc", ->
      waitsForPromise ->
        activationPromise

      editor.insertText """
        class UndocumentedClass
          def undocumented_method(param1, param2=3)
            'The method is not documented!'
          end
        end

      """
      editor.getLastCursor().setBufferPosition([2,0])
      atom.commands.dispatch workspaceElement, 'yard:create'

      expected_output = """class UndocumentedClass
                             # Description of method
                             #
                             # @param [Type] param1 describe param1
                             # @param [Type] param2=3 describe param2=3
                             # @return [Type] description of returned object
                             def undocumented_method(param1, param2=3)
                               'The method is not documented!'
                             end
                           end
                           """
      output = buffer.getText()
      expect(output).toContain(expected_output)
