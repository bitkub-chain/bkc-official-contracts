// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/interfaces/IAdminProjectRouter.sol


pragma solidity 0.8.0;

interface IAdminProjectRouter {
    function isSuperAdmin(address _addr, string calldata _project) external view returns (bool);

    function isAdmin(address _addr, string calldata _project) external view returns (bool);
}


// File contracts/abstracts/Authorization.sol


pragma solidity 0.8.0;

abstract contract Authorization {
    IAdminProjectRouter public adminRouter;
    string public constant PROJECT = "bitkub-mut";
    address public transferRouter;

    address public committee;
    event SetAdmin(address indexed oldAdmin, address indexed newAdmin, address indexed caller);
    event SetCommittee(address indexed oldCommittee, address indexed newCommittee, address indexed caller);

    modifier onlySuperAdmin() {
        require(adminRouter.isSuperAdmin(msg.sender, PROJECT), "Restricted only super admin");
        _;
    }

    modifier onlyAdmin() {
        require(adminRouter.isAdmin(msg.sender, PROJECT), "Restricted only admin");
        _;
    }

    modifier onlySuperAdminOrAdmin() {
        require(
            adminRouter.isSuperAdmin(msg.sender, PROJECT) || adminRouter.isAdmin(msg.sender, PROJECT),
            "Restricted only super admin or admin"
        );
        _;
    }

    modifier onlySuperAdminOrTransferRouter() {
        require(
            adminRouter.isSuperAdmin(msg.sender, PROJECT) || msg.sender == transferRouter,
            "Restricted only super admin ot transfer router"
        );
        _;
    }

    modifier onlyCommittee() {
        require(msg.sender == committee, "Restricted only committee");
        _;
    }

    function setAdmin(address _adminRouter) external onlySuperAdmin {
        emit SetAdmin(address(adminRouter), _adminRouter, msg.sender);
        adminRouter = IAdminProjectRouter(_adminRouter);
    }

    function setCommittee(address _committee) external onlyCommittee {
        emit SetCommittee(committee, _committee, msg.sender);
        committee = _committee;
    }

    function setTransferRouter(address _transferRouter) external onlySuperAdmin {
        transferRouter = _transferRouter;
    }
}


// File contracts/interfaces/IKYCBitkubChain.sol


pragma solidity 0.8.0;

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


// File contracts/abstracts/Pauseable.sol


pragma solidity 0.8.0;

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


// File contracts/interfaces/IKAP165.sol


pragma solidity 0.8.0;

interface IKAP165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File contracts/abstracts/KAP165.sol


pragma solidity 0.8.0;

abstract contract KAP165 is IKAP165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IKAP165).interfaceId;
    }
}


// File contracts/interfaces/IKAP721.sol


pragma solidity 0.8.0;

interface IKAP721 is IKAP165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function adminTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function internalTransfer(
        address sender,
        address recipient,
        uint256 tokenId
    ) external returns (bool);

    function externalTransfer(
        address sender,
        address recipient,
        uint256 tokenId
    ) external returns (bool);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File contracts/interfaces/IKAP721Receiver.sol


pragma solidity 0.8.0;

interface IKAP721Receiver {
    function onKAP721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/interfaces/IKAP721Metadata.sol


pragma solidity 0.8.0;

interface IKAP721Metadata {
    event Uri(uint256 indexed id);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File contracts/interfaces/IKAP721Enumerable.sol


pragma solidity 0.8.0;

interface IKAP721Enumerable {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File contracts/libraries/Address.sol


pragma solidity 0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}


// File contracts/libraries/EnumerableSetUint.sol


pragma solidity 0.8.0;

library EnumerableSetUint {
    struct UintSet {
        uint256[] _values;
        mapping(uint256 => uint256) _indexes;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            uint256 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    function getAll(UintSet storage set) internal view returns (uint256[] memory) {
        return set._values;
    }

    function get(
        UintSet storage set,
        uint256 _page,
        uint256 _limit
    ) internal view returns (uint256[] memory) {
        require(_page > 0 && _limit > 0);
        uint256 tempLength = _limit;
        uint256 cursor = (_page - 1) * _limit;
        uint256 _uintLength = length(set);
        if (cursor >= _uintLength) {
            return new uint256[](0);
        }
        if (tempLength > _uintLength - cursor) {
            tempLength = _uintLength - cursor;
        }
        uint256[] memory uintList = new uint256[](tempLength);
        for (uint256 i = 0; i < tempLength; i++) {
            uintList[i] = at(set, cursor + i);
        }
        return uintList;
    }
}


// File contracts/libraries/EnumerableMap.sol


pragma solidity 0.8.0;

library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        mapping(bytes32 => uint256) _indexes;
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}


// File contracts/libraries/Strings.sol


pragma solidity 0.8.0;

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}


// File contracts/abstracts/KAP721.sol


pragma solidity 0.8.0;











abstract contract KAP721 is IKAP721, IKAP721Metadata, IKAP721Enumerable, KAP165, Authorization, KYCHandler, Pauseable {
    using Address for address;
    using Strings for uint256;
    using EnumerableSetUint for EnumerableSetUint.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    // Token name
    string public override name;

    // Token symbol
    string public override symbol;

    // Base URI
    string public baseURI;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSetUint.UintSet) _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    constructor(
        string memory name_,
        string memory symbol_,
        address adminRouter_,
        address kyc_,
        address committee_,
        uint256 acceptedKycLevel_
    ) {
        name = name_;
        symbol = symbol_;
        adminRouter = IAdminProjectRouter(adminRouter_);
        kyc = IKYCBitkubChain(kyc_);
        committee = committee_;
        acceptedKycLevel = acceptedKycLevel_;
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

    function pause() public onlyCommittee {
        _pause();
    }

    function unpause() public onlyCommittee {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(KAP165, IKAP165) returns (bool) {
        return
            interfaceId == type(IKAP721).interfaceId ||
            interfaceId == type(IKAP721Metadata).interfaceId ||
            interfaceId == type(IKAP721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _holderTokens[owner].length();
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "KAP721: owner query for nonexistent token");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "KAP721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(baseURI, _tokenURI));
        }

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = KAP721.ownerOf(tokenId);
        require(to != owner, "KAP721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "KAP721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "KAP721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "KAP721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "KAP721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function adminTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external override onlyCommittee {
        _transfer(from, to, tokenId);
    }

    function internalTransfer(
        address sender,
        address recipient,
        uint256 tokenId
    ) external override onlySuperAdminOrTransferRouter returns (bool) {
        require(
            kyc.kycsLevel(sender) >= acceptedKycLevel && kyc.kycsLevel(recipient) >= acceptedKycLevel,
            "Only internal purpose"
        );

        _transfer(sender, recipient, tokenId);
        return true;
    }

    function externalTransfer(
        address sender,
        address recipient,
        uint256 tokenId
    ) external override onlySuperAdminOrTransferRouter returns (bool) {
        require(kyc.kycsLevel(sender) >= acceptedKycLevel, "Only external purpose");

        _transfer(sender, recipient, tokenId);
        return true;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "KAP721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnKAP721Received(from, to, tokenId, _data), "KAP721: transfer to non KAP721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "KAP721: operator query for nonexistent token");
        address owner = KAP721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnKAP721Received(address(0), to, tokenId, _data),
            "KAP721: transfer to non KAP721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual whenNotPaused {
        require(to != address(0), "KAP721: mint to the zero address");
        require(!_exists(tokenId), "KAP721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual whenNotPaused {
        address owner = ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _holderTokens[owner].remove(tokenId);
        _holderTokens[address(0)].add(tokenId);

        _tokenOwners.set(tokenId, address(0));

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual whenNotPaused {
        require(ownerOf(tokenId) == from, "KAP721: transfer of token that is not own"); // internal owner
        require(to != address(0), "KAP721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(KAP721.ownerOf(tokenId), to, tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "KAP721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
        emit Uri(tokenId);
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        baseURI = baseURI_;
    }

    function _checkOnKAP721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IKAP721Receiver(to).onKAP721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IKAP721Receiver.onKAP721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("KAP721: transfer to non KAP721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


// File contracts/MUTToken.sol


pragma solidity 0.8.0;


contract MUTToken is KAP721 {
    using EnumerableSetUint for EnumerableSetUint.UintSet;

    struct mintNum {
        uint256 mintCounter;
        uint256 mintMax;
    }

    // Mapping from typeID to mintNum
    mapping(uint256 => mintNum) public mintInfo;
    event MintWithMetadataBatch(address indexed operator, string[] _ipfsUrls, uint256[] _tokenIds);

    constructor(
        address adminRouter_,
        address kyc_,
        address committee_,
        uint256 acceptedKycLevel_
    ) KAP721("Miss Universe Thailand", "MUT-NFT", adminRouter_, kyc_, committee_, acceptedKycLevel_) {}

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function tokenOfOwnerByPage(
        address _owner,
        uint256 _page,
        uint256 _limit
    ) external view returns (uint256[] memory) {
        return _holderTokens[_owner].get(_page, _limit);
    }

    function tokenOfOwnerAll(address _owner) external view returns (uint256[] memory) {
        return _holderTokens[_owner].getAll();
    }

    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external onlyCommittee {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setBaseURI(string calldata _baseURI) external onlyCommittee {
        _setBaseURI(_baseURI);
    }

    function setMintMax(uint256[] memory _typeIds, uint256[] memory _mintMaxs) external onlySuperAdmin {
        require(_typeIds.length == _mintMaxs.length, "typeIds & mintMaxs must have same length");
        for (uint256 i = 0; i < _typeIds.length; i++) {
            mintInfo[_typeIds[i]].mintMax = _mintMaxs[i];
        }
    }

    function _mintWithMetadata(
        address _to,
        string memory _ipfsUrl,
        uint256 _tokenId
    ) internal {
        uint256 typeId = (_tokenId >> 14) << 14;
        require(mintInfo[typeId].mintCounter < mintInfo[typeId].mintMax, "Exceed mint max");
        mintInfo[typeId].mintCounter += 1;
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _ipfsUrl);
    }

    function mintWithMetadata(
        address _to,
        string memory _ipfsUrl,
        uint256 _tokenId
    ) external onlySuperAdmin {
        _mintWithMetadata(_to, _ipfsUrl, _tokenId);
    }

    function mintWithMetadataBatch(
        address _to,
        string[] memory _ipfsUrls,
        uint256[] memory _tokenIds
    ) external onlySuperAdmin {
        require(_ipfsUrls.length == _tokenIds.length, "Need all input in same length");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _mintWithMetadata(_to, _ipfsUrls[i], _tokenIds[i]);
        }
        emit MintWithMetadataBatch(_to, _ipfsUrls, _tokenIds);
    }

    function burn(address _from, uint256 _tokenId) external onlySuperAdmin {
        require(ownerOf(_tokenId) == _from, "Not owner of token");
        _burn(_tokenId);
    }
}