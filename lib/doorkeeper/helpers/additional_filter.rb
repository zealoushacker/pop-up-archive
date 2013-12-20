module Doorkeeper
  module Helpers
    module AdditionalFilter

      module ClassMethods
        def doorkeeper_try(*args)
          doorkeeper_for = DoorkeeperForBuilder.create_doorkeeper_for(*args)

          before_filter doorkeeper_for.filter_options do
            doorkeeper_for.validate_token(doorkeeper_token)
            return true
          end
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

    end
  end
end
