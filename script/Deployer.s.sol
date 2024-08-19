// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {Script, console} from "forge-std/Script.sol";
import "../src/core/RedemptionPool.sol";
import "../src/core/sale/DirectSalePool.sol";
import "../src/core/sale/InvestorSalePool.sol";
import "../src/core/token/NftManager.sol";
import "../src/core/FishcakeEventManager.sol";

/*
forge script script/Deployer.s.sol:DeployerScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY  --broadcast -vvvv
*/
contract DeployerScript is Script {
    ProxyAdmin public dapplinkProxyAdmin;

    RedemptionPool public redemptionPool;

    // ========= can upgrade ===========
    FishCakeCoin public fishCakeCoin;
    DirectSalePool public directSalePool;
    InvestorSalePool public investorSalePool;
    NftManager public nftManager;
    FishcakeEventManager public fishcakeEventManager;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        address usdtTokenAddress =  vm.envAddress("USDT_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        dapplinkProxyAdmin = new ProxyAdmin(deployerAddress);
        console.log("deploy dapplinkProxyAdmin:", address(dapplinkProxyAdmin));


        fishCakeCoin = new FishCakeCoin();

        TransparentUpgradeableProxy proxyFishCakeCoin = new TransparentUpgradeableProxy(
            address(fishCakeCoin),
            address(dapplinkProxyAdmin),
            abi.encodeWithSelector(FishCakeCoin.initialize.selector, deployerAddress, address(0))
        );
        console.log("deploy proxyFishCakeCoin:", address(proxyFishCakeCoin));


        // can not upgrade
        redemptionPool = new  RedemptionPool(address(proxyFishCakeCoin), usdtTokenAddress);
        console.log("deploy redemptionPool:", address(redemptionPool));


        directSalePool = new DirectSalePool(address(proxyFishCakeCoin), address(redemptionPool), usdtTokenAddress);
        TransparentUpgradeableProxy proxyDirectSalePool = new TransparentUpgradeableProxy(
            address(directSalePool),
            address(dapplinkProxyAdmin),
            abi.encodeWithSelector(DirectSalePool.initialize.selector, deployerAddress)
        );
        console.log("deploy proxyDirectSalePool:", address(proxyDirectSalePool));


        investorSalePool = new InvestorSalePool(address(proxyFishCakeCoin), address(redemptionPool), usdtTokenAddress);
        TransparentUpgradeableProxy proxyInvestorSalePool = new TransparentUpgradeableProxy(
            address(investorSalePool),
            address(dapplinkProxyAdmin),
            abi.encodeWithSelector(InvestorSalePool.initialize.selector, deployerAddress)
        );
        console.log("deploy proxyInvestorSalePool:", address(proxyInvestorSalePool));

        nftManager = new NftManager(address(proxyFishCakeCoin), usdtTokenAddress, address(redemptionPool));
        TransparentUpgradeableProxy proxyNftManager = new TransparentUpgradeableProxy(
            address(nftManager),
            address(dapplinkProxyAdmin),
            abi.encodeWithSelector(NftManager.initialize.selector, deployerAddress)
        );
        console.log("deploy proxyNftManager:", address(proxyNftManager));

        fishcakeEventManager = new FishcakeEventManager(address(proxyFishCakeCoin), usdtTokenAddress, address(proxyNftManager));
        TransparentUpgradeableProxy proxyFishcakeEventManager = new TransparentUpgradeableProxy(
            address(fishcakeEventManager),
            address(dapplinkProxyAdmin),
            abi.encodeWithSelector(FishcakeEventManager.initialize.selector, deployerAddress)
        );
        console.log("deploy proxyFishcakeEventManager:", address(proxyFishcakeEventManager));

        // setUp
        FishCakeCoin(address(proxyFishCakeCoin)).setRedemptionPool(address(redemptionPool));
        IInvestorSalePool(address(proxyInvestorSalePool)).setValutAddress(deployerAddress);

        vm.stopBroadcast();
    }
}
