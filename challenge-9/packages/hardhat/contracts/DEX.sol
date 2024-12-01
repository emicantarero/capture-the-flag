// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    IERC20 public token; 
    uint256 public totalLiquidity; 
    mapping(address => uint256) public liquidity;

    /* ========== EVENTS ========== */
    event EthToTokenSwap(address indexed swapper, uint256 tokenOutput, uint256 ethInput);
    event TokenToEthSwap(address indexed swapper, uint256 tokensInput, uint256 ethOutput);
    event LiquidityProvided(address indexed provider, uint256 liquidityMinted, uint256 ethInput, uint256 tokensInput);
    event LiquidityRemoved(address indexed remover, uint256 liquidityWithdrawn, uint256 ethOutput, uint256 tokenOutput);

    /* ========== CONSTRUCTOR ========== */
    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Inicializa el contrato DEX con liquidez inicial
     * @param tokens Cantidad de tokens ERC20 transferidos al DEX
     * @return totalLiquidity Devuelve la liquidez total inicial creada
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX: init - already has liquidity");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens), "DEX: init - transfer did not transact");
        return totalLiquidity;
    }

    /**
     * @notice Calcula la cantidad de tokens o ETH a intercambiar según el modelo de curva constante
     * @param xInput Monto de entrada
     * @param xReserves Reservas del activo de entrada
     * @param yReserves Reservas del activo de salida
     * @return yOutput Monto del activo de salida
     */
    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = xInput * 997;
        uint256 numerator = xInputWithFee * yReserves;
        uint256 denominator = (xReserves * 1000) + xInputWithFee;
        return (numerator / denominator);
    }

    /**
     * @notice Devuelve la liquidez de un usuario
     * @param lp Dirección del proveedor de liquidez
     * @return Liquidez del usuario
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice Intercambia ETH por tokens
     * @return tokenOutput Cantidad de tokens recibidos
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "cannot swap 0 ETH");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        tokenOutput = price(msg.value, ethReserve, tokenReserve);

        require(token.transfer(msg.sender, tokenOutput), "ethToToken(): reverted swap.");
        emit EthToTokenSwap(msg.sender, tokenOutput, msg.value);
        return tokenOutput;
    }

    /**
     * @notice Intercambia tokens por ETH
     * @param tokenInput Cantidad de tokens a intercambiar
     * @return ethOutput Cantidad de ETH recibidos
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "cannot swap 0 tokens");
        uint256 tokenReserve = token.balanceOf(address(this));
        ethOutput = price(tokenInput, tokenReserve, address(this).balance);
        require(token.transferFrom(msg.sender, address(this), tokenInput), "tokenToEth(): reverted swap.");
        (bool sent, ) = msg.sender.call{ value: ethOutput }("");
        require(sent, "tokenToEth: revert in transferring eth to you!");
        emit TokenToEthSwap(msg.sender, tokenInput, ethOutput);
        return ethOutput;
    }

    /**
     * @notice Proporciona liquidez al pool
     * @return tokensDeposited Cantidad de tokens depositados
     */
    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0, "Must send value when depositing");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokenDeposit;

        tokenDeposit = (msg.value * tokenReserve / ethReserve) + 1;

        uint256 liquidityMinted = msg.value * totalLiquidity / ethReserve;
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        require(token.transferFrom(msg.sender, address(this), tokenDeposit));
        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokenDeposit);
        return tokenDeposit;
    }

    /**
     * @notice Retira liquidez del pool
     * @param amount Cantidad de liquidez a retirar
     * @return ethAmount Cantidad de ETH recibida
     * @return tokenAmount Cantidad de tokens recibida
     */
    function withdraw(uint256 amount) public returns (uint256 ethAmount, uint256 tokenAmount) {
        require(liquidity[msg.sender] >= amount, "withdraw: sender does not have enough liquidity to withdraw.");
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethWithdrawn;

        ethWithdrawn = amount * ethReserve / totalLiquidity;

        uint256 tokenAmount = amount * tokenReserve / totalLiquidity;
        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;
        (bool sent, ) = payable(msg.sender).call{ value: ethWithdrawn }("");
        require(sent, "withdraw(): revert in transferring eth to you!");
        require(token.transfer(msg.sender, tokenAmount));
        emit LiquidityRemoved(msg.sender, amount, tokenAmount, ethWithdrawn);
        return (ethWithdrawn, tokenAmount);
    }
}
