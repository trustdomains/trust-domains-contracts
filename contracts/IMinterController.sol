// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

interface IMinterController {
    
    /// The defi domain support two level format.
    /// Only subdomain can be burned by the owner
    /// 
    /// the base URI `eth://` Used to distinguish different blockchain
    /// eth://token.defi    ethereum main domain format(neo://token.defi, neo main domain format)
    /// eth://app.token.defi

    /// The resolver can be set/access key - value string content

    /// The router is a protocol to access the resource stored in ethereum,
    /// also can execute the smartcontract by delegate call / custom the router
    /// implementation
    /// eth://token.defi - default access the index(tokenId) function
    /// eth://token.defi/get/name=tom   read data   ?
    /// eth://token.defi/post/name=tom   write data  !

    function setBaseURI(string calldata baseURI) external;

    function mintURI(address to, string calldata label) external;

    function safeMintURI(address to, string calldata label, bytes  calldata _data) external;

    function mintURIWithResolver(address to, string calldata label, address resolver) external;


    function mintSubURI(address to, uint256 tokenId, string calldata label) external;

    function safeMintSubURI(address to, uint256 tokenId, string calldata label, bytes calldata _data) external;

    function mintSubURIWithResolver(address to, uint256 tokenId, string calldata label,  address resolver) external;

    function burnSubURI(uint256 tokenId, string calldata label) external;


    function setResolver(uint256 tokenId, address resolver) external;

    function setRouter(uint256 tokenId, address router) external;
}
