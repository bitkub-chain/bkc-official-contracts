pragma solidity 0.6.6;

interface IAdminAsset {
    function isSuperAdmin(address _addr, string calldata _token) external view returns (bool);
}

interface IKYC {
    function kycsLevel(address _addr) external view returns (uint256);
}

interface IKAP20 {
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Paused(address _addr);
    event Unpaused(address _addr);
    event AddBlacklist(address indexed _blacklistAddr, address indexed _caller);
    event RevokeBlacklist(address indexed _blacklistAddr, address indexed _caller);
    
    function totalSupply() external view returns (uint256);
    
    function paused() external view returns (bool);

    function balanceOf(address tokenOwner) external view returns (uint256 balance);

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);

    function transfer(address to, uint256 tokens) external returns (bool success);

    function approve(address spender, uint256 tokens) external returns (bool success);

    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    
    function getOwner() external view returns (address);
    
    function adminTransfer(address _from, address _to, uint256 _value) external returns (bool success);
    
    function pause() external;

    function unpause() external;
    
    function addBlacklist(address _addr) external;
    
    function revokeBlacklist(address _addr) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
}

contract KETH is IKAP20 {
    using SafeMath for uint256;
    
    string public name     = "Bitkub-Peg ETH";
    string public symbol   = "KETH";
    uint8  public decimals = 18;
    
    uint256 public override totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);
    event Paused(address account);
    event Unpaused(address account);
    event AddBlacklist(address indexed _blacklistAddr, address indexed _caller);
    event RevokeBlacklist(address indexed _blacklistAddr, address indexed _caller);

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    mapping (address => bool) public blacklist;
    
    IAdminAsset public admin;
    IKYC public kyc;
    bool public isActivatedOnlyKycAddress;
    bool public override paused;
    
    modifier onlySuperAdmin() {
        require(admin.isSuperAdmin(msg.sender, symbol), "Restricted only super admin");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }
    
    modifier notInBlacklist(address _addr) {
        require(!blacklist[_addr], "Address is in the blacklist");
        _;
    }
    
    constructor(address _admin, address _kyc) public {
        admin = IAdminAsset(_admin);
        kyc = IKYC(_kyc);
    }
    
    function setKYC(address _kyc) external onlySuperAdmin {
        kyc = IKYC(_kyc);
    }
    
    function activateOnlyKycAddress() external onlySuperAdmin {
        isActivatedOnlyKycAddress = true;
    }
    
    function getOwner() external view override returns (address) {
        return address(admin);
    }
    
    function mint(address _toAddr, uint256 _amount) external onlySuperAdmin returns (bool) {
        require(_toAddr != address(0), "KAP20: mint to zero address");
        
        totalSupply = totalSupply.add(_amount);
        balances[_toAddr] = balances[_toAddr].add(_amount);
        emit Transfer(address(0), _toAddr, _amount);
        return true;
    }

    function burn(address _fromAddr, uint256 _amount) external onlySuperAdmin returns (bool) {
        require(_fromAddr != address(0), "KAP20: burn from zero address");
        require(balances[_fromAddr] >= _amount, "KAP20: burn amount exceeds balance");
        
        totalSupply = totalSupply.sub(_amount);
        balances[_fromAddr] = balances[_fromAddr].sub(_amount);
        emit Transfer(_fromAddr, address(0), _amount);
        return true;
    }
    
    function balanceOf(address _addr) public view override returns (uint256) {
        return balances[_addr];
    }
    
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public override whenNotPaused notInBlacklist(msg.sender) returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }
    
    function increaseAllowance(address _spender, uint256 _addedValue) public whenNotPaused notInBlacklist(msg.sender) returns (bool) {
        _approve(msg.sender, _spender, allowed[msg.sender][_spender].add(_addedValue));
        return true;
    }
  
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public whenNotPaused notInBlacklist(msg.sender) returns (bool) {
        _approve(msg.sender, _spender, allowed[msg.sender][_spender].sub(_subtractedValue, "KAP20: decreased allowance below zero"));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "KAP20: approve from the zero address");
        require(spender != address(0), "KAP20: approve to the zero address");
    
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address _to, uint256 _value) public override whenNotPaused returns (bool) {
        require(_value <= balances[msg.sender], "Insufficient Balance");
        require(_to != address(0), "KAP20: transfer to zero address");
        require(blacklist[msg.sender] == false && blacklist[_to] == false, "Address is in the blacklist");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }
    
     function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override whenNotPaused returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0), "KAP20: transfer to zero address");
        require(blacklist[_from] == false && blacklist[_to] == false, "Address is in the blacklist");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function adminTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external override onlySuperAdmin returns (bool) {
        if (isActivatedOnlyKycAddress) {
            require(kyc.kycsLevel(_from) > 1 && kyc.kycsLevel(_to) > 1, "Admin can control only KYC Address");
        }

        require(balances[_from] >= _value, "KAP20: transfer amount exceed balance");
        require(_to != address(0), "KAP20: transfer to zero address");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        return true;
    }
    
    function pause() external override onlySuperAdmin whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external override onlySuperAdmin whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
    
    function addBlacklist(address _addr) external override onlySuperAdmin {
        blacklist[_addr] = true;
        emit AddBlacklist(_addr, msg.sender);
    }
    
    function revokeBlacklist(address _addr) external override onlySuperAdmin {
        blacklist[_addr] = false;
        emit RevokeBlacklist(_addr, msg.sender);
    }
}
