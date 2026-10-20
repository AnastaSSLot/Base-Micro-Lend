// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract OmniMicroLendHub {
    struct Loan {
        address payable borrower;
        address payable lender;
        uint256 principalWei;
        uint256 repaymentWei;
        bool isActive;
        bool isFunded;
        bytes32 purposeHash;
    }

    address payable public immutable hubAdmin;
    string public hubDescriptor;
    uint256 public platformFeeBps; // 250 = 2.5%
    uint256 public loanCounter;
    uint256 public accumulatedFees;
    bool public isHubHalted;

    mapping(uint256 => Loan) public loans;

    event LoanRequested(uint256 indexed loanId, address indexed borrower, uint256 principal, uint256 repayment);
    event LoanCanceled(uint256 indexed loanId);
    event TreasuryDeposited(address indexed funder, uint256 amount);
    event ReservesDrained(address indexed admin, uint256 amount);
    event LoanFunded(uint256 indexed loanId, address indexed lender, uint256 amount);
    event FeesGathered(address indexed admin, uint256 amount);
    event HubHaltToggled(bool isHalted);
    event LoanRepaid(uint256 indexed loanId, address indexed borrower, uint256 totalRepaid);
    event DescriptorUpdated(string newDescriptor);

    modifier onlyAdmin() {
        require(msg.sender == hubAdmin, "OmniLend: Access denied");
        _;
    }

    modifier whenNotHalted() {
        require(!isHubHalted, "OmniLend: Hub is halted");
        _;
    }

    constructor() {
        hubAdmin = payable(msg.sender);
        hubDescriptor = "Omni Base Micro-Lending Hub v1";
        platformFeeBps = 250; // 2.5%
        isHubHalted = false;
    }

    // 1. cancelLoanRequest
    function cancelLoanRequest(uint256 loanId) external {
        Loan storage l = loans[loanId];
        require(loanId > 0 && loanId <= loanCounter, "OmniLend: Invalid ID");
        require(msg.sender == l.borrower || msg.sender == hubAdmin, "OmniLend: Unauthorized");
        require(l.isActive && !l.isFunded, "OmniLend: Cannot cancel now");

        l.isActive = false;
        emit LoanCanceled(loanId);
    }

    // 2. depositPlatformTreasury
    function depositPlatformTreasury() external payable whenNotHalted {
        require(msg.value > 0, "OmniLend: Zero deposit");
        accumulatedFees += msg.value;
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    // 3. drainPlatformReserves
    function drainPlatformReserves() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "OmniLend: Zero balance");

        accumulatedFees = 0;
        (bool sent, ) = hubAdmin.call{value: balance}("");
        require(sent, "OmniLend: Sweep failed");

        emit ReservesDrained(hubAdmin, balance);
    }

    // 4. fundLoanRequest
    function fundLoanRequest(uint256 loanId) external payable whenNotHalted {
        Loan storage l = loans[loanId];
        require(loanId > 0 && loanId <= loanCounter, "OmniLend: Invalid ID");
        require(l.isActive && !l.isFunded, "OmniLend: Not available for funding");
        require(msg.value == l.principalWei, "OmniLend: Incorrect funding amount");

        l.isFunded = true;
        l.lender = payable(msg.sender);

        (bool sent, ) = l.borrower.call{value: msg.value}("");
        require(sent, "OmniLend: Transfer to borrower failed");

        emit LoanFunded(loanId, msg.sender, msg.value);
    }

    // 5. gatherPlatformFees
    function gatherPlatformFees() external onlyAdmin {
        uint256 amount = accumulatedFees;
        require(amount > 0, "OmniLend: Zero fees");

        accumulatedFees = 0;
        (bool sent, ) = hubAdmin.call{value: amount}("");
        require(sent, "OmniLend: Harvest failed");

        emit FeesGathered(hubAdmin, amount);
    }

    // 6. haltLendingHub
    function haltLendingHub(bool isHalted) external onlyAdmin {
        isHubHalted = isHalted;
        emit HubHaltToggled(isHalted);
    }

    // 7. repayActiveLoan
    function repayActiveLoan(uint256 loanId) external payable whenNotHalted {
        Loan storage l = loans[loanId];
        require(loanId > 0 && loanId <= loanCounter, "OmniLend: Invalid ID");
        require(l.isActive && l.isFunded, "OmniLend: Not an active funded loan");
        require(msg.value >= l.repaymentWei, "OmniLend: Insufficient repayment");

        l.isActive = false; // Кредит закрыт

        uint256 fee = (msg.value * platformFeeBps) / 10000;
        uint256 lenderShare = msg.value - fee;

        accumulatedFees += fee;

        (bool sent, ) = l.lender.call{value: lenderShare}("");
        require(sent, "OmniLend: Payout to lender failed");

        emit LoanRepaid(loanId, msg.sender, msg.value);
    }

    // 8. requestNewLoan
    function requestNewLoan(uint256 principalWei, uint256 repaymentWei, bytes32 purposeHash) external whenNotHalted returns (uint256) {
        require(principalWei > 0, "OmniLend: Zero principal");
        require(repaymentWei > principalWei, "OmniLend: Repayment must exceed principal");

        loanCounter++;
        loans[loanCounter] = Loan({
            borrower: payable(msg.sender),
            lender: payable(address(0)),
            principalWei: principalWei,
            repaymentWei: repaymentWei,
            isActive: true,
            isFunded: false,
            purposeHash: purposeHash
        });

        emit LoanRequested(loanCounter, msg.sender, principalWei, repaymentWei);
        return loanCounter;
    }

    // 9. updateHubDescriptor
    function updateHubDescriptor(string calldata newDescriptor) external onlyAdmin {
        require(bytes(newDescriptor).length > 0, "OmniLend: Empty string");
        hubDescriptor = newDescriptor;
        emit DescriptorUpdated(newDescriptor);
    }
}