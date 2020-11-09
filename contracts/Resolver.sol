// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./Registry.sol";
import "./utils/StringEnumerableMap.sol";



contract Resolver  {

    event NewKey(uint256 indexed tokenId, string indexed key);
    event ResetContentId(uint256 indexed tokenId, uint256 indexed contentId);
    event ResetKeyId(uint256 indexed tokenId, uint256 indexed contentId);
    event Set(uint256 indexed tokenId, string indexed keyIndex, string indexed valueIndex, string key, string value);
    
    using StringEnumerableMap for StringEnumerableMap.UintToStringMap;
    using EnumerableSet for EnumerableSet.UintSet; 

    Registry private _registry;

    // mapping token ID to content id to content key to value
    mapping(uint256 => mapping(uint256 => StringEnumerableMap.UintToStringMap)) private _contentMaps;

    // mapping token ID to content id
    mapping(uint256 => uint256) _tokenContent;

    // mapping token ID to all key key hash 
    mapping(uint256 => mapping(uint256 => EnumerableSet.UintSet)) _hashedKeys;

    // mapping token ID to hashed keys id
    mapping(uint256 => uint256) _keyIds;

    // mapping key hash to key string
    mapping(uint256 => string) _keys;
   

    modifier onlyResolver(uint256 tokenId) {
        require(
            address(this) == _registry.resolverOf(tokenId),
            "Resolver: resolver is not belong to the domain"
        );
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _registry.isApprovedOrOwner(msg.sender, tokenId),
            "Resolver: sender must be approved or owner"
        );
        _;
    }


    constructor(Registry registry) public {
        _registry = registry;
    }


    function reset(uint256 tokenId) external onlyApprovedOrOwner(tokenId) {
        _setContentId(tokenId, now);
        _setKeyId(tokenId, now);
    }


    function allKeys(uint256 tokenId) external view
        onlyResolver(tokenId) returns (string[] memory keys){
        uint256 length = _hashedKeys[tokenId][_keyIds[tokenId]].length();
        keys = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 keyHash = _hashedKeys[tokenId][_keyIds[tokenId]].at(i);
            keys[i] = _keys[keyHash];
        }
    }

    function allRecords(uint256 tokenId) external view
        onlyResolver(tokenId) returns (string[] memory keys, string[] memory values) {
        uint256 length = _hashedKeys[tokenId][_keyIds[tokenId]].length();
        keys = new string[](length);
        values = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 keyHash = _hashedKeys[tokenId][_keyIds[tokenId]].at(i);
            keys[i] = _keys[keyHash];

            values[i] = _get(tokenId, _keys[keyHash]);
        }
    }


    function set(uint256 tokenId, string calldata key, string calldata value) external 
        onlyApprovedOrOwner(tokenId) 
    {
        _set(tokenId, key, value);
    }

    function get(uint256 tokenId, string memory key)  public view 
        onlyResolver(tokenId) 
        returns (string memory) 
    {
        return _get(tokenId, key);
    }

    function setMulti(uint256 tokenId, string[] memory keys, string[] memory values) public 
        onlyApprovedOrOwner(tokenId) 
    {
        _setMulti(tokenId, keys, values);
    }

    function getMulti(uint256 tokenId, string[] memory keys)  public view 
        onlyResolver(tokenId)
        returns (string[] memory)
    {
        return _getMulti(tokenId, keys);
    }


    function _setMulti(uint256 tokenId, string[] memory keys, string[] memory values) internal {
        uint256 count = keys.length;
        for (uint256 i = 0; i < count; i++) {
            _set(tokenId, keys[i], values[i]);
        }
    }
    
    function _getMulti(uint256 tokenId, string[] memory keys) internal view returns (string[] memory) {
        uint256 count = keys.length;
        string[] memory values = new string[](count);
        for (uint256 i = 0; i < count; i++) {
            values[i] = _get(tokenId, keys[i]);
        }
        return values;
    }

    function _setContentId(uint256 tokenId, uint256 contentId) internal {
        _tokenContent[tokenId] = contentId;
        emit ResetContentId(tokenId, contentId);
    }

    function _setKeyId(uint256 tokenId, uint256 keyId) internal {
        _keyIds[tokenId] = keyId;
        emit ResetKeyId(tokenId, keyId);
    }

    function _set(uint256 tokenId, string memory key, string memory value) internal {
        if (!(_tokenContent[tokenId] > 0 && _keyIds[tokenId] > 0)) {
            _setContentId(tokenId, now);
            _setKeyId(tokenId, now);
        }

        uint256 keyHash = uint256(keccak256(bytes(key)));
        bool _isNewKey = _contentMaps[tokenId][_tokenContent[tokenId]].contains(keyHash);
        
        _registry.sync(tokenId, keyHash);
        _contentMaps[tokenId][_tokenContent[tokenId]].set(keyHash, value);

        // save the key hash
        _hashedKeys[tokenId][_keyIds[tokenId]].add(keyHash);

        if (bytes(_keys[keyHash]).length == 0) {
            _keys[keyHash] = key;
        }

        if (_isNewKey) {
            emit NewKey(tokenId, key);
        }

        emit Set(tokenId, key, value, key, value);
    }
    
    function _get(uint256 tokenId, string memory key) internal view returns (string memory) {
        return _contentMaps[tokenId][_tokenContent[tokenId]].get(uint256(keccak256(bytes(key))));
    }
}