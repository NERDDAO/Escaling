import type { NextPage } from "next";
import Head from "next/head";
import React from "react";
import { ContractUI } from "~~/components/scaffold-eth";
import { useDeployedContractNames } from "~~/hooks/scaffold-eth/useDeployedContractNames";
import { useEffect, useState } from "react";

const Home: NextPage = () => {
  const contractNames = useDeployedContractNames();
  const [selectedContract, setSelectedContract] = useState<string>();

  useEffect(() => {
    if (!selectedContract && contractNames.length) {
      setSelectedContract(contractNames[0]);
    }
  }, [contractNames, selectedContract]);

  return (
    <>
      <Head>
        <title>DelegatOOOOOr</title>
        <meta name="description" content="Created with 🏗 scaffold-eth" />
      </Head>

      <div className="flex items-center flex-col flex-grow pt-10 bg-gray-900 text-gray-200">
        <div className="px-5">
          <h1 className="text-center mb-8 font-bold text-4xl text-red-500">
            <span className="block text-2xl mb-2">Welcome to the</span>
            DelegatOOOOOOOr DOME
          </h1>

          <div className="block text-2xl border-black border-4 p-8 rounded-3xl bg-gray-700">
            {/* <p className="justify-center items-center flex text-center text-red-500 font-bold">
              CONTRACTY STUFF HERE
            </p> */}

            <div className="flex flex-col gap-y-6 lg:gap-y-8 py-8 lg:py-12 justify-center items-center">
              {contractNames.length === 0 ? (
                <p className="text-3xl mt-14 font-bold text-yellow-500">NO CONTRACTS FOUND!</p>
              ) : (
                <>
                  {contractNames.length > 1 && (
                    <div className="flex flex-row gap-2 w-full max-w-7xl pb-1 px-6 lg:px-10 flex-wrap">
                      {contractNames.map(contractName => (
                        <button
                          className={`px-2 py-1 bg-gray-900 border-2 border-red-500 rounded-md text-red-500 font-bold ${
                            contractName === selectedContract ? "bg-red-500" : ""
                          }`}
                          key={contractName}
                          onClick={() => setSelectedContract(contractName)}
                        >
                          {contractName}
                        </button>
                      ))}
                    </div>
                  )}
                  {contractNames.map(contractName => (
                    <ContractUI
                      key={contractName}
                      contractName={contractName}
                      className={contractName === selectedContract ? "" : "hidden"}
                    />
                  ))}
                </>
              )}
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
