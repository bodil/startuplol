(ns startuplol.rules
  (:use startuplol.dispatch
        clojure.test)
  (require [noir.session :as session]))

(with-test
  (defn prime? [n]
    (if (< n 2) false
        (empty? (filter #(= 0 %) (map #(rem n %) (range 2 n)))))))

(with-test
  (defn join-comma [ns]
    (loop [l (rest ns)
           r (str (first ns))]
      (if (seq l)
        (recur (rest l) (str r ", " (first l)))
        r
       )
      ))
  (is (= "2, 3, 4" (join-comma [2 3 4]))))

(defn padzero [n]
  (if (< n 10)
    (str "0" n)
    (str n)))

(with-test
  (defn fib [n]
    (if (< n 2) n
        (+ (fib (- n 2)) (fib (- n 1)))))
  (is (= 5 (fib 5))))

;; is_cube = (n) ->
;;   a = Math.round Math.pow n, 1/3
;;   n == a * a * a

(with-test
  (defn cube? [n]
    (let [cr (java.lang.Math/round (java.lang.Math/pow n (double (/ 1 3))))]
      (= n (* cr cr cr))))
  (is (true? (cube? 27)))
  (is (true? (cube? 64)))
  (is (false? (cube? 26))))
(with-test
  (defn square? [n]
    (let [sqr (java.lang.Math/round (java.lang.Math/pow n (double (/ 1 2))))]
      (= n (* sqr sqr))))
  (is (true? (square? 9)))
  (is (false? (square? 7))))

(dispatch
 (rule #".*what is your name" _ "Bodilpwnz")
 
 (rule-ints #".*what is (\d+) plus (\d+)" [a b] (+ a b))
 (rule-ints #".*what is (\d+) plus (\d+) multiplied by (\d+)" [a b c] (* (+ a b) c))
 (rule-ints #".*what is (\d+) multiplied by (\d+) plus (\d+)" [a b c] (+ (* a b) c))
 (rule-ints #".*what is (\d+) minus (\d+)" [a b] (- a b))
 (rule-ints #".*what is (\d+) multiplied by (\d+)" [a b] (* a b))
 (rule-ints #".*what is (\d+) divided by (\d+)" [a b] (double (/ a b)))

 (rule-ints #".*what is the (\d+)\w+ number in the Fibonacci sequence" [n] (fib n))
 
 (rule-intlist #".*which of the following numbers is the largest: (.*)"
               ns (apply max ns))
 (rule-intlist #".*which of the following numbers is both a square and a cube: (.*)"
               ns (join-comma (filter cube? ns)))
 
 (rule #".*my name is (\w+). what is my name" m
       (let [name (m 1)] (session/put! :myname name) name))
 (rule #".*what is my name" _ (session/get :myname "Justin Bieber"))
 
 (rule-ints #".*leaves from Paris (\d+)\.(\d+)\.(\d+) at (\d+):(\d+)\. It takes (\d+) minutes.*"
            [y mo d h m duration]
            (let [startmins (+ (* h 60) m)]
              (let [endmins (+ startmins duration)]
                (str y "." mo "." d " at " (padzero (int (/ endmins 60))) ":" (padzero (mod endmins 60))))))

 (rule-ints #".*leaves (\d+)\.(\d+)\.(\d+) at (\d+):(\d+)\. It takes (\d+) minutes.*"
            [y mo d h m duration]
            (let [startmins (+ (* h 60) m)]
              (let [endmins (+ startmins (+ duration 60))]
                (str y "." mo "." d " at " (padzero (int (/ endmins 60))) ":" (padzero (mod endmins 60))))))
 (rule-ints #".*Rome takes off (\d+)\.(\d+)\.(\d+) at (\d+):(\d+)\. It takes (\d+) minutes.*"
            [y mo d h m duration]
            (let [startmins (+ (* h 60) m)]
              (let [endmins (+ startmins duration)]
                (str y "." mo "." d " at " (padzero (int (/ endmins 60))) ":" (padzero (mod endmins 60))))))

 (rule-ints #".*New Your takes off (\d+)\.(\d+)\.(\d+) at (\d+):(\d+)\. It takes (\d+) minutes.*"
            [y mo d h m duration]
            (let [startmins (+ (* h 60) m)]
              (let [endmins (+ startmins (+ 360 duration))]
                (str y "." mo "." d " at " (padzero (int (/ endmins 60))) ":" (padzero (mod endmins 60))))))

 (rule-intlist #".*which of the following numbers are primes: (.*)" ns
               (join-comma (filter prime? ns)))

 (rule #".*how many dollars does one (.+) cost" m
       (let [product (m 1)]
         (cond
          (= "foo" m) 1
          (= "bar" m) 2
          (= "baz" m) 3)))
 
 (rule #".*who played James Bond in the film Dr No" _ "Sean Connery")
 (rule #".*what is the twitter id of the organizer of this dojo" _ "jhannes")
 (rule #".*which city is the Eiffel tower in" _ "Paris")
 (rule #".*what currency did Spain use before the Euro" _ "peseta")
 (rule #".*who is the Prime Minister of Great Britain" _ "David Cameron")

 (rule #".*what products do you have for sale \(comma separated\)" _ "foo, bar, baz")
 
 (rule #".*" _ "I have no idea"))

(testrule "what is your name" "Bodilpwnz"
          "what is 13 plus 37" "50"
          "what is 13 plus 37 multiplied by 2" "100"
          "what is 13 multiplied by 2 plus 2" "28"
          "what is 37 minus 13" "24"
          "which of the following numbers is the largest: 37, 13, 1" "37"
          "what is 5 multiplied by 3" "15"
          "what is 5 divided by 2" "2.5"
          "which of the following numbers are primes: 5, 6, 7" "5, 7"
          "what products do you have for sale (comma separated)" "foo, bar, baz"
          "what is the 5th number in the Fibonacci sequence" "5"
          "A flight from Paris to Oslo leaves from Paris 29.10.2011 at 08:00. It takes 133 minutes. When (local time) does it land in Oslo ?" "29.10.2011 at 10:13"
          "A flight from London to Oslo leaves 29.10.2011 at 08:00. It takes 133 minutes. When (local time) does it land in Oslo ?" "29.10.2011 at 11:13"
          "A jetplane from Rome takes off 30.10.2011 at 01:13. It takes 230 minutes. When (local time) does it land in Oslo ?" "30.10.2011 at 05:03"
          "A jetplane from New Your takes off 29.10.2011 at 03:26. It takes 319 minutes. When (local time) does it land in Oslo ?" "29.10.2011 at 14:45"
          "which of the following numbers is both a square and a cube: 9, 10, 64" "64"
          "how many hit singles does Justin Bieber have?" "I have no idea")

