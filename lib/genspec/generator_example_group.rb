module GenSpec
  module GeneratorExampleGroup
    include RSpec::Matchers
    include GenSpec::Matchers

    def self.included(base)
      base.send(:extend, GenSpec::GeneratorExampleGroup::ClassMethods)
      base.send(:subject) { self.class.generator_descriptor }
    end

    module ClassMethods
      # Sets the list of arguments for this generator.
      #
      # * All arguments will be converted to Strings, because that's how
      #   they'd enter the generator from a command line. To avoid this,
      #   pass :object => true at the end;
      #
      # Ex:
      #
      #   with_args '--orm', 'active_record' do
      #     it "should use activerecord" do
      #       # . . .
      #     end
      #   end
      #
      #   with_args '--size', 5, :object => true do
      #     # . . .
      #   end
      #
      def with_args(*args, &block)
        options = args.extract_options!
        args = args.flatten.collect { |c| c.to_s } unless options[:object]
        if block_given?
          context "with arguments #{args.inspect}" do
            with_args(args, options)
            instance_eval(&block)
          end
        else
          metadata[:generator_args] = args
        end
      end
      
      # Sets the input stream for this generator.
      #
      # Ex:
      #
      #   with_input <<-end_input do
      #     y
      #     n
      #     a
      #   end_input
      #     it "should overwrite, then skip, then overwrite all" do
      #       # . . .
      #     end
      #   end
      #
      def with_input(string, &block)
        if block_given?
          context "with input string #{string.inspect}" do
            with_input string
            instance_eval &block
          end
        else
          metadata[:generator_input] = string
        end
      end
      
      def generator_args
        return metadata[:generator_args] if metadata[:generator_args]
        
        metadata[:generator_args] = if genspec_subclass?
          superclass.generator_args
        else
          []
        end
      end
      
      def generator_input
        return metadata[:generator_input] if metadata[:generator_input]
        
        metadata[:generator_input] = if genspec_subclass?
          superclass.generator_input
        else
          nil
        end
      end
      
      alias with_arguments      with_args
      alias generator_arguments generator_args
      
      def generator_descriptor
        {
          :described => target_generator,
          :args => generator_args,
          :input => generator_input
        }
      end
      
      def target_generator
        if genspec_subclass?
          superclass.target_generator
        else
          describes || description
        end
      end

      def genspec_subclass?
        superclass.include?(GenSpec::GeneratorExampleGroup)
      end
    end
  end
end