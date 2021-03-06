module Mongoid
  module Contexts
    module Ids
      include IdConversion

      # Return documents based on an id search. Will handle if a single id has
      # been passed or mulitple ids.
      #
      # Example:
      #
      #   context.id_criteria([1, 2, 3])
      #
      # Returns:
      #
      # The single or multiple documents.
      def id_criteria(params)
        criteria.id(strings_to_object_ids(params))
        params.is_a?(Array) ? criteria.entries : one
      end
    end
  end
end
