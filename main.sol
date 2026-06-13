// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title JestarAIX — spectral intent relay over epoch-keyed lattice lines.
/// @dev codename: violet jestar / echo shelf delta

library JxaScale {
    error JXA_ScaleOverflow();
    uint256 internal constant BPS = 10_000;
    function clampU24(uint256 v, uint24 lo, uint24 hi) internal pure returns (uint24) {
        if (v < lo) return lo;
        if (v > hi) return hi;
        return uint24(v);
    }
    function takeBps(uint256 gross, uint256 bps) internal pure returns (uint256) {
        unchecked { return (gross * bps) / BPS; }
    }
    function safeAdd(uint256 a, uint256 b, uint256 cap) internal pure returns (uint256) {
        unchecked {
            uint256 s = a + b;
            if (s < a || s > cap) revert JXA_ScaleOverflow();
            return s;
        }
    }
}

contract JestarAIX {
    error JXA_NotDirector();
    error JXA_NotHerald();
    error JXA_GridFrozen();
    error JXA_ZeroAddr();
    error JXA_ZeroWei();
    error JXA_Reentered();
    error JXA_LineDead();
    error JXA_LineMuted();
    error JXA_BeaconTaken();
    error JXA_BeaconGone();
    error JXA_BandOff();
    error JXA_CapHit();
    error JXA_EpochOff();
    error JXA_PulseLive();
    error JXA_PulseGone();
    error JXA_PulseDone();
    error JXA_HeraldStale();
    error JXA_SignalLow();
    error JXA_SignalHigh();
    error JXA_SelfRoute();
    error JXA_HashEmpty();
    error JXA_VoteSpent();
    error JXA_VoteSelf();
    error JXA_BondThin();
    error JXA_SendFail();
    error JXA_ArrayWide();
    error JXA_SizeMismatch();
    error JXA_NotScout();
    error JXA_ScoutKnown();
    error JXA_NoPending();
    error JXA_PendingSet();
    error JXA_Fault_31();
    error JXA_Fault_32();
    error JXA_Fault_33();
    error JXA_Fault_34();
    error JXA_Fault_35();
    error JXA_Fault_36();
    error JXA_Fault_37();
    error JXA_Fault_38();
    error JXA_Fault_39();

    event JXA_BeaconPosted(bytes32 indexed beaconId, uint256 indexed lineId, address indexed scout, uint8 band, uint256 weiLocked);
    event JXA_BeaconVoted(bytes32 indexed beaconId, address indexed voter, bool up, uint256 epochId);
    event JXA_BeaconBoosted(bytes32 indexed beaconId, address indexed from, uint256 weiAmt, uint256 epochId);
    event JXA_PulseQueued(bytes32 indexed pulseId, uint256 indexed lineId, bytes32 relayTag, uint256 queuedAt);
    event JXA_PulseFired(bytes32 indexed pulseId, bytes32 outcomeHash, uint16 signalRating, uint256 epochId);
    event JXA_WaveEmitted(bytes32 indexed waveId, uint256 indexed lineId, uint16 wavelength, uint256 at);
    event JXA_LineOpened(uint256 indexed lineId, bytes32 lineNonce, uint8 band, uint256 seedMass);
    event JXA_EpochTurned(uint256 indexed epochId, uint64 wallAt, uint256 beaconMass, uint256 pulseMass);
    event JXA_GridFrozenSet(bool gridFrozen, address indexed by, uint256 atBlock);
    event JXA_HeraldSet(address indexed herald, uint256 atBlock);
    event JXA_RelayFunded(address indexed from, uint256 weiAmt, uint256 atBlock);
    event JXA_ScoutJoined(address indexed scout, bytes32 tag, uint256 bondWei);
    event JXA_ScoutLeft(address indexed scout, uint256 atBlock);
    event JXA_DirectorProposed(address indexed pending, uint256 atBlock);
    event JXA_DirectorAccepted(address indexed director, uint256 atBlock);
    event JXA_Echo_0(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);
    event JXA_Echo_1(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);
    event JXA_Echo_2(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);
    event JXA_Echo_3(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);
    event JXA_Echo_4(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);
    event JXA_Echo_5(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);
    event JXA_Echo_6(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);
    event JXA_Echo_7(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);
    event JXA_Echo_8(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);
    event JXA_Echo_9(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);
    event JXA_Echo_10(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);
    event JXA_Echo_11(uint256 indexed slot, address indexed actor, uint256 meta, uint256 epochId);

    enum JxaLineStatus { Vacant, Live, Muted }
    enum JxaPulseStage { Waiting, Active, Finalized, Scrapped }

    struct JxaLine {
        JxaLineStatus status;
        uint8 signalBand;
        uint64 openedAt;
        uint32 beaconCount;
        uint32 pulseCount;
        uint256 massSum;
        bytes32 lineNonce;
    }

    struct JxaBeacon {
        uint256 lineId;
        address scout;
        bytes32 intentSeal;
        uint8 signalBand;
        uint32 upVotes;
        uint32 downVotes;
        uint256 lockedWei;
        uint64 postedAt;
        bool open;
    }

    struct JxaPulse {
        uint256 lineId;
        address proposer;
        bytes32 relayTag;
        JxaPulseStage stage;
        bytes32 outcomeHash;
        uint16 signalRating;
        uint64 queuedAt;
    }

    struct JxaWave {
        uint256 lineId;
        bytes32 waveTag;
        bytes32 prismHash;
        uint16 wavelength;
        uint64 stampedAt;
    }

    struct JxaEpochRing {
        uint64 openedAt;
        uint256 beaconMass;
        uint256 pulseMass;
        bytes32 ringDigest;
    }

    struct JxaScoutBench {
        bool active;
        bytes32 tag;
        uint64 joinedAt;
        uint32 beaconCount;
    }

    uint256 public constant JXA_BAND_CAP = 5;
    uint256 public constant JXA_BEACON_FEE = 0.003 ether;
