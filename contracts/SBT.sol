// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC5192.sol";

contract SBT is ERC721, ERC721Enumerable, Ownable {
    string private baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        adminAddresses[msg.sender] = true;
        adminAddressesArray.push(msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Mapping from token ID to locked status
    mapping(uint256 => bool) _locked;

    mapping(address => bool) public adminAddresses;
    address[] public adminAddressesArray;

    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @notice currently SBT Contract does not emit Unlocked event
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool) {
        require(ownerOf(tokenId) != address(0));
        return _locked[tokenId];
    }

    function getAdminAddressList() external view returns(address[] memory) {
        return adminAddressesArray;
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require(balanceOf(to) == 0, "MNT01");
        require(_locked[tokenId] != true, "MNT02");

        _locked[tokenId] = true;
        emit Locked(tokenId);

        _safeMint(to, tokenId);
    }

    /// @dev Access modifier for Admin-only functionality
    modifier onlyAdmin() {
        require(adminAddresses[msg.sender]);
        _;
    }

    function burn(uint256 tokenId) external onlyAdmin {
        require(msg.sender == ownerOf(tokenId), "BRN01");
        _burn(tokenId);
    }

    modifier IsTransferAllowed(uint256 tokenId) {
        require(!_locked[tokenId]);
        _;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ERC721) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(IERC721, ERC721) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ERC721) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return _interfaceId == type(IERC5192).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @dev Adds a admin address
    function addAdminAddress(address _address) external onlyOwner {
        require(!adminAddresses[_address], "Address is already an admin");
        adminAddresses[_address] = true;
        adminAddressesArray.push(_address);
    }

    /// @dev Removes a admin address
    function removeAdminAddress(address _address) external onlyOwner {
        require(adminAddresses[_address], "Address is not an admin");
        adminAddresses[_address] = false;

        // Remove from the array
        for (uint i = 0; i < adminAddressesArray.length; i++) {
            if (adminAddressesArray[i] == _address) {
                adminAddressesArray[i] = adminAddressesArray[adminAddressesArray.length - 1];
                adminAddressesArray.pop();
                break;
            }
        }
    }
}
