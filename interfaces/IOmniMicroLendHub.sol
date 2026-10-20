// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface IOmniMicroLendHub {
    function requestNewLoan(uint256 principalWei, uint256 repaymentWei, bytes32 purposeHash) external returns (uint256);
    function fundLoanRequest(uint256 loanId) external payable;
    function repayActiveLoan(uint256 loanId) external payable;
}
