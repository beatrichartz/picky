module Picky

  class Bundle
    
    # TODO Push methods back into the backend, so that we
    #      can apply more efficient methods tailored for
    #      each specific backends.
    #
    
    # Removes the given id from the indexes.
    #
    def remove id
      # Is it anywhere?
      #
      str_or_syms = @realtime[id]

      return if str_or_syms.blank?

      str_or_syms.each do |str_or_sym|
        ids = @inverted[str_or_sym]
        ids.delete id

        if ids.empty?
          @inverted.delete str_or_sym
          @weights.delete  str_or_sym

          # Since no element uses this sym anymore, we can delete the similarity for it.
          #
          # TODO Not really. Since multiple syms can point to the same encoded.
          # In essence, we don't know if and when we can remove it.
          # (One idea is to add an array of ids and remove from that)
          #
          @similarity.delete self.similarity_strategy.encode(str_or_sym)
        else
          @weights[str_or_sym] = self.weight_strategy.weight_for ids.size
          # @weights[str_or_sym] = self.weight_strategy.respond_to?(:[]) &&
          #                        self.weight_strategy[str_or_sym] ||
          #                        self.weight_strategy.weight_for(ids.size)
        end
      end

      @realtime.delete id
    end

    # Returns a reference to the array where the id has been added.
    #
    # Does not add to realtime if static.
    #
    def add id, str_or_sym, where = :unshift, static = false
      
      # If static, indexing will be slower, but will use less
      # space in the end.
      #
      if static
        ids = @inverted[str_or_sym] ||= []
        ids.send where, id unless ids.include? id
      else
        # Use a generalized strategy.
        #
        str_or_syms = (@realtime[id] ||= []) # (static ? nil : []))

        # Inverted.
        #
        ids = if str_or_syms && str_or_syms.include?(str_or_sym)
          ids = @inverted[str_or_sym] ||= []
          ids.delete id
          ids.send where, id
        else
          # Update the realtime index.
          #
          str_or_syms << str_or_sym # unless static
          ids = @inverted[str_or_sym] ||= []
          ids.send where, id
        end
      end
        
      # Weights.
      #
      @weights[str_or_sym] = self.weight_strategy.weight_for ids.size

      # Similarity.
      #
      add_similarity str_or_sym, where

      # Return reference.
      #
      ids
    end

    # Add string/symbol to similarity index.
    #
    def add_similarity str_or_sym, where = :unshift
      if encoded = self.similarity_strategy.encode(str_or_sym)
        similars = @similarity[encoded] ||= []

        # Not completely correct, as others will also be affected, but meh.
        #
        similars.delete str_or_sym if similars.include? str_or_sym
        similars << str_or_sym

        self.similarity_strategy.prioritize similars, str_or_sym
      end
    end

    # Partializes the text and then adds each.
    #
    def add_partialized id, text, where = :unshift, static = false
      partialized text do |partial_text|
        add id, partial_text, where, static
      end
    end
    def partialized text, &block
      self.partial_strategy.each_partial text, &block
    end

    # Builds the realtime mapping.
    #
    # Note: Experimental feature. Might be removed in 5.0.
    #
    # THINK Maybe load it and just replace the arrays with the corresponding ones.
    #
    def build_realtime
      clear_realtime
      @inverted.each_pair do |str_or_sym, ids|
        ids.each do |id|
          str_or_syms = @realtime[id] ||= []
          @realtime[id] << str_or_sym unless str_or_syms.include? str_or_sym
        end
      end
    end

  end

end
