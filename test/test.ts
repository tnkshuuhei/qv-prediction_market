import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

describe("Contract Test", () => {
  let owner: any;
  let addr1: any;
  let addr2: any;
  let oracle: any;
  let provider: any;
  let contract: any;

  async function deployContract() {
    const ContractFactory = await ethers.getContractFactory("PredictionMarket");
    const contract = await upgrades.deployProxy(ContractFactory, [
      oracle.address,
      "This is prediction market for governance",
      "YES",
      "NO",
    ]);
    return contract;
  }

  beforeEach(async () => {
    [owner, addr1, addr2, oracle] = await ethers.getSigners();
    contract = await deployContract();
    provider = ethers.provider;
  });

  it("Should deploy the contract", async () => {
    expect(contract.address).to.not.equal(0);
  });
  it("Should initialize Market", async () => {
    let initialMarketId = await contract.getInitialMarketId();
    let initialMarket = await contract.getMarket(initialMarketId);

    console.log(ethers.toUtf8String(initialMarket.description));

    expect(await contract.getInitialMarketId()).to.not.equal(0);
  });
});
