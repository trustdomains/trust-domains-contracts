// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./IRegistry.sol";
import "./AdminControl.sol";
import "./utils/StringUtil.sol";


contract Registry is IRegistry, ERC721Burnable, AdminControl {
    using EnumerableSet for EnumerableSet.UintSet;  

    // Mapping from holder tokenId to their (enumerable) set of subdomain tokenIds
    mapping (uint256 => EnumerableSet.UintSet) private _subTokens;

    // Mapping from token ID to router address
    mapping (uint256 => address) internal _tokenRouters;

    // Mapping from token ID to resolver address
    mapping (uint256 => address) internal _tokenResolvers;

    // cfx hash
    uint256 private constant _CFX_ROOT_HASH = 0xf60b73180d56a49cd45c6477f69b0b2505679b536bfd4fee397e6aaf4e2a4b39;

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId)
        );
        _;
    }

    constructor() ERC721("TD - Conflux Name Service (.cfx)", "TD") public {
        _mint(address(0xfc00000000000000000000000000000000000000), _CFX_ROOT_HASH);
        _tokenURIs[_CFX_ROOT_HASH] = "cfx";
    }


    // expose for Resolver
    function isApprovedOrOwner(address account, uint256 tokenId) external view returns(bool)  {
        return _isApprovedOrOwner(account, tokenId);
    }
    

    function root() public pure returns (uint256) {
        return _CFX_ROOT_HASH;
    }

    function subTokenIdByIndex(uint256 tokenId, uint256 index) public view override returns (uint256) {
        require (subTokenIdCount(tokenId) > index);
        return _subTokens[tokenId].at(index);
    }
    
    function subTokenIdCount(uint256 tokenId) public view override returns (uint256) {
        require (_exists(tokenId));
        return _subTokens[tokenId].length();
    }


    function setBaseURI(string calldata baseURI) external override onlyMinterController {
        _setBaseURI(baseURI);
    }

    function setResolver(uint256 tokenId, address resolver) public override onlyApprovedOrOwner(tokenId) {
        _setResolver(tokenId, resolver);
    }

    function setResolverByController(uint256 tokenId, address resolver) public override onlyMinterController {
        _setResolver(tokenId, resolver);
    }

    function resolverOf(uint256 tokenId) external view override returns (address) {
        address resolver = _tokenResolvers[tokenId];
        require (resolver != address(0));
        return resolver;
    }
    
    function setRouter(uint256 tokenId, address router) public override onlyApprovedOrOwner(tokenId) {
        _setRouter(tokenId, router);
    }

    function setRouterByController(uint256 tokenId, address router) public override onlyMinterController {
        _setRouter(tokenId, router);
    }
    
    function routerOf(uint256 tokenId) external view override returns (address) {
        address router = _tokenRouters[tokenId];
        require (router != address(0));
        return router;
    }

    function sync(uint256 tokenId, uint256 keyHash) external {
        require(_tokenResolvers[tokenId] == msg.sender);
        emit Sync(msg.sender, tokenId, keyHash);
    }


    /// transfer tokenId through label string
    function transferURI(address from, address to, string calldata label) external override
        onlyApprovedOrOwner(subTokenId(root(), label))
    {
        _transfer(from, to, subTokenId(root(), label));
    }

    function safeTransferURI(address from, address to, string calldata label, bytes calldata _data) external override
        onlyApprovedOrOwner(subTokenId(root(), label))
    {
        _safeTransfer(from, to, subTokenId(root(), label), _data);
    }

    function transferSubURI(address from, address to, string calldata label, string calldata subLabel) external override
        onlyApprovedOrOwner(subTokenId(subTokenId(root(), label), subLabel))
    {
        _transfer(from, to, subTokenId(subTokenId(root(), label), subLabel));
    }

    function safeTransferSubURI(
        address from, 
        address to, 
        string calldata label, 
        string calldata subLabel, 
        bytes calldata _data) external override
        onlyApprovedOrOwner(subTokenId(subTokenId(root(), label), subLabel))
    {
        _safeTransfer(from, to, subTokenId(subTokenId(root(), label), subLabel), _data);
    }

    
    function setOwner(address to, uint256 tokenId) external override onlyApprovedOrOwner(tokenId) {
        _transfer(ownerOf(tokenId), to, tokenId);
    }
    
    /**
     * For user to mint the subdomain of a exists tokenURI
     * @param to address which will set as the subdomain owner
     * @param tokenId the parent token Id of the subdomain
     * @param label the label of the subdomain
     */


    function mintSubURI(address to, uint256 tokenId, string calldata label) external override 
        onlyApprovedOrOwner(tokenId) 
    {
        _safeMintURI(to, tokenId, label, "");
    }

    function safeMintSubURI(address to, uint256 tokenId, string calldata label, bytes calldata _data) external override
        onlyApprovedOrOwner(tokenId) 
    {
        _safeMintURI(to, tokenId, label, _data);
    }

    function mintSubURIByController(address to, uint256 tokenId, string calldata label) external override
        onlyMinterController 
    {
        _safeMintURI(to, tokenId, label, "");
    }

    function safeMintSubURIByController(address to, uint256 tokenId, string calldata label, bytes calldata _data) external override
        onlyMinterController 
    {
        _safeMintURI(to, tokenId, label, _data);
    }


    /// the subdomain can be burn by token owner
    function burnSubURI(uint256 tokenId, string calldata label) external override onlyApprovedOrOwner(tokenId) {
        _burnURI(tokenId, label);
    }


    function burnSubURIByController(uint256 tokenId, string calldata label) external override onlyMinterController {
        _burnURI(tokenId, label);
    }



    // Internal
    function subTokenId(uint256 tokenId, string memory label) public pure override returns(uint256)  {
        require (bytes(label).length != 0);
        return uint256(keccak256(
            abi.encodePacked(tokenId, 
            keccak256(abi.encodePacked(label))) )
        );
    }


    function _safeMintURI(address to, uint256 tokenId, string memory label, bytes memory _data) internal {
        require (bytes(label).length != 0);
        require (StringUtil.dotCount(label) == 0);
        require (_exists(tokenId));
        
        uint256 _newTokenId = subTokenId(tokenId, label);
        bytes memory _newUri = abi.encodePacked(label, ".", _tokenURIs[tokenId]);

        uint256 count = StringUtil.dotCount(_tokenURIs[tokenId]);
        if (count == 1) {
            _subTokens[tokenId].add(_newTokenId);
        }

        if (bytes(_data).length != 0) {
            _safeMint(to, _newTokenId, _data);
        } else {
            _mint(to, _newTokenId);
        }
        
        _setTokenURI(_newTokenId, string(_newUri));

        emit NewURI(_newTokenId, string(_newUri));
    }

    /**
     * @dev Burn the tokenURI according the token ID,
     * @param tokenId the root tokenId of a tokenURI, 
     * @param label the label of a tokenURI should be burn
     */
    function _burnURI(uint256 tokenId, string memory label) internal {
        uint256 _subTokenId = subTokenId(tokenId, label);
        // remove sub tokenIds itself
        _subTokens[tokenId].remove(_subTokenId);

        //_burn(subTokenId);
        if (_tokenRouters[tokenId] != address(0)) {
            delete _tokenRouters[tokenId];
        }

        if (_tokenResolvers[tokenId] != address(0)) {
            delete _tokenResolvers[tokenId];
        }

        super._burn(_subTokenId);
    }
    
    

    function _setResolver(uint256 tokenId, address resolver) internal {
        require (_exists(tokenId));
        _tokenResolvers[tokenId] = resolver;
        emit NewResolver(tokenId, resolver);
    }
    
    function _setRouter(uint256 tokenId, address router) internal {
        require (_exists(tokenId));
        _tokenRouters[tokenId] = router;
        emit NewRouter(tokenId, router);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
    
}
