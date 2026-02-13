// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title LatticePoWV1 - Challenge-bound lattice puzzle verifier for EVM
/// @notice Standalone Layer-4-style primitive extracted from TLOS.
/// @dev This is an application-level PoW/CAPTCHA primitive, not a full blockchain consensus PoW.
contract LatticePoWV1 {
    uint256 public constant N = 128;
    uint256 public constant M = 192;
    uint256 public constant Q = 2039;
    uint256 public constant THRESHOLD_SQ = 800;

    bytes32 public constant DOMAIN = keccak256("LatticePoW-v1");

    /// @notice Verify solution for a specific challenge.
    /// @param challenge Public challenge bytes32 (should be unpredictable at protocol level).
    /// @param solution Packed u16[128] in bytes32[8].
    /// @return valid Whether residual norm is below threshold.
    /// @return solutionHash Keccak hash of packed solution when valid.
    /// @return normSq Residual norm (squared).
    function verify(bytes32 challenge, bytes32[8] calldata solution)
        external
        pure
        returns (bool valid, bytes32 solutionHash, uint256 normSq)
    {
        unchecked {
            uint16[128] memory candidate;
            for (uint256 i = 0; i < N; ++i) {
                uint256 word = i / 16;
                uint256 shift = (15 - (i % 16)) * 16;
                uint16 v = uint16(uint256(solution[word]) >> shift);
                if (v >= Q) return (false, bytes32(0), 0);
                candidate[i] = v;
            }

            bytes32 seed = keccak256(abi.encodePacked(DOMAIN, challenge));
            uint16[128] memory planted = _derivePlantedSecret(seed);

            normSq = _computeResidualNormSq(seed, candidate, planted);
            valid = normSq < THRESHOLD_SQ;
            if (valid) {
                solutionHash = keccak256(abi.encodePacked(solution));
            }
        }
    }

    /// @notice Derive canonical challenge binding helper.
    function deriveChallenge(
        bytes32 randomness,
        address solver,
        uint64 nonce,
        bytes32 domainTag
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(DOMAIN, domainTag, randomness, solver, nonce));
    }

    /// @notice Return deterministic reference solution for testing/integration.
    function getReferenceSolution(bytes32 challenge) external pure returns (bytes32[8] memory packed) {
        bytes32 seed = keccak256(abi.encodePacked(DOMAIN, challenge));
        uint16[128] memory secret = _derivePlantedSecret(seed);
        uint256 idx = 0;
        for (uint256 i = 0; i < 8; ++i) {
            uint256 word = 0;
            for (uint256 j = 0; j < 16; ++j) {
                word |= uint256(secret[idx]) << (240 - (j * 16));
                idx++;
            }
            packed[i] = bytes32(word);
        }
    }

    function _derivePlantedSecret(bytes32 seed) private pure returns (uint16[128] memory secret) {
        bytes32 secretSeed = keccak256(abi.encodePacked(seed, "planted-secret"));
        uint256 blocks = (N + 15) / 16;
        for (uint256 blk = 0; blk < blocks; ++blk) {
            bytes32 coeffs = keccak256(abi.encodePacked(secretSeed, blk));
            uint256 coeffsInt = uint256(coeffs);
            for (uint256 k = 0; k < 16; ++k) {
                uint256 idx = blk * 16 + k;
                if (idx >= N) break;
                uint256 shift = (15 - k) * 16;
                uint256 raw = (coeffsInt >> shift) & 0xFFFF;
                secret[idx] = uint16(raw % Q);
            }
        }
    }

    function _computeResidualNormSq(
        bytes32 seed,
        uint16[128] memory candidate,
        uint16[128] memory planted
    ) private pure returns (uint256 normSq) {
        uint256 blocks = (N + 15) / 16;
        for (uint256 row = 0; row < M; ++row) {
            bytes32 rowSeed = keccak256(abi.encodePacked(seed, row));

            int256 dotCandidate = 0;
            int256 dotPlanted = 0;

            for (uint256 blk = 0; blk < blocks; ++blk) {
                bytes32 coeffs = keccak256(abi.encodePacked(rowSeed, blk));
                uint256 coeffsInt = uint256(coeffs);

                for (uint256 k = 0; k < 16; ++k) {
                    uint256 col = blk * 16 + k;
                    if (col >= N) break;
                    uint256 shift = (15 - k) * 16;
                    int256 aij = int256((coeffsInt >> shift) & 0xFFFF) % int256(Q);

                    dotCandidate += aij * int256(uint256(candidate[col]));
                    dotPlanted += aij * int256(uint256(planted[col]));
                }
            }

            int256 e = int256(uint256(keccak256(abi.encodePacked(seed, "error", row))) % 5) - 2;
            int256 bRow = (dotPlanted + e) % int256(Q);
            if (bRow < 0) bRow += int256(Q);

            int256 residual = (dotCandidate - bRow) % int256(Q);
            if (residual > int256(Q / 2)) {
                residual -= int256(Q);
            } else if (residual < -int256(Q / 2)) {
                residual += int256(Q);
            }

            normSq += uint256(residual * residual);
        }
    }
}
