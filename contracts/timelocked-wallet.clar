;; Constant Variables

;; Owner
(define-constant contract-owner tx-sender) ;; Holds the Contract Owner

;; Errors
(define-constant err-owner-only (err u100)) ;; Accessed denied for function
(define-constant err-already-locked (err u101)) ;; Trying to call the lock function more than once
(define-constant err-unlock-in-past (err u102)) ;; Already unlocked
(define-constant err-no-value (err u103)) ;; No value passed initally
(define-constant err-beneficiary-only (err u104)) ;; Accessed by others than beneficiary
(define-constant err-unlock-height-not-reached (err u105)) ;; Unlock block height not reached yet

;; Data
(define-data-var beneficiary (optional principal) none) ;; Holds the Beneficiary
(define-data-var unlock-height uint u0) ;; Holds the Unlock height

;; Lock the wallet
(define-public (lock (new-beneficiary principal) (unlock-at uint) (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (var-get beneficiary)) err-already-locked)
    (asserts! (> unlock-at block-height) err-unlock-in-past)
    (asserts! (> amount u0) err-no-value)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set beneficiary (some new-beneficiary))
    (var-set unlock-height unlock-at)
    (ok true)
  )
)

;; Pass Benficiary to someone else
(define-public (bestow (new-beneficiary principal))
  (begin
    (asserts! (is-eq (some tx-sender) (var-get beneficiary)) err-beneficiary-only)
    (var-set beneficiary (some new-beneficiary))
    (ok true)
  )
)

;; Claim if its the beneficiary and unlock time is passed
(define-public (claim)
  (begin
    (asserts! (is-eq (some tx-sender) (var-get beneficiary)) err-beneficiary-only)
    (asserts! (>= block-height (var-get unlock-height)) err-unlock-height-not-reached)
    (as-contract (stx-transfer? (stx-get-balance tx-sender) tx-sender (unwrap-panic (var-get beneficiary))))
  )
)
