// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";

contract fomo3d {
    using SafeMath for uint256;

    enum Group {
        One,
        Two,
        Three
    }
    enum Way {
        Bnb,
        Vault
    }
    address public owner;
    uint256 public key_init_price;
    uint256 public key_final_price;
    uint256 public key_increasing_price;
    uint256 public rounds;
    mapping(uint256 => uint256) public start_time;
    mapping(uint256 => uint256) public end_time;
    mapping(address => mapping(uint256 => Group)) public team;
    mapping(address => uint256) private _nonce;
    bool private _notEntered = true;

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    bytes32 public constant VAULTBUY_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "VaultBuy(uint256 buy_num,uint256 team,address account,uint256 nonce)"
            )
        );
    bytes32 public constant CLAIM_TRANSACTION_TYPEHASH =
        keccak256(bytes("Claim(address account,uint256 number,uint256 nonce)"));

    event BuyKey(
        address account,
        uint256 bnbvalue,
        uint256 buy_num,
        Group team,
        uint256 rounds,
        Way buyway,
        address invite_address
    );

    event Claim(address account, uint256 claimvalue);

    event SetActionTime(uint256 time);

    constructor(address _owner) {
        owner = _owner;
        key_init_price = 0.01 * 1e18;
        key_final_price = 0.01 * 1e18;
        key_increasing_price = 0.00002 * 1e18;
        rounds = 1;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("Fomo3d")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    function setActionTime(uint256 _time) external onlyOwner {
        // require(start_time[rounds] == 0, "Start time has been set");
        require(
            _time > block.timestamp,
            "Set time must be greater than the current time"
        );
        start_time[rounds] = _time;
        end_time[rounds] = _time.add(24 * 60 * 20 * 3);
        emit SetActionTime(_time);
    }

    function nonceOf(address account) public view returns (uint256) {
        return _nonce[account];
    }

    function _buy_key_inner(
        uint256 _buy_num,
        Group _team,
        Way _way
    ) internal returns (uint256) {
        team[msg.sender][rounds] = _team;
        uint256 key_add_price = key_increasing_price.mul(_buy_num.sub(1));
        uint256 final_price = key_add_price.add(key_final_price);
        uint256 first_last_add_price = final_price.add(key_final_price);
        key_final_price = final_price.add(key_increasing_price);
        first_last_add_price = first_last_add_price.mul(_buy_num);
        first_last_add_price = first_last_add_price.div(2);
        if (_way == Way.Bnb) {
            require(first_last_add_price == msg.value, "Insufficient payment");
        }
        end_time[rounds] = end_time[rounds].add(_buy_num.mul(30));
        return first_last_add_price;
    }

    function _buy_key(
        uint256 _buy_num,
        Group _team,
        Way _way
    ) internal returns (uint256) {
        require(block.timestamp >= start_time[rounds], "Not started yet");
        if (block.timestamp >= end_time[rounds]) {
            rounds = rounds.add(1);
            end_time[rounds] = end_time[rounds].add(24 * 60 * 20 * 3);
            key_final_price = key_init_price;
            return _buy_key_inner(_buy_num, _team, _way);
        } else {
            return _buy_key_inner(_buy_num, _team, _way);
        }
    }

    function bnbBuy(
        uint256 _buy_num,
        Group _team,
        address _invite_address
    ) external payable nonReentrant {
        _buy_key(_buy_num, _team, Way.Bnb);
        emit BuyKey(
            msg.sender,
            msg.value,
            _buy_num,
            _team,
            rounds,
            Way.Bnb,
            _invite_address
        );
    }

    function vaultBuy(
        uint256 _buy_num,
        Group _team,
        address _account,
        uint256 nonce,
        address _invite_address,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        VAULTBUY_TRANSACTION_TYPEHASH,
                        _buy_num,
                        _team,
                        _account,
                        nonce
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress == owner &&
                _account == msg.sender &&
                _buy_num > uint256(0) &&
                nonce > _nonce[_account]
        );
        uint256 value = _buy_key(_buy_num, _team, Way.Vault);
        _nonce[_account]++;

        emit BuyKey(
            msg.sender,
            value,
            _buy_num,
            _team,
            rounds,
            Way.Vault,
            _invite_address
        );
    }

    function claim(
        address payable _account,
        uint256 _number,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        CLAIM_TRANSACTION_TYPEHASH,
                        _account,
                        _number,
                        nonce
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress == owner &&
                _account == msg.sender &&
                _number > uint256(0) &&
                nonce > _nonce[_account]
        );
        _nonce[_account]++;
        _account.transfer(_number);
        emit Claim(msg.sender, _number);
    }
}
