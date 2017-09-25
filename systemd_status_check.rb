#! /usr/bin/env ruby

# Diff::LCS is used by rspec, it is already present in the YaST Docker image
require "diff/lcs"
# Rainbow is used by Rubocop, it is already present in the YaST Docker image
require "rainbow"

require "yaml"
require "English"

# run systemctl and get the help about the defined states
# @return [String]
def systemd_help
  help = `systemctl --state=help`
  raise "Cannot read systemd states help" unless $CHILD_STATUS.success?
  help
end

# parses the systemd status help text
# @param help [String] the input help text
# @return [Hash<String,Array<String>>]
def parse_status_help(help)
  states = {}

  # split the status groups
  help.split("\n\n").each do |group|
    lines = group.split("\n")
    header = lines.shift

    raise "Cannot parse header: #{header}" unless header =~ /Available (.*):/
    states[Regexp.last_match[1]] = lines.sort
  end

  states
end

# read the expected states from the file
# @param file [String] file name (YAML)
# @return [Hash<String,Array<String>>] the loaded content
def read_expected_states(file)
  YAML.load_file(file)
end

# print the LCS::Diff changes
# @param diff [Diff::LCS::ContextChange] a diff change from LCS
def print_lsc_diff(diff)
  case diff.action
  when "-"
    puts Rainbow("- #{diff.old_element}").red
  when "+"
    puts Rainbow("+ #{diff.new_element}").yellow
  when "!"
    puts Rainbow("- #{diff.old_element}").red
    puts Rainbow("+ #{diff.new_element}").yellow
  else
    puts "  #{diff.old_element}"
  end
end

# print the difference
# @param name [String] systemd the group name (description)
# @param expected_states [Array<String>] the expected states
# @param current_states [Array<String>] the current states
def print_diff(name, expected_states, current_states)
  diffs = Diff::LCS.sdiff(expected_states, current_states)
  puts Rainbow("Found difference in the #{name.inspect} group:").red
  diffs.each { |d| print_lsc_diff(d) }
  puts
end

# compare the current and the expected states
# prints a diff if a difference is found
# @return [Boolean] true if the states are equal
def compare_states(expected, current)
  compared_groups = expected.map do |name, states|

    # sort the states to accept different order
    known_states = states.sort
    current_states = (current[name] || []).sort

    if known_states == current_states
      puts Rainbow("Found expected states in the #{name.inspect} group:").green
      puts known_states.map { |s| "  #{s}" }.join("\n")
      puts
    else
      print_diff(name, known_states, current_states)
    end

    known_states == current_states
  end

  compared_groups.all?
end

# get the current states
current = parse_status_help(systemd_help)
# read the expected states
expected = read_expected_states("expected_states.yml")

# compare them
equal = compare_states(expected, current)

if equal
  puts Rainbow("Check OK, no difference found").green
else
  puts Rainbow("Check failed!").red
  exit 1
end
