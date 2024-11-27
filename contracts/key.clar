(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-IDENTITY-EXISTS (err u2))
(define-constant ERR-IDENTITY-NOT-FOUND (err u3))
(define-constant ERR-INVALID-CLAIM (err u4))
(define-constant ERR-INVALID-DID (err u5))
(define-constant ERR-INVALID-USER (err u6))
(define-constant ERR-CLAIM-NOT-FOUND (err u7))

(define-map user-identities 
  principal 
  {
    did: (string-ascii 100),
    verification-status: bool,
    claims: (list 10 (string-ascii 200)),
    created-at: uint,
    updated-at: uint
  }
)

(define-map verified-claims 
  { user: principal, claim: (string-ascii 200) } 
  bool)

(define-public (create-identity (did (string-ascii 100)))
  (begin
    (asserts! (is-none (map-get? user-identities tx-sender)) ERR-IDENTITY-EXISTS)
    (asserts! (> (len did) u0) ERR-INVALID-DID)
    (asserts! (<= (len did) u100) ERR-INVALID-DID)
    
    (map-set user-identities 
      tx-sender 
      {
        did: did,
        verification-status: false,
        claims: (list ),
        created-at: block-height,
        updated-at: block-height
      }
    )
    (ok true)
  )
)

(define-public (add-claim (claim (string-ascii 200)))
  (let 
    (
      (current-identity (unwrap! (map-get? user-identities tx-sender) ERR-IDENTITY-NOT-FOUND))
    )
    (asserts! (> (len claim) u0) ERR-INVALID-CLAIM)
    (asserts! (<= (len claim) u200) ERR-INVALID-CLAIM)
    
    (let
      (
        (updated-claims 
          (if (< (len (get claims current-identity)) u10)
            (unwrap-panic (as-max-len? (append (get claims current-identity) claim) u10))
            (get claims current-identity)
          )
        )
      )
      (map-set user-identities 
        tx-sender 
        (merge current-identity 
          { 
            claims: updated-claims,
            updated-at: block-height 
          }
        )
      )
      (ok true)
    )
  )
)

(define-public (verify-claim (user principal) (claim (string-ascii 200)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? user-identities user)) ERR-INVALID-USER)
    (asserts! (> (len claim) u0) ERR-INVALID-CLAIM)
    (asserts! (<= (len claim) u200) ERR-INVALID-CLAIM)
    
    (map-set verified-claims 
      { user: user, claim: claim } 
      true
    )
    (ok true)
  )
)

(define-read-only (is-claim-verified (user principal) (claim (string-ascii 200)))
  (default-to false 
    (map-get? verified-claims { user: user, claim: claim })
  )
)

(define-read-only (get-identity (user principal))
  (map-get? user-identities user)
)
