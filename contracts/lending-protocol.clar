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