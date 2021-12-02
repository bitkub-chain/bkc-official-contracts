// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IKToken.sol


pragma solidity ^0.8.0;

interface IKToken {
    function internalTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function externalTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


// File contracts/abstracts/Blacklist.sol


pragma solidity ^0.8.0;

abstract contract Blacklist {
    mapping(address => bool) public blacklist;

    event AddBlacklist(address indexed account, address indexed caller);

    event RevokeBlacklist(address indexed account, address indexed caller);

    modifier notInBlacklist(address account) {
        require(!blacklist[account], "Address is in blacklist");
        _;
    }

    modifier inBlacklist(address account) {
        require(blacklist[account], "Address is not in blacklist");
        _;
    }

    function _addBlacklist(address account) internal virtual notInBlacklist(account) {
        blacklist[account] = true;
        emit AddBlacklist(account, msg.sender);
    }

    function _revokeBlacklist(address account) internal virtual inBlacklist(account) {
        blacklist[account] = false;
        emit RevokeBlacklist(account, msg.sender);
    }
}


// File contracts/abstracts/Pauseable.sol


pragma solidity ^0.8.0;

abstract contract Pauseable {
    event Paused(address account);

    event Unpaused(address account);

    bool public paused;

    constructor() {
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused, "Pauseable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pauseable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
}


// File contracts/abstracts/Authorization.sol


pragma solidity ^0.8.0;

abstract contract Authorization {
    address public committee;
    address public admin;

    event SetAdmin(address indexed oldAdmin, address indexed newAdmin, address indexed caller);
    event SetCommittee(address indexed oldCommittee, address indexed newCommittee, address indexed caller);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Restricted only admin");
        _;
    }

    modifier onlyCommittee() {
        require(msg.sender == committee, "Restricted only committee");
        _;
    }

    modifier onlyAdminOrCommittee() {
        require(msg.sender == committee || msg.sender == admin, "Restricted only committee or admin");
        _;
    }

    function setAdmin(address _admin) external onlyCommittee {
        emit SetAdmin(admin, _admin, msg.sender);
        admin = _admin;
    }

    function setCommittee(address _committee) external onlyCommittee {
        emit SetCommittee(committee, _committee, msg.sender);
        committee = _committee;
    }
}


// File contracts/interfaces/IKYCBitkubChain.sol


pragma solidity ^0.8.0;

interface IKYCBitkubChain {
    function kycsLevel(address _addr) external view returns (uint256);
}


// File contracts/abstracts/KYCHandler.sol


pragma solidity ^0.8.0;

abstract contract KYCHandler {
    IKYCBitkubChain public kyc;

    uint256 public acceptedKycLevel;
    bool public isActivatedOnlyKycAddress;

    function _activateOnlyKycAddress() internal virtual {
        isActivatedOnlyKycAddress = true;
    }

    function _setKYC(IKYCBitkubChain _kyc) internal virtual {
        kyc = _kyc;
    }

    function _setAcceptedKycLevel(uint256 _kycLevel) internal virtual {
        acceptedKycLevel = _kycLevel;
    }
}


// File contracts/interfaces/IKAP20.sol


pragma solidity ^0.8.0;

interface IKAP20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowances(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function adminTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/token/KAP20.sol


pragma solidity ^0.8.0;






contract KAP20 is IKAP20, KYCHandler, Pauseable, Authorization, Blacklist {
    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) public override allowances;

    uint256 public override totalSupply;

    string public override name;
    string public override symbol;
    uint8 public override decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _admin,
        address _committee,
        IKYCBitkubChain _kyc,
        uint256 _acceptedKycLevel
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        kyc = _kyc;
        acceptedKycLevel = _acceptedKycLevel;
        admin = _admin;
        committee = _committee;
    }

    /**
     * @dev See {IKAP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IKAP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        notInBlacklist(msg.sender)
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IKAP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        notInBlacklist(msg.sender)
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused notInBlacklist(sender) notInBlacklist(recipient) returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "KAP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "KAP20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "KAP20: transfer from the zero address");
        require(recipient != address(0), "KAP20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "KAP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "KAP20: mint to the zero address");

        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "KAP20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "KAP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "KAP20: approve from the zero address");
        require(spender != address(0), "KAP20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function adminTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) public override onlyCommittee returns (bool) {
        require(_balances[sender] >= amount, "KAP20: transfer amount exceed balance");
        require(recipient != address(0), "KAP20: transfer to zero address");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);

        return true;
    }

    function pause() public onlyCommittee {
        _pause();
    }

    function unpause() public onlyCommittee {
        _unpause();
    }

    function addBlacklist(address account) public onlyCommittee {
        _addBlacklist(account);
    }

    function revokeBlacklist(address account) public onlyCommittee {
        _revokeBlacklist(account);
    }

    function activateOnlyKycAddress() public onlyCommittee {
        _activateOnlyKycAddress();
    }

    function setKYC(IKYCBitkubChain _kyc) public onlyCommittee {
        _setKYC(_kyc);
    }

    function setAcceptedKycLevel(uint256 _kycLevel) public onlyCommittee {
        _setAcceptedKycLevel(_kycLevel);
    }
}


// File contracts/KBTC.sol


pragma solidity ^0.8.0;



contract KBTC is KAP20, IKToken {
    constructor(
        address admin,
        address committee,
        IKYCBitkubChain kyc,
        uint256 acceptedKycLevel
    ) KAP20("Bitkub-Peg BTC", "KBTC", 18, admin, committee, kyc, acceptedKycLevel) {
        _mint(0x6002Bd66c5DA67b812CCAaB16716dBF57BD2aA18, 50 ether);
    }

    function internalTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external override whenNotPaused onlyAdmin returns (bool) {
        require(
            kyc.kycsLevel(sender) >= acceptedKycLevel && kyc.kycsLevel(recipient) >= acceptedKycLevel,
            "Only internal purpose"
        );

        _transfer(sender, recipient, amount);
        return true;
    }

    function externalTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external override whenNotPaused onlyAdmin returns (bool) {
        require(kyc.kycsLevel(sender) >= acceptedKycLevel, "Only internal purpose");

        _transfer(sender, recipient, amount);
        return true;
    }

    function mint(address account, uint256 amount) external virtual onlyCommittee returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) external virtual onlyCommittee returns (bool) {
        _burn(account, amount);
        return true;
    }
}