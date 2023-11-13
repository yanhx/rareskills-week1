# SafeERC20

## issues related to ERC20:

- **ERC20 transfer and transferFrom**: Should return a boolean. Several tokens do not return a boolean on these functions. As a result, their calls in the contract might fail.
- **ERC20 *approve* race-condition:** The ERC20 standard has a known ERC20 race condition that must be mitigated to prevent attackers from stealing tokens. https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#heading=h.m9fhqynw2xvt
- **Token Deflation via fees**: Transfer and transferFrom should not take a fee. Deflationary tokens can lead to unexpected behavior

```solidity
ERC20 feeToken = ERC20(0x.....);
uint256 balanceBefore = feeToken.balanceOf(recipient);
//basic implementation, lacking proper checks
(bool success,) = feeToken.transferFrom(sender, recipient, 1000);
uint256 balanceAfter = feeToken.balanceOf(recipient);
uint256 transferValue = balanceAfter - balanceBefore; //this value should be used
```

- **Token Inflation via interest (Rebasing Token)**: Potential interest earned from the token should be taken into account. Some tokens distribute interest to token holders. This interest might be trapped in the contract if not taken into account.

## SafeERC20 is created to address 2 issues:
(A) transfer function return value, and (B) approve race-condition.

Wrappers around ERC20 operations that throw on failure (when the token contract returns false). Tokens that return no value (and instead revert or throw on failure) are also supported, non-reverting calls are assumed to be successful.

```solidity
(bool success, bytes returndata) = address(token).call(data);
require(success || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
```

**increaseAllowance** and **decreaseAllowance** functions: They guarantee that no double-spending can occur.

These functions only **change** the allowance by a certain value, instead of **setting** the new one.


## When to Use SafeERC20  

1. **Broad Compatibility**: If you're writing a contract that needs to interact with multiple ERC20 tokens, especially those not well-known or audited, using SafeERC20 can help ensure that your contract behaves correctly regardless of any peculiarities in the token's implementation.  

2. **Avoiding Edge Cases**: When you want to avoid unexpected behavior or errors due to the inconsistent implementations of ERC20 tokens.  

3. **Security**: If you want to ensure the best practices when calling `approve` and prevent potential attacks related to token allowances.  