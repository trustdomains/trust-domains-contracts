// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRegistry is IERC721 {


    event NewURI(uint256 indexed tokenId, string tokenUri);
    event NewRouter(uint256 indexed tokenId, address indexed router);
    event NewResolver(uint256 indexed tokenId, address indexed resolver);
    event Sync(address indexed to, uint256 indexed tokenId, uint256 indexed keyHash);
    
    ///
    function setBaseURI(string calldata baseURI) external;

    function setOwner(address to, uint256 tokenId) external;

    function subTokenId(uint256 tokenId, string calldata label) external pure returns(uint256);


    function mintSubURI(address to, uint256 tokenId, string calldata label) external;
    function safeMintSubURI(address to, uint256 tokenId, string calldata label, bytes calldata _data) external;
    function mintSubURIByController(address to, uint256 tokenId, string calldata label) external;
    function safeMintSubURIByController(address to, uint256 tokenId, string calldata label, bytes calldata _data) external;


    function burnSubURI(uint256 tokenId, string calldata label) external;
    function burnSubURIByController(uint256 tokenId, string calldata label) external;


    function transferURI(address from, address to, string calldata label) external;
    function safeTransferURI(address from, address to, string calldata label, bytes calldata _data) external;
    function transferSubURI(address from, address to, string calldata label, string calldata subLabel) external;
    function safeTransferSubURI(address from, address to, string calldata label, string calldata subLabel, bytes calldata _data) external;


    function setRouter(uint256 tokenId, address router) external;
    function setRouterByController(uint256 tokenId, address router) external;
    function routerOf(uint256 tokenId) external view returns (address);

    function setResolver(uint256 tokenId, address resolver) external;
    function setResolverByController(uint256 tokenId, address resolver) external;
    function resolverOf(uint256 tokenId) external view returns (address);


    function subTokenIdByIndex(uint256 tokenId, uint256 index) external view returns (uint256);
    function subTokenIdCount(uint256 tokenId) external view returns (uint256);
    
}
