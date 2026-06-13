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
    uint256 public constant JXA_HERALD_BOND = 0.03 ether;
    uint256 public constant JXA_MAX_BEACONS = 187;
    uint256 public constant JXA_OPEN_PULSE_CAP = 66;
    uint256 public constant JXA_WAVE_FLOOR = 464;
    uint256 public constant JXA_WAVE_CEIL = 7294;
    uint256 public constant JXA_EPOCH_BLOCKS = 396;
    uint256 public constant JXA_MASS_CAP = 12634;
    uint256 public constant JXA_SIGNAL_FLOOR = 296;
    uint256 public constant JXA_SIGNAL_CEIL = 7160;
    uint256 public constant JXA_LINE_COUNT = 30;

    bytes32 private constant _NONCE_0 = 0x8f0afe56e239b0acbc05e31ad109462d8beca393528d917e7adbf6a0ad4e3852;
    bytes32 private constant _NONCE_1 = 0xf54b57c3d0eecc10a01ab73ee8f4c07d44108b13644d14e7276c72f76c870fb9;
    bytes32 private constant _NONCE_2 = 0x75b3341df3aeebcac3acb2a9a624542c169e36586bdc13e86743691a1e5bf077;
    bytes32 private constant _NONCE_3 = 0x68bbd8229a4e1029f3ca50cc7df16e2d9223eec2ad925905ad1969944a84c0bb;
    bytes32 private constant _NONCE_4 = 0x338f0ce465321b3a83e8948694781254ba0131f1bce72999354b944b5fdfb592;
    bytes32 private constant _NONCE_5 = 0x709308d0bff25a5801741a6c0064955566aaa4900893e7890bfca55aa0495659;
    bytes32 private constant _NONCE_6 = 0xb19b45494e07db3e6e3bc5dbe876d48da69bbc469715b0a7e2c8904e3697d10f;
    bytes32 private constant _NONCE_7 = 0x63568a8347be43a3ef61355387a07b9fd71226bda24b4bd8747097e988bcdf1d;
    bytes32 private constant JXA_DOMAIN = keccak256("JestarAIX.spectralRelay");

    address public director;
    address public immutable ADDRESS_A;
    address public immutable ADDRESS_B;
    address public immutable ADDRESS_C;

    address public pendingDirector;
    address public herald;
    bool public gridFrozen;
    uint256 public activeEpoch;
    uint256 public echoSerial;
    uint256 public openPulses;
    uint256 public escrowWei;
    uint256 public bornBlock;
    uint256 public lineSerial;

    mapping(uint256 => JxaLine) public lines;
    mapping(bytes32 => JxaBeacon) public beacons;
    mapping(bytes32 => JxaPulse) public pulses;
    mapping(bytes32 => JxaWave) public waves;
    mapping(uint256 => JxaEpochRing) public epochRings;
    mapping(uint256 => mapping(address => uint256)) public scoutMass;
    mapping(bytes32 => mapping(address => bool)) public voteCast;
    mapping(bytes32 => bool) public beaconIdUsed;
    mapping(bytes32 => bool) public pulseIdUsed;
    mapping(bytes32 => bool) public waveIdUsed;
    mapping(address => JxaScoutBench) public scoutBenches;
    mapping(address => bytes32[]) private _beaconsByScout;
    bytes32[] private _beaconRoll;
    uint256 private _guard;

    modifier nonReentrant() {
        if (_guard == 2) revert JXA_Reentered();
        _guard = 2;
        _;
        _guard = 1;
    }

    modifier onlyDirector() {
        if (msg.sender != director) revert JXA_NotDirector();
        _;
    }

    modifier onlyHerald() {
        if (msg.sender != herald) revert JXA_NotHerald();
        _;
    }

    modifier whenLive() {
        if (gridFrozen) revert JXA_GridFrozen();
        _;
    }

    modifier onlyActiveScout() {
        if (!scoutBenches[msg.sender].active) revert JXA_NotScout();
        _;
    }

    constructor() {
        director = msg.sender;
        ADDRESS_A = 0x2C132795c32391fd70901a78A51157E973172d68;
        ADDRESS_B = 0x762fe07Ec9b52f09C6712ac1c4fFf02e851A04F8;
        ADDRESS_C = 0x089a29601FDcf1056a6Ff9CC0473B6fDF9d5923B;
        herald = ADDRESS_A;
        _guard = 1;
        bornBlock = block.number;
        activeEpoch = 1;
        lineSerial = JXA_LINE_COUNT;
        _beginEpoch(1);
        _bootLines();
    }

    function proposeDirector(address next_) external onlyDirector {
        if (next_ == address(0)) revert JXA_ZeroAddr();
        if (pendingDirector != address(0)) revert JXA_PendingSet();
        pendingDirector = next_;
        emit JXA_DirectorProposed(next_, block.number);
    }

    function acceptDirector() external {
        if (msg.sender != pendingDirector) revert JXA_NoPending();
        director = pendingDirector;
        pendingDirector = address(0);
        emit JXA_DirectorAccepted(director, block.number);
    }

    function setHerald(address next_) external onlyDirector {
        if (next_ == address(0)) revert JXA_ZeroAddr();
        herald = next_;
        emit JXA_HeraldSet(next_, block.number);
    }

    function setGridFrozen(bool on) external onlyDirector {
        gridFrozen = on;
        emit JXA_GridFrozenSet(on, msg.sender, block.number);
    }

    function turnEpoch() external onlyDirector whenLive {
        uint256 n = activeEpoch + 1;
        if (n > 44) revert JXA_EpochOff();
        activeEpoch = n;
        _beginEpoch(n);
        emit JXA_EpochTurned(n, uint64(block.timestamp), _epochBeaconMass(), openPulses);
    }

    function muteLine(uint256 lineId) external onlyHerald {
        JxaLine storage ln = lines[lineId];
        if (ln.status == JxaLineStatus.Vacant) revert JXA_LineDead();
        ln.status = JxaLineStatus.Muted;
    }

    function enrollScout(address scout, bytes32 tag) external onlyDirector {
        if (scout == address(0)) revert JXA_ZeroAddr();
        if (scoutBenches[scout].active) revert JXA_ScoutKnown();
        scoutBenches[scout] = JxaScoutBench({
            active: true,
            tag: tag,
            joinedAt: uint64(block.timestamp),
            beaconCount: 0
        });
        emit JXA_ScoutJoined(scout, tag, 0);
    }

    function dropScout(address scout) external onlyDirector {
        if (!scoutBenches[scout].active) revert JXA_NotScout();
        scoutBenches[scout].active = false;
        emit JXA_ScoutLeft(scout, block.number);
    }

    function skimExcess(uint256 amt, address payable to) external onlyDirector nonReentrant {
        if (to == address(0)) revert JXA_ZeroAddr();
        if (amt == 0 || amt > address(this).balance) revert JXA_ZeroWei();
        if (amt > address(this).balance - escrowWei) revert JXA_CapHit();
        _pushNative(to, amt);
    }

    function fundRelay() external payable whenLive {
        if (msg.value == 0) revert JXA_ZeroWei();
        emit JXA_RelayFunded(msg.sender, msg.value, block.number);
        emit JXA_Echo_0(echoSerial, msg.sender, msg.value, activeEpoch);
        unchecked { echoSerial += 1; }
    }

    function postBeacon(
        bytes32 beaconId,
        uint256 lineId,
        bytes32 intentSeal,
        uint8 signalBand
    ) external payable nonReentrant whenLive onlyActiveScout {
        if (beaconId == bytes32(0)) revert JXA_HashEmpty();
        if (beaconIdUsed[beaconId]) revert JXA_BeaconTaken();
        if (msg.value < JXA_BEACON_FEE) revert JXA_BondThin();
        if (signalBand == 0 || signalBand > JXA_BAND_CAP) revert JXA_BandOff();
        JxaLine storage ln = lines[lineId];
        if (ln.status != JxaLineStatus.Live) revert JXA_LineMuted();
        if (ln.beaconCount >= JXA_MAX_BEACONS) revert JXA_CapHit();
        beaconIdUsed[beaconId] = true;
        beacons[beaconId] = JxaBeacon({
            lineId: lineId,
            scout: msg.sender,
            intentSeal: intentSeal,
            signalBand: signalBand,
            upVotes: 0,
            downVotes: 0,
            lockedWei: msg.value,
            postedAt: uint64(block.timestamp),
            open: true
        });
        unchecked {
            ln.beaconCount += 1;
            ln.massSum = JxaScale.safeAdd(
                ln.massSum, uint256(signalBand) * 73, JXA_MASS_CAP
            );
            scoutBenches[msg.sender].beaconCount += 1;
        }
        scoutMass[activeEpoch][msg.sender] += uint256(signalBand) * 19;
        escrowWei += msg.value;
        _beaconsByScout[msg.sender].push(beaconId);
        _beaconRoll.push(beaconId);
        emit JXA_BeaconPosted(beaconId, lineId, msg.sender, signalBand, msg.value);
    }

    function voteBeacon(bytes32 beaconId, bool up) external whenLive {
        JxaBeacon storage b = beacons[beaconId];
        if (!b.open) revert JXA_BeaconGone();
        if (b.scout == msg.sender) revert JXA_VoteSelf();
        if (voteCast[beaconId][msg.sender]) revert JXA_VoteSpent();
        voteCast[beaconId][msg.sender] = true;
        if (up) unchecked { b.upVotes += 1; }
        else unchecked { b.downVotes += 1; }
        emit JXA_BeaconVoted(beaconId, msg.sender, up, activeEpoch);
    }

    function boostBeacon(bytes32 beaconId) external payable nonReentrant whenLive {
        if (msg.value == 0) revert JXA_ZeroWei();
        JxaBeacon storage b = beacons[beaconId];
        if (!b.open) revert JXA_BeaconGone();
        b.lockedWei += msg.value;
        escrowWei += msg.value;
        emit JXA_BeaconBoosted(beaconId, msg.sender, msg.value, activeEpoch);
    }

    function joinScout(bytes32 tag) external payable nonReentrant whenLive {
        if (msg.value < JXA_HERALD_BOND) revert JXA_BondThin();
        if (scoutBenches[msg.sender].active) revert JXA_ScoutKnown();
        scoutBenches[msg.sender] = JxaScoutBench({
            active: true,
            tag: tag,
            joinedAt: uint64(block.timestamp),
            beaconCount: 0
        });
        escrowWei += msg.value;
        emit JXA_ScoutJoined(msg.sender, tag, msg.value);
    }

    function queuePulse(bytes32 pulseId, uint256 lineId, bytes32 relayTag)
        external
        payable
        nonReentrant
        whenLive
        onlyActiveScout
    {
        if (pulseId == bytes32(0)) revert JXA_HashEmpty();
        if (pulseIdUsed[pulseId]) revert JXA_PulseLive();
        if (msg.value < JXA_BEACON_FEE) revert JXA_BondThin();
        if (openPulses >= JXA_OPEN_PULSE_CAP) revert JXA_CapHit();
        JxaLine storage ln = lines[lineId];
        if (ln.status != JxaLineStatus.Live) revert JXA_LineMuted();
        pulseIdUsed[pulseId] = true;
        pulses[pulseId] = JxaPulse({
            lineId: lineId,
            proposer: msg.sender,
            relayTag: relayTag,
            stage: JxaPulseStage.Waiting,
            outcomeHash: bytes32(0),
            signalRating: 0,
            queuedAt: uint64(block.timestamp)
        });
        unchecked {
            openPulses += 1;
            ln.pulseCount += 1;
        }
        escrowWei += msg.value;
        emit JXA_PulseQueued(pulseId, lineId, relayTag, block.timestamp);
    }

    function firePulse(bytes32 pulseId, bytes32 outcomeHash, uint16 signalRating) external onlyHerald {
        JxaPulse storage p = pulses[pulseId];
        if (p.stage != JxaPulseStage.Waiting && p.stage != JxaPulseStage.Active) revert JXA_PulseDone();
        if (signalRating < JXA_SIGNAL_FLOOR) revert JXA_SignalLow();
        if (signalRating > JXA_SIGNAL_CEIL) revert JXA_SignalHigh();
        p.stage = JxaPulseStage.Finalized;
        p.outcomeHash = outcomeHash;
        p.signalRating = signalRating;
        if (openPulses > 0) unchecked { openPulses -= 1; }
        emit JXA_PulseFired(pulseId, outcomeHash, signalRating, activeEpoch);
    }

    function emitWave(
        bytes32 waveId,
        uint256 lineId,
        bytes32 waveTag,
        bytes32 prismHash,
        uint16 wavelength
    ) external onlyHerald whenLive {
        if (waveIdUsed[waveId]) revert JXA_HeraldStale();
        if (wavelength < JXA_WAVE_FLOOR) revert JXA_SignalLow();
        if (wavelength > JXA_WAVE_CEIL) revert JXA_SignalHigh();
        JxaLine storage ln = lines[lineId];
        if (ln.status != JxaLineStatus.Live) revert JXA_LineMuted();
        waveIdUsed[waveId] = true;
        waves[waveId] = JxaWave({
            lineId: lineId,
            waveTag: waveTag,
            prismHash: prismHash,
            wavelength: wavelength,
            stampedAt: uint64(block.timestamp)
        });
        emit JXA_WaveEmitted(waveId, lineId, wavelength, block.timestamp);
    }

    function redeemBeacon(bytes32 beaconId, address payable to) external nonReentrant whenLive {
        JxaBeacon storage b = beacons[beaconId];
        if (!b.open) revert JXA_BeaconGone();
        if (b.scout != msg.sender) revert JXA_SelfRoute();
        if (to == address(0)) revert JXA_ZeroAddr();
        uint256 amt = b.lockedWei;
        if (amt == 0) revert JXA_ZeroWei();
        b.open = false;
        b.lockedWei = 0;
        escrowWei -= amt;
        _pushNative(to, amt);
    }

    function _pushNative(address to, uint256 amt) internal {
        (bool ok, ) = payable(to).call{value: amt}("");
        if (!ok) revert JXA_SendFail();
    }

    function _beginEpoch(uint256 epochId) internal {
        JxaEpochRing storage ring = epochRings[epochId];
        ring.openedAt = uint64(block.timestamp);
        ring.beaconMass = _epochBeaconMass();
        ring.pulseMass = openPulses;
        ring.ringDigest = _ringDigest(epochId, ring.beaconMass, ring.pulseMass);
    }

    function _ringDigest(uint256 epochId, uint256 bm, uint256 pm) internal view returns (bytes32) {
        bytes32 hA = keccak256(abi.encode(JXA_DOMAIN, epochId, bm, _NONCE_0, ADDRESS_A));
        bytes32 hB = keccak256(abi.encode(pm, _NONCE_1, ADDRESS_B, ADDRESS_C, bornBlock));
        return keccak256(abi.encodePacked(hA, hB, JXA_EPOCH_BLOCKS));
    }

    function beaconDigest(bytes32 beaconId) public view returns (bytes32) {
        JxaBeacon storage b = beacons[beaconId];
        bytes32 hA = keccak256(abi.encode(beaconId, b.lineId, b.scout, _NONCE_2));
        bytes32 hB = keccak256(abi.encode(b.lockedWei, b.intentSeal, activeEpoch, _NONCE_3));
        return keccak256(abi.encodePacked(hA, hB));
    }

    function _epochBeaconMass() internal view returns (uint256 mass) {
        for (uint256 i = 1; i <= JXA_LINE_COUNT; ++i) {
            mass += lines[i].massSum;
        }
    }

    function _bootLines() internal {
        lines[1] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(3),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 66,
            lineNonce: 0xf54b57c3d0eecc10a01ab73ee8f4c07d44108b13644d14e7276c72f76c870fb9
        });
        emit JXA_LineOpened(1, 0xf54b57c3d0eecc10a01ab73ee8f4c07d44108b13644d14e7276c72f76c870fb9, uint8(3), 66);
        lines[2] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(5),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 103,
            lineNonce: 0x75b3341df3aeebcac3acb2a9a624542c169e36586bdc13e86743691a1e5bf077
        });
        emit JXA_LineOpened(2, 0x75b3341df3aeebcac3acb2a9a624542c169e36586bdc13e86743691a1e5bf077, uint8(5), 103);
        lines[3] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(4),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 140,
            lineNonce: 0x68bbd8229a4e1029f3ca50cc7df16e2d9223eec2ad925905ad1969944a84c0bb
        });
        emit JXA_LineOpened(3, 0x68bbd8229a4e1029f3ca50cc7df16e2d9223eec2ad925905ad1969944a84c0bb, uint8(4), 140);
        lines[4] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(6),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 177,
            lineNonce: 0x338f0ce465321b3a83e8948694781254ba0131f1bce72999354b944b5fdfb592
        });
        emit JXA_LineOpened(4, 0x338f0ce465321b3a83e8948694781254ba0131f1bce72999354b944b5fdfb592, uint8(6), 177);
        lines[5] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(2),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 214,
            lineNonce: 0x709308d0bff25a5801741a6c0064955566aaa4900893e7890bfca55aa0495659
        });
        emit JXA_LineOpened(5, 0x709308d0bff25a5801741a6c0064955566aaa4900893e7890bfca55aa0495659, uint8(2), 214);
        lines[6] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(7),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 251,
            lineNonce: 0xb19b45494e07db3e6e3bc5dbe876d48da69bbc469715b0a7e2c8904e3697d10f
        });
        emit JXA_LineOpened(6, 0xb19b45494e07db3e6e3bc5dbe876d48da69bbc469715b0a7e2c8904e3697d10f, uint8(7), 251);
        lines[7] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(4),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 288,
            lineNonce: 0x63568a8347be43a3ef61355387a07b9fd71226bda24b4bd8747097e988bcdf1d
        });
        emit JXA_LineOpened(7, 0x63568a8347be43a3ef61355387a07b9fd71226bda24b4bd8747097e988bcdf1d, uint8(4), 288);
        lines[8] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(5),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 325,
            lineNonce: 0x8f0afe56e239b0acbc05e31ad109462d8beca393528d917e7adbf6a0ad4e3852
        });
        emit JXA_LineOpened(8, 0x8f0afe56e239b0acbc05e31ad109462d8beca393528d917e7adbf6a0ad4e3852, uint8(5), 325);
        lines[9] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(3),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 362,
            lineNonce: 0xf54b57c3d0eecc10a01ab73ee8f4c07d44108b13644d14e7276c72f76c870fb9
        });
        emit JXA_LineOpened(9, 0xf54b57c3d0eecc10a01ab73ee8f4c07d44108b13644d14e7276c72f76c870fb9, uint8(3), 362);
        lines[10] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(5),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 399,
            lineNonce: 0x75b3341df3aeebcac3acb2a9a624542c169e36586bdc13e86743691a1e5bf077
        });
        emit JXA_LineOpened(10, 0x75b3341df3aeebcac3acb2a9a624542c169e36586bdc13e86743691a1e5bf077, uint8(5), 399);
        lines[11] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(4),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 436,
            lineNonce: 0x68bbd8229a4e1029f3ca50cc7df16e2d9223eec2ad925905ad1969944a84c0bb
        });
        emit JXA_LineOpened(11, 0x68bbd8229a4e1029f3ca50cc7df16e2d9223eec2ad925905ad1969944a84c0bb, uint8(4), 436);
        lines[12] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(6),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 473,
            lineNonce: 0x338f0ce465321b3a83e8948694781254ba0131f1bce72999354b944b5fdfb592
        });
        emit JXA_LineOpened(12, 0x338f0ce465321b3a83e8948694781254ba0131f1bce72999354b944b5fdfb592, uint8(6), 473);
        lines[13] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(2),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 510,
            lineNonce: 0x709308d0bff25a5801741a6c0064955566aaa4900893e7890bfca55aa0495659
        });
        emit JXA_LineOpened(13, 0x709308d0bff25a5801741a6c0064955566aaa4900893e7890bfca55aa0495659, uint8(2), 510);
        lines[14] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(7),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 547,
            lineNonce: 0xb19b45494e07db3e6e3bc5dbe876d48da69bbc469715b0a7e2c8904e3697d10f
        });
        emit JXA_LineOpened(14, 0xb19b45494e07db3e6e3bc5dbe876d48da69bbc469715b0a7e2c8904e3697d10f, uint8(7), 547);
        lines[15] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(4),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 584,
            lineNonce: 0x63568a8347be43a3ef61355387a07b9fd71226bda24b4bd8747097e988bcdf1d
        });
        emit JXA_LineOpened(15, 0x63568a8347be43a3ef61355387a07b9fd71226bda24b4bd8747097e988bcdf1d, uint8(4), 584);
        lines[16] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(5),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 621,
            lineNonce: 0x8f0afe56e239b0acbc05e31ad109462d8beca393528d917e7adbf6a0ad4e3852
        });
        emit JXA_LineOpened(16, 0x8f0afe56e239b0acbc05e31ad109462d8beca393528d917e7adbf6a0ad4e3852, uint8(5), 621);
        lines[17] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(3),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 658,
            lineNonce: 0xf54b57c3d0eecc10a01ab73ee8f4c07d44108b13644d14e7276c72f76c870fb9
        });
        emit JXA_LineOpened(17, 0xf54b57c3d0eecc10a01ab73ee8f4c07d44108b13644d14e7276c72f76c870fb9, uint8(3), 658);
        lines[18] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(5),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 695,
            lineNonce: 0x75b3341df3aeebcac3acb2a9a624542c169e36586bdc13e86743691a1e5bf077
        });
        emit JXA_LineOpened(18, 0x75b3341df3aeebcac3acb2a9a624542c169e36586bdc13e86743691a1e5bf077, uint8(5), 695);
        lines[19] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(4),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 732,
            lineNonce: 0x68bbd8229a4e1029f3ca50cc7df16e2d9223eec2ad925905ad1969944a84c0bb
        });
        emit JXA_LineOpened(19, 0x68bbd8229a4e1029f3ca50cc7df16e2d9223eec2ad925905ad1969944a84c0bb, uint8(4), 732);
        lines[20] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(6),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 769,
            lineNonce: 0x338f0ce465321b3a83e8948694781254ba0131f1bce72999354b944b5fdfb592
        });
        emit JXA_LineOpened(20, 0x338f0ce465321b3a83e8948694781254ba0131f1bce72999354b944b5fdfb592, uint8(6), 769);
        lines[21] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(2),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 806,
            lineNonce: 0x709308d0bff25a5801741a6c0064955566aaa4900893e7890bfca55aa0495659
        });
        emit JXA_LineOpened(21, 0x709308d0bff25a5801741a6c0064955566aaa4900893e7890bfca55aa0495659, uint8(2), 806);
        lines[22] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(7),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 843,
            lineNonce: 0xb19b45494e07db3e6e3bc5dbe876d48da69bbc469715b0a7e2c8904e3697d10f
        });
        emit JXA_LineOpened(22, 0xb19b45494e07db3e6e3bc5dbe876d48da69bbc469715b0a7e2c8904e3697d10f, uint8(7), 843);
        lines[23] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(4),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 880,
            lineNonce: 0x63568a8347be43a3ef61355387a07b9fd71226bda24b4bd8747097e988bcdf1d
        });
        emit JXA_LineOpened(23, 0x63568a8347be43a3ef61355387a07b9fd71226bda24b4bd8747097e988bcdf1d, uint8(4), 880);
        lines[24] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(5),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 917,
            lineNonce: 0x8f0afe56e239b0acbc05e31ad109462d8beca393528d917e7adbf6a0ad4e3852
        });
        emit JXA_LineOpened(24, 0x8f0afe56e239b0acbc05e31ad109462d8beca393528d917e7adbf6a0ad4e3852, uint8(5), 917);
        lines[25] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(3),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 954,
            lineNonce: 0xf54b57c3d0eecc10a01ab73ee8f4c07d44108b13644d14e7276c72f76c870fb9
        });
        emit JXA_LineOpened(25, 0xf54b57c3d0eecc10a01ab73ee8f4c07d44108b13644d14e7276c72f76c870fb9, uint8(3), 954);
        lines[26] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(5),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 991,
            lineNonce: 0x75b3341df3aeebcac3acb2a9a624542c169e36586bdc13e86743691a1e5bf077
        });
        emit JXA_LineOpened(26, 0x75b3341df3aeebcac3acb2a9a624542c169e36586bdc13e86743691a1e5bf077, uint8(5), 991);
        lines[27] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(4),
            openedAt: uint64(block.timestamp),
            beaconCount: 0,
            pulseCount: 0,
            massSum: 1028,
            lineNonce: 0x68bbd8229a4e1029f3ca50cc7df16e2d9223eec2ad925905ad1969944a84c0bb
        });
        emit JXA_LineOpened(27, 0x68bbd8229a4e1029f3ca50cc7df16e2d9223eec2ad925905ad1969944a84c0bb, uint8(4), 1028);
        lines[28] = JxaLine({
            status: JxaLineStatus.Live,
            signalBand: uint8(6),
