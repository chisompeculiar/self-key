;; Selfkey: Decentralized Identity Management Contract

(define-map user-identities 
  { user-principal: principal }
  {
    name: (optional string-ascii 100),
    email: (optional string-ascii 100),
    age-verified: bool,
    attributes: (list 10 (string-ascii 50))
  }
)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-IDENTITY-NOT-FOUND (err u101))

;; Create or update user identity
(define-public (create-or-update-identity 
  (name (optional string-ascii 100))
  (email (optional string-ascii 100))
  (age-verified bool)
  (attributes (list 10 (string-ascii 50)))
)
  (begin
    (map-set user-identities 
      { user-principal: tx-sender }
      {
        name: name,
        email: email,
        age-verified: age-verified,
        attributes: attributes
      }
    )
    (ok true)
  )
)

;; Retrieve user identity (with selective disclosure)
(define-read-only (get-identity-attributes 
  (user principal)
  (requested-attributes (list 5 (string-ascii 50)))
)
  (match (map-get? user-identities { user-principal: user })
    identity (filter-attributes identity requested-attributes)
    (err ERR-IDENTITY-NOT-FOUND)
  )
)

;; Helper function to filter attributes
(define-private (filter-attributes 
  (identity { 
    name: (optional string-ascii 100), 
    email: (optional string-ascii 100), 
    age-verified: bool, 
    attributes: (list 10 (string-ascii 50)) 
  })
  (requested-attributes (list 5 (string-ascii 50)))
)
  (let 
    (
      (filtered-attributes 
        (filter 
          (lambda (attr) (contains attr requested-attributes)) 
          (get attributes identity)
        )
      )
    )
    {
      name: (get name identity),
      email: (get email identity),
      age-verified: (get age-verified identity),
      attributes: filtered-attributes
    }
  )
)

;; Verify age
(define-public (verify-age (is-of-age bool))
  (begin
    (map-set user-identities 
      { user-principal: tx-sender }
      (merge 
        (unwrap! (map-get? user-identities { user-principal: tx-sender }) ERR-IDENTITY-NOT-FOUND)
        { age-verified: is-of-age }
      )
    )
    (ok true)
  )
)