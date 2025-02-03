require("dotenv").config({ path: "../../.env" });
const {
  createThirdwebClient,
  getContract,
  prepareContractCall,
  sendAndConfirmTransaction,
} = require("thirdweb");
const { sepolia, arbitrum } = require("thirdweb/chains");
const { privateKeyToAccount } = require("thirdweb/wallets");
const CitizenTableV2ABI = require("./CitizenTableV2ABI.json");

//Constants
const ENV = "mainnet";
const CITIZEN_TABLE_NAME = "CITIZENTABLE_42161_98";
const NEW_CITIZEN_TABLE_ADDRESS = "0x40C7F938F1df609092c101614E52d60673A7dC9F";

const chain = ENV === "mainnet" ? arbitrum : sepolia;
const tablelandEndpoint = `https://${
  ENV != "mainnet" ? "testnets." : ""
}tableland.network/api/v1/query`;

//Client
const client = new createThirdwebClient({
  secretKey: process.env.THIRDWEB_CLIENT_SECRET,
});
const account = privateKeyToAccount({
  client,
  privateKey: process.env.PRIVATE_KEY,
});

//Contracts
const newCitizenTableContract = getContract({
  client,
  address: NEW_CITIZEN_TABLE_ADDRESS,
  chain,
  abi: CitizenTableV2ABI,
});

async function migrateCitizenTable() {
  const statement = `SELECT * FROM ${CITIZEN_TABLE_NAME}`;
  const citizenTableRes = await fetch(
    `${tablelandEndpoint}?statement=${statement}`
  );
  const citizenTableData = await citizenTableRes.json();

  for (const citizen of citizenTableData) {
    const {
      id,
      name,
      description,
      image,
      location,
      discord,
      twitter,
      website,
      view,
      formId,
      owner,
    } = citizen;

    const transaction = prepareContractCall({
      contract: newCitizenTableContract,
      method: "insertIntoTable",
      params: [
        id,
        name,
        description,
        image,
        location,
        discord,
        twitter,
        website,
        view,
        formId,
        owner,
      ],
    });

    const receipt = await sendAndConfirmTransaction({
      account,
      transaction,
    });

    console.log(
      `Citizen ${id} has been migrated. Receipt: ${receipt.transactionHash}`
    );
  }
}

migrateCitizenTable();
