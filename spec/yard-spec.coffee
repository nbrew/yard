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
    describe "for single line method", ->
      beforeEach ->
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

      it "writes a default YARD doc", ->
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

    describe "for multiline method", ->
      beforeEach ->
        waitsForPromise ->
          activationPromise

        editor.insertText """
          class UndocumentedClass
            def undocumented_multiline_method(param1, param2 = 3, opts = {})
              'Not documented!'
              'Noot documented!'
              'Noooot documented!!!'
            end
          end

        """
        editor.getLastCursor().setBufferPosition([4,0])
        atom.commands.dispatch workspaceElement, 'yard:create'

      it "writes a default YARD doc", ->
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

  describe "when the yard:doc-class event is triggered", ->
    describe "for a class declaration with no attributes", ->
      beforeEach ->
        waitsForPromise ->
          activationPromise

        editor.insertText """
          class UndocumentedClass; end
        """
        editor.getLastCursor().setBufferPosition([2,0])
        atom.commands.dispatch workspaceElement, 'yard:doc-class'

      it "writes just class description", ->
        expected_output = """
          ##
          # Description of class
          class UndocumentedClass; end
          """
        output = buffer.getText()
        expect(output).toContain(expected_output)

    describe "for a multi-line class with no attributes", ->
      beforeEach ->
        waitsForPromise ->
          activationPromise

        editor.insertText """
          class UndocumentedClass
            def stuff
            end

            def things
            end
          end
          """
        editor.getLastCursor().setBufferPosition([2,0])
        atom.commands.dispatch workspaceElement, 'yard:doc-class'

      it "writes just class description", ->
        expected_output = """##
          # Description of class
          class UndocumentedClass
            def stuff
            end

            def things
            end
          end
          """
        output = buffer.getText()
        expect(output).toContain(expected_output)


  describe "when the yard:doc-attr event is triggered", ->
    describe "for single attribute per line", ->
      beforeEach ->
        waitsForPromise ->
          activationPromise

        editor.insertText """class UndocumentedClass
                               attr_reader :count
                             end
                             """
        editor.getLastCursor().setBufferPosition([1,0])
        atom.commands.dispatch workspaceElement, 'yard:doc-attr'
      it "writes @return tag for attribute", ->
        expected_output = """
          class UndocumentedClass
            # @return [Type] description of returned object
            attr_reader :count
          end
          """
        output = buffer.getText()
        expect(output).toContain(expected_output)

    describe "for a class with writeable attribute", ->
      beforeEach ->
        waitsForPromise ->
          activationPromise
        editor.insertText """class UndocumentedClass
                               attr_writer :name
                             end
                             """
        editor.getLastCursor().setBufferPosition([1,0])
        atom.commands.dispatch workspaceElement, 'yard:doc-attr'


      it "writes attribute doc string", ->
        expected_output = """class UndocumentedClass
                               # @return [Type] description of returned object
                               attr_writer :name
                             end
                             """
        output = buffer.getText()
        expect(output).toContain(expected_output)


    describe "with attr accessor", ->
      beforeEach ->
        waitsForPromise ->
          activationPromise
        editor.insertText """class UndocumentedClass
                               attr_accessor :name
                             end
                             """
        editor.getLastCursor().setBufferPosition([1,0])
        atom.commands.dispatch workspaceElement, 'yard:doc-attr'

      it "writes accessor attribute doc string", ->
        expected_output = """class UndocumentedClass
                               # @return [Type] description of returned object
                               attr_accessor :name
                             end
                             """
        output = buffer.getText()
        expect(output).toContain(expected_output)

  describe "when the yard:doc-context is triggered", ->
    beforeEach ->
      waitsForPromise ->
        activationPromise
      editor.insertText """class UndocumentedClass

                              def stuff
                              end
                            end
                            """
      editor.getLastCursor().setBufferPosition([1,0])
      # this should use the atom-text-editor context, not the workspace
      # FIXME When cursor is on the empty line below a class definition documentClass is not called
      atom.commands.dispatch workspaceElement, 'yard:doc-context'

    it "writes the class doc string", ->
      expected_output = """##
        # Description of class
        class UndocumentedClass

          def stuff
          end
        end
        """
      output = buffer.getText()
      expect(output).toContain(expected_output)
