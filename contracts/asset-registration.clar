;; Asset Registration Contract
;; This contract records transportation equipment

(define-data-var admin principal tx-sender)

;; Asset types
(define-constant TRUCK u1)
(define-constant TRAILER u2)
(define-constant CONTAINER u3)
(define-constant SHIP u4)
(define-constant PLANE u5)

;; Map to store registered assets
(define-map registered-assets
  { owner: principal, asset-id: (string-utf8 50) }
  {
    asset-type: uint,
    capacity: uint,
    description: (string-utf8 100),
    registration-date: uint,
    active: bool
  }
)

;; Map to track asset count per owner
(define-map asset-count principal uint)

;; Public function to register an asset
(define-public (register-asset
    (asset-id (string-utf8 50))
    (asset-type uint)
    (capacity uint)
    (description (string-utf8 100)))
  (let ((asset-key { owner: tx-sender, asset-id: asset-id })
        (current-count (default-to u0 (map-get? asset-count tx-sender))))
    (begin
      ;; Validate asset type
      (asserts! (or (is-eq asset-type TRUCK)
                   (is-eq asset-type TRAILER)
                   (is-eq asset-type CONTAINER)
                   (is-eq asset-type SHIP)
                   (is-eq asset-type PLANE))
               (err u1))
      ;; Check if asset already exists
      (asserts! (is-none (map-get? registered-assets asset-key)) (err u2))
      ;; Register the asset
      (map-set registered-assets asset-key
        {
          asset-type: asset-type,
          capacity: capacity,
          description: description,
          registration-date: block-height,
          active: true
        }
      )
      ;; Update asset count
      (map-set asset-count tx-sender (+ current-count u1))
      (ok true)
    )
  )
)

;; Public function to deactivate an asset
(define-public (deactivate-asset (asset-id (string-utf8 50)))
  (let ((asset-key { owner: tx-sender, asset-id: asset-id }))
    (begin
      (asserts! (is-some (map-get? registered-assets asset-key)) (err u3))
      (ok (map-set registered-assets asset-key
        (merge (unwrap-panic (map-get? registered-assets asset-key))
          { active: false }
        )
      ))
    )
  )
)

;; Public function to reactivate an asset
(define-public (reactivate-asset (asset-id (string-utf8 50)))
  (let ((asset-key { owner: tx-sender, asset-id: asset-id }))
    (begin
      (asserts! (is-some (map-get? registered-assets asset-key)) (err u3))
      (ok (map-set registered-assets asset-key
        (merge (unwrap-panic (map-get? registered-assets asset-key))
          { active: true }
        )
      ))
    )
  )
)

;; Public function to get asset details
(define-read-only (get-asset-details (owner principal) (asset-id (string-utf8 50)))
  (map-get? registered-assets { owner: owner, asset-id: asset-id })
)

;; Public function to get asset count for an owner
(define-read-only (get-asset-count (owner principal))
  (default-to u0 (map-get? asset-count owner))
)

;; Admin function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u5))
    (ok (var-set admin new-admin))
  )
)
