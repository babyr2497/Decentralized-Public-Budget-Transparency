;; performance-metrics.clar
;; This contract links spending to outcomes

(define-data-var admin principal tx-sender)

;; Data structures
(define-map performance-metrics
  { metric-id: (string-ascii 64) }
  {
    agency-id: (string-ascii 64),
    budget-id: (string-ascii 64),
    name: (string-ascii 64),
    description: (string-ascii 256),
    target-value: uint,
    actual-value: uint,
    unit: (string-ascii 32),
    fiscal-year: uint,
    last-updated: uint
  }
)

;; Define a new performance metric
(define-public (define-metric
    (metric-id (string-ascii 64))
    (agency-id (string-ascii 64))
    (budget-id (string-ascii 64))
    (name (string-ascii 64))
    (description (string-ascii 256))
    (target-value uint)
    (unit (string-ascii 32))
    (fiscal-year uint))
  (begin
    ;; In a real implementation, we would verify the agency and budget exist
    ;; For simplicity, we're not making contract calls here

    (asserts! (is-none (map-get? performance-metrics { metric-id: metric-id })) (err u100))

    (map-set performance-metrics
      { metric-id: metric-id }
      {
        agency-id: agency-id,
        budget-id: budget-id,
        name: name,
        description: description,
        target-value: target-value,
        actual-value: u0,
        unit: unit,
        fiscal-year: fiscal-year,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

;; Update the actual value of a metric
(define-public (update-metric-value (metric-id (string-ascii 64)) (actual-value uint))
  (let ((metric (unwrap! (map-get? performance-metrics { metric-id: metric-id }) (err u404))))
    ;; In a real implementation, we would verify the caller is authorized
    ;; For simplicity, we're only checking admin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set performance-metrics
      { metric-id: metric-id }
      (merge metric {
        actual-value: actual-value,
        last-updated: block-height
      })
    )
    (ok true)
  )
)

;; Calculate performance score (as a percentage of target achieved)
(define-read-only (calculate-performance-score (metric-id (string-ascii 64)))
  (let ((metric (unwrap! (map-get? performance-metrics { metric-id: metric-id }) (err u404))))
    (if (> (get target-value metric) u0)
      (ok (* (/ (* (get actual-value metric) u100) (get target-value metric)) u1))
      (err u500) ;; Cannot calculate if target is zero
    )
  )
)

;; Get metric details
(define-read-only (get-metric-details (metric-id (string-ascii 64)))
  (map-get? performance-metrics { metric-id: metric-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
