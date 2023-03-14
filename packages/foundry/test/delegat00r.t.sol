// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/forge-std/src/Test.sol";
import { delegat00r } from "../src/delegat00r.sol";
import { DelegatedMultiSig } from "../src/DelegatedMultiSig.sol";
import { MetaMultiSigWallet } from "../src/MetaMultiSigWallet.sol";

contract delegat00rtest is Test {

  delegat00r Delegat00r;

  function setUp() public {
    Delegat00r = new delegat00r();
  }

  function testCreation() public {
    address funder = vm.addr(1);
    address signer1 = vm.addr(2);
    address signer2 = vm.addr(3);
    address[] memory signers = new address[](2);
    signers[0] = signer1;
    signers[1] = signer2;
    address delegation = Delegat00r.createDelegation("test delegation", funder, signers, 2);
    console.log(delegation);
  }

  function testGetDelegators() public {
    testCreation();
    delegat00r.Delegation[] memory result = Delegat00r.getDelegatingForWallet(vm.addr(1));
  }
  

}