;; public-disclosure.clar
;; This contract generates accessible reports

(define-data-var admin principal tx-sender)

;; Data structures
(define-map disclosure-reports
  { report-id: (string-ascii 64) }
  {
    agency-id: (string-ascii 64),
    fiscal-year: uint,
    report-type: (string-ascii 32),
    report-hash: (buff 32),
    publication-date: uint,
    data-period-start: uint,
    data-period-end: uint,
    metadata: (string-ascii 256)
  }
)

;; Track report versions
(define-map report-versions
  { report-id: (string-ascii 64) }
  { current-version: uint }
)

;; Publish a new report
(define-public (publish-report
    (report-id (string-ascii 64))
    (agency-id (string-ascii 64))
    (fiscal-year uint)
    (report-type (string-ascii 32))
    (report-hash (buff 32))
    (data-period-start uint)
    (data-period-end uint)
    (metadata (string-ascii 256)))
  (begin
    ;; In a real implementation, we would verify the agency exists
    ;; For simplicity, we're not making contract calls here

    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    ;; Check if this is a new report or an update
    (match (map-get? report-versions { report-id: report-id })
      version-data (map-set report-versions
                    { report-id: report-id }
                    { current-version: (+ (get current-version version-data) u1) })
      (map-set report-versions { report-id: report-id } { current-version: u1 })
    )

    (map-set disclosure-reports
      { report-id: report-id }
      {
        agency-id: agency-id,
        fiscal-year: fiscal-year,
        report-type: report-type,
        report-hash: report-hash,
        publication-date: block-height,
        data-period-start: data-period-start,
        data-period-end: data-period-end,
        metadata: metadata
      }
    )
    (ok true)
  )
)

;; Get report details
(define-read-only (get-report-details (report-id (string-ascii 64)))
  (map-get? disclosure-reports { report-id: report-id })
)

;; Get report version
(define-read-only (get-report-version (report-id (string-ascii 64)))
  (default-to { current-version: u0 } (map-get? report-versions { report-id: report-id }))
)

;; Verify report authenticity (checks if the hash matches what's stored)
(define-read-only (verify-report-authenticity (report-id (string-ascii 64)) (provided-hash (buff 32)))
  (match (map-get? disclosure-reports { report-id: report-id })
    report (ok (is-eq (get report-hash report) provided-hash))
    (err u404)
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
