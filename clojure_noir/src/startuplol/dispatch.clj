(ns startuplol.dispatch
  (:use clojure.test)
  (require [clojure.string :as string]))

(defmacro testrule
  "Tests a sequence of questions and expected answers."
  [& pairs]
  `(deftest testanswer#
     ~@(for [pair (partition 2 pairs)]
         (let [question (first pair)
               expected (fnext pair)]
           `(is (= ~expected (~'dispatcher ~question)))))))

(with-test
  (defn match [re func]
    (fn [q] (let [m (re-matches re q)] (if (not-empty m) (func m) nil))))
  (is (= "ohai foo" ((match #"my name is (.*)" #(str "ohai " (%1 1)))
                     "my name is foo")))
  (is (= "bar" ((match #"foo" (fn [m] "bar")) "foo")))
  (is (nil? ((match #"foo" (fn [m] "bar")) "bar"))))

(with-test
  (defn match-intlist [re func]
    (match re (fn [m] (func (map #(Integer/parseInt %1 10)
                                 (string/split (fnext m) #", *"))))))
  (is (= "6" ((match-intlist #"sum of (.*)" #(str (apply + %1)))
              "sum of 1, 2, 3"))))

(with-test
  (defn match-ints [re func]
    (match re (fn [m] (apply func (map #(Integer/parseInt %1 10) (rest m))))))
  (is (= "5" ((match-ints #"what is (\d+) plus (\d+)" #(str (apply + %&)))
              "what is 2 plus 3"))))

(with-test
  (defn match-strings [re func]
    (match re (fn [m] (apply func (rest m)))))
  (is (= "foobar" ((match-strings #"concatenate (\w+) and (\w+)" #(apply str %&))
                   "concatenate foo and bar"))))

(with-test
  (defmacro rule [re arg & body]
    `(match ~re (fn [~arg] ~@body)))
  (is (= "ohai foo" ((rule #"my name is (.*)" m (str "ohai " (m 1)))
                     "my name is foo")))
  (is (= "bar" ((rule #"foo" _ "bar") "foo")))
  (is (nil? ((rule #"foo" _ "bar") "bar"))))

(with-test
  (defmacro rule-strings [re args & body]
    `(match-strings ~re (fn ~args ~@body)))
  (is (= "foobar" ((rule-strings #"concatenate (\w+) and (\w+)" [a b] (str a b))
                   "concatenate foo and bar"))))

(with-test
  (defmacro rule-ints [re args & body]
    `(match-ints ~re (fn ~args ~@body)))
  (is (= "5" ((rule-ints #"what is (\d+) plus (\d+)" [a b] (str (+ a b)))
              "what is 2 plus 3"))))

(with-test
  (defmacro rule-intlist [re arg & body]
    `(match-intlist ~re (fn [~arg] ~@body)))
  (is (= "6" ((rule-intlist #"sum of (.*)" l (str (apply + l)))
              "sum of 1, 2, 3"))))

(defmacro dispatch [& rules]
  `(defn ~'dispatcher [~'q] (str (or ~@(for [rule rules] `(~rule ~'q))))))


