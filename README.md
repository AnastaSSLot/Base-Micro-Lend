# Base Omni Micro-Lend

A decentralized, peer-to-peer micro-lending protocol deployed on the Base L2 network. This hub allows users to request trustless short-term loans and enables liquidity providers to fund these requests, earning predetermined yields upon repayment.

## Core Features
* **Automated Settlement:** The protocol completely eliminates intermediaries. Once a loan is funded, ETH is instantly routed to the borrower. Upon repayment, principal and interest are automatically split between the lender and the platform treasury.
* **State-Locked Lifecycles:** Loan states (Requested, Funded, Repaid, Canceled) are rigorously managed. A borrower cannot cancel a loan once it has been funded, and a lender cannot force early liquidation.
* **Zero-Collateral Tracking:** Designed specifically for uncollateralized reputation-based micro-loans or integration with external soulbound identity protocols.

## Architecture & Security
Built with Solidity `0.8.37`. Employs the Checks-Effects-Interactions pattern strictly during the `repayActiveLoan` execution to eliminate any possibility of reentrancy when routing funds back to the lender.
