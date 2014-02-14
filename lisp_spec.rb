require './spec_helper'

def add_operator(lisp_object)
  lisp_object[:value][1..-1].inject(0) do |r_val, arg_lisp_object|
    r_val + eval_lisp_object(arg_lisp_object)
  end
end

def def_operator(lisp_object)
  identifier = lisp_object[:value][1][:value]
  value = eval_lisp_object(lisp_object[:value][2])
  @vars[identifier] = value
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
          when :let
            return let_operator(lisp_object)
          else
            return nil
        end
      when :identifier
        return @vars[lisp_object[:value]]
      else
        return nil
    end
  end
  lisp_object[:value]
end

def let_operator(lisp_object)
  var_args = lisp_object[:value][1][:value]
  while var_args != []
    identifier = var_args[0][:value]
    value = eval_lisp_object(var_args[1])
    @vars[identifier] = value
    var_args = var_args[2..-1]
  end
  eval_lisp_object(lisp_object[:value][2])
end

def multiply_operator(lisp_object)
  lisp_object[:value][1..-1].inject(1) do |r_val, arg_lisp_object|
    r_val * eval_lisp_object(arg_lisp_object)
  end
end

def lisp_eval(expression)
  @vars = {}
  r_val = nil
  while expression != ''
    lisp_object, expression = read_lisp_object(expression)
    r_val = eval_lisp_object(lisp_object)
  end
  r_val
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
        when /[-+]?\d/
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
          {:type => :s_expr, :value => args}
        when ')'
          nil
        when 'let'
          {:type => :let}
        when 'def'
          {:type => :def}
        when /\w/
          {:type => :identifier, :value => first_token}
        else
          {:type => :unknown, :value => first_token}
      end
  return lisp_object, first_token, remainder
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

  describe 'CHALLENGE 4', pending: true  do
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

  describe 'CHALLENGE 9', pending: true  do
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
