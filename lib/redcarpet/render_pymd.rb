require 'yaml'
require 'pp'

module Redcarpet
  module Render
    class PyMarkdown < Base

      def initialize
        @symbol_table = [ ]
        @span_stack = [ ]
        super
      end



      # ----------------------------------------------------
      # Methods where the first argument is the text content
      # ----------------------------------------------------
      [
        # block-level calls
        :block_code, :block_quote,
        :block_html, :header, :list,
        :list_item, :paragraph,
      ].each do |method|
        define_method method do |*args|
          block(method, *args)
        end
      end

      [
        # span-level calls
        :autolink, :codespan, :double_emphasis,
        :emphasis, :raw_html, :triple_emphasis,
        :strikethrough, :superscript,

        # low level rendering
        :entity
      ].each do |method|
        define_method method do |*args|
          span(method, *args)
        end
      end



      # -----------------------------------------------------------
      # Other methods where the text content is in another argument
      # -----------------------------------------------------------

      def link(link, title, content)
        span("link", content, link, title)
      end

      def normal_text(content)
        content
      end

      def function(name, args)
        custom_span(name, *args)
      end

      def yaml_frontmatter(yaml_string)
        yaml = YAML.load(yaml_string)
        pp yaml
      end

      # -------------------------
      # Building the symbol table
      # -------------------------

      def block(method_name, content, *args)
        children = [ ]
        while content.index("%(block)s")
          children.push @symbol_table.pop
          content.sub!("%(block)s", "%s")
        end

        # Given that we pop them in reverse order from the stack, we must un-reverse them
        children.reverse!

        @symbol_table.push({:method =>  method_name, :content => content, :args => args, :spans => @span_stack, :children => children })
        @span_stack = [ ]
        "%(block)s"
      end

      def span(method_name, content, *args)
        @span_stack.push({:method => method_name, :content => content, :args => args})
        "%s"
      end

      # Same as span, only for custom method invocations with the \function{foo} syntax
      def custom_span(method_name, *args)
        @span_stack.push({:method => method_name, :content => "", :args => args, :custom => true})
        "%s"
      end



      # --------------------------
      # Rendering the symbol table
      # --------------------------

      def build
        out = build_helper(@symbol_table, 0)

        "import PyMarkdown.test_renderer as renderer \n" +
        "import PyMarkdown.test_customs as custom \n" + # TODO: only temporary
        "print ''.join([ #{out} ])"
      end

      def build_helper(that, level)
        out = [ ]
        that.each do |x|
          if x[:custom]
            out.push build_custom_span(x, level + 1)
          elsif x[:children].nil?
            out.push build_span(x, level + 1)
          else
            out.push build_block(x, level + 1)
          end
        end

        out.join(", ")
      end

      def build_block(x, level)
        children = x[:children].length > 0 ? x[:children] : x[:spans]
        children = build_helper(children, level + 1)
        tabify(pythonize(x, children), level)
      end

      def build_span(x, level)
        tabify(pythonize(x), level)
      end

      def build_custom_span(x, level)
        tabify(custom_pythonize(x), level)
      end



      # --------------
      # Helper methods
      # --------------

      """
      Converts an item of the symbol_table (created by #block or #span) into a python
      method invocation.
      """
      def pythonize(x, children=nil)
        string_args = [x[:args].map { |x| "\"#{x}\"" } ].flatten.join(", ")
        out = "renderer.#{x[:method]}(\"\"\"#{x[:content]}\"\"\""
        out += " % (#{children})" if not children.nil?
        out += ", " + string_args if x[:args].length > 0
        "#{out})"
      end

      def custom_pythonize(x)
        string_args = [x[:args].map { |x| "\"\"\"#{x}\"\"\"" } ].flatten.join(", ")
        out = "custom.#{x[:method]}("
        out += string_args if x[:args].length > 0
        "#{out})"
      end

      def tabify(content, level)
        tabs = "\t" * level
        "\n#{tabs}#{content}"
      end

    end
  end
end
