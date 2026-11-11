;;; pub-trivia.el --- Pub trivia with multiple choice answers -*- lexical-binding: t -*-

;; Copyright (C) 2026  Free Software Foundation, Inc.

;; Author: Protesilaos <info@protesilaos.com>
;; Maintainer: Protesilaos <info@protesilaos.com>
;; URL: https://github.com/protesilaos/pub-trivia
;; Version: 0.0.0
;; Package-Requires: ((emacs "28.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Pub trivia with multiple choice answers.  Invoke the `pub-trivia'
;; command to get started.  Then type 1, 2, 3, 4 to pick a choice.
;; When you go through all the questions, you will be presented with
;; the results.
;;
;; As you can obviously tell, the backronyms are: Prot Understands
;; Basic ... TRIVIA; PUB ... Trivia Randomly Inserted Verily Inspire
;; Angst.

;;; Code:
(defgroup pub-trivia nil
  "Pub trivia with multiple choice answers."
  :group 'convenience)

(defvar-local pub-trivia-all-question-data nil)
(defvar-local pub-trivia-specific-question-data nil)
(defvar-local pub-trivia-score nil)

(defface pub-trivia-category
  '((t :inherit shadow))
  "Face for the category of the question.
The category is a short description, such as \"Politics\", \"Emacs\",
etc.")

(defface pub-trivia-question
  '((t :inherit error :height 2.0))
  "Face for the question.")

(defface pub-trivia-choice
  '((t :inherit bold))
  "Face for the choices.")

(defface pub-trivia-correct-answer
  '((t :inherit success))
  "Face for the correct answer.")

(defface pub-trivia-results-message
  '((t :height 2.0))
  "Face for the results message.")

(defface pub-trivia-results-score
  '((t :inherit warning :height 2.0))
  "Face for the results score.")

(defvar pub-trivia-data-lists
  '(pub-trivia-data-politics
    pub-trivia-data-sport
    pub-trivia-data-emacs
    pub-trivia-data-geography)
  "List of variables with questions and answers.
Each list is of the form (CATEGORY DATA).  CATEGORY is a string
describing the data.  While DATA is a plist of the form:

    ( :question STRING-QUESTION
      :choices ( STRING-OPTION-1
                 STRING-OPTION-2
                 STRING-OPTION-3
                 STRING-OPTION-4)
      :answer 2)
")

(defvar pub-trivia-data-politics
  '("Politics"
    ( :question "Which is the French national anthem?"
      :choices ( "Les Hommes Qui Passent"
                 "La Marseilaise"
                 "Papaoutai"
                 "Les Trois Mousquaitieres")
      :answer 2)
    ( :question "Where is Juan de Fuca from?"
      :choices ( "Spain"
                 "Italy"
                 "Greece"
                 "China")
      :answer 3))
  "Questions and answers about politics.")

(defvar pub-trivia-data-sport
  '("Sport"
    ( :question "Football is a sport in which players..."
      :choices ( "... Hug the ball"
                 "... Kick the ball"
                 "... Volley the ball"
                 "... Observe the ball")
      :answer 2)
    ( :question "Which team won Euro 2004 in Portugal in their own capital?"
      :choices ( "England"
                 "Czechia"
                 "Portugal"
                 "Greece")
      :answer 4)
    ( :question "Which group of tourists took Euro 1992 by storm?"
      :choices ( "English"
                 "Irish"
                 "Danish"
                 "German")
      :answer 3))
  "Questions and answers about sport.")

(defvar pub-trivia-data-emacs
  '("Emacs"
    ( :question "How do you add order to the window management madness?"
      :choices ( "display-buffer-alist"
                 "M-x doctor"
                 "No problem; no stress: just call Prot"
                 "set-window-configuration")
      :answer 1)
    ( :question "Default keybinding to read echo area messages"
      :choices ( "C-h m"
                 "C-h r"
                 "C-h a"
                 "C-h e")
      :answer 4))
  "Questions and answers about emacs.")

(defvar pub-trivia-data-geography
  '("Geography"
    ( :question "The Land of Fire is in..."
      :choices ( "... the equator"
                 "... off the coast of England"
                 "... North of Australia"
                 "... South America")
      :answer 4)
    ( :question "The capital of New York State is..."
      :choices ( "... New York"
                 "... Albany"
                 "... Paris"
                 "... London")
      :answer 2)
    ( :question "What is the population of Greece in rough numbers?"
      :choices ( "10 million"
                 "2 million"
                 "5 million"
                 "100 million")
      :answer 1)
    ( :question "The capital of Iceland?"
      :choices ( "Stockholm"
                 "Copenhagen"
                 "Oslo"
                 ;; TODO 2026-11-11: Check spelling of Iceland capital.
                 "Reijkjavik")
      :answer 4)
    ( :question "\"Tundra\" refers to what?"
      :choices ( "A cocktail"
                 "School of philosophy"
                 "Boreal forests"
                 "Artistic movement")
      :answer 3))
  "Questions and answers about geography.")

;; TODO 2026-11-11: I want to change this approach.  It should be
;; pushing to a list.  At the end, the score/results buffer, reads
;; this list and inserts in the buffer.
(defun pub-trivia-validate-answer (choice-number choice-text answer-number answer-text question-text)
  (if (= choice-number answer-number)
      (progn
        (push t pub-trivia-score)
        ;; TODO 2026-11-11: Follow this up with the question.
        (message
         "CORRECT! You answered correctly with `%s'\nto the question `%s'"
         (propertize answer-text 'face 'pub-trivia-correct-answer)
         (propertize question-text 'face 'pub-trivia-choice)))
    ;; TODO 2026-11-11: Maybe have a user option to opt-in to showing the answer.
    (push nil pub-trivia-score)
    (message
     ;; "WRONG! The answer is: %s\nYour choice is: %s"
     ;; (propertize answer-text 'face 'pub-trivia-correct-answer)
     "WRONG! Your choice is: %s"
     (propertize choice-text 'face 'pub-trivia-choice))))

(defun pub-trivia-pick-next-question ()
  "Pick the next question among `pub-trivia-all-question-data'."
  (if-let* ((_ pub-trivia-all-question-data)
            (question (seq-random-elt pub-trivia-all-question-data)))
      (progn
        (setq-local pub-trivia-all-question-data (delete question pub-trivia-all-question-data))
        (pub-trivia--prepare-quiz-buffer question pub-trivia-all-question-data))
    (pub-trivia--prepare-results-buffer pub-trivia-score)
    (kill-buffer (get-buffer "*pub-trivia*"))))

(defmacro pub-trivia-define-choice-command (number)
  "Define command to choose NUMBER choice."
  `(defun ,(intern (format "pub-trivia-choose-%s" number)) ()
     ,(format "Choose option %s." number)
     (interactive)
     (if-let* ((data pub-trivia-specific-question-data)
               (choices (plist-get data :choices))
               (choice-number ,(- number 1))
               (choice-text (nth choice-number choices))
               (answer-number (- (plist-get data :answer) 1))
               (answer-text (nth answer-number choices))
               (question-text (plist-get data :question)))
         (progn
           (pub-trivia-validate-answer choice-number choice-text answer-number answer-text question-text)
           (pub-trivia-pick-next-question))
       (error "The data is wrong: `%S'" pub-trivia-specific-question-data))))

(pub-trivia-define-choice-command 1)
(pub-trivia-define-choice-command 2)
(pub-trivia-define-choice-command 3)
(pub-trivia-define-choice-command 4)
    
(defvar pub-trivia-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "1") #'pub-trivia-choose-1)
    (define-key map (kbd "2") #'pub-trivia-choose-2)
    (define-key map (kbd "3") #'pub-trivia-choose-3)
    (define-key map (kbd "4") #'pub-trivia-choose-4)
    map)
  "Keymap for `pub-trivia-mode'.")

(define-derived-mode pub-trivia-mode special-mode "Pub Trivia"
  "Major mode for pub trivia.")

(defcustom pub-trivia-display-buffer-action-alist
  '((display-buffer-reuse-mode-window display-buffer-full-frame)
    (mode . (pub-trivia-mode))
    (body-function . select-window))
  "The `display-buffer' action alist for `pub-trivia' buffers."
  :risky t
  :type `(choice
          (alist :key-type
                 (choice :tag "Condition"
                         regexp
                         (function :tag "Matcher function"))
                 :value-type ,display-buffer--action-custom-type)
          (function :tag "Custom function to return an action alist"))
  :package-version '(pub-trivia . "0.1.0"))

;; TODO 2026-11-11: Have a `header-line-format' that shows the
;; progress.  For example, 3/10 if you are on the third question out
;; of ten.
;;
;; TODO 2026-11-11: In the header line also have a hint to type 1-4
;; for the choice.
(defun pub-trivia--prepare-quiz-buffer (question-data all-data)
  "Prepare buffer to display DATA.
QUESTION-DATA is an element of `pub-trivia-data-lists' and has the form
documented therein."
  (let* ((buffer (get-buffer-create "*pub-trivia*"))
         (category (plist-get question-data :category))
         (question (plist-get question-data :question))
         (choices (plist-get question-data :choices))
         (answer (plist-get question-data :answer)))
    (with-current-buffer buffer
      (unless (eq major-mode 'pub-trivia-mode)
        (setq-local pub-trivia-score nil)
        (pub-trivia-mode))
      (unless pub-trivia-all-question-data
        (setq-local pub-trivia-all-question-data all-data))
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (propertize category 'face 'pub-trivia-category))
        (insert "\n")
        (insert (propertize question 'face 'pub-trivia-question))
        (insert "\n\n")
        (let ((number 1))
          (dolist (choice choices)
            (insert (format
                     "%s. %s"
                     number
                     (propertize choice 'face 'pub-trivia-choice)))
            (insert "\n")
            (setq number (+ number 1)))
          (setq-local pub-trivia-specific-question-data question-data))))
    (display-buffer buffer pub-trivia-display-buffer-action-alist)))
;; TODO 2026-11-11: I want to also get the percentage of this.  Then
;; the results buffer can give a funny message.
(defun pub-trivia--calculate-score (score)
  "Calculate the SCORE.
SCORE is a list of nil and non-nil values, representing the users false
and correct choices, respectively."
  (let* ((total-length (length score))
         (correct (seq-filter #'identity score))
         (correct-length (length correct)))
    (format "%s/%s" correct-length total-length)))

(defun pub-trivia--prepare-results-buffer (score)
  (let ((buffer (get-buffer-create "*pub-trivia-results*"))
        (formatted-score (pub-trivia--calculate-score score)))
    (with-current-buffer buffer
      (unless (eq major-mode 'pub-trivia-mode)
        (pub-trivia-mode))
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format
                 (propertize "Your score is %s" 'face 'pub-trivia-results-message)
                 (propertize formatted-score 'face 'pub-trivia-results-score)))
        (insert "\n\n")
        ;; TODO 2026-11-11: Once I have `pub-trivia--calculate-score'
        ;; with the percentage, I want to use a `pcase' here to return
        ;; the appropriate message, such as "Prot believes in you".
        ))
    (display-buffer buffer pub-trivia-display-buffer-action-alist)))

(defvar pub-trivia-number-of-questions-prompt-history nil
  "Minibuffer history for `pub-trivia-number-of-questions-prompt'.")

(defun pub-trivia-number-of-questions-prompt ()
  "Prompt for a number of `pub-trivia' questions."
  (let ((default (car pub-trivia-number-of-questions-prompt-history)))
    (completing-read
     (format-prompt "Number of questions?" default)
     '("5" "10" "15" "20")
     nil t nil 'pub-trivia-number-of-questions-prompt-history default)))

;; FIXME 2026-11-11: This is not deterministic.  We should always return a list with NUMBER-OF-QUESTIONS.
(defun pub-trivia-get-questions (number-of-questions &optional existing-data number-of-attempts)
  "Return list with NUMBER-OF-QUESTIONS from `pub-trivia-data-lists'.
Build on the EXISTING-DATA until its length matches NUMBER-OF-QUESTIONS.
In this case, abort after NUMBER-OF-ATTEMPTS."
  (let ((all-questions-choices nil)
        (number-of-attempts 3))
    (while (not (length= all-questions-choices number-of-questions))
      (let* ((questions-choices-variable (seq-random-elt pub-trivia-data-lists))
             (questions-choices-value (symbol-value questions-choices-variable))
             (category (car questions-choices-value))
             (questions-choices (cdr questions-choices-value))
             (data (mapcar
                    (lambda (element)
                      (plist-put element :category category))
                    questions-choices))
             (question-choices (seq-random-elt data)))
        (if (and (member question-choices all-questions-choices)
                 (> number-of-attempts 0))
            (progn
              (pub-trivia-get-questions 1 all-questions-choices number-of-attempts)
              (setq number-of-attempts (- number-of-attempts 1)))
          (push question-choices all-questions-choices))))
    all-questions-choices))

;;;###autoload
(defun pub-trivia (number-of-questions)
  "Start a pub trivia buffer for NUMBER-OF-QUESTIONS."
  (interactive
   (list
    (if-let* ((string (pub-trivia-number-of-questions-prompt))
              (number (string-to-number string)))
        number
      (error "Pick a number"))))
  (if-let* ((all-questions-choices (pub-trivia-get-questions number-of-questions))
            (initial-question (seq-random-elt all-questions-choices)))
      (pub-trivia--prepare-quiz-buffer initial-question all-questions-choices)
    (error "Could not get questions from `pub-trivia-data-lists'")))

(provide 'pub-trivia)
;;; pub-trivia.el ends here
