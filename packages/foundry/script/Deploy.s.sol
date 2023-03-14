// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Script } from "../lib/forge-std/src/Script.sol";
import { delegat00r } from "../src/delegat00r.sol";

contract DeployScript is Script {

  delegat00r Delegat00r;
  
  uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

  function run() external {
    vm.startBroadcast(deployerPrivateKey);

    Delegat00r = new delegat00r();

    vm.stopBroadcast();
  }

}