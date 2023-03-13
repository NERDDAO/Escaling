import { ethers } from "hardhat";
import { expect } from "chai";
import { DelegaOOr, DelegatedMultiSig } from "../typechain-types";

describe("DelegaOOr", () => {
  let delegaOOr: DelegaOOr;
  let funder: Signer;
  let signer: Signer;
  let delegationAddress: string;

  beforeEach(async () => {
    const DelegaOOrFactory = await ethers.getContractFactory("DelegaOOr");
    delegaOOr = await DelegaOOrFactory.deploy();
    await delegaOOr.deployed();

    // Get signers
    [funder, signer] = await ethers.getSigners();

    // Create a delegation
    const name = "My Delegation";
    const signers = [signer.address];
    const signaturesRequired = 1;
    delegationAddress = await delegaOOr.createDelegation(name, funder.address, signers, signaturesRequired);
  });

  describe("getDelegationsForWallet", () => {
    it("returns the correct delegations for a wallet", async () => {
      const [delegationNames, delegations] = await delegaOOr.getDelegationsForWallet(funder.address);
      expect(delegationNames.length).to.equal(1);
      expect(delegations.length).to.equal(1);
      expect(delegations[0].name).to.equal("My Delegation");
      expect(delegations[0].funder).to.equal(funder.address);
      expect(delegations[0].signers[0]).to.equal(signer.address);
      expect(delegations[0].signaturesRequired).to.equal(1);
    });
  });
});
