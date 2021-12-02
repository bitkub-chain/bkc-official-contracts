// SPDX-License-Identifier: 
// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/shared/interfaces/IKAP20/IKAP20.sol

pragma solidity >=0.6.0;

interface IKAP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

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
  ) external returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/shared/interfaces/IKAP20/IKAP20AdminApprove.sol

pragma solidity >=0.6.0;

interface IKAP20AdminApprove is IKAP20 {
  function adminApprove(
    address _owner,
    address _spender,
    uint256 _amount
  ) external returns (bool);
}


// File contracts/shared/interfaces/IKYCBitkubChain.sol

pragma solidity >=0.6.0;

interface IKYCBitkubChain {
  function kycsLevel(address _addr) external view returns (uint256);
}


// File contracts/shared/abstracts/KYCHandler.sol

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


// File contracts/shared/abstracts/Context.sol

pragma solidity ^0.8.0;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}


// File contracts/shared/abstracts/Pausable.sol

pragma solidity ^0.8.0;

abstract contract Pausable is Context {
  event Paused(address account);

  event Unpaused(address account);

  bool private _paused;

  constructor() {
    _paused = false;
  }

  function paused() public view virtual returns (bool) {
    return _paused;
  }

  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}


// File contracts/shared/interfaces/IAdminProjectRouter.sol

pragma solidity >=0.6.0;

interface IAdminProjectRouter {
  function isSuperAdmin(address _addr, string calldata _project) external view returns (bool);

  function isAdmin(address _addr, string calldata _project) external view returns (bool);
}


// File contracts/shared/abstracts/Authorization.sol

pragma solidity >=0.6.0;

abstract contract Authorization {
  IAdminProjectRouter public adminRouter;
  string public constant PROJECT = "morning-moon";

  modifier onlySuperAdmin() {
    require(adminRouter.isSuperAdmin(msg.sender, PROJECT), "Restricted only super admin");
    _;
  }

  modifier onlyAdmin() {
    require(adminRouter.isAdmin(msg.sender, PROJECT), "Restricted only admin");
    _;
  }

  function setAdmin(address _adminRouter) external onlySuperAdmin {
    adminRouter = IAdminProjectRouter(_adminRouter);
  }
}


// File contracts/shared/abstracts/Blacklist.sol

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


// File contracts/shared/interfaces/IKAP20/IKAP20Committee.sol

pragma solidity >=0.6.0;

interface IKAP20Committee is IKAP20 {
  function committee() external view returns (address);

  function setCommittee(address _committee) external;
}


// File contracts/shared/interfaces/IKAP20/IKAP20KYC.sol

pragma solidity >=0.6.0;

interface IKAP20KYC is IKAP20 {
  function activateOnlyKycAddress() external;

  function setKYC(address _kyc) external;

  function setAcceptedKycLevel(uint256 _kycLevel) external;
}


// File contracts/shared/interfaces/IKToken.sol

pragma solidity >=0.6.0;

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


// File contracts/shared/token/KAP20.sol

pragma solidity ^0.8.0;








contract KAP20 is IKAP20, IKAP20Committee, IKAP20KYC, IKToken, KYCHandler, Pausable, Authorization {
  modifier onlyCommittee() {
    require(msg.sender == committee, "Restricted only committee");
    _;
  }

  modifier onlySuperAdminOrTransferRouter() {
    require(
      adminRouter.isSuperAdmin(msg.sender, PROJECT) || msg.sender == transferRouter,
      "Restricted only super admin or transfer router"
    );
    _;
  }

  mapping(address => uint256) _balances;

  mapping(address => mapping(address => uint256)) internal _allowance;

  uint256 public override totalSupply;

  string public override name;
  string public override symbol;
  uint8 public override decimals;

  address public override committee;
  address public transferRouter;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    address _adminRouter,
    address _committee,
    address _kyc,
    uint256 _acceptedKycLevel,
    address _transferRouter
  ) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    kyc = IKYCBitkubChain(_kyc);
    acceptedKycLevel = _acceptedKycLevel;
    adminRouter = IAdminProjectRouter(_adminRouter);
    committee = _committee;
    transferRouter = _transferRouter;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowance[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override whenNotPaused returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowance[sender][msg.sender];
    require(currentAllowance >= amount, "KAP20: transfer amount exceeds allowance");
    unchecked { _approve(sender, msg.sender, currentAllowance - amount); }

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowance[msg.sender][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowance[msg.sender][spender];
    require(currentAllowance >= subtractedValue, "KAP20: decreased allowance below zero");
    unchecked { _approve(msg.sender, spender, currentAllowance - subtractedValue); }

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
    unchecked { _balances[sender] = senderBalance - amount; }
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
    unchecked { _balances[account] = accountBalance - amount; }
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

    _allowance[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function adminTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override onlyCommittee returns (bool) {
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

  function internalTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external override whenNotPaused onlySuperAdminOrTransferRouter returns (bool) {
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
  ) external override whenNotPaused onlySuperAdminOrTransferRouter returns (bool) {
    require(kyc.kycsLevel(sender) >= acceptedKycLevel, "Only internal purpose");

    _transfer(sender, recipient, amount);
    return true;
  }

  function activateOnlyKycAddress() public override onlyCommittee {
    _activateOnlyKycAddress();
  }

  function setKYC(address _kyc) public override onlyCommittee {
    _setKYC(IKYCBitkubChain(_kyc));
  }

  function setAcceptedKycLevel(uint256 _kycLevel) public override onlyCommittee {
    _setAcceptedKycLevel(_kycLevel);
  }

  function setCommittee(address _committee) external override onlyCommittee {
    committee = _committee;
  }

  function setTransferRouter(address _transferRouter) external onlyCommittee {
    transferRouter = _transferRouter;
  }
}


// File contracts/shared/token/Lumi.sol

pragma solidity ^0.8.0;

contract Lumi is KAP20, IKAP20AdminApprove {
  modifier onlySuperAdminOrAdmin() {
    require(
      adminRouter.isSuperAdmin(msg.sender, PROJECT) || adminRouter.isAdmin(msg.sender, PROJECT),
      "Restricted only super admin or admin"
    );
    _;
  }

  uint256 public constant HARD_CAP = 200_000_000 ether;

  constructor(
    address _adminRouter,
    address _kyc,
    address _committee,
    uint256 _acceptedKycLevel
  ) KAP20("Lumi", "LUMI", 18, _adminRouter, _committee, _kyc, _acceptedKycLevel, address(0)) {}

  ////////////////////////////////////////////////////////////////////////////////
  // KAP20-overriding methods
  // Add HARD_CAP
  function _mint(address _account, uint256 _amount) internal override {
    require(totalSupply + _amount <= HARD_CAP, "KAP20: totalSupply exceeds HARD_CAP");
    KAP20._mint(_account, _amount);
  }

  // Allow transfer to address 0 and anti-bot measure
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    require(sender != address(0), "KAP20: transfer from the zero address");

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "KAP20: transfer amount exceeds balance");
    unchecked { _balances[sender] = senderBalance - amount; }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  // Add whenNotPaused
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal override whenNotPaused {
    KAP20._approve(owner, spender, amount);
  }

  // Allow transfer to address 0
  function adminTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) public override(IKAP20, KAP20) onlyCommittee returns (bool) {
    require(_balances[sender] >= amount, "KAP20: transfer amount exceeds balance");
    _balances[sender] -= amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
    return true;
  }

  ////////////////////////////////////////////////////////////////////////////////

  function mint(address _to, uint256 _amount) external whenNotPaused onlySuperAdmin returns (bool) {
    _mint(_to, _amount);
    return true;
  }

  function burn(uint256 _amount) external whenNotPaused returns (bool) {
    _burn(msg.sender, _amount);
    return true;
  }

  function burnFrom(address _account, uint256 _amount) external whenNotPaused {
    uint256 currentAllowance = allowance(_account, msg.sender);
    require(currentAllowance >= _amount, "KAP20: burn amount exceeds allowance");
    unchecked { _approve(_account, msg.sender, currentAllowance - _amount); }
    _burn(_account, _amount);
  }

  function adminApprove(
    address _owner,
    address _spender,
    uint256 _amount
  ) external override onlySuperAdminOrAdmin returns (bool) {
    require(
      kyc.kycsLevel(_owner) >= acceptedKycLevel && kyc.kycsLevel(_spender) >= acceptedKycLevel,
      "KAP20: Owner or spender address is not a KYC user"
    );

    _approve(_owner, _spender, _amount);
    return true;
  }
}