// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;


import "./Registry.sol";
import "./IMinterController.sol";
import "./AdminControl.sol";
import "./Registry.sol";

/**
 * The MinterController is the domain minter for control to mint, also 
 * setting the domain baseURI.
 */
contract MinterController is IMinterController, AdminControl {
    
    Registry private _registry; 
    
    constructor(Registry registry) public {
        _registry = registry;
    }

    function setBaseURI(string memory baseURI) public override onlyMinter {
        _registry.setBaseURI(baseURI);
    }


    function mintURI(address to, string memory label) public override
        onlyMinter 
    {
        _registry.mintSubURIByController(to, rootId(), label);
    }
    
    function safeMintURI(address to, string memory label, bytes  memory _data) public override
        onlyMinter 
    {
        _registry.safeMintSubURIByController(to, rootId(), label, _data);
    }

    function mintURIWithResolver(address to, string memory label, address resolver) public override
        onlyMinter 
    {
        _registry.mintSubURIByController(to, rootId(), label);
        _registry.setResolverByController(_registry.subTokenId(rootId(), label), resolver);
    }

    function mintSubURI(address to, uint256 tokenId, string memory label) public override
        onlyMinter
    {
        _registry.mintSubURIByController(to, tokenId, label);
    }

    function safeMintSubURI(address to, uint256 tokenId, string memory label, bytes memory _data) public override
        onlyMinter
    {
        _registry.safeMintSubURIByController(to, tokenId, label, _data);
    }

    function mintSubURIWithResolver(address to, uint256 tokenId, string memory label, address resolver) public override
        onlyMinter
    {
        _registry.mintSubURIByController(to, tokenId, label);
        _registry.setResolverByController(_registry.subTokenId(tokenId, label), resolver);
    }

    function burnSubURI(uint256 tokenId, string memory label) public override onlyMinter {
        _registry.burnSubURIByController(tokenId, label);
    }
    
    function setResolver(uint256 tokenId, address resolver) public override onlyMinter {
        _registry.setResolverByController(tokenId, resolver);
    }

    function setRouter(uint256 tokenId, address router) public override onlyMinter {
        _registry.setRouterByController(tokenId, router);
    }

    function rootId() internal view returns(uint256)  {
        return _registry.root();
    }

}
