require './spec_helper'

def eval_lisp_object(lisp_object)
  if lisp_object[:type]
    return lisp_object[:value][1..-1].inject(0) do |r_val, arg_lisp_object|
      r_val + eval_lisp_object(arg_lisp_object)
    end
  end
  lisp_object[:value]
end

def lisp_eval(expression)
  lisp_object = read_lisp_object(expression)
  eval_lisp_object(lisp_object)
end

def read_lisp_object(lisp_object_expr)
  lisp_object, _, _ = read_lisp_object1(lisp_object_expr)
  lisp_object
end

def read_lisp_object1(lisp_object_expr)
  tokens = /(\(|[^\s\(\)]+|\))(.*)/m.match(lisp_object_expr)
  first_token, remainder = tokens[1], tokens[2]
  return {:value => true}, first_token, remainder if first_token == '#t'
  return {:value => false}, first_token, remainder if first_token == '#f'
  if first_token == '('
    args = []
    while first_token != ')'
      arg, first_token, remainder = read_lisp_object1(remainder)
      args << arg if first_token != ')'
    end
    return {:type => :s_expr, :value => args}, first_token, remainder
  end
  return {:type => :operator, :value => :+}, first_token, remainder if first_token == '+'
  return {:value => lisp_object_expr.to_i}, first_token, remainder
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

    it 'lisp_evaluates multiplication', pending: true do
      lisp_eval('(* 2 2 3)').should == 12
    end
  end

  describe 'CHALLENGE 3', pending: true  do
    it 'lisp_evaluates nested arithmetic' do
      lisp_eval('(+ 1 (* 2 3))').should == 7
    end
  end

  describe 'CHALLENGE 4', pending: true  do
    it 'lisp_evaluates conditionals' do
      lisp_eval('(if #t 1 2)').should == 1
      lisp_eval('(if #f #t #f)').should == false
    end
  end

  describe 'CHALLENGE 5', pending: true  do
    it 'lisp_evaluates top-level defs' do
      lisp_eval('(def x 3)
                 (+ x 1)').should == 4
    end
  end

  describe 'CHALLENGE 6', pending: true  do
    it 'lisp_evaluates simple `let` bindings' do
      lisp_eval('(let (x 3)
                   x)').should == 3
    end
  end

  describe 'CHALLENGE 7', pending: true  do
    it 'lisp_evaluates let bindings with a more sophisticated body' do
      lisp_eval('(let (x 3)
                   (+ x 1))').should == 4
    end
  end

  describe 'CHALLENGE 8', pending: true  do
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
