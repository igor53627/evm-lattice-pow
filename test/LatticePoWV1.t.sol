// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/LatticePoWV1.sol";

contract LatticePoWV1Test {
    LatticePoWV1 internal pow = new LatticePoWV1();

    function testVerifyReferenceSolution() public view {
        bytes32 challenge = keccak256("challenge-1");
        bytes32[8] memory solution = pow.getReferenceSolution(challenge);

        (bool valid, bytes32 solutionHash, uint256 normSq) = pow.verify(challenge, solution);
        require(valid, "reference solution should verify");
        require(solutionHash == keccak256(abi.encodePacked(solution)), "solution hash mismatch");
        require(normSq < pow.THRESHOLD_SQ(), "norm should be below threshold");
    }

    function testVerifyRejectsWrongSolution() public view {
        bytes32 challenge = keccak256("challenge-2");
        bytes32[8] memory solution = pow.getReferenceSolution(challenge);

        solution[0] ^= bytes32(uint256(1));
        (bool valid,, uint256 normSq) = pow.verify(challenge, solution);
        require(!valid, "corrupted solution should fail");
        require(normSq >= pow.THRESHOLD_SQ(), "norm should be above threshold");
    }

    function testDeriveChallengeBindsInputs() public view {
        bytes32 r = keccak256("rand");
        bytes32 tag = keccak256("domain");
        bytes32 c1 = pow.deriveChallenge(r, address(0xBEEF), 1, tag);
        bytes32 c2 = pow.deriveChallenge(r, address(0xBEEF), 2, tag);
        bytes32 c3 = pow.deriveChallenge(r, address(0xCAFE), 1, tag);

        require(c1 != c2, "nonce should bind challenge");
        require(c1 != c3, "solver should bind challenge");
    }

    function testGasVerifyReferenceSolution() public {
        bytes32 challenge = keccak256("gas");
        bytes32[8] memory solution = pow.getReferenceSolution(challenge);

        uint256 g0 = gasleft();
        (bool valid,,) = pow.verify(challenge, solution);
        uint256 used = g0 - gasleft();

        require(valid, "solution must validate");
        require(used > 0, "gas should be measurable");
    }
}
