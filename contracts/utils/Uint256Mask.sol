// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../error/Errors.sol";

library Uint256Mask {
    struct Mask {
        uint256 bits;
    }

    function validateUniqueAndSetIndex(
        Mask memory mask,
        uint256 index,
        string memory label
    ) internal pure {
        if (index >= 256) {
            revert Errors.MaskIndexOutOfBounds(index, label);
        }

        uint256 bit = 1 << index;

        // @question I am not sure what this intends to do.
        // @note Mechnically, this checks if the i-th bit is set on the signerIndexMask
        if (mask.bits & bit != 0) {
            revert Errors.DuplicatedIndex(index, label);
        }

        // @note bitwise or puts in the masked bit, to mark as seen
        mask.bits = mask.bits | bit;
    }
}
