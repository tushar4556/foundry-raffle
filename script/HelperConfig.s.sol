//SPDX-License-Idenitifier:MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
abstract contract CodeConstants {
    /* VRF Mock Values */

    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;

    // LINK / ETH price
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15;

    uint256 public constant SEPOLIA_ETH_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_ETH_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns(NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 500000,
                subscriptionId: 0,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: 0x40d8e343e3f55E4d19105971A6D7fBcF8Af0A890
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        //Deploy mocks and such
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            //Doesn't matter
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            link: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });

        return localNetworkConfig;
    }
}
