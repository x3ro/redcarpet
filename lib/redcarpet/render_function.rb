module Redcarpet
  module Render
    class Test < HTML

      def function_call(name, parameters)
        "Neat! Called function '#{name}' with parameters '#{parameters}'"
      end

    end
  end
end
