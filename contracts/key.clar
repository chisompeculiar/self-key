;; SelfKey: Decentralized Identity Management Contract

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-IDENTITY-EXISTS (err u2))
(define-constant ERR-IDENTITY-NOT-FOUND (err u3))
(define-constant ERR-INVALID-CLAIM (err u4))

;; Data Maps
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

;; Map to track verified claims
(define-map verified-claims 
  { user: principal, claim: (string-ascii 200) } 
  bool)

;; Create a new decentralized identity
(define-public (create-identity (did (string-ascii 100)))
  (begin
    (asserts! (is-none (map-get? user-identities tx-sender)) ERR-IDENTITY-EXISTS)
    
    (map-set user-identities 
      tx-sender 
      {
        did: did,
        verification-status: false,
        claims: (list),
        created-at: block-height,
        updated-at: block-height
      }
    )
    
    (ok true)
  )
)

;; Add a claim to user's identity
(define-public (add-claim (claim (string-ascii 200)))
  (let 
    (
      (current-identity (unwrap! (map-get? user-identities tx-sender) ERR-IDENTITY-NOT-FOUND))
      (updated-claims 
        (if (< (len (get claims current-identity)) u10)
          (append (get claims current-identity) claim)
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

;; Verify a claim (only contract owner can do this)
(define-public (verify-claim (user principal) (claim (string-ascii 200)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    (map-set verified-claims 
      { user: user, claim: claim } 
      true
    )
    
    (ok true)
  )
)

;; Check if a specific claim is verified
(define-read-only (is-claim-verified (user principal) (claim (string-ascii 200)))
  (default-to false 
    (map-get? verified-claims { user: user, claim: claim })
  )
)

;; Get user identity details
(define-read-only (get-identity (user principal))
  (map-get? user-identities user)
)