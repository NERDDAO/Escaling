import { expect } from "chai";
import { ethers } from "hardhat";

describe("Delegation contract", function () {
  let delegationContract;
  let owner;
  let delegate;
  let alice;
  let bob;
  const amount = 100;
  const nonce = 1;

  before(async () => {
    [owner, delegate, alice, bob] = await ethers.getSigners();
    const Delegation = await ethers.getContractFactory("Delegation");
    delegationContract = await Delegation.deploy();
    await delegationContract.deployed();
  });

  it("should set the owner and delegate correctly", async () => {
    expect(await delegationContract.owner()).to.equal(owner.address);
    expect(await delegationContract.delegate()).to.equal(owner.address);
  });

  it("should deposit correctly", async () => {
    await delegationContract.deposit({ value: amount });
    expect(await delegationContract.getBalance(owner.address)).to.equal(amount);
  });

  it("should request transfer correctly", async () => {
    const message = ethers.utils.solidityKeccak256(
      ["address", "address", "uint", "uint"],
      [bob.address, alice.address, amount, nonce],
    );
    const signature = await delegate.signMessage(ethers.utils.arrayify(message));
    try {
      await delegationContract.requestTransfer(alice.address, amount, nonce, bob.address, signature);
    } catch (error) {
      console.log("error message: ", error.message);
    }
    expect(await delegationContract.getAllowance(bob.address, alice.address)).to.equal(amount);
    expect(await delegationContract.nonce(bob.address)).to.equal(nonce);
  });

  it("should not approve transfer with invalid signature", async () => {
    const message = ethers.utils.solidityKeccak256(
      ["address", "address", "uint", "uint"],
      [bob.address, alice.address, amount, nonce],
    );
    const signature = await alice.signMessage(ethers.utils.arrayify(message));
    await expect(delegationContract.approveTransfer(bob.address, alice.address, amount, signature)).to.be.revertedWith(
      "Invalid signature",
    );
  });

  it("should not approve transfer without sufficient allowance", async () => {
    const message = ethers.utils.solidityKeccak256(
      ["address", "address", "uint", "uint"],
      [bob.address, alice.address, amount, nonce],
    );
    const signature = await bob.signMessage(ethers.utils.arrayify(message));
    await expect(delegationContract.approveTransfer(bob.address, alice.address, amount, signature)).to.be.revertedWith(
      "Not authorized",
    );
  });

  it("should approve transfer correctly", async () => {
    const message = ethers.utils.solidityKeccak256(
      ["address", "address", "uint", "uint"],
      [bob.address, alice.address, amount, nonce],
    );
    const signature = await bob.signMessage(ethers.utils.arrayify(message));
    await delegationContract.approveTransfer(bob.address, alice.address, amount, signature);
    expect(await delegationContract.getBalance(alice.address)).to.equal(amount);
    expect(await delegationContract.getAllowance(bob.address, alice.address)).to.equal(0);
    expect(await delegationContract.nonce(bob.address)).to.equal(nonce);
  });
});
