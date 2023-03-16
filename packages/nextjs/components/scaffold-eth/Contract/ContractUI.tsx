import { Contract, ethers } from "ethers";
import { useMemo, useState, useEffect } from "react";
import { useContract, useProvider } from "wagmi";
import { getAllContractFunctions, getContractWriteMethods } from "./utilsContract";
import { Address } from "~~/components/scaffold-eth";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { getTargetNetwork } from "~~/utils/scaffold-eth";
import Spinner from "~~/components/Spinner";

type TContractUIProps = {
  contractName: string;
  className?: string;
};

type TDelegation = {
  delegator: string;
  delegate: string;
  token: string;
  amount: string;
};

/**
 * UI component to interface with deployed contracts.
 **/
const ContractUI = ({ contractName, className = "" }: TContractUIProps) => {
  const configuredChain = getTargetNetwork();
  const provider = useProvider() as ethers.providers.JsonRpcProvider;
  const [refreshDisplayVariables, setRefreshDisplayVariables] = useState(false);
  const [delegations, setDelegations] = useState<TDelegation[]>([]);
  const [isLoadingDelegations, setIsLoadingDelegations] = useState(false);

  let contractAddress = "";
  let contractABI = [];
  const { data: deployedContractData, isLoading: deployedContractLoading } = useDeployedContractInfo(contractName);
  if (deployedContractData) {
    ({ address: contractAddress, abi: contractABI } = deployedContractData);
  }

  const contract: Contract | null = useContract({
    address: contractAddress,
    abi: contractABI,
    signerOrProvider: provider,
  });

  const displayedContractFunctions = useMemo(() => getAllContractFunctions(contract), [contract]);

  useEffect(() => {
    const fetchDelegations = async () => {
      if (contract && provider) {
        const signer = provider.getSigner();
        const address = await signer.getAddress();
        setIsLoadingDelegations(true);
        try {
          const delegationsData = await contract.getDelegationsForWallet(address);
          const delegationsArray = [];

          if (typeof delegationsData === "string") {
            delegationsData.split(",").reduce((acc: TDelegation[], value: string, index: number) => {
              if (index % 4 === 0) {
                acc.push({
                  delegator: value,
                  delegate: "",
                  token: "",
                  amount: "",
                });
              } else {
                const currentDelegation = acc[acc.length - 1];
                switch (index % 4) {
                  case 1:
                    currentDelegation.delegate = value;
                    break;
                  case 2:
                    currentDelegation.token = value;
                    break;
                  case 3:
                    currentDelegation.amount = ethers.utils.formatEther(value);
                    break;
                }
              }
              return acc;
            }, []);
          } else if (Array.isArray(delegationsData)) {
            for (const delegationData of delegationsData) {
              // Assuming the data is an array of arrays with 4 elements each.
              delegationsArray.push({
                delegator: delegationData[0],
                delegate: delegationData[1],
                token: delegationData[2],
                amount: ethers.utils.formatEther(delegationData[3]),
              });
            }
          } else {
            console.error("Unexpected delegationsData format:", delegationsData);
          }

          setDelegations(delegationsArray);
        } catch (err) {
          console.error("Failed to fetch delegations", err);
        } finally {
          setIsLoadingDelegations(false);
        }
      }
    };

    if (provider) {
      fetchDelegations();
    }
  }, [contract, provider]);
  console.log("Delegations:", delegations);

  const contractWriteMethods = useMemo(
    () => getContractWriteMethods(contract, displayedContractFunctions, setRefreshDisplayVariables),
    [contract, displayedContractFunctions],
  );

  if (deployedContractLoading) {
    return (
      <div className="mt-14">
        <Spinner width="50px" height="50px" />
      </div>
    );
  }

  if (!contractAddress) {
    return (
      <p className="text-3xl mt-14">
        {`No contract found by the name of "${contractName}" on chain "${configuredChain.name}"!`}
      </p>
    );
  }

  function abbreviateAddress(address: string | any[], length = 6) {
    if (!address) return "";
    const prefix = address.slice(0, length + 2);
    const suffix = address.slice(-length);
    return `${prefix}...${suffix}`;
  }

  return (
    <div className={`bg-gray-900 py-16 ${className}`}>
      <div className="mx-auto max-w-7xl px-100 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1 className="text-4xl font-extrabold text-white sm:text-5xl sm:tracking-tight lg:text-6xl"></h1>
          <div className="text-gray-400 mt-4 items-center">
            <Address address={contractAddress} />
            {configuredChain && (
              <p>
                <span className="font-bold text-gray-400">Network:</span>{" "}
                <span className="text-base text-gray-400">{configuredChain.name}</span>
              </p>
            )}
          </div>
        </div>
        <div className="mt-12 grid gap-16 lg:grid-cols-2 lg:gap-x-5 lg:gap-y-12">
          {/* <div className="flex flex-col bg-gray-800 rounded-lg border-2 border-gray-600 shadow-lg overflow-hidden">
            <div className="px-6 py-8 bg-gray-700 border-b-2 border-gray-600">
              <h3 className="text-lg font-medium leading-6 text-white">{contractName} Variables</h3>
            </div>
            <div className="flex-1 bg-gray-600 px-6 pt-6 pb-8">
              {contractVariablesDisplay.methods.length > 0 ? (
                contractVariablesDisplay.methods
              ) : (
                <p className="text-base font-medium text-gray-400">No contract variables</p>
              )}
            </div>
          </div> */}
          <div className="flex flex-col bg-gray-800 rounded-lg border-2 border-gray-600 shadow-lg overflow-hidden">
            <div className="px-6 py-8 bg-gray-700 border-b-2 border-gray-600">
              <h3 className="text-lg font-medium leading-6 text-white">Your DelegatiOOns</h3>
            </div>
            {delegations && delegations.length > 0 ? (
              <div className="grid grid-cols-4 gap-4 text-sm p-4">
                {delegations.map((delegation, index) => (
                  <div
                    key={index}
                    className="bg-gray-800 border-4 border-gray-700 shadow-lg hover:bg-gray-900 hover:border-gray-600 hover:shadow-xl transition-all duration-200 p-4 rounded break-word"
                  >
                    <p>
                      <strong>Delegator:</strong> {abbreviateAddress(delegation.delegator)}
                    </p>
                    <p>
                      <strong>Delegate:</strong> {abbreviateAddress(delegation.delegate)}
                    </p>
                    <p>
                      <strong>Token:</strong> {abbreviateAddress(delegation.token)}
                    </p>
                    <p>
                      <strong>Amount:</strong> {delegation.amount}
                    </p>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-base font-medium text-gray-400">No delegations!</p>
            )}
          </div>
          <div className="flex flex-col bg-gray-800 rounded-lg border-2 border-gray-600 shadow-lg overflow-hidden">
            <div className="px-6 py-8 bg-gray-700 border-b-2 border-gray-600">
              <h3 className="text-lg font-medium leading-6 text-white">Write Methods</h3>
            </div>
            <div className="flex-1 bg-gray-600 px-6 pt-6 pb-8">
              {contractWriteMethods.methods.length > 0 ? (
                contractWriteMethods.methods
              ) : (
                <p className="text-base font-medium text-gray-400">No write methods</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ContractUI;
