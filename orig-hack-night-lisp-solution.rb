
def lisp_eval(expression)
  @vars = {}
  fn, remainder = nil, expression
  while remainder != nil
    fn, remainder = lisp_eval1(remainder)
  end
  fn
end

def lisp_eval1(expression)
  # remember to use the m modifier so it does not stop at line-feeds & carriage-returns
  tokens = /\s*(\(|[^\s\)]+|\))(.+)?/m.match(expression)
  operator = tokens[1]
  remainder = tokens[2]
  return true, remainder if operator == "#t"
  return false, remainder if operator == "#f"
  if operator == "("
    args = []
    while operator != ')'
      operator, remainder = lisp_eval1(remainder)
      args << operator if operator != ')'
    end
    case args[0]
    when '+'
      return args[1..-1].inject(0) { |r, a| r + a }, remainder
    when '*'
      return args[1..-1].inject(1) { |r, a| r * a }, remainder
    when 'if'
      return args[args[1] ? 2 : 3], remainder
    when 'def'
      @vars[args[1]] = args[2]
      return nil, remainder
    else
        return 'unknown operator', args[0]
    end
  end
  return operator.to_i, remainder if operator =~ /\d+/
  return @vars[operator], remainder if @vars[operator]
  return operator, remainder
end
