Yard = require '../lib/yard'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Yard", ->
  [workspaceElement, activationPromise, editor, buffer] = []

  beforeEach ->
    workspaceElement  = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('yard')
    waitsForPromise ->
      # Open a sample Ruby class file
      atom.workspace.open().then (o) ->
        editor = o
        buffer = editor.buffer

  xdescribe "when the yard:create event is triggered", ->

    it "writes a default YARD doc with multi-line class", ->
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

    it "writes a default YARD doc with single line method", ->

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

  describe "for a class declaration with no attributes", ->
    it "writes just class description", ->
      # waitsForPromise ->
      #   atom.workspace.open().then (o) ->
      #     editor = o
      #     buffer = editor.buffer

      editor.insertText """
        class UndocumentedClass; end
        """
      editor.getLastCursor().setBufferPosition([2,0])
      atom.commands.dispatch workspaceElement, 'yard:doc-class'

      expected_output = """
        ##
        # Description of class
        class UndocumentedClass; end
        """
      output = buffer.getText()
      expect(output).toContain(expected_output)

    it "multi-line class with no attributes writes just class description", ->
      editor.insertText """
        class UndocumentedClass
          def stuff
          end

          def things
          end
        end
        """
      expected_output = """##
        # Description of class
        class UndocumentedClass
          def stuff
          end

          def things
          end
        end
        """
      editor.getLastCursor().setBufferPosition([2,0])
      atom.commands.dispatch workspaceElement, 'yard:doc-class'
      output = buffer.getText()
      expect(output).toContain(expected_output)


  describe "Attribute Docs", ->
    it "writes @return tag and class description", ->
      editor.insertText """class UndocumentedClass
                             attr_reader :count
                           end
                           """
      expected_output = """
        class UndocumentedClass
          # @return [Type] count
          attr_reader :count
        end
        """
      editor.getLastCursor().setBufferPosition([1,0])
      atom.commands.dispatch workspaceElement, 'yard:doc-attr'
      output = buffer.getText()
      expect(output).toContain(expected_output)


  xdescribe "multi-line class with writeable attribute", ->
    it "writes class and attribute doc string", ->
      editor.insertText """class UndocumentedClass
                             attr_writer :name
                           end
                           """
      expected_output = """# Description of class
                           class UndocumentedClass
                             # @!attribute [w] name
                             #   @return [Type] description of returned object
                             attr_reader :name
                           end
                           """
      output = buffer.getText()
      expect(output).toContain(expected_output)

  xdescribe "with attr accessor", ->
    it "writes accessor attribute and class doc string", ->
      editor.insertText """class UndocumentedClass
                             attr_accessor :name
                           end
                           """
      expected_output = """# Description of class
                           class UndocumentedClass
                             # @!attribute name
                             #   @return [Type] description of returned object
                             attr_reader :name
                           end
                           """
      output = buffer.getText()
      expect(output).toContain(expected_output)
