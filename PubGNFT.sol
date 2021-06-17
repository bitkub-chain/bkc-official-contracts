// Sources flattened with hardhat v2.2.0 https://hardhat.org

// File contracts/KAP165.sol

pragma solidity 0.6.6;

contract KAP165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_KAP165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() internal {
        _registerInterface(_INTERFACE_ID_KAP165);
    }

    //Auto Call from outside to check supportInterface
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


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


// File contracts/interfaces/IKAP721.sol

pragma solidity 0.6.6;

interface IKAP721 {
    event Transfer(address indexed _from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address _from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address _from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address _from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File contracts/interfaces/IRandStorage.sol

pragma solidity 0.6.6;

interface IRandStorage {
    function getCardTypeArr() external view returns (uint256[108] memory);
}


// File contracts/libraries/EnumerableSet.sol

pragma solidity 0.6.6;

library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


// File contracts/libraries/Strings.sol

pragma solidity 0.6.6;

library Strings {
    function toString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}


// File contracts/PubGNFT.sol

pragma solidity 0.6.6;





// version 18 add burn token and add more event

contract PubGNFT is KAP165, IKAP721 {
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;

    string public name = "PUBG NFT";
    string public symbol = "PNFT";
    uint256 public version = 3;
    uint256 public totalSupply = 0;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string public baseURI;

    //event ContractUpgrade(address newContract);
    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_KAP721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_KAP721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_KAP721_ENUMERABLE = 0x780e9d63;

    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) _cardHolders;
    mapping(uint256 => string) public cardHashImages;

    // Mapping from token ID to owner
    mapping(uint256 => address) private tokenOwner;
    // mapping (address => uint256) private ownershipTokenCount;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => uint256) tokenIdx; // By ID
    mapping(uint256 => uint256) tokenID; // By Idx

    address[] public allUsers;
    mapping(address => uint256) public userIdxs;

    // event MintToken(address indexed _addr, uint256 indexed _tokenID);
    // event BurnToken(address indexed _addr, uint256 indexed _tokenID);
    // event AllowBurn(address indexed _addr, uint256 indexed _tokenID);

    IAdmin public admin;
    IKYC public kyc;
    IRandStorage public randStorage;
    bool public isActivatedOnlyKycAddress;

    modifier onlySuperAdmin() {
        require(admin.isSuperAdmin(msg.sender), "Restricted only super admin");
        _;
    }

    constructor(
        address _admin,
        address _kyc,
        address _randStorage
    ) public {
        _registerInterface(_INTERFACE_ID_KAP721);
        _registerInterface(_INTERFACE_ID_KAP721_METADATA);
        _registerInterface(_INTERFACE_ID_KAP721_ENUMERABLE);

        admin = IAdmin(_admin);
        kyc = IKYC(_kyc);
        randStorage = IRandStorage(_randStorage);
    }

    function setAdmin(address _admin) external onlySuperAdmin {
        admin = IAdmin(_admin);
    }

    function setKYC(address _kyc) external onlySuperAdmin {
        kyc = IKYC(_kyc);
    }

    function setRandStorage(address _randStorage) external onlySuperAdmin {
        randStorage = IRandStorage(_randStorage);
    }

    function getCardHolder(address _user, uint256 _typeId) external view returns (uint256[] memory) {
        uint256 cardHoldersLength = _cardHolders[_user][_typeId].length();
        uint256[] memory result = new uint256[](cardHoldersLength);

        for (uint256 i = 0; i < cardHoldersLength; i++) {
            result[i] = _cardHolders[_user][_typeId].at(i);
        }
        return result;
    }

    function mintToken(address _to, uint256 _tokenId) external onlySuperAdmin returns (bool) {
        require(isValidToken(_tokenId) == false, "Token already mint");
        _mint(_to, _tokenId);
    }

    function batchMintToken(address[] calldata _to, uint256[] calldata _tokenId)
        external
        onlySuperAdmin
        returns (bool)
    {
        require(_to.length == _tokenId.length, "Need all input have same length");

        for (uint256 i = 0; i < _to.length; i++) {
            if (!isValidToken(_tokenId[i])) {
                _mint(_to[i], _tokenId[i]);
            }
        }

        return true;
    }

    function batchMintToken(address _to, uint256[] calldata _tokenId) external onlySuperAdmin returns (bool) {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            if (!isValidToken(_tokenId[i])) {
                _mint(_to, _tokenId[i]);
            }
        }

        return true;
    }

    function _mint(address _to, uint256 _tokenId) internal returns (bool) {
        uint256 _typeId = (_tokenId >> 20) << 20;

        if (userIdxs[_to] == 0) {
            allUsers.push(_to);
            uint256 newIdx = allUsers.length - 1;
            userIdxs[_to] = newIdx;
        }

        tokenOwner[_tokenId] = _to;
        _cardHolders[_to][_typeId].add(_tokenId);

        totalSupply += 1;
        tokenIdx[_tokenId] = 1;

        // _setTokenURI(tokenId, _tokenURI);
        emit Transfer(address(0), _to, _tokenId);
        return true;
    }

    function burnToken(uint256 _tokenId) external onlySuperAdmin returns (bool) {
        _burn(_tokenId);
    }

    function batchBurnToken(uint256[] calldata _tokenId) external onlySuperAdmin returns (bool) {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            _burn(_tokenId[i]);
        }
    }

    function _burn(uint256 _tokenId) internal returns (bool) {
        address _from = tokenOwner[_tokenId];
        uint256 _typeId = (_tokenId >> 20) << 20;
        tokenOwner[_tokenId] = address(0);
        _cardHolders[_from][_typeId].remove(_tokenId);

        totalSupply -= 1;
        emit Transfer(_from, address(0), _tokenId);
    }

    function isValidToken(uint256 _tokenId) public view returns (bool) {
        return (tokenIdx[_tokenId] != 0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(isValidToken(tokenId) == true, "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function balanceOf(address owner) public view override returns (uint256) {
        uint256 result = 0;
        uint256[108] memory cardTypeId = randStorage.getCardTypeArr();

        for (uint256 i = 0; i < cardTypeId.length; i++) {
            result += _cardHolders[owner][cardTypeId[i]].length();
        }

        return result;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return tokenOwner[tokenId];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(isValidToken(tokenId) == true, "KAP721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI, _tokenURI));
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        return tokenID[index];
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "KAP721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "KAP721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        //  require(tokenIdx[tokenId] > 0," nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "KAP721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address _from,
        address to,
        uint256 tokenId
    ) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "KAP721: transfer caller is not owner nor approved");
        _transfer(_from, to, tokenId);
    }

    function safeTransferFrom(
        address _from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(_from, to, tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _safeTransfer(_from, to, tokenId, _data);
    }

    function _safeTransfer(
        address _from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(_from, to, tokenId);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        require(ownerOf(_tokenId) == _from, "KAP721: transfer of token that is not own");
        require(_to != address(0), "KAP721: transfer to the zero address");

        if (_tokenApprovals[_tokenId] != address(0)) {
            _tokenApprovals[_tokenId] = address(0);
        }

        uint256 _typeId = (_tokenId >> 20) << 20;

        _cardHolders[_from][_typeId].remove(_tokenId);
        _cardHolders[_to][_typeId].add(_tokenId);

        tokenOwner[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(isValidToken(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setBaseURI(string memory _baseURI_) public onlySuperAdmin {
        baseURI = _baseURI_;
    }

    function setCardHashImage(uint256 _typeId, string memory _cardHashImage) public onlySuperAdmin {
        cardHashImages[_typeId] = _cardHashImage;
    }

    function adminTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external onlySuperAdmin {
        if (isActivatedOnlyKycAddress == true) {
            require(kyc.kycsLevel(_from) > 1 && kyc.kycsLevel(_to) > 1, "only kyc address admin can control");
        }

        _transfer(_from, _to, _tokenId);
    }

    function batchTransfer(
        address[] calldata _from,
        address[] calldata _to,
        uint256[] calldata _tokenId
    ) external onlySuperAdmin returns (bool) {
        require(_from.length == _to.length);
        require(_to.length == _tokenId.length);

        for (uint256 i = 0; i < _to.length; i++) {
            if (ownerOf(_tokenId[i]) == _from[i] && _to[i] != address(0)) {
                if (isActivatedOnlyKycAddress == true) {
                    if (kyc.kycsLevel(_from[i]) <= 1 || kyc.kycsLevel(_to[i]) <= 1) {
                        continue;
                    }
                }

                if (_tokenApprovals[_tokenId[i]] != address(0)) {
                    _tokenApprovals[_tokenId[i]] = address(0);
                }

                uint256 _typeId = (_tokenId[i] >> 20) << 20;

                _cardHolders[_from[i]][_typeId].remove(_tokenId[i]);
                _cardHolders[_to[i]][_typeId].add(_tokenId[i]);

                tokenOwner[_tokenId[i]] = _to[i];
                emit Transfer(_from[i], _to[i], _tokenId[i]);
            }
        }

        return true;
    }
}
