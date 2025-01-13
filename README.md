# sBTC Secure Lending Protocol

A robust decentralized lending protocol enabling secure sBTC-collateralized loans on the Stacks blockchain.

## Overview

The sBTC Secure Lending Protocol is a decentralized finance (DeFi) smart contract that enables users to:

- Deposit sBTC as collateral
- Borrow against their collateral at dynamic interest rates
- Maintain healthy collateral ratios to avoid liquidation
- Participate in liquidations for undercollateralized positions

## Key Features

### Collateralization and Borrowing

- Minimum collateral ratio: 200%
- Liquidation threshold: 150%
- Base interest rate: 5% APR (adjustable by protocol owner)
- Dynamic interest calculation based on time elapsed
- Automated interest accrual

### Safety Mechanisms

- Protocol pause functionality for emergencies
- Strict collateral ratio enforcement
- Automated liquidation process
- Owner-only administrative functions
- SIP-010 token standard compliance

## Smart Contract Functions

### User Operations

#### Deposit Collateral

```clarity
(deposit-collateral (sbtc-contract <sip-010-trait>) (amount uint))
```

Allows users to deposit sBTC as collateral into the protocol.

#### Withdraw Collateral

```clarity
(withdraw-collateral (sbtc-contract <sip-010-trait>) (amount uint))
```

Enables users to withdraw their deposited collateral if maintaining required ratios.

#### Borrow

```clarity
(borrow (amount uint))
```

Permits users to borrow against their deposited collateral while maintaining minimum collateral ratio.

#### Repay

```clarity
(repay (sbtc-contract <sip-010-trait>) (amount uint))
```

Allows users to repay their borrowed amounts.

### Liquidation

```clarity
(liquidate (sbtc-contract <sip-010-trait>) (user principal))
```

Enables liquidators to liquidate positions below the liquidation threshold:

- Liquidation bonus: 10% of collateral
- Automatic debt settlement
- Collateral transfer to liquidator

### Read-Only Functions

- `get-user-position`: Retrieve user's current position
- `get-protocol-metrics`: Get protocol-wide statistics
- `get-current-interest-rate`: View current interest rate
- `get-sbtc-token`: Get sBTC token contract address

### Administrative Functions

- `set-interest-rate`: Adjust protocol interest rate (owner only)
- `toggle-protocol-pause`: Emergency pause/unpause protocol (owner only)

## Error Codes

| Code | Description               |
| ---- | ------------------------- |
| u100 | Owner-only operation      |
| u101 | Insufficient balance      |
| u102 | Insufficient collateral   |
| u103 | Unauthorized operation    |
| u104 | Already initialized       |
| u105 | Position not liquidatable |
| u106 | Invalid amount            |
| u107 | Transfer failed           |

## Protocol Parameters

- **Liquidation Threshold**: 150% - positions below this ratio can be liquidated
- **Minimum Collateral Ratio**: 200% - required ratio for borrowing
- **Base Interest Rate**: 5% APR (50000 basis points)
- **Maximum Interest Rate**: 100% APR (1,000,000 basis points)

## Security Features

1. **Access Control**

   - Owner-only administrative functions
   - Validated sBTC contract principal
   - Protected initialization process

2. **Safety Checks**

   - Collateral ratio validation
   - Balance verification
   - Amount validation
   - Protocol state checks

3. **Interest Calculation**
   - Block-based interest accrual
   - Automatic interest updates before key operations
   - Protected interest rate bounds

## Protocol State Management

The protocol maintains state through several data structures:

1. **User Deposits Map**

   ```clarity
   {
     sbtc-balance: uint,
     borrowed-amount: uint,
     last-interest-update: uint
   }
   ```

2. **Protocol State Map**
   ```clarity
   {
     total-deposits: uint,
     total-borrows: uint,
     cumulative-interest-rate: uint,
     last-update-block: uint
   }
   ```

## Best Practices for Users

1. **Maintaining Healthy Collateral Ratio**

   - Keep collateral ratio well above 200%
   - Monitor market conditions
   - Add collateral proactively

2. **Avoiding Liquidation**

   - Watch for position health
   - Repay loans or add collateral when near threshold
   - Consider market volatility

3. **Efficient Borrowing**
   - Borrow only what's needed
   - Maintain buffer for market movements
   - Plan repayment strategy

## Liquidator Guidelines

1. **Monitoring Opportunities**

   - Watch for positions below 150% collateral ratio
   - Ensure sufficient sBTC for liquidation
   - Act quickly on liquidatable positions

2. **Liquidation Process**
   - Verify position is liquidatable
   - Have full debt amount ready
   - Receive collateral plus 10% bonus

## Technical Integration

### Contract Initialization

```clarity
(initialize (sbtc-contract <sip-010-trait>))
```

Must be called by contract owner with valid sBTC contract principal.

### Error Handling

- All functions return (response) types
- Check error codes for failure cases
- Handle transfer failures appropriately

## Security Considerations

1. **Smart Contract Risks**

   - Interest rate manipulation
   - Flash loan attacks
   - Price oracle dependencies

2. **User Risks**

   - Liquidation risk
   - Interest rate changes
   - Protocol pause impact

3. **System Risks**
   - Market volatility
   - Network congestion
   - Contract upgrades

## Contributing

For contributions, please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description
