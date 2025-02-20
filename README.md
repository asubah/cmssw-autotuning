# Autotuning CMSSW GPU Kernels
This project aims to autotune the GPU kernels in the [CMSSW](https://github.com/cms-sw/cmssw) framework.

The project introduces the following:

- An autotuning interface that leverages the CMSSW configuration files to autotune the GPU kernels ([branch](https://github.com/asubah/cmssw/tree/autotuning-interface)).
- An autotuning framework based on [OpenTuner](https://github.com/jansel/opentuner).

## Autotuning Interface

This section details the public methods of the `KernelConfigurations` header file, which acts as the autotuning interface for CMSSW. Examples are provided to illustrate usage.

---

### `KernelConfigurations(const edm::ParameterSet& config) // Constructor`

// Add a link to the code

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
## Configuration Files

## Autotuning Framework

## Results

