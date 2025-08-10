;; Implement SIP-010 fungible token trait
(impl-trait 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sip-010-trait-ft-standard.sip-010-trait)

;; Define the token
(define-fungible-token warung-token)

;; Constants - ALL DEFINED HERE
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-insufficient-balance (err u102))

;; Token metadata
(define-constant token-name "Warung Swap")
(define-constant token-symbol "WSW")
(define-constant token-decimals u6)
(define-constant token-uri u"https://workshop.blockdev.id/token.json")

;; Data variables for tracking
(define-data-var total-minted uint u0)
(define-data-var total-burned uint u0)

;; Maps for tracking user activities
(define-map user-mint-count principal uint)
(define-map user-burn-count principal uint)

;; SIP-010 required functions
(define-read-only (get-name)
  (ok token-name)
)

(define-read-only (get-symbol)
  (ok token-symbol)
)

(define-read-only (get-decimals)
  (ok token-decimals)
)

(define-read-only (get-balance (user principal))
  (ok (ft-get-balance warung-token user))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply warung-token))
)

(define-read-only (get-token-uri)
  (ok (some token-uri))
)

;; SIP-010 transfer function
(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq from tx-sender) err-not-token-owner)
    (try! (ft-transfer? warung-token amount from to))
    (print memo)
    (ok true)
  )
)

;; Mint function (owner only)
(define-public (mint (amount uint) (to principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    ;; Update tracking variables
    (var-set total-minted (+ (var-get total-minted) amount))
    (map-set user-mint-count to (+ (default-to u0 (map-get? user-mint-count to)) amount))
    
    ;; Mint the tokens
    (try! (ft-mint? warung-token amount to))
    (ok true)
  )
)

;; Burn function (owner only)
(define-public (burn-owner (amount uint) (from principal))
  (begin
    ;; Check that the caller is the contract owner
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    ;; Check sufficient balance
    (asserts! (>= (ft-get-balance warung-token from) amount) err-insufficient-balance)
    
    ;; Update tracking variables
    (var-set total-burned (+ (var-get total-burned) amount))
    (map-set user-burn-count from (+ (default-to u0 (map-get? user-burn-count from)) amount))
    
    ;; Burn the tokens
    (try! (ft-burn? warung-token amount from))
    (ok true)
  )
)

;; Read-only functions for tracking
(define-read-only (get-total-minted)
  (ok (var-get total-minted))
)

(define-read-only (get-total-burned)
  (ok (var-get total-burned))
)

(define-read-only (get-user-mint-count (user principal))
  (ok (default-to u0 (map-get? user-mint-count user)))
)

(define-read-only (get-user-burn-count (user principal))
  (ok (default-to u0 (map-get? user-burn-count user)))
)

;; Get net supply (total minted - total burned)
(define-read-only (get-net-supply)
  (ok (- (var-get total-minted) (var-get total-burned)))
)