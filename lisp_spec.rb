require './spec_helper'

def eval_lisp_object(lisp_object)
  return 3 if lisp_object[:type]
  lisp_object[:value]
end

def lisp_eval(expression)
  lisp_object = read_lisp_object(expression)
  eval_lisp_object(lisp_object)
end

def read_lisp_object(lisp_object_expr)
  return {:value => true} if lisp_object_expr == '#t'
  return {:value => false} if lisp_object_expr == '#f'
  return {:type => :s_expr} if lisp_object_expr[0] == '('
  {:value => lisp_object_expr.to_i}
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
      lisp_eval('(+ 1 2)').should == 3
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
