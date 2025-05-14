;; Carrier Verification Contract
;; This contract validates transportation providers

(define-data-var admin principal tx-sender)

;; Map to store verified carriers
(define-map verified-carriers principal
  {
    name: (string-utf8 100),
    license-id: (string-utf8 50),
    verified: bool,
    verification-date: uint
  }
)

;; Public function to register a carrier (can only be called by the carrier themselves)
(define-public (register-carrier (name (string-utf8 100)) (license-id (string-utf8 50)))
  (begin
    (asserts! (not (is-some (map-get? verified-carriers tx-sender))) (err u1)) ;; Error if already registered
    (ok (map-set verified-carriers tx-sender
      {
        name: name,
        license-id: license-id,
        verified: false,
        verification-date: u0
      }
    ))
  )
)

;; Admin function to verify a carrier
(define-public (verify-carrier (carrier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Only admin can verify
    (asserts! (is-some (map-get? verified-carriers carrier)) (err u3)) ;; Error if carrier not registered
    (ok (map-set verified-carriers carrier
      (merge (unwrap-panic (map-get? verified-carriers carrier))
        {
          verified: true,
          verification-date: block-height
        }
      )
    ))
  )
)

;; Public function to check if a carrier is verified
(define-read-only (is-verified (carrier principal))
  (match (map-get? verified-carriers carrier)
    carrier-data (ok (get verified carrier-data))
    (err u4) ;; Error if carrier not found
  )
)

;; Public function to get carrier details
(define-read-only (get-carrier-details (carrier principal))
  (map-get? verified-carriers carrier)
)

;; Admin function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u5)) ;; Only current admin can transfer
    (ok (var-set admin new-admin))
  )
)
