;; ---------------------------------------------------------
;; Contract: AccessKeyManager
;; Purpose: Manage on-chain access keys with simple metadata.
;; ---------------------------------------------------------

;; Store contract owner
(define-data-var owner principal tx-sender)

;; A map of registered keys and their metadata
(define-map keys
  { key-id: uint }
  { active: bool, metadata: (string-ascii 64) }
)

;; Error codes
(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))

;; ---------------------------------------------------------
;; Owner-only helper
;; ---------------------------------------------------------

(define-private (is-owner)
  (is-eq tx-sender (var-get owner))
)

(define-private (assert-owner)
  (begin
    (asserts! (is-owner) ERR-NOT-OWNER)
    ;; return (ok true) instead of true to match response type from asserts!
    (ok true)
  )
)

;; ---------------------------------------------------------
;; Public Functions
;; ---------------------------------------------------------

;; Register a new access key
(define-public (register-key (id uint) (meta (string-ascii 64)))
  (begin
    ;; wrap assert-owner with try! to check the response
    (try! (assert-owner))

    (match (map-get? keys { key-id: id })
      existing (asserts! false ERR-ALREADY-EXISTS)
      (map-set keys { key-id: id } { active: true, metadata: meta })
    )

    (ok true)
  )
)

;; Disable an existing key
(define-public (revoke-key (id uint))
  (begin
    ;; wrap assert-owner with try! to check the response
    (try! (assert-owner))

    (match (map-get? keys { key-id: id })
      entry
        (map-set keys { key-id: id } { active: false, metadata: (get metadata entry) })
      (asserts! false ERR-NOT-FOUND)
    )

    (ok true)
  )
)

;; Check whether a key is active
;; Removed extra closing paren after function signature
(define-read-only (is-key-active? (id uint))
  (match (map-get? keys { key-id: id })
    entry (ok (get active entry))
    (ok false)
  )
)

;; Retrieve metadata for a key
;; Removed extra closing paren after function signature
(define-read-only (get-key-metadata (id uint))
  (match (map-get? keys { key-id: id })
    entry (ok (get metadata entry))
    (ok "")
  )
)

;; Get the contract owner
(define-read-only (get-owner)
  (var-get owner)
)
