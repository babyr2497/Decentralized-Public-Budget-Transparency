;; agency-verification.clar
;; This contract validates government entities

(define-data-var admin principal tx-sender)

;; Data map to store verified agencies
(define-map verified-agencies
  { agency-id: (string-ascii 64) }
  {
    name: (string-ascii 256),
    address: (string-ascii 256),
    verification-date: uint,
    is-active: bool
  }
)

;; Register a new government agency
(define-public (register-agency (agency-id (string-ascii 64)) (name (string-ascii 256)) (address (string-ascii 256)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? verified-agencies { agency-id: agency-id })) (err u100))

    (map-set verified-agencies
      { agency-id: agency-id }
      {
        name: name,
        address: address,
        verification-date: block-height,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Deactivate an agency
(define-public (deactivate-agency (agency-id (string-ascii 64)))
  (let ((agency (unwrap! (map-get? verified-agencies { agency-id: agency-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set verified-agencies
      { agency-id: agency-id }
      (merge agency { is-active: false })
    )
    (ok true)
  )
)

;; Check if an agency is verified
(define-read-only (is-agency-verified (agency-id (string-ascii 64)))
  (match (map-get? verified-agencies { agency-id: agency-id })
    agency (ok (get is-active agency))
    (err u404)
  )
)

;; Get agency details
(define-read-only (get-agency-details (agency-id (string-ascii 64)))
  (map-get? verified-agencies { agency-id: agency-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
