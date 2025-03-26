// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

error AllowanceIsLesserThanRequired(uint256 allowed, uint256 required);
error TokenNotAllowed(address token);
error UnauthorizedCaller();

/**
 * @title ProjectLedgerMVP
 * @notice A minimal, gas–efficient contract for a project-management MVP,
 *         updated to allow a user to be both Company and Freelancer.
 *
 * Key changes:
 *  1) Roles: Unregistered, Company, Freelancer, Both.
 *  2) Deterministic IDs for projects/submissions via hashing a nonce.
 *  3) projectId and submissionId stored directly in their structs.
 *  4) Each user also stores an ENS string; likewise, each Project/Submission
 *     stores the relevant ENS for quick lookups.
 *  5) A token whitelist enforced in createProject(...).
 *  6) Executor can act on behalf of users with walletAddress parameter
 */
contract ProjectLedgerMVP {
    // ------------------------------------------------------------------------
    // Data Structures
    // ------------------------------------------------------------------------
    
    enum Role {
        Unregistered, // 0
        Company,      // 1
        Freelancer,   // 2
        Both          // 3
    }
    
    // Tracks each user's role. 
    struct UserData {
        Role role;
    }

    // Each project references its ID, the owner's wallet, the reward token, etc.
    struct Project {
        bytes32 projectId;
        address projectOwner;
        address token;        // The ERC-20 token address used for rewards
        uint256 totalReward;  // Amount of token locked for rewarding completion
        bool    rewardClaimed;
    }

    // Each submission references its ID, the associated project, the freelancer's wallet, etc.
    struct Submission {
        bytes32 submissionId;
        bytes32 projectId;
        address freelancer;
        bool    approved;
        bool    paid;
    }

    // ------------------------------------------------------------------------
    // Storage
    // ------------------------------------------------------------------------

    // Executor (e.g., admin or off-chain oracle) who can finalize approvals if desired
    address public executor;

    // Mapping of user => data
    mapping(address => UserData) public userData;

    // Project storage: projectId => Project struct
    mapping(bytes32 => Project) public projects;

    // Submission storage: submissionId => Submission struct
    mapping(bytes32 => Submission) public submissions;

    // Whitelisted tokens
    mapping(address => bool) public tokenList;

    // Simple internal nonce for pseudo-random ID generation
    uint256 private _nonce;

    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------
    event UserRegistered(address indexed user, Role role);
    event ProjectCreated(bytes32 indexed projectId, address indexed owner, address token, uint256 reward);
    event SubmissionCreated(bytes32 indexed submissionId, bytes32 indexed projectId, address indexed freelancer);
    event SubmissionApproved(bytes32 indexed submissionId, address indexed approver);
    event RewardPayout(bytes32 indexed projectId, bytes32 indexed submissionId, address freelancer, uint256 amount);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _executor) {
        require(_executor != address(0), "Executor cannot be zero");
        executor = _executor;
    }

    // ------------------------------------------------------------------------
    // Authentication Helpers
    // ------------------------------------------------------------------------

    /**
     * @dev Validates if the caller is authorized to act on behalf of the wallet
     * @param wallet The wallet address to verify
     */
    function _isAuthorized(address wallet) internal view returns (bool) {
        return msg.sender == wallet || msg.sender == executor;
    }

    /**
     * @dev Reverts if the caller is not authorized to act on behalf of the wallet
     * @param wallet The wallet address to verify
     */
    function _requireAuthorized(address wallet) internal view {
        if (!_isAuthorized(wallet)) {
            revert UnauthorizedCaller();
        }
    }

    // ------------------------------------------------------------------------
    // Modified Role Checks
    // ------------------------------------------------------------------------
    modifier onlyCompany() {
        Role r = userData[msg.sender].role;
        require(
            r == Role.Company || r == Role.Both,
            "Caller is not a registered company"
        );
        _;
    }

    modifier isCompanyRole(address wallet) {
        Role r = userData[wallet].role;
        require(
            r == Role.Company || r == Role.Both,
            "Wallet is not a registered company"
        );
        _;
    }

    modifier onlyFreelancer() {
        Role r = userData[msg.sender].role;
        require(
            r == Role.Freelancer || r == Role.Both,
            "Caller is not a registered freelancer"
        );
        _;
    }

    modifier isFreelancerRole(address wallet) {
        Role r = userData[wallet].role;
        require(
            r == Role.Freelancer || r == Role.Both,
            "Wallet is not a registered freelancer"
        );
        _;
    }

    modifier onlyExecutorOrEligibleFreelancer(bytes32 projectId) {
        Project storage p = projects[projectId];
        require(
            msg.sender == executor || userData[msg.sender].role >= Role.Freelancer || p.projectOwner != msg.sender,
            "Caller is not a registered executor or freelancer"
        );
        _;
    }

    modifier isEligibleFreelancer(address wallet, bytes32 projectId) {
        Project storage p = projects[projectId];
        require(
            userData[wallet].role >= Role.Freelancer || p.projectOwner != wallet,
            "Wallet is not an eligible freelancer"
        );
        _;
    }

    /**
     * @dev Approvals can be done by the global executor or by the project's owner.
     */
    modifier onlyExecutorOrOwner(bytes32 _projectId) {
        Project storage p = projects[_projectId];
        require(
            msg.sender == executor || msg.sender == p.projectOwner,
            "Not authorized to approve"
        );
        _;
    }

    /**
     * @dev Only the executor can manage the token whitelist in this simple example.
     *      You could define a separate admin or expand roles as needed.
     */
    modifier onlyExecutor() {
        require(msg.sender == executor, "Only executor can manage token list");
        _;
    }

    // ------------------------------------------------------------------------
    // Registration
    // ------------------------------------------------------------------------

    /**
     * @notice Register caller as a company
     */
    function registerAsCompany() external {
        _registerAsCompany(msg.sender);
    }

    /**
     * @notice Register a wallet as a company (executor only)
     * @param walletAddress The wallet to register
     */
    function registerAsCompanyFor(address walletAddress) external {
        _requireAuthorized(walletAddress);
        _registerAsCompany(walletAddress);
    }

    /**
     * @notice Internal function to register a wallet as a company
     * @param walletAddress The wallet to register
     */
    function _registerAsCompany(address walletAddress) internal {
        UserData storage user = userData[walletAddress];
        if (user.role == Role.Unregistered) {
            user.role = Role.Company;
        } else if (user.role == Role.Freelancer) {
            user.role = Role.Both;
        } else if (user.role == Role.Company || user.role == Role.Both) {
            revert("Already registered as Company or Both");
        }
        emit UserRegistered(walletAddress, user.role);
    }

    /**
     * @notice Register caller as a freelancer
     */
    function registerAsFreelancer() external {
        _registerAsFreelancer(msg.sender);
    }

    /**
     * @notice Register a wallet as a freelancer (executor only)
     * @param walletAddress The wallet to register
     */
    function registerAsFreelancerFor(address walletAddress) external {
        _requireAuthorized(walletAddress);
        _registerAsFreelancer(walletAddress);
    }

    /**
     * @notice Internal function to register a wallet as a freelancer
     * @param walletAddress The wallet to register
     */
    function _registerAsFreelancer(address walletAddress) internal {
        UserData storage user = userData[walletAddress];
        if (user.role == Role.Unregistered) {
            user.role = Role.Freelancer;
        } else if (user.role == Role.Company) {
            user.role = Role.Both;
        } else if (user.role == Role.Freelancer || user.role == Role.Both) {
            revert("Already registered as Freelancer or Both");
        }
        emit UserRegistered(walletAddress, user.role);
    }

    // ------------------------------------------------------------------------
    // Whitelisted Tokens Management
    // ------------------------------------------------------------------------

    function setTokenAllowed(address _token, bool _status) external onlyExecutor {
        tokenList[_token] = _status;
    }

    // ------------------------------------------------------------------------
    // Project Creation (Company)
    // ------------------------------------------------------------------------
    
    /**
     * @notice Create a project using the caller's wallet
     */
    function createProject(address _token, uint256 _totalReward)
        external
        onlyCompany
        returns (bytes32 projectId)
    {
        return _createProject(msg.sender, _token, _totalReward);
    }

    /**
     * @notice Create a project on behalf of a wallet (executor only)
     * @param walletAddress The wallet to create the project for
     */
    function createProjectFor(address walletAddress, address _token, uint256 _totalReward)
        external
        isCompanyRole(walletAddress)
        returns (bytes32 projectId)
    {
        _requireAuthorized(walletAddress);
        return _createProject(walletAddress, _token, _totalReward);
    }

    /**
     * @notice Internal function to create a project
     * @param walletAddress The wallet to create the project for
     */
    function _createProject(address walletAddress, address _token, uint256 _totalReward)
        internal
        returns (bytes32 projectId)
    {
        require(_token != address(0), "Invalid token address");
        require(_totalReward > 0, "Reward must be > 0");

        // Check if this token is whitelisted
        if (!tokenList[_token]) {
            revert TokenNotAllowed(_token);
        }

        // Check allowance before we do transferFrom
        uint256 allowed = IERC20(_token).allowance(walletAddress, address(this));
        if (allowed < _totalReward) {
            revert AllowanceIsLesserThanRequired(allowed, _totalReward);
        }

        // 1) Generate a pseudo-random ID
        projectId = _generateProjectId(walletAddress);

        // 2) Transfer the reward from the company to this contract
        bool success = IERC20(_token).transferFrom(
            walletAddress,
            address(this),
            _totalReward
        );
        require(success, "ERC20 transferFrom failed (check allowance)");

        // 3) Initialize project data
        Project storage p = projects[projectId];
        p.projectId       = projectId;
        p.projectOwner    = walletAddress;
        p.token           = _token;
        p.totalReward     = _totalReward;
        p.rewardClaimed   = false;

        emit ProjectCreated(projectId, walletAddress, _token, _totalReward);
    }

    // ------------------------------------------------------------------------
    // Task Submission (Freelancer)
    // ------------------------------------------------------------------------
    
    /**
     * @notice Create a submission using the caller's wallet
     */
    function createSubmission(bytes32 _projectId)
        external
        onlyExecutorOrEligibleFreelancer(_projectId)
        returns (bytes32 submissionId)
    {
        return _createSubmission(msg.sender, _projectId);
    }

    /**
     * @notice Create a submission on behalf of a wallet (executor only)
     * @param walletAddress The wallet to create the submission for
     */
    function createSubmissionFor(address walletAddress, bytes32 _projectId)
        external
        isEligibleFreelancer(walletAddress, _projectId)
        returns (bytes32 submissionId)
    {
        _requireAuthorized(walletAddress);
        return _createSubmission(walletAddress, _projectId);
    }

    /**
     * @notice Internal function to create a submission
     * @param walletAddress The wallet to create the submission for
     */
    function _createSubmission(address walletAddress, bytes32 _projectId)
        internal
        returns (bytes32 submissionId)
    {
        Project storage p = projects[_projectId];
        require(p.projectOwner != address(0), "Project does not exist");

        // Generate a pseudo-random submission ID
        submissionId = _generateSubmissionId(walletAddress);

        // Store submission data
        Submission storage s = submissions[submissionId];
        require(s.freelancer == address(0), "SubmissionId collision");

        s.submissionId   = submissionId;
        s.projectId      = _projectId;
        s.freelancer     = walletAddress;
        s.approved       = false;
        s.paid           = false;

        emit SubmissionCreated(submissionId, _projectId, walletAddress);
    }

    // ------------------------------------------------------------------------
    // Approval Flow & Reward Distribution
    // ------------------------------------------------------------------------
    
    /**
     * @notice Approve a submission using the caller's wallet
     */
    function approveSubmission(bytes32 _submissionId)
        external
        onlyExecutorOrOwner(submissions[_submissionId].projectId)
        returns (bool)
    {
        return _approveSubmission(msg.sender, _submissionId);
    }

    /**
     * @notice Approve a submission on behalf of a wallet (executor only)
     * @param walletAddress The wallet to approve the submission for
     */
    function approveSubmissionFor(address walletAddress, bytes32 _submissionId)
        external
        returns (bool)
    {
        bytes32 projectId = submissions[_submissionId].projectId;
        Project storage p = projects[projectId];
        
        // Check that the wallet is the owner or executor
        require(
            walletAddress == p.projectOwner || msg.sender == executor,
            "Not authorized to approve"
        );
        
        _requireAuthorized(walletAddress);
        return _approveSubmission(walletAddress, _submissionId);
    }

    /**
     * @notice Internal function to approve a submission
     * @param approver The wallet approving the submission
     */
    function _approveSubmission(address approver, bytes32 _submissionId)
        internal
        returns (bool)
    {
        Submission storage s = submissions[_submissionId];
        require(s.freelancer != address(0), "Submission not found");
        require(!s.approved, "Already approved");
        require(!s.paid, "Already paid");

        s.approved = true;
        emit SubmissionApproved(_submissionId, approver);

        // Transfer reward to the freelancer
        Project storage p = projects[s.projectId];
        require(!p.rewardClaimed, "Reward already claimed for this project");
        p.rewardClaimed = true;

        uint256 rewardAmount = p.totalReward;
        require(
            IERC20(p.token).transfer(s.freelancer, rewardAmount),
            "Reward transfer failed"
        );

        s.paid = true;
        emit RewardPayout(s.projectId, _submissionId, s.freelancer, rewardAmount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Internal ID Generation
    // ------------------------------------------------------------------------
    function _generateProjectId(address _creator) internal returns (bytes32) {
        _nonce++;
        return keccak256(abi.encodePacked(_creator, block.timestamp, block.number, _nonce));
    }

    function _generateSubmissionId(address _freelancer) internal returns (bytes32) {
        _nonce++;
        return keccak256(abi.encodePacked(_freelancer, block.timestamp, block.number, _nonce));
    }

    // ------------------------------------------------------------------------
    // View Helpers
    // ------------------------------------------------------------------------
    function isCompany(address _user) external view returns (bool) {
        Role r = userData[_user].role;
        return (r == Role.Company || r == Role.Both);
    }

    function isFreelancer(address _user) external view returns (bool) {
        Role r = userData[_user].role;
        return (r == Role.Freelancer || r == Role.Both);
    }
}
