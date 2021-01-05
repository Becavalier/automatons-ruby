class Stack < Struct.new(:contents)
  def push(character)
    Stack.new([character] + contents)
  end
  def pop
    Stack.new(contents.drop(1))
  end
  def top
    contents.first
  end
  def inspect
    "#<Stack (#{top})#{contents.drop(1).join}>"
  end
end

class PDAConfiguration < Struct.new(:state, :stack)
  # STUCK_STATE = Object.new
  # def stuck
  #   PDAConfiguration.new(STUCK_STATE, stack)
  # end
  # def stuck?
  #   state == STUCK_STATE
  # end
end

class PDARule < Struct.new(:state, :character, :next_state, :pop_character, :push_character)
  def applies_to?(configuration, character)
    self.state == configuration.state &&
      self.pop_character == configuration.stack.top &&
      self.character == character
  end
  def follow(configuration)
    PDAConfiguration.new(next_state, next_stack(configuration))
  end
  def next_stack(configuration)
    popped_stack = configuration.stack.pop
    push_character.reverse.inject(popped_stack) {
      |stack, character| stack.push(character) 
    }
  end
end

class DPDARulebook < Struct.new(:rules)
  def next_configuration(configuration, character)
    rule_for(configuration, character).follow(configuration)
  end
  def rule_for(configuration, character)
    rules.detect {
      |rule| rule.applies_to?(configuration, character)
    }
  end
  def applies_to?(configuration, character)
    !rule_for(configuration, character).nil?
  end
  # support "free move".
  def follow_free_move(configuration)
    if applies_to?(configuration, nil)
      follow_free_move(next_configuration(configuration, nil))
    else
      configuration
    end
  end
end

class DPDA < Struct.new(:current_configuration, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_configuration.state)
  end
  def read_character(character)
    self.current_configuration = rulebook.next_configuration(current_configuration, character)
  end
  def read_string(string)
    string.chars.each do
      |character| read_character(character)
    end
  end
  def current_configuration
    rulebook.follow_free_move(super)  # input -> current_configuration.
  end
end

class DPDADesign < Struct.new(:start_state, :bottom_character, :accept_states, :rulebook)
  def accepts?(string)
    to_dpda.tap { |dpda| dpda.read_string(string) }.accepting?
  end
  def to_dpda
    start_stack = Stack.new([bottom_character])
    start_configuration = PDAConfiguration.new(start_state, start_stack)
    DPDA.new(start_configuration, accept_states, rulebook)
  end 
end

rulebook = DPDARulebook.new([
  # :state, :char, :next_state, :pop_char, :push_char.
  PDARule.new(1, '(', 2, '$', ['b', '$']),
  PDARule.new(2, '(', 2, 'b', ['b', 'b']),
  PDARule.new(2, ')', 2, 'b', []),
  PDARule.new(2, nil, 1, '$', ['$'])
])

dpda_design = DPDADesign.new(1, '$', [1], rulebook)
# puts dpda_design.accepts?('(((((((((())))))))))')
