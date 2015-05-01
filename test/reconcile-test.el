;;; reconcile-test.el --- ERT for ledger-mode

;;; Commentary:
;;  Regression tests for ledger-reconcile

;;; Code:
(require 'test-helper)


(ert-deftest ledger-reconcile/test-001 ()
  "Regress test for Bug 1107
http://bugs.ledger-cli.org/show_bug.cgi?id=1107"
  :tags '(reconcile regress)

  (ledger-tests-with-temp-file
      demo-ledger
    (ledger-reconcile "Assets:Checking" '(0 "$")) ; this moves to *recon* buffer
    (other-window 1)                ; go to *ledger* buffer
    (insert " ")                    ; simulate modification of ledger buffer
    (delete-char -1)
    (other-window 1)                ; back to *reconcile* buffer
    (ledger-reconcile-save)         ; key 's'
    (should ;; current buffer should be *recon* buffer
     (equal (buffer-name)           ; current buffer name
            ledger-recon-buffer-name))
    (other-window 1)                ; switch to *other* window
    (should ;; Expected: this must be ledger buffer
     (equal (buffer-name)           ; current buffer name
            (buffer-name ledger-buffer)))))


(ert-deftest ledger-reconcile/test-002 ()
  "Regress test for Bug 1060 + Bug 1039
http://bugs.ledger-cli.org/show_bug.cgi?id=1060
http://bugs.ledger-cli.org/show_bug.cgi?id=1039"
  :tags '(reconcile regress)

  (ledger-tests-with-temp-file
      demo-ledger
    (ledger-reconcile "Assets:Checking" '(0 "$")) ; launch reconciliation
    (select-window (get-buffer-window ledger-recon-buffer-name)) ; IRL user select recon window
    (forward-line 2)                    ; because of ledger-reconcile-buffer-header
    (ledger-reconcile-toggle)                     ; mark pending
    (ledger-reconcile-toggle)                     ; mark pending
    (ledger-reconcile-finish)                     ; C-c C-c
    (should ;; Expected: buffer recon must still exist and be selected
     (equal ledger-recon-buffer-name
            (buffer-name (window-buffer (selected-window)))))))


(ert-deftest ledger-reconcile/test-003 ()
  "Regress test for Bug 1060
http://bugs.ledger-cli.org/show_bug.cgi?id=1060

If `ledger-reconcile-finish-force-quit' is set, recon window is killed"
  :tags '(reconcile regress)

  (ledger-tests-with-temp-file
      demo-ledger
    (setq ledger-reconcile-finish-force-quit t)
    (ledger-reconcile "Assets:Checking" '(0 "$")) ; launch reconciliation
    (select-window (get-buffer-window ledger-recon-buffer-name)) ; IRL user select recon window
    (forward-line 2)                    ; because of ledger-reconcile-buffer-header
    (ledger-reconcile-toggle)                     ; mark pending
    (ledger-reconcile-toggle)                     ; mark pending
    (ledger-reconcile-finish)                     ; C-c C-c
    (should ;; Expected: recon buffer has been killed
     (equal nil (get-buffer-window ledger-recon-buffer-name)))))


(ert-deftest ledger-reconcile/test-004 ()
  "Regress test for Bug 1108 and Bug 1061
http://bugs.ledger-cli.org/show_bug.cgi?id=1108
http://bugs.ledger-cli.org/show_bug.cgi?id=1061"
  :tags '(reconcile regress)

  (ledger-tests-with-temp-file
"2014/11/10  EDF
    Dépense:Maison:Service:Électricité    36,23 €
    Actif:Courant:BnpCc

2014/11/14  Banque Accord Retrait
    Passif:Crédit:BanqueAccord              60,00 €
    Actif:Courant:BnpCc
"
    (goto-char 150)                 ; line 6, before A of BanqueAccord
    (let ((context (ledger-context-at-point)))
      (should (eq (ledger-context-current-field context) 'account))
      (should (equal "Passif:Crédit:BanqueAccord"
                     (ledger-context-field-value context 'account))))))


(ert-deftest ledger-reconcile/test-005 ()
  "Regress test for Bug 1105+875
http://bugs.ledger-cli.org/show_bug.cgi?id=1105
http://bugs.ledger-cli.org/show_bug.cgi?id=875"
  :tags '(reconcile regress)

  (ledger-tests-with-temp-file
"2008/10/16 (2090) Bountiful Blessings Farm Williamsport
    Expenses:Food:Groceries                  $ 37.50  ; [=2008/10/01]
    Expenses:Food:Groceries                  $ 37.50  ; [=2008/11/01]
    Expenses:Food:Groceries                  $ 37.50  ; [=2008/12/01]
    Expenses:Food:Groceries                  $ 37.50  ; [=2009/01/01]
    Expenses:Food:Groceries                  $ 37.50  ; [=2009/02/01]
    Expenses:Food:Groceries                  $ 37.50  ; [=2009/03/01]
    Assets:Checking
"

    (setq ledger-reconcile-buffer-header ""
          ledger-reconcile-buffer-line-format "%(date)s %-30(payee)s %-22(account)s %10(amount)s\n"
          ledger-reconcile-buffer-payee-max-chars 30
          ledger-reconcile-buffer-account-max-chars 22)
    (ledger-reconcile "Expenses:Food:Groceries" '(0 "$"))
    (switch-to-buffer ledger-recon-buffer-name)
    (should (equal
             "2008/10/16 Bountiful Blessings Farm Will… …penses:Food:Groceries    $ 37.50
2008/10/16 Bountiful Blessings Farm Will… …penses:Food:Groceries    $ 37.50
2008/10/16 Bountiful Blessings Farm Will… …penses:Food:Groceries    $ 37.50
2008/10/16 Bountiful Blessings Farm Will… …penses:Food:Groceries    $ 37.50
2008/10/16 Bountiful Blessings Farm Will… …penses:Food:Groceries    $ 37.50
2008/10/16 Bountiful Blessings Farm Will… …penses:Food:Groceries    $ 37.50"
             (buffer-string)))))


(ert-deftest ledger-reconcile/test-006 ()
  "Regress test for Bug 1104
http://bugs.ledger-cli.org/show_bug.cgi?id=1104"
  :tags '(reconcile regress)

  (ledger-tests-with-temp-file
      demo-ledger
    (setq ledger-reconcile-buffer-header "")
    (ledger-reconcile "Expenses:Books" '(0 "$"))
    (should-not
     (equal nil (get-buffer-window ledger-recon-buffer-name)))))


(ert-deftest ledger-reconcile/test-007 ()
  "Regress test for Bug 1059
http://bugs.ledger-cli.org/show_bug.cgi?id=1059"
  :tags '(reconcile regress)

  (ledger-tests-with-temp-file
"2014/03/03 * Retrait
    Dépense:Alimentation:Épicerie            20,00 €
    Dépense:Alimentation:Restaurant          23,80 €
    Dépense:Alimentation:Restaurant          11,50 €
    Actif:Remboursement:Cie  1,50 €
    Dépense:Liquide
    Passif:Crédit:BanqueAccord              -60,00 €
"
    (goto-char 206)
    (ledger-toggle-current)             ; C-c C-c
    (should
     (equal
      "2014/03/03 Retrait
    * Dépense:Alimentation:Épicerie          20,00 €
    * Dépense:Alimentation:Restaurant        23,80 €
    * Dépense:Alimentation:Restaurant        11,50 €
    Actif:Remboursement:Cie    1,50 €
    * Dépense:Liquide
    * Passif:Crédit:BanqueAccord            -60,00 €
"
             (buffer-string)))))


(ert-deftest ledger-reconcile/test-008 ()
  "Regress test for Bug 1056
http://bugs.ledger-cli.org/show_bug.cgi?id=1056"
  :tags '(reconcile regress)

  (ledger-tests-with-temp-file
"2014/04/03 www.amazon.fr
    Dépense:Loisir:Ordi:Matériel            101,50 €  ; disque dur portable 2,5\" 2000 Go
    Dépense:Maison:Service:Poste
    * Passif:Crédit:BanqueAccord           -171,63 €
"
    (setq ledger-reconcile-default-commodity "€") ; FIXME This must be set even if below call (ledger-reconcile "Dépense" '(0 "€")) is using "€". Is this a bug?
    (ledger-reconcile "Dépense" '(0 "€"))
    (should-not ;; ledger recon must exists and no error prevented to go to this point
     (equal nil (get-buffer-window ledger-recon-buffer-name)))))


(ert-deftest ledger-reconcile/test-009 ()
  "Regress test for Bug 1040
http://bugs.ledger-cli.org/show_bug.cgi?id=1040"
  :tags '(reconcile regress)

  (ledger-tests-with-temp-file
      demo-ledger
    (ledger-reconcile "Assets:Checking" '(0 "$")) ; launch reconciliation
    (select-window (get-buffer-window ledger-recon-buffer-name)) ; IRL user select recon window
    (forward-line 6)
    (ledger-reconcile-toggle)
    (ledger-reconcile-toggle)
    (let ((line-before-save (line-number-at-pos)))
      (ledger-reconcile-save)             ; key 's'
      (should ;; Expected: line position is kept
       (eq line-before-save (line-number-at-pos)))
      (should ;; current buffer should be *recon* buffer
       (equal (buffer-name)           ; current buffer name
              ledger-recon-buffer-name)))))


(provide 'reconcile-test)

;;; reconcile-test.el ends here
