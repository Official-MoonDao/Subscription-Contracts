require("dotenv").config({ path: "../../.env" });
const {
  createThirdwebClient,
  getContract,
  prepareContractCall,
  sendAndConfirmTransaction,
} = require("thirdweb");
const { sepolia, arbitrum } = require("thirdweb/chains");
const { privateKeyToAccount } = require("thirdweb/wallets");

//Constants
const ENV = "testnet";
const TEAM_TABLE_NAME = "ENTITYTABLE_11155111_1731";
const NEW_TEAM_TABLE_ADDRESS = "";

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
const newTeamTableContract = getContract({
  client,
  address: NEW_TEAM_TABLE_ADDRESS,
  chain,
});

//Get the current team table
async function migrateTeamTable() {
  const statement = `SELECT * FROM ${TEAM_TABLE_NAME}`;
  const teamTableRes = await fetch(
    `${tablelandEndpoint}?statement=${statement}`
  );
  const teamTableData = await teamTableRes.json();

  for (const team of teamTableData) {
    const {
      id,
      name,
      description,
      image,
      website,
      twitter,
      discord,
      telegram,
    } = team;

    const transaction = prepareContractCall({
      contract: newTeamTableContract,
      method: "insertIntoTable",
      args: [id, name, description, image, website, twitter, discord, telegram],
    });

    const receipt = await sendAndConfirmTransaction({
      account,
      transaction,
    });

    console.log(
      `Team ${id} has been migrated. Receipt: ${receipt.transactionHash}`
    );
  }
}

migrateTeamTable();
