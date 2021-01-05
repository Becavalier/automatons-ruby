require 'set'
require './dfa.rb'

class NFARulebook < Struct.new(:rules)
  def next_states(states, character)
    # discard repeated states (Set).
    states.flat_map { |state| follow_rules_for(state, character) }.to_set
  end
  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end
  def rules_for(state, character)
    # find all the applicable rules, otherwise return nil.
    rules.select { |rule| rule.applies_to?(state, character) }
  end
  def follow_free_moves(states)
    # find free move paths recursively.
    more_states = next_states(states, nil)
    if more_states.subset?(states)  # if no new state found.
      states
    else
      follow_free_moves(states + more_states)
    end
  end
  def alphabet
    rules.map(&:character).compact.uniq
  end
end

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def accepting?
    # check the intersection.
    (current_states & accept_states).any?
  end
  def read_character(character)
    self.current_states = rulebook.next_states(current_states, character)
  end
  def read_string(string)
    string.chars.each do
      |character| read_character(character)
    end
  end
  def current_states  # override the original attributes.
    rulebook.follow_free_moves(super)
  end
end

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def accepts?(string)
    to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end
  def to_nfa(current_states = Set[start_state])
    NFA.new(current_states, accept_states, rulebook)
  end
end

class NFASimulation < Struct.new(:nfa_design)
  def next_state(state, character)
    nfa_design.to_nfa(state).tap {
      |nfa| nfa.read_character(character)
  }.current_states
  end
  def rules_for(state)
    nfa_design.rulebook.alphabet.map {
      |character| FARule.new(state, character, next_state(state, character))
    }
  end
  def discover_states_and_rules(states)
    rules = states.flat_map { |state| rules_for(state) }
    more_states = rules.map(&:follow).to_set
    if more_states.subset?(states)
      [states, rules]
    else
      discover_states_and_rules(states + more_states)
    end
  end
  def to_dfa_design
    start_state = nfa_design.to_nfa.current_states
    states, rules = discover_states_and_rules(Set[start_state])
    accept_states = states.select { |state| nfa_design.to_nfa(state).accepting? }
    DFADesign.new(start_state, accept_states, DFARulebook.new(rules))
  end
end

# rulebook = NFARulebook.new([
#   FARule.new(1, nil, 2), 
#   FARule.new(1, nil, 4), 
#   FARule.new(2, 'a', 3),
#   FARule.new(3, 'a', 2),
#   FARule.new(4, 'a', 5),
#   FARule.new(5, 'a', 6),
#   FARule.new(6, 'a', 4)
# ])
# nfa_design = NFADesign.new(1, [2, 4], rulebook)
# puts nfa_design.accepts?('aaaaaa')  # true.

rulebook = NFARulebook.new([
  FARule.new(1, 'a', 1), 
  FARule.new(1, 'a', 2), 
  FARule.new(1, nil, 2), 
  FARule.new(2, 'b', 3),
  FARule.new(3, 'b', 1), 
  FARule.new(3, nil, 2)
])

nfa_design = NFADesign.new(1, [3], rulebook)
nfa = nfa_design.to_nfa
nfa.read_character('a')

#<Set: {1, 2}>
puts nfa.current_states

simulation = NFASimulation.new(nfa_design)
dfa_design = simulation.to_dfa_design
dfa = dfa_design.to_dfa
dfa.read_character('a')

#<Set: {1, 2}>
puts dfa.current_state

#<struct FARule state=#<Set: {1, 2}>, character="a", next_state=#<Set: {1, 2}>>
#<struct FARule state=#<Set: {1, 2}>, character="b", next_state=#<Set: {3, 2}>>
#<struct FARule state=#<Set: {3, 2}>, character="a", next_state=#<Set: {}>>
#<struct FARule state=#<Set: {3, 2}>, character="b", next_state=#<Set: {1, 3, 2}>>
#<struct FARule state=#<Set: {}>, character="a", next_state=#<Set: {}>>
#<struct FARule state=#<Set: {}>, character="b", next_state=#<Set: {}>>
#<struct FARule state=#<Set: {1, 3, 2}>, character="a", next_state=#<Set: {1, 2}>>
#<struct FARule state=#<Set: {1, 3, 2}>, character="b", next_state=#<Set: {1, 3, 2}>>
# puts dfa_design.rulebook.rules
