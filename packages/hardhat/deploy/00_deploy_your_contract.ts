import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import fs from "fs";
import path from "path";

const deployDelegaOOr: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // Read the source code from delegaOOr.sol
  const sourcePath = path.join(__dirname, "..", "contracts", "delegaOOr.sol");
  const sourceCode = fs.readFileSync(sourcePath, "utf8");

  // Compile the contract
  const contractName = "DelegaOOr";
  const compiled = await hre.ethers.getContractFactory(contractName, sourceCode);
  const abi = compiled.interface.abi;
  const bytecode = compiled.bytecode;

  // Deploy the contract
  const { address } = await deploy(contractName, {
    from: deployer,
    args: [],
    data: bytecode,
    abi: abi,
  });

  console.log("Contract deployed to:", address);

  // Create some template delegations
  const delegaOOr = await hre.ethers.getContractAt("DelegaOOr", address);
  const signers = await hre.ethers.getSigners();
  const delegationNames = ["Delegation 1", "Delegation 2", "Delegation 3"];

  for (let i = 0; i < delegationNames.length; i++) {
    const name = delegationNames[i];
    const funder = signers[i];
    const delegationAddress = await delegaOOr.createDelegation(
      name,
      funder.address,
      signers.map(s => s.address),
      2,
    );
    console.log(`Created delegation "${name}" at address: ${delegationAddress}`);
  }
};

deployDelegaOOr.tags = ["DelegaOOr"];

export default deployDelegaOOr;
