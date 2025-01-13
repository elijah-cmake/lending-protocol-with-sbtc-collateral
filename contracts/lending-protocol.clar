;; Title: sBTC Secure Lending Protocol
;;
;; Summary: A robust decentralized lending protocol enabling sBTC-collateralized loans
;;
;; Description: This protocol implements a secure lending platform where users can:
;;  - Deposit sBTC as collateral
;;  - Borrow against their collateral at dynamic interest rates
;;  - Maintain healthy collateral ratios to avoid liquidation
;;  - Participate in liquidations for undercollateralized positions
;;  Features include automated interest calculations, liquidation thresholds,
;;  and comprehensive safety mechanisms.


;; Define SIP-010 Trait
(define-trait sip-010-trait
    (
        ;; Transfer from the caller to a new principal
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))
        ;; The human-readable name of the token
        (get-name () (response (string-ascii 32) uint))
        ;; The symbol or "ticker" for this token
        (get-symbol () (response (string-ascii 32) uint))
        ;; The number of decimals used
        (get-decimals () (response uint uint))
        ;; The balance of the passed principal
        (get-balance (principal) (response uint uint))
        ;; The current total supply (which does not need to be a constant)
        (get-total-supply () (response uint uint))
        ;; Optional URI for token metadata
        (get-token-uri () (response (optional (string-utf8 256)) uint))
    )
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-insufficient-collateral (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-already-initialized (err u104))
(define-constant err-not-liquidatable (err u105))
(define-constant err-invalid-amount (err u106))
(define-constant err-transfer-failed (err u107))

;; Liquidation threshold (150%)
(define-constant liquidation-threshold u150)
;; Minimum collateral ratio (200%)
(define-constant min-collateral-ratio u200)
;; Interest rate base (5% APR)
(define-constant interest-rate-base u50000) ;; 5.0000%

;; Data Maps
(define-map user-deposits
    principal
    {
        sbtc-balance: uint,
        borrowed-amount: uint,
        last-interest-update: uint
    }
)

(define-map protocol-state
    {version: (string-ascii 10)}
    {
        total-deposits: uint,
        total-borrows: uint,
        cumulative-interest-rate: uint,
        last-update-block: uint
    }
)

;; Data Variables
(define-data-var protocol-paused bool false)
(define-data-var interest-rate uint interest-rate-base)
(define-data-var sbtc-token (optional principal) none)

;; Private Functions

(define-private (calculate-interest (amount uint) (blocks uint))
    (let (
        (interest-per-block (/ (var-get interest-rate) u525600)) ;; Assuming 1 block per minute
        (interest-multiplier (+ u100000000 (* interest-per-block blocks)))
    )
        (/ (* amount interest-multiplier) u100000000)
    )
)

(define-private (get-collateral-ratio (user principal))
    (let (
        (user-data (unwrap! (map-get? user-deposits user) (err u0)))
        (sbtc-value (* (get sbtc-balance user-data) u100))
        (borrowed (get borrowed-amount user-data))
    )
        (if (is-eq borrowed u0)
            (ok u0)
            (ok (/ sbtc-value borrowed))
        )
    )
)

(define-private (update-user-interest (user principal))
    (let (
        (user-data (unwrap! (map-get? user-deposits user) (err u0)))
        (current-block block-height)
        (blocks-passed (- current-block (get last-interest-update user-data)))
        (updated-borrow-amount (calculate-interest (get borrowed-amount user-data) blocks-passed))
    )
        (map-set user-deposits
            user
            (merge user-data {
                borrowed-amount: updated-borrow-amount,
                last-interest-update: current-block
            })
        )
        (ok updated-borrow-amount)
    )
)

;; Public Functions

;; Initialize protocol state and set sBTC token contract
(define-public (initialize (sbtc-contract <sip-010-trait>))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-none (map-get? protocol-state {version: "1.0.0"})) err-already-initialized)
        
        ;; Set sBTC contract
        (var-set sbtc-token (some (contract-of sbtc-contract)))
        
        (map-set protocol-state
            {version: "1.0.0"}
            {
                total-deposits: u0,
                total-borrows: u0,
                cumulative-interest-rate: interest-rate-base,
                last-update-block: block-height
            }
        )
        (ok true)
    )
)

;; Deposit sBTC as collateral
(define-public (deposit-collateral (sbtc-contract <sip-010-trait>) (amount uint))
    (let (
        (current-deposit (default-to {sbtc-balance: u0, borrowed-amount: u0, last-interest-update: block-height}
            (map-get? user-deposits tx-sender)))
    )
        (asserts! (not (var-get protocol-paused)) err-unauthorized)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (is-some (var-get sbtc-token)) err-unauthorized)
        (asserts! (is-eq (contract-of sbtc-contract) (unwrap! (var-get sbtc-token) err-unauthorized))
            err-unauthorized)
        
        ;; Transfer sBTC to contract
        (try! (contract-call? sbtc-contract transfer 
            amount 
            tx-sender 
            (as-contract tx-sender) 
            none))
        
        ;; Update user deposits
        (map-set user-deposits
            tx-sender
            (merge current-deposit {
                sbtc-balance: (+ (get sbtc-balance current-deposit) amount)
            })
        )
        
        ;; Update protocol state
        (let ((protocol-data (unwrap! (map-get? protocol-state {version: "1.0.0"}) err-unauthorized)))
            (map-set protocol-state
                {version: "1.0.0"}
                (merge protocol-data {
                    total-deposits: (+ (get total-deposits protocol-data) amount)
                })
            )
        )
        
        (ok true)
    )
)