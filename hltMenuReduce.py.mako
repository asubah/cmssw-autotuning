import FWCore.ParameterSet.Config as cms

from hltMenu import process

# delete all paths and endpaths
for path in list(process.paths.keys()):
  delattr(process, path)
for path in list(process.endpaths.keys()):
  delattr(process, path)

# remove the PrescaleService
del process.PrescaleService

# define alpaka-only paths
process.MC_PixelReconstruction_v11 = cms.Path(
    process.hltTriggerType +
    process.HLTBeamSpot +
    process.HLTDoLocalPixelSequence +
    process.HLTRecopixelvertexingSequence +
    process.HLTEndSequence )

process.MC_EcalReconstruction_v11 = cms.Path(
    process.hltTriggerType +
    process.HLTBeamSpot +
    process.HLTDoFullUnpackingEgammaEcalWithoutPreshowerSequence +
    process.HLTEndSequence )

process.MC_HcalReconstruction_v9 = cms.Path(
    process.hltTriggerType +
    process.HLTBeamSpot +
    process.HLTDoLocalHcalSequence +
    process.HLTPFHcalClustering +
    process.HLTEndSequence )

# schedule the alpaka-only paths
process.schedule = cms.Schedule(
    process.MC_PixelReconstruction_v11,
    process.MC_EcalReconstruction_v11,
    process.MC_HcalReconstruction_v9)

process.hltSiPixelClustersSoA = cms.EDProducer( "SiPixelRawToClusterPhase1@alpaka",
    IncludeErrors = cms.bool( True ),
    UseQualityInfo = cms.bool( False ),
    clusterThreshold_layer1 = cms.int32( 4000 ),
    clusterThreshold_otherLayers = cms.int32( 4000 ),
    VCaltoElectronGain = cms.double( 1.0 ),
    VCaltoElectronGain_L1 = cms.double( 1.0 ),
    VCaltoElectronOffset = cms.double( 0.0 ),
    VCaltoElectronOffset_L1 = cms.double( 0.0 ),
    InputLabel = cms.InputTag( "rawDataCollector" ),
    Regions = cms.PSet(  ),
    CablingMapLabel = cms.string( "" ),
    alpaka = cms.untracked.PSet(  backend = cms.untracked.string( "" ) ),

    kernels = cms.PSet(
      RawToDigi_kernel = cms.VPSet(
        cms.PSet(
          blocks = cms.vuint32(0),
          device = cms.string('.'),
          threads = cms.vuint32(${RawToDigi_kernel * 32})
          ),
        ),
      CalibDigis = cms.VPSet(
        cms.PSet(
          blocks = cms.vuint32(0),
          device = cms.string('.'),
          threads = cms.vuint32(${CalibDigis * 32})
          ),
        ),
      CountModules = cms.VPSet(
        cms.PSet(
          blocks = cms.vuint32(0),
          device = cms.string('.'),
          threads = cms.vuint32(${CountModules * 32})
          ),
        ),
      FindClus = cms.VPSet(
          cms.PSet(
            blocks = cms.vuint32(0),
            device = cms.string('.'),
            threads = cms.vuint32(${FindClus * 32})
            ),
          ),
      ClusterChargeCut = cms.VPSet(
          cms.PSet(
            blocks = cms.vuint32(0),
            device = cms.string('.'),
            threads = cms.vuint32(${ClusterChargeCut * 32})
            ),
          ),
      ))

process.hltSiPixelRecHitsSoA = cms.EDProducer( "SiPixelRecHitAlpakaPhase1@alpaka",
    beamSpot = cms.InputTag( "hltOnlineBeamSpotDevice" ),
    src = cms.InputTag( "hltSiPixelClustersSoA" ),
    CPE = cms.string( "PixelCPEFastParams" ),
    alpaka = cms.untracked.PSet(  backend = cms.untracked.string( "" ) ),
    kernels = cms.PSet(
      GetHits = cms.VPSet(
        cms.PSet(
          blocks = cms.vuint32(0),
          device = cms.string('.'),
          threads = cms.vuint32(${GetHits * 32})
          ),
        ),
      ))

process.hltPixelTracksSoA = cms.EDProducer( "CAHitNtupletAlpakaPhase1@alpaka",
    pixelRecHitSrc = cms.InputTag( "hltSiPixelRecHitsSoA" ),
    CPE = cms.string( "PixelCPEFastParams" ),
    ptmin = cms.double( 0.9 ),
    CAThetaCutBarrel = cms.double( 0.002 ),
    CAThetaCutForward = cms.double( 0.003 ),
    hardCurvCut = cms.double( 0.0328407225 ),
    dcaCutInnerTriplet = cms.double( 0.15 ),
    dcaCutOuterTriplet = cms.double( 0.25 ),
    earlyFishbone = cms.bool( True ),
    lateFishbone = cms.bool( False ),
    fillStatistics = cms.bool( False ),
    minHitsPerNtuplet = cms.uint32( 3 ),
    minHitsForSharingCut = cms.uint32( 10 ),
    fitNas4 = cms.bool( False ),
    doClusterCut = cms.bool( True ),
    doZ0Cut = cms.bool( True ),
    doPtCut = cms.bool( True ),
    useRiemannFit = cms.bool( False ),
    doSharedHitCut = cms.bool( True ),
    dupPassThrough = cms.bool( False ),
    useSimpleTripletCleaner = cms.bool( True ),
    maxNumberOfDoublets = cms.uint32( 524288 ),
    idealConditions = cms.bool( False ),
    includeJumpingForwardDoublets = cms.bool( True ),
    cellZ0Cut = cms.double( 12.0 ),
    cellPtCut = cms.double( 0.5 ),
    trackQualityCuts = cms.PSet( 
        chi2MaxPt = cms.double( 10.0 ),
        tripletMaxTip = cms.double( 0.3 ),
        chi2Scale = cms.double( 8.0 ),
        quadrupletMaxTip = cms.double( 0.5 ),
        quadrupletMinPt = cms.double( 0.3 ),
        quadrupletMaxZip = cms.double( 12.0 ),
        tripletMaxZip = cms.double( 12.0 ),
        tripletMinPt = cms.double( 0.5 ),
        chi2Coeff = cms.vdouble( 0.9, 1.8 )
        ),
    phiCuts = cms.vint32( 522, 730, 730, 522, 626, 626, 522, 522, 626, 626, 626, 522, 522, 522, 522, 522, 522, 522, 522 ),
    alpaka = cms.untracked.PSet(  backend = cms.untracked.string( "" ) ),
    kernels = cms.PSet(
        Kernel_BLFastFit_3 = cms.VPSet(
          cms.PSet(
            blocks = cms.vuint32(0),
            device = cms.string('.'),
            threads = cms.vuint32(${Kernel_BLFastFit_3 * 32})
            ),
          ),
        Kernel_BLFit_3 = cms.VPSet(
          cms.PSet(
            blocks = cms.vuint32(0),
            device = cms.string('.'),
            threads = cms.vuint32(${Kernel_BLFit_3 * 32})
            ),
          ),
        Kernel_BLFastFit_4 = cms.VPSet(
          cms.PSet(
            blocks = cms.vuint32(0),
            device = cms.string('.'),
            threads = cms.vuint32(${Kernel_BLFastFit_4 * 32})
            ),
          ),
        Kernel_BLFit_4 = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_BLFit_4 * 32})
              ),
            ),
        Kernel_connect = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_connect * 64})
              ),
            ),
        CAFishbone = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${CAFishbone * 32})
              ),
            ),
        Kernel_find_ntuplets = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_find_ntuplets * 32})
              ),
            ),
        finalizeBulk = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${finalizeBulk * 32})
              ),
            ),
        Kernel_fillHitDetIndices = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_fillHitDetIndices * 32})
              ),
            ),
        Kernel_fillNLayers = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_fillNLayers * 32})
              ),
            ),
        Kernel_earlyDuplicateRemover = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_earlyDuplicateRemover * 32})
              ),
            ),
        Kernel_countMultiplicity = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_countMultiplicity * 32})
              ),
            ),
        Kernel_fillMultiplicity = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_fillMultiplicity * 32})
              ),
            ),
        InitDoublets = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${InitDoublets * 32})
              ),
            ),
        GetDoubletsFromHisto = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${GetDoubletsFromHisto * 32})
              ),
            ),
        Kernel_classifyTracks = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_classifyTracks * 32})
              ),
            ),
        Kernel_fastDuplicateRemover = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_fastDuplicateRemover * 32})
              ),
            ),
        Kernel_countHitInTracks = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_countHitInTracks * 32})
              ),
            ),
        Kernel_fillHitInTracks = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_fillHitInTracks * 32})
              ),
            ),
        Kernel_rejectDuplicate = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_rejectDuplicate * 32})
              ),
            ),
        Kernel_sharedHitCleaner = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_sharedHitCleaner * 32})
              ),
            ),
        Kernel_simpleTripletCleaner = cms.VPSet(
            cms.PSet(
              blocks = cms.vuint32(0),
              device = cms.string('.'),
              threads = cms.vuint32(${Kernel_simpleTripletCleaner * 32})
              ),
            )
        ))

process.hltPixelVerticesSoA = cms.EDProducer( "PixelVertexProducerAlpakaPhase1@alpaka",
    oneKernel = cms.bool( True ),
    useDensity = cms.bool( True ),
    useDBSCAN = cms.bool( False ),
    useIterative = cms.bool( False ),
    doSplitting = cms.bool( True ),
    minT = cms.int32( 2 ),
    eps = cms.double( 0.07 ),
    errmax = cms.double( 0.01 ),
    chi2max = cms.double( 9.0 ),
    PtMin = cms.double( 0.5 ),
    PtMax = cms.double( 75.0 ),
    pixelTrackSrc = cms.InputTag( "hltPixelTracksSoA" ),
    alpaka = cms.untracked.PSet(  backend = cms.untracked.string( "" ) ),
    kernels = cms.PSet(
      LoadTracks = cms.VPSet(
        cms.PSet(
          blocks = cms.vuint32(0),
          device = cms.string('.'),
          threads = cms.vuint32(${LoadTracks * 32})
          ),
        ),
      ))
