;; spending-tracking.clar
;; This contract monitors actual disbursements

(define-data-var admin principal tx-sender)

;; Data structures
(define-map spending-records
  { spending-id: (string-ascii 64) }
  {
    budget-id: (string-ascii 64),
    agency-id: (string-ascii 64),
    amount: uint,
    recipient: (string-ascii 256),
    purpose: (string-ascii 256),
    date: uint,
    status: (string-ascii 16)
  }
)

;; Track total spending by budget
(define-map budget-spending
  { budget-id: (string-ascii 64) }
  { total-spent: uint }
)

;; Record a new spending transaction
(define-public (record-spending
    (spending-id (string-ascii 64))
    (budget-id (string-ascii 64))
    (agency-id (string-ascii 64))
    (amount uint)
    (recipient (string-ascii 256))
    (purpose (string-ascii 256)))
  (begin
    ;; In a real implementation, we would verify the agency and budget exist
    ;; For simplicity, we're not making contract calls here

    (asserts! (is-none (map-get? spending-records { spending-id: spending-id })) (err u100))

    (map-set spending-records
      { spending-id: spending-id }
      {
        budget-id: budget-id,
        agency-id: agency-id,
        amount: amount,
        recipient: recipient,
        purpose: purpose,
        date: block-height,
        status: "recorded"
      }
    )

    ;; Update the total spending for this budget
    (let (
      (current-spending (default-to { total-spent: u0 } (map-get? budget-spending { budget-id: budget-id })))
    )
      (map-set budget-spending
        { budget-id: budget-id }
        { total-spent: (+ (get total-spent current-spending) amount) }
      )
    )

    (ok true)
  )
)

;; Verify a spending record
(define-public (verify-spending (spending-id (string-ascii 64)))
  (let ((spending (unwrap! (map-get? spending-records { spending-id: spending-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-eq (get status spending) "recorded") (err u401))

    (map-set spending-records
      { spending-id: spending-id }
      (merge spending { status: "verified" })
    )
    (ok true)
  )
)

;; Flag a spending record for audit
(define-public (flag-spending-for-audit (spending-id (string-ascii 64)))
  (let ((spending (unwrap! (map-get? spending-records { spending-id: spending-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set spending-records
      { spending-id: spending-id }
      (merge spending { status: "flagged" })
    )
    (ok true)
  )
)

;; Get spending details
(define-read-only (get-spending-details (spending-id (string-ascii 64)))
  (map-get? spending-records { spending-id: spending-id })
)

;; Get total spending for a budget
(define-read-only (get-budget-total-spending (budget-id (string-ascii 64)))
  (default-to { total-spent: u0 } (map-get? budget-spending { budget-id: budget-id }))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
