
# frozen_literal_string: true
module RandomGenerator
  LOWER_CHARS = ('a'..'z').to_a.freeze
  UPPER_CHARS = ('A'..'Z').to_a.freeze
  NUMBER_CHARS = ('0'..'9').to_a.freeze
  DEFAULT_CHARSET = (LOWER_CHARS + UPPER_CHARS + NUMBER_CHARS).freeze

  def self.string(length, options = {})
    charset = options[:charset] || DEFAULT_CHARSET
    (0...length).map{|_| charset.sample}.join
  end
end
