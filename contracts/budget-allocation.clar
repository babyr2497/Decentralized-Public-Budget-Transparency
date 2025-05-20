;; budget-allocation.clar
;; This contract records planned expenditures

(define-data-var admin principal tx-sender)

;; Data structures
(define-map budget-allocations
  { budget-id: (string-ascii 64) }
  {
    agency-id: (string-ascii 64),
    fiscal-year: uint,
    amount: uint,
    category: (string-ascii 64),
    description: (string-ascii 256),
    approval-status: (string-ascii 16),
    creation-date: uint
  }
)

;; Track total allocations by agency and fiscal year
(define-map agency-fiscal-allocations
  { agency-id: (string-ascii 64), fiscal-year: uint }
  { total-allocated: uint }
)

;; Create a new budget proposal
(define-public (create-budget-proposal
    (budget-id (string-ascii 64))
    (agency-id (string-ascii 64))
    (fiscal-year uint)
    (amount uint)
    (category (string-ascii 64))
    (description (string-ascii 256)))
  (begin
    ;; Verify the agency exists and is active (would call agency-verification contract in a real implementation)
    ;; For simplicity, we're not making a contract call here

    (asserts! (is-none (map-get? budget-allocations { budget-id: budget-id })) (err u100))

    (map-set budget-allocations
      { budget-id: budget-id }
      {
        agency-id: agency-id,
        fiscal-year: fiscal-year,
        amount: amount,
        category: category,
        description: description,
        approval-status: "pending",
        creation-date: block-height
      }
    )
    (ok true)
  )
)

;; Approve a budget proposal
(define-public (approve-budget (budget-id (string-ascii 64)))
  (let (
    (budget (unwrap! (map-get? budget-allocations { budget-id: budget-id }) (err u404)))
    (agency-fiscal-key { agency-id: (get agency-id budget), fiscal-year: (get fiscal-year budget) })
    (current-total (default-to { total-allocated: u0 } (map-get? agency-fiscal-allocations agency-fiscal-key)))
  )
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-eq (get approval-status budget) "pending") (err u401))

    ;; Update the budget status
    (map-set budget-allocations
      { budget-id: budget-id }
      (merge budget { approval-status: "approved" })
    )

    ;; Update the total allocation for this agency and fiscal year
    (map-set agency-fiscal-allocations
      agency-fiscal-key
      { total-allocated: (+ (get total-allocated current-total) (get amount budget)) }
    )

    (ok true)
  )
)

;; Reject a budget proposal
(define-public (reject-budget (budget-id (string-ascii 64)))
  (let ((budget (unwrap! (map-get? budget-allocations { budget-id: budget-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-eq (get approval-status budget) "pending") (err u401))

    (map-set budget-allocations
      { budget-id: budget-id }
      (merge budget { approval-status: "rejected" })
    )
    (ok true)
  )
)

;; Get budget details
(define-read-only (get-budget-details (budget-id (string-ascii 64)))
  (map-get? budget-allocations { budget-id: budget-id })
)

;; Get total allocation for an agency in a fiscal year
(define-read-only (get-agency-fiscal-allocation (agency-id (string-ascii 64)) (fiscal-year uint))
  (default-to { total-allocated: u0 }
    (map-get? agency-fiscal-allocations { agency-id: agency-id, fiscal-year: fiscal-year })
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
