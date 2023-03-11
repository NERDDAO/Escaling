import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import fs from "fs";
import path from "path";

const deploydelegaOOr: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // Read the source code from TopLevelMultiSig.sol
  const sourcePath = path.join(__dirname, "..", "contracts", "delegaOOr.sol");
  const sourceCode = fs.readFileSync(sourcePath, "utf8");

  // Compile the contract
  const contractName = "delegaOOr";
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
};

deploydelegaOOr.tags = ["delegaOOr"];

export default deploydelegaOOr;
