// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library DataTypes {
    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 currentLiquidityRate;
        uint128 variableBorrowIndex;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        uint16 id;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint128 accruedToTreasury;
        uint128 unbacked;
        uint128 isolationModeTotalDebt;
    }
}

interface IPool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function getReserveData(
        address asset
    ) external view returns (DataTypes.ReserveData memory);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract AaveLender {
    address public immutable AAVE_POOL_ADDRESS = 0x48914C788295b5db23aF2b5F0B3BE775C4eA9440;
    address public immutable STAKED_TOKEN_ADDRESS = 0x7984E363c38b590bB4CA35aEd5133Ef2c6619C40;

    mapping(address => uint256) public deposits;

    function stake(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");

        IERC20 daiToken = IERC20(STAKED_TOKEN_ADDRESS);
        IPool aavePool = IPool(AAVE_POOL_ADDRESS);

        require(daiToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        require(daiToken.approve(AAVE_POOL_ADDRESS, amount), "Approval failed");

        aavePool.supply(STAKED_TOKEN_ADDRESS, amount, msg.sender, 0);

        deposits[msg.sender] += amount;
    }

    function unstake(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(deposits[msg.sender] >= amount, "Insufficient balance");

        IPool aavePool = IPool(AAVE_POOL_ADDRESS);

        DataTypes.ReserveData memory reserveData = aavePool.getReserveData(STAKED_TOKEN_ADDRESS);
        address aTokenAddress = reserveData.aTokenAddress;

        IERC20 aToken = IERC20(aTokenAddress);

        require(aToken.approve(AAVE_POOL_ADDRESS, amount), "Approval failed");

        uint256 withdrawnAmount = aavePool.withdraw(STAKED_TOKEN_ADDRESS, amount, msg.sender);
        require(withdrawnAmount == amount, "Withdrawn amount mismatch");

        deposits[msg.sender] -= amount;
    }
}
