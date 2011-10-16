(ns startuplol.rules
  (:use startuplol.dispatch))

(dispatch
 (rule #"what is your favourite colour" _ "blue")
 (rule-ints #"what is (\d+) plus (\d+)" [a b] (+ a b))
 (rule-intlist #"which of these numbers is the largest: (.*)" ns (apply max ns))
 (rule #".*" _ "I have no idea"))

(testrule "what is your favourite colour" "blue"
          "what is 2 plus 3" "5"
          "which of these numbers is the largest: 5, 23, 31337, 32, 5" "31337"
          "how many hit singles does Justin Bieber have?" "I have no idea")

