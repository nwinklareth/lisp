require './spec_helper'

def add_operator(lisp_object)
  lisp_object[:value][1..-1].inject(0) do |r_val, arg_lisp_object|
    r_val + eval_lisp_object(arg_lisp_object)
  end
end

def build_fn_args(fn_args, fn_arg_values)
  args = []
  fn_args.each_with_index do |arg_name, index|
    args << arg_name << fn_arg_values[index]
  end
  s_expression_object(args)
end

def call_function(lisp_object)
  fn = @fns[lisp_object[:value][0][:value]]
  let_context = @let_vars
  @let_vars = [{}]
  function_call = [
      let_lisp_object,
      build_fn_args(fn[:fn_args][:value], [lisp_object[:value][1]]),
      fn[:fn_body]
  ]
  r_val = eval_lisp_object(s_expression_object(function_call))
  @let_vars = let_context
  r_val
end

def def_operator(lisp_object)
  identifier = lisp_object[:value][1][:value]
  @vars[identifier] = eval_lisp_object(lisp_object[:value][2])
end

def defn_operator(lisp_object)
  defn_expression = lisp_object[:value]
  @fns[defn_expression[1][:value]] = {
    :fn_args => defn_expression[2],
    :fn_body => defn_expression[3]
  }
end

def eval_lisp_object(lisp_object)
  if lisp_object[:type]
    case lisp_object[:type]
      when :s_expr
        fn = lisp_object[:value][0]
        case fn[:type]
          when :operator
            if fn[:value] == :+
              return add_operator(lisp_object)
            else
              return multiply_operator(lisp_object)
            end
          when :def
            return def_operator(lisp_object)
          when :defn
            return defn_operator(lisp_object)
          when :function_call
            return call_function(lisp_object)
          when :if
            return if_operator(lisp_object)
          when :let
            return let_operator(lisp_object)
          else
            return nil
        end
      when :identifier
        @let_vars.each do |let_env|
          return let_env[lisp_object[:value]] if let_env.has_key?(lisp_object[:value])
        end
        return @vars[lisp_object[:value]]
      else
        return nil
    end
  end
  lisp_object[:value]
end

def if_operator(lisp_object)
  if_expression = lisp_object[:value]
  eval_lisp_object(if_expression[if_expression[1][:value] ? 2 : 3])
end

def let_lisp_object
  {:type => :let}
end

def let_operator(lisp_object)
  @let_vars.unshift({})
  var_args = lisp_object[:value][1][:value]
  while var_args != []
    identifier = var_args[0][:value]
    value = eval_lisp_object(var_args[1])
    @let_vars[0][identifier] = value
    var_args = var_args[2..-1]
  end
  r_val = eval_lisp_object(lisp_object[:value][2])
  @let_vars.shift
  r_val
end

def lisp_eval(expression)
  @let_vars = [{}]
  @vars = {}
  @fns = {}
  r_val = nil
  while expression != ''
    lisp_object, expression = read_lisp_object(expression)
    r_val = eval_lisp_object(lisp_object)
  end
  r_val
end

def multiply_operator(lisp_object)
  lisp_object[:value][1..-1].inject(1) do |r_val, arg_lisp_object|
    r_val * eval_lisp_object(arg_lisp_object)
  end
end

def read_lisp_object(lisp_object_expr)
  lisp_object, _, remainder = read_lisp_object1(lisp_object_expr)
  return lisp_object, remainder
end

def read_lisp_object1(lisp_object_expr)
  tokens = /\s*(\(|[^\s\(\)]+|\))(.*)/m.match(lisp_object_expr)
  first_token, remainder = tokens[1], tokens[2]
  lisp_object =
      case first_token
        when /^[\-\+]?\d+$/
          {:value => lisp_object_expr.to_i}
        when '+', '*'
          {:type => :operator, :value => first_token.to_sym}
        when '#t'
          {:value => true}
        when '#f'
          {:value => false}
        when '('
          args = []
          while first_token != ')'
            arg, first_token, remainder = read_lisp_object1(remainder)
            args << arg if first_token != ')'
          end
          first_token = nil
          s_expression_object(args)
        when ')'
          nil
        when 'let'
          let_lisp_object
        when 'def'
          {:type => :def}
        when 'defn'
          {:type => :defn}
        when 'if'
          {:type => :if}
        when /^\w+$/
          {:type => @fns.has_key?(first_token) ? :function_call : :identifier, :value => first_token}
        else
          {:type => :unknown, :value => first_token}
      end
  return lisp_object, first_token, remainder
end

def s_expression_object(args)
  {:type => :s_expr, :value => args}
end

describe '#lisp_eval' do
  describe 'CHALLENGE 1' do
    it 'lisp_evaluates numbers' do
      [0, 1, 77, -8].each do |expected|
        lisp_eval(expected.to_s).should == expected
      end
    end

    it 'lisp_evaluates booleans' do
      {'#t' => true, '#f' => false}.each do |expression, expected|
        lisp_eval(expression).should == expected
      end
    end
  end

  describe 'CHALLENGE 2' do
    it 'lisp_evaluates addition' do
      {'(+ 1 2)' => 3, '(+ 1 5)' => 6, '(+ 5 7 -8)' => 4}.each do |expression, expected|
        lisp_eval(expression).should == expected
      end
    end

    it 'lisp_evaluates multiplication' do
      lisp_eval('(* 2 2 3)').should == 12
    end
  end

  describe 'CHALLENGE 3'  do
    it 'lisp_evaluates nested arithmetic' do
      {
        '(+ 1 (* 2 3))' => 7,
        '(+ 5 7 -8 (* 2 (+ 5 (* 2 3) 1)))' => 28}.each do |expression, expected|
        lisp_eval(expression).should == expected
      end
    end
  end

  describe 'CHALLENGE 4'  do
    it 'lisp_evaluates conditionals' do
      lisp_eval('(if #t 1 2)').should == 1
      lisp_eval('(if #f #t #f)').should == false
    end
  end

  describe 'CHALLENGE 5' do
    it 'lisp_evaluates top-level defs' do
      lisp_eval('(def x 3)
                 (+ x 1)').should == 4
      lisp_eval('(def x 3)(def x 7)
                 (+ x 1)').should == 8
      lisp_eval('(def x 3)(def y 7)
                 (+ x y)').should == 10
    end
  end

  describe 'CHALLENGE 6'  do
    it 'lisp_evaluates simple `let` bindings' do
      lisp_eval('(let (x 3)
                   x)').should == 3
    end
  end

  describe 'CHALLENGE 7' do
    it 'lisp_evaluates let bindings with a more sophisticated body' do
      lisp_eval('(let (x 3)
                   (+ x 1))').should == 4
    end
  end

  describe 'CHALLENGE 8'  do
    it 'lisp_evaluates let bindings with multiple variables' do
      lisp_eval('(let (x 3
                       y 4)
                   (+ x y))').should == 7
    end
  end

  describe 'CHALLENGE 8b'  do
    it 'lisp_evaluates let bindings are no longer present after let expression is completed' do
      lisp_eval('(def x 8)
                 (let (x 3
                       y 4)
                   (def y (+ x y)))
                   (+ x y)').should == 15
    end
  end

  describe 'CHALLENGE 8c'  do
    it 'lisp_evaluates let bindings nest' do
      lisp_eval('(let (x 3
                       y 4)
                   (+ (let (x 8 y 5) (+ x y)) y))').should == 17
    end
  end

  describe 'CHALLENGE 8c'  do
    it 'lisp_evaluates let bindings nest and selects' do
      lisp_eval('(let (x 3
                       y 4)
                   (+ (let (x 8 y 5) (+ x y)) y))').should == 17
    end
  end

  describe 'CHALLENGE 8d'  do
    it 'lisp_evaluates let bindings nest and selects' do
      lisp_eval('(def x 6)
                 (let (y 4)
                   (let (z 9) (+ x y z)))').should == 19
    end
  end

  describe 'CHALLENGE 9'  do
    it 'lisp_evaluates function definitions with single variables' do
      code = '(defn add2 (x)
                (+ x 2))

              (add2 10)'

      lisp_eval(code).should == 12
    end
  end

  describe 'CHALLENGE 10', pending: true  do
    it 'lisp_evaluates function definitions with multiple variables' do
      code = '(defn maybeAdd2 (bool x)
                (if bool
                  (+ x 2)
                  x))

              (+ (maybeAdd2 #t 1) (maybeAdd2 #f 1))'

      lisp_eval(code).should == 4
    end
  end
end
