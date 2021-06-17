/**
* Submitted for verification at blockscout.com on 2021-05-07 09:29:25.469922Z
*/
// Sources flattened with hardhat v2.1.2 https://hardhat.org

// File contracts/interfaces/IAdmin.sol

pragma solidity 0.6.6;

interface IAdmin {
    function isSuperAdmin(address _addr) external view returns (bool);

    function isAdmin(address _addr) external view returns (bool);
}


// File contracts/interfaces/IKYC.sol

pragma solidity 0.6.6;

interface IKYC {
    function kycsLevel(address _addr) external view returns (uint256);
}


// File contracts/interfaces/IKAP20.sol

pragma solidity 0.6.6;

interface IKAP20 {
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    function balanceOf(address tokenOwner) external view returns (uint256 balance);

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);

    function transfer(address to, uint256 tokens) external returns (bool success);

    function approve(address spender, uint256 tokens) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function getOwner() external view returns (address);

    function mint(address _toAddr, uint256 _amount) external returns (bool success);

    function burn(address _fromAddr, uint256 _amount) external returns (bool success);
}


// File contracts/FansToken.sol

pragma solidity 0.6.6;



contract FansToken is IKAP20 {
    string public name = "FANS Token";
    string public symbol = "FANS";
    uint256 public decimals = 18;

    uint256 public totalSupply;

    IAdmin public admin;
    IKYC public kyc;

    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) public allowed;

    bool public isActivatedOnlyKycAddress;

    modifier onlySuperAdmin() {
        require(admin.isSuperAdmin(msg.sender), "Restricted only super admin");
        _;
    }

    function getOwner() external view override returns (address) {
        return address(admin);
    }

    constructor(address _admin, address _kyc) public {
        admin = IAdmin(_admin);
        kyc = IKYC(_kyc);
    }

    function setNewAdminAndKYC(address _admin, address _kyc) external onlySuperAdmin {
        admin = IAdmin(_admin);
        kyc = IKYC(_kyc);
    }

    function changeName(string memory _newName) public onlySuperAdmin {
        name = _newName;
    }

    function changeSymbol(string memory _newSymbol) public onlySuperAdmin {
        symbol = _newSymbol;
    }

    function activateOnlyKycAddress() external onlySuperAdmin {
        isActivatedOnlyKycAddress = true;
    }

    function burnToken(address _burnAddr, uint256 _amount) public onlySuperAdmin {
        require(balance[_burnAddr] >= _amount, "Insufucual fund to burn");
        balance[_burnAddr] -= _amount;
        totalSupply += _amount;
        emit Transfer(_burnAddr, address(0), _amount);
    }

    function mint(address _toAddr, uint256 _amount) external override onlySuperAdmin returns (bool) {
        balance[_toAddr] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0), _toAddr, _amount);
        return true;
    }

    function burn(address _fromAddr, uint256 _amount) external override onlySuperAdmin returns (bool) {
        require(balance[_fromAddr] >= _amount);
        balance[_fromAddr] -= _amount;
        emit Transfer(_fromAddr, address(0), _amount);
        return true;
    }

    function balanceOf(address _walletAddress) public view override returns (uint256) {
        return balance[_walletAddress];
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_value <= balance[msg.sender], "Insufficient Balance");

        balance[msg.sender] -= _value;
        balance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function batchTransfer(
        address[] calldata _from,
        address[] calldata _to,
        uint256[] calldata _value
    ) external onlySuperAdmin returns (bool) {
        require(_from.length == _to.length && _to.length == _value.length, "Need all input in same length");

        for (uint256 i = 0; i < _from.length; i++) {
            if (isActivatedOnlyKycAddress == true) {
                if (kyc.kycsLevel(_from[i]) <= 1 || kyc.kycsLevel(_to[i]) <= 1) {
                    continue;
                }
            }
            balance[_from[i]] -= _value[i];
            balance[_to[i]] += _value[i];
        }

        return true;
    }

    function adminTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external onlySuperAdmin returns (bool) {
        if (isActivatedOnlyKycAddress == true) {
            require(kyc.kycsLevel(_from) > 1 && kyc.kycsLevel(_to) > 1, "only kyc address admin can control");
        }

        require(balance[_from] >= _value);
        balance[_from] -= _value;
        balance[_to] += _value;
        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        require(_value <= balance[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balance[_from] -= (_value);
        balance[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}
