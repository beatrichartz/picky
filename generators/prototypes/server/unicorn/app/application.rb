# encoding: utf-8
#
# TODO Adapt the generated example
#      (a library books finder) to what you need.
#
# Check the Wiki http://github.com/floere/picky/wiki for more options.
# Ask me or the google group if you have questions or specific requests.
#
class PickySearch < Application

  # Indexing: How text is indexed.
  #
  default_indexing removes_characters: /[^a-zA-Z0-9\s\/\-\"\&\.]/,
                   stopwords:          /\b(and|the|of|it|in|for)\b/,
                   splits_text_on:     /[\s\/\-\"\&\.]/

  # Querying: How query text is handled.
  #
  default_querying removes_characters: /[^a-zA-Z0-9\s\/\-\,\&\"\~\*\:]/, # Picky needs control chars *"~: to pass through.
                   stopwords:          /\b(and|the|of|it|in|for)\b/,
                   splits_text_on:     /[\s\/\-\,\&]+/,
                   maximum_tokens: 5, # Amount of tokens used in a search (5 = default).
                   substitutes_characters_with: CharacterSubstituters::WestEuropean.new # Normalizes special user input, Ä -> Ae, ñ -> n etc.

  # Define an index, Index::Memory or Index::Redis.
  # See http://github.com/floere/picky/wiki/Sources-Configuration#sources
  #
  library_src = Sources::CSV.new :title, :author, :year, file: 'app/library.csv'
  books_index = Index::Memory.new :books, library_src do
    category :title,
             similarity: Similarity::Phonetic.new(3), # Up to three similar title word indexed (default: No similarity).
             partial: Partial::Substring.new(from: 1) # Indexes substrings upwards from character 1 (default: -3),
                                                      # You'll find "picky" even when entering just a "p".
    category :author, partial: Partial::Substring.new(from: 1)
    category :year, partial: Partial::None.new
  end

  route %r{\A/books\Z} => Search.new(books_index, :weights => { [:title, :author] => +3, [:title] => +1 })

  # Note: You can pass a query multiple indexes and it will query in all of them.

end