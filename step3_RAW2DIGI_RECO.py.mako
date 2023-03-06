# Auto generated configuration file
# using: 
# Revision: 1.19 
# Source: /local/reps/CMSSW/CMSSW/Configuration/Applications/python/ConfigBuilder.py,v 
# with command line options: step3 -s RAW2DIGI:RawToDigi_pixelOnly,RECO:reconstruction_pixelTrackingOnly --conditions auto:run3_data --datatier GEN-SIM-RECO -n 10 --eventcontent RECOSIM --data --scenario pp --geometry DB:Extended --era Run3 --procModifiers pixelNtupletFit,gpu --customise RecoPixelVertexing/Configuration/customizePixelTracksForTriplets.customizePixelTracksForTriplets,RecoTracker/Configuration/customizePixelOnlyForProfiling.customizePixelOnlyForProfilingGPUOnly --no_exec
import FWCore.ParameterSet.Config as cms

from Configuration.Eras.Era_Run3_cff import Run3
from Configuration.ProcessModifiers.pixelNtupletFit_cff import pixelNtupletFit
from Configuration.ProcessModifiers.gpu_cff import gpu

process = cms.Process('RECO',Run3,pixelNtupletFit,gpu)

# import of standard configurations
process.load('Configuration.StandardSequences.Services_cff')
process.load('SimGeneral.HepPDTESSource.pythiapdt_cfi')
process.load('FWCore.MessageService.MessageLogger_cfi')
process.load('Configuration.EventContent.EventContent_cff')
process.load('Configuration.StandardSequences.GeometryRecoDB_cff')
process.load('Configuration.StandardSequences.MagneticField_cff')
process.load('Configuration.StandardSequences.RawToDigi_Data_cff')
process.load('Configuration.StandardSequences.Reconstruction_Data_cff')
process.load('Configuration.StandardSequences.EndOfProcess_cff')
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(${events}),
    output = cms.optional.untracked.allowed(cms.int32,cms.PSet)
)

# Input source
process.source = cms.Source("PoolSource",
    fileNames = cms.untracked.vstring('file:step3_DIGI2RAW.root'),
    secondaryFileNames = cms.untracked.vstring()
)

process.options = cms.untracked.PSet(
    FailPath = cms.untracked.vstring(),
    IgnoreCompletely = cms.untracked.vstring(),
    Rethrow = cms.untracked.vstring(),
    SkipEvent = cms.untracked.vstring(),
    accelerators = cms.untracked.vstring('*'),
    allowUnscheduled = cms.obsolete.untracked.bool,
    canDeleteEarly = cms.untracked.vstring(),
    deleteNonConsumedUnscheduledModules = cms.untracked.bool(True),
    dumpOptions = cms.untracked.bool(False),
    emptyRunLumiMode = cms.obsolete.untracked.string,
    eventSetup = cms.untracked.PSet(
        forceNumberOfConcurrentIOVs = cms.untracked.PSet(
            allowAnyLabel_=cms.required.untracked.uint32
        ),
        numberOfConcurrentIOVs = cms.untracked.uint32(0)
    ),
    fileMode = cms.untracked.string('FULLMERGE'),
    forceEventSetupCacheClearOnNewRun = cms.untracked.bool(False),
    holdsReferencesToDeleteEarly = cms.untracked.VPSet(),
    makeTriggerResults = cms.obsolete.untracked.bool,
    modulesToIgnoreForDeleteEarly = cms.untracked.vstring(),
    numberOfConcurrentLuminosityBlocks = cms.untracked.uint32(0),
    numberOfConcurrentRuns = cms.untracked.uint32(1),
    numberOfStreams = cms.untracked.uint32(0),
    numberOfThreads = cms.untracked.uint32(1),
    printDependencies = cms.untracked.bool(False),
    sizeOfStackForThreadsInKB = cms.optional.untracked.uint32,
    throwIfIllegalParameter = cms.untracked.bool(True),
    wantSummary = cms.untracked.bool(False)
)

# Production Info
process.configurationMetadata = cms.untracked.PSet(
    annotation = cms.untracked.string('step3 nevts:10'),
    name = cms.untracked.string('Applications'),
    version = cms.untracked.string('$Revision: 1.19 $')
)

# Output definition

process.RECOSIMoutput = cms.OutputModule("PoolOutputModule",
    dataset = cms.untracked.PSet(
        dataTier = cms.untracked.string('GEN-SIM-RECO'),
        filterName = cms.untracked.string('')
    ),
    fileName = cms.untracked.string('step3_RAW2DIGI_RECO.root'),
    outputCommands = process.RECOSIMEventContent.outputCommands,
    splitLevel = cms.untracked.int32(0)
)

# Additional output definition

# Other statements
from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, 'auto:run3_data', '')

# Path and EndPath definitions
process.raw2digi_step = cms.Path(process.RawToDigi_pixelOnly)
process.reconstruction_step = cms.Path(process.reconstruction_pixelTrackingOnly)
process.endjob_step = cms.EndPath(process.endOfProcess)
process.RECOSIMoutput_step = cms.EndPath(process.RECOSIMoutput)

# Schedule definition
process.schedule = cms.Schedule(process.raw2digi_step,process.reconstruction_step,process.endjob_step,process.RECOSIMoutput_step)
from PhysicsTools.PatAlgos.tools.helpers import associatePatAlgosToolsTask
associatePatAlgosToolsTask(process)

# customisation of the process.

# Automatic addition of the customisation function from RecoPixelVertexing.Configuration.customizePixelTracksForTriplets
from RecoPixelVertexing.Configuration.customizePixelTracksForTriplets import customizePixelTracksForTriplets 

#call to customisation function customizePixelTracksForTriplets imported from RecoPixelVertexing.Configuration.customizePixelTracksForTriplets
process = customizePixelTracksForTriplets(process)

# Automatic addition of the customisation function from RecoTracker.Configuration.customizePixelOnlyForProfiling
from RecoTracker.Configuration.customizePixelOnlyForProfiling import customizePixelOnlyForProfilingGPUOnly 

#call to customisation function customizePixelOnlyForProfilingGPUOnly imported from RecoTracker.Configuration.customizePixelOnlyForProfiling
process = customizePixelOnlyForProfilingGPUOnly(process)

# End of customisation functions


# Customisation from command line

#Have logErrorHarvester wait for the same EDProducers to finish as those providing data for the OutputModule
from FWCore.Modules.logErrorHarvester_cff import customiseLogErrorHarvesterUsingOutputCommands
process = customiseLogErrorHarvesterUsingOutputCommands(process)

# Add early deletion of temporary data products to reduce peak memory need
from Configuration.StandardSequences.earlyDeleteSettings_cff import customiseEarlyDelete
process = customiseEarlyDelete(process)
# End adding early deletion

process.pixelTracksCUDA = cms.EDProducer("CAHitNtupletCUDA",
    CAThetaCutBarrel = cms.double(0.0020000000949949026),
    CAThetaCutForward = cms.double(0.003000000026077032),
    dcaCutInnerTriplet = cms.double(0.15000000596046448),
    dcaCutOuterTriplet = cms.double(0.25),
    doClusterCut = cms.bool(True),
    doPtCut = cms.bool(True),
    doSharedHitCut = cms.bool(True),
    doZ0Cut = cms.bool(True),
    dupPassThrough = cms.bool(False),
    earlyFishbone = cms.bool(True),
    fillStatistics = cms.bool(False),
    fitNas4 = cms.bool(False),
    hardCurvCut = cms.double(0.03284072249589491),
    idealConditions = cms.bool(True),
    includeJumpingForwardDoublets = cms.bool(True),
    lateFishbone = cms.bool(False),
    maxNumberOfDoublets = cms.uint32(524288),
    mightGet = cms.optional.untracked.vstring,
    minHitsForSharingCut = cms.uint32(10),
    minHitsPerNtuplet = cms.uint32(3),
    onGPU = cms.bool(True),
    pixelRecHitSrc = cms.InputTag("siPixelRecHitsPreSplittingCUDA"),
    ptmin = cms.double(0.8999999761581421),
    trackQualityCuts = cms.PSet(
        chi2Coeff = cms.vdouble(0.9, 1.8),
        chi2MaxPt = cms.double(10),
        chi2Scale = cms.double(8),
        quadrupletMaxTip = cms.double(0.5),
        quadrupletMaxZip = cms.double(12),
        quadrupletMinPt = cms.double(0.3),
        tripletMaxTip = cms.double(0.3),
        tripletMaxZip = cms.double(12),
        tripletMinPt = cms.double(0.5)
    ),
    useRiemannFit = cms.bool(False),
    useSimpleTripletCleaner = cms.bool(True),
    kernels = cms.PSet(
        kernel_connect = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(128, 4),
                blocks = cms.vuint32(0),
                ),
            ),
        fishbone = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(64, 16),
                blocks = cms.vuint32(0),
                ),
            ),
        kernel_find_ntuplets = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(32),
                blocks = cms.vuint32(0),
                ),
            ),
        finalizeBulk = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(224),
                blocks = cms.vuint32(0),
                ),
            ),
        kernel_fillHitDetIndices = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(96),
                blocks = cms.vuint32(0),
                ),
            ),
        kernel_fillNLayers = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(128),
                blocks = cms.vuint32(0),
                ),
            ),
        kernel_earlyDuplicateRemover = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(96),
                blocks = cms.vuint32(0),
                ),
            ),
        kernel_countMultiplicity = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(96),
                blocks = cms.vuint32(0),
                ),
            ),
        kernel_fillMultiplicity = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(128),
                blocks = cms.vuint32(0),
                ),
            ),
        initDoublets = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(256),
                blocks = cms.vuint32(0),
                ),
            ),
        getDoubletsFromHisto = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(0, 4),
                blocks = cms.vuint32(0),
                ),
            ),
        kernel_classifyTracks = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(192),
                blocks = cms.vuint32(0),
                ),
            ),
        kernel_fishboneCleaner = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(32),
                blocks = cms.vuint32(0),
                ),
            ),
        kernel_fastDuplicateRemover = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(96),
                blocks = cms.vuint32(0),
                ),
            ),
        kernel_BLFastFit = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(64),
                blocks = cms.vuint32(0),
                ),
            ),
        kernel_BLFit = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(32),
                blocks = cms.vuint32(0),
                ),
            ),
        )
)

process.siPixelClustersPreSplittingCUDA = cms.EDProducer("SiPixelRawToClusterCUDA",
    CablingMapLabel = cms.string(''),
    IncludeErrors = cms.bool(True),
    InputLabel = cms.InputTag("rawDataCollector"),
    Regions = cms.PSet(
        beamSpot = cms.optional.InputTag,
        deltaPhi = cms.optional.vdouble,
        inputs = cms.optional.VInputTag,
        maxZ = cms.optional.vdouble
    ),
    UseQualityInfo = cms.bool(False),
    clusterThreshold_layer1 = cms.int32(4000),
    clusterThreshold_otherLayers = cms.int32(4000),
    isRun2 = cms.bool(False),
    mightGet = cms.optional.untracked.vstring,
    kernels = cms.PSet(
        RawToDigi_kernel = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(128),
                blocks = cms.vuint32(0),
            ),
        ),
        calibDigis = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(64),
                blocks = cms.vuint32(0),
            ),
        ),
        countModules = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(64),
                blocks = cms.vuint32(0),
            ),
        ),
        findClus = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(192),
                blocks = cms.vuint32(0),
            ),
        ),
        clusterChargeCut = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(64),
                blocks = cms.vuint32(0),
            ),
        ),
    )
)

process.siPixelRecHitsPreSplittingCUDA = cms.EDProducer("SiPixelRecHitCUDA",
    CPE = cms.string('PixelCPEFast'),
    beamSpot = cms.InputTag("offlineBeamSpotToCUDA"),
    mightGet = cms.optional.untracked.vstring,
    src = cms.InputTag("siPixelClustersPreSplittingCUDA"),
    kernels = cms.PSet(
        getHits = cms.VPSet(
            # kernel name id
            cms.PSet(
                # on an NVIDIA T4
                device = cms.string('cuda/sm_75/T4'),
                threads = cms.vuint32(64),
                blocks = cms.vuint32(0),
            ),
        ),
    )
)

process.load("run360992_cff")
