# Autotuning CMSSW GPU Kernels
This project aims to autotune the GPU kernels in the [CMSSW](https://github.com/cms-sw/cmssw) framework.

The project introduces the following:

- An autotuning interface that leverages the CMSSW configuration files to autotune the GPU kernels ([branch](https://github.com/asubah/cmssw/tree/autotuning-interface)).
- An autotuning framework based on [OpenTuner](https://github.com/jansel/opentuner).

## Autotuning Interface

This section details the public methods of the `KernelConfigurations` header file, which acts as the autotuning interface for CMSSW. Examples are provided to illustrate usage.

---

### Constructor

https://github.com/asubah/cmssw/blob/35d5aff43decb3020615e7ceb488fc1c54e5093c/HeterogeneousCore/KernelConfigurations/interface/KernelConfigurations.h#L47

Initializes kernel configurations from a ParameterSet containing a "kernels" key. This key must map to a PSet where each entry is a kernel name paired with a VPSet of device-specific configurations.
Example Usage in an EDProducer

Below is an example demonstrating how to use the constructor in a CMSSW EDProducer module.
```cpp
private:
    cms::KernelConfigurations kernelConfigs_;

public:
    SampleProducer(const edm::ParameterSet& config)
        : kernelConfigs_(config.getParameter<edm::ParameterSet>("kernels")) {  }
```

### getConfigsForDevice

https://github.com/asubah/cmssw/blob/35d5aff43decb3020615e7ceb488fc1c54e5093c/HeterogeneousCore/KernelConfigurations/interface/KernelConfigurations.h#L50

Retrieves kernel launch configurations for a specific device or device architecture (e.g., "cuda", "cuda/sm\_75", "rocm", "cpu").

Device matching uses regular expressions (e.g., "cuda" matches "cuda/sm\_75"). Note that the device string in the configuration file is the pattern, and the device string passed to this method is the text to match.

The method will return the first match. It is the configuration file's responsibility to order the device-specific configurations from most to least specific.

Example configuration file:
```python
process.MyProducer = cms.EDProducer(  
    "MyProducer",  
    kernels = cms.PSet(  
        exampleKernel = cms.VPSet(  
            # Specific configuration for T4 GPUs  
            cms.PSet(  
                device = cms.string("cuda/sm_75"),  
                threads = cms.vuint32(256, 1, 1),  
                blocks = cms.vuint32(128, 1, 1)  
            ),  
            # General CUDA fallback  
            cms.PSet(  
                device = cms.string("cuda"),  
                threads = cms.vuint32(128, 1, 1),  
                blocks = cms.vuint32(64, 1, 1)  
            ),  
            # Default for unmatched devices (e.g., CPU, ROCm)  
            cms.PSet(  
                device = cms.string(""),  
                threads = cms.vuint32(1),  
                blocks = cms.vuint32(1)  
            )  
        )  
    )  
)
```

Using the configuration file above, the following code matches different devices:
```cpp
void MyProducer::produce(edm::Event& event, const edm::EventSetup& setup) {  
    // Matches configurations for "cuda/sm_75"
    auto configs = kernelConfigs_.getConfigsForDevice("cuda/sm_75/T4");  
    
    // Matches configurations for "cuda"
    auto configs = kernelConfigs_.getConfigsForDevice("cuda/sm_80");  

    // Matches the default configuration
    auto configs = kernelConfigs_.getConfigsForDevice("rocm/gfx906");  
}
```

### getConfig

Retrieves the launch configuration for a specific kernel.

https://github.com/asubah/cmssw/blob/35d5aff43decb3020615e7ceb488fc1c54e5093c/HeterogeneousCore/KernelConfigurations/interface/KernelConfigurations.h#L26

```cpp
    auto cudaConfigs = kernelConfigs_.getConfigsForDevice("cuda");  

    // Retrieve configuration for "clusterKernel"  
    const auto& kernelConfig = cudaConfigs.getConfig("clusterKernel");

    // Launch kernel with configuration
    clusterKernel<<<kernelConfig.blocks, kernelConfig.threads>>>();
```

### fillBasicDescriptions

Generates a basic `ParameterSetDescription` with default values for kernels.

https://github.com/asubah/cmssw/blob/35d5aff43decb3020615e7ceb488fc1c54e5093c/HeterogeneousCore/KernelConfigurations/interface/KernelConfigurations.h#L64

Example:
```cpp
edm::ParameterSetDescription desc;
std::vector<std::string> kernels = {"kernelA", "kernelB"};

// Add basic configuration options for each kernel
cms::KernelConfigurations::fillBasicDescriptions(desc, kernels);
```

Configuration in Python:
```python
    kernels = cms.PSet(
        kernelA = cms.VPSet(cms.PSet(
            device = cms.string(""),  # Matches any device
            threads = cms.vuint32(1),
            blocks = cms.vuint32(1)
        )),
        kernelB = cms.VPSet(...)  # Same structure
    )
```

### fillDetailedDescriptions

Generates a detailed ParameterSetDescription with constraints (e.g., minThreads, maxBlocks).

Example:
```cpp
// Define constraints for a kernel
cms::KernelConfigurations::KernelDescription kernelDesc;
kernelDesc.name = "exampleKernel";
kernelDesc.threads = {64, 1, 1};       // Default threads per block
kernelDesc.blocks = {256, 1, 1};       // Default blocks per grid
kernelDesc.minThreads = {32, 1, 1};    // Minimum allowed threads
kernelDesc.maxThreads = {128, 1, 1};   // Maximum allowed threads
kernelDesc.minBlocks = {40, 1, 1};    // Minimum allowed blocks
kernelDesc.maxBlocks = {400, 1, 1};    // Maximum allowed blocks

// Add to ParameterSetDescription
edm::ParameterSetDescription desc;
std::vector<cms::KernelConfigurations::KernelDescription> kernels = {kernelDesc};
cms::KernelConfigurations::fillDetailedDescriptions(desc, kernels);
```

Configuration in Python:
```python
    kernels = cms.PSet(
        exampleKernel = cms.VPSet(cms.PSet(
            device = cms.string(""),
            threads = cms.vuint32(64, 1, 1),
            blocks = cms.vuint32(256, 1, 1),
            minThreads = cms.vuint32(32, 1, 1),
            maxThreads = cms.vuint32(128, 1, 1),
            minBlocks = cms.vuint32(40, 1, 1),
            maxBlocks = cms.vuint32(400, 1, 1)
        ))
    )
```

## Configuration Files

## Autotuning Framework

## Results

