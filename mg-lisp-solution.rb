require 'pry'

def tokenize(input)
  tokens = []
  loop do
    input = input.strip
    return tokens if input.empty?

    first_char = input[0]
    if first_char == '(' or first_char == ')'
      tok = first_char
    else
      tok = /[^\s)]+/.match(input)[0]
    end

    tokens << tok
    input = input[(tok.length)..-1]
  end
end

def to_expr(tokens)
  raise if tokens.empty?

  tok = tokens.shift
  if tok == '#t'
    return true
  elsif tok == '#f'
    return false
  elsif /\d+/.match tok
    return tok.to_i
  elsif tok == ')'
    return nil
  elsif tok != '('
    return tok
  else
    body = []
    loop do
      next_expr = to_expr(tokens)
      break if next_expr.nil?
      body << next_expr
    end

    return body
  end
end

class Env
  attr_reader :parent, :bindings
  def initialize(parent, bindings={})
    @parent = parent
    @bindings = bindings
  end

  def clone
    Env.new parent, bindings.clone
  end

  def lookup(id)
    if bindings.has_key? id
      bindings[id]
    elsif parent
      parent.lookup id
    else
      nil
    end
  end

  def set!(id, val)
    if bindings.has_key? id
      bindings[id] = val
    elsif parent
      parent.set id, val
    else
      bindings[id] = val
    end
  end

  def make_fn(args, body)
    Fn.new self, body, args
  end

  def eval_cond(cond, yes, no)
    eval(cond) ? eval(yes) : eval(no)
  end

  def eval(expr)
    if expr.is_a? Fixnum
      return expr
    elsif expr == true
      return true
    elsif expr == false
      return false
    elsif expr.is_a? String
      @bindings[expr]
    elsif expr.is_a? Fn
      return expr
    elsif expr == []
      return nil
    else
      if expr[0] == 'if'
        eval_cond(expr[1], expr[2], expr[3])
      elsif expr[0] == 'def'
        set! expr[1], eval(expr[2])
      elsif expr[0] == 'fn'
        make_fn expr[1], expr[2..-1]
      elsif expr[0] == 'defn'
        fn = make_fn expr[2], expr[3..-1]
        bindings[expr[1]] = fn
      else
        first = eval expr[0]
        rest = expr[1..-1].map { |expr| eval expr }
        first.call *rest
      end
    end
  end
end

class Fn
  attr_reader :env, :body, :arg_names

  def initialize(env, body, arg_names)
    @env = env
    @body = body
    @arg_names = arg_names
  end

  def call(*args)
    e = env.clone
    arg_names.each_with_index do |name, idx|
      val = args[idx]
      e.bindings[name] = val
    end
    body.map { |expr| e.eval expr }.last
  end
end

GLOBAL_ENV = Env.new nil
GLOBAL_ENV.bindings['+'] = Proc.new {|x, y| x + y}
GLOBAL_ENV.bindings['*'] = Proc.new {|x, y| x * y}


def go(input)
  tokens = tokenize input
  exprs = []
  loop do
    break if tokens.empty?
    exprs << to_expr(tokens)
  end

  exprs.map { |expr| GLOBAL_ENV.eval expr }.last
end

code = <<CODE

(define makeAddr (x)
  )

CODE

require 'pry'
binding.pry
