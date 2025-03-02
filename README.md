# Autotuning CMSSW GPU Kernels
This project aims to autotune the GPU kernels in the [CMSSW](https://github.com/cms-sw/cmssw) framework.

The project introduces the following:

- An autotuning interface that leverages the CMSSW configuration files to autotune the GPU kernels ([branch](https://github.com/asubah/cmssw/tree/autotuning-interface)).
- An autotuning framework based on [OpenTuner](https://github.com/jansel/opentuner).

---
## Autotuning Interface

This section details the public methods of the `KernelConfigurations` header file, which acts as the autotuning interface for CMSSW. Examples are provided to illustrate usage.

### [Constructor](https://github.com/asubah/cmssw/blob/35d5aff43decb3020615e7ceb488fc1c54e5093c/HeterogeneousCore/KernelConfigurations/interface/KernelConfigurations.h#L47)

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

### [getConfigsForDevice](https://github.com/asubah/cmssw/blob/35d5aff43decb3020615e7ceb488fc1c54e5093c/HeterogeneousCore/KernelConfigurations/interface/KernelConfigurations.h#L50)

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

### [getConfig](https://github.com/asubah/cmssw/blob/35d5aff43decb3020615e7ceb488fc1c54e5093c/HeterogeneousCore/KernelConfigurations/interface/KernelConfigurations.h#L26)

Retrieves the launch configuration for a specific kernel.

```cpp
auto cudaConfigs = kernelConfigs_.getConfigsForDevice("cuda");  

// Retrieve configuration for "clusterKernel"  
const auto& kernelConfig = cudaConfigs.getConfig("clusterKernel");

// Launch kernel with configuration
clusterKernel<<<kernelConfig.blocks, kernelConfig.threads>>>();
```

### [fillBasicDescriptions](https://github.com/asubah/cmssw/blob/35d5aff43decb3020615e7ceb488fc1c54e5093c/HeterogeneousCore/KernelConfigurations/interface/KernelConfigurations.h#L64)

Generates a basic `ParameterSetDescription` with default values for kernels.

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

### [fillDetailedDescriptions](https://github.com/asubah/cmssw/blob/35d5aff43decb3020615e7ceb488fc1c54e5093c/HeterogeneousCore/KernelConfigurations/interface/KernelConfigurations.h#L76)

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

## Autotuning Framework

The autotuning framework is built on [OpenTuner](https://github.com/jansel/opentuner) to optimize CMSSW GPU kernel configurations. This section describes the implementation of the `cmssw_tuner.py` script.

### Implementation Overview

The autotuner is implemented as a custom `MeasurementInterface` class that extends OpenTuner's framework. The key components include:

1. **Parameter Space Definition**: Defines the search space for optimization
2. **Configuration Generation**: Creates CMSSW configurations with different parameter values
3. **Benchmark Execution**: Runs CMSSW with the generated configurations
4. **Performance Evaluation**: Measures throughput and updates the search strategy

### Implementation Details

#### 1. Parameter Definition

The `manipulator()` method defines the search space by specifying all tunable parameters with their ranges:

```python
def manipulator(self):
    manipulator = ConfigurationManipulator()
    manipulator.add_parameter(IntegerParameter("number_of_jobs", 1, 4))
    manipulator.add_parameter(IntegerParameter("number_of_cpu_threads", 1, 32))
    # Additional kernel-specific parameters
    manipulator.add_parameter(IntegerParameter("fishbone_threads", 1, 32))
    manipulator.add_parameter(IntegerParameter("fishbone_stride", 1, 8))
    # ... other parameters
    return manipulator
```

Each parameter corresponds to a value that will be used in the CMSSW configuration.

It is possible to use `edmPluginHelp` to get the list of available parameters and their boundaries for a specific module. 

```bash
edmPluginHelp --plugin SiPixelRawToClusterPhase1@alpaka --brief
```

Sample output:
```
Section 1.1.2 kernels PSet description:                        
    RawToDigi_kernel VPSet  see Section 1.1.2.1                                                                                                                 
Section 1.1.2.1 RawToDigi_kernel VPSet description:                                                                                                   
    All elements will be validated using the PSet description in Section 1.1.2.1.1.                                                                   
    The default VPSet has 1 element.                                                                                                                      
    [0]: see Section 1.1.2.1.2                                                                                                                         
Section 1.1.2.1.1 description of PSet used to validate elements of VPSet:
    device     string   ''                                                                                                                             
    threads    vuint32  (vector size = 1)                   
      [0]: 64                                                             
    blocks     vuint32  (vector size = 1)                                
      [0]: 0                                                           
    minThreads vuint32  (vector size = 1)                                
      [0]: 32                                                                 
    maxThreads vuint32  (vector size = 1)                                
      [0]: 512                                  
         minBlocks  vuint32  (vector size = 1)
      [0]: 0
    maxBlocks  vuint32  (vector size = 1)
      [0]: 0
```

#### 2. Template-Based Configuration Generation

The autotuner uses Mako templates to generate CMSSW configurations. The `output_cmssw_config_file()` method renders the template with parameter values:

```python
def output_cmssw_config_file(self, params):
    params["events"] = self.args.events
    from mako.template import Template
    template = Template(filename="hltMenuReduce.py.mako")
    with open("step3_RAW2DIGI_RECO.py", "w") as f:
        f.write(template.render(**params))
```

The template syntax allows direct substitution of optimization parameters, enabling complex kernel configurations.

An example template snippet:
```python
Kernel_find_ntuplets = cms.VPSet(                                                                                                                                     
  cms.PSet(                                                                                                                                                         
    blocks = cms.vuint32(0),                                                                                                                                        
    device = cms.string('.'),                                                                                                                                       
    threads = cms.vuint32(${Kernel_find_ntuplets * 32}) # Parameter substitution                                                                                            
    ),                                                                                                                                                              
  ),
```

#### 3. Performance Measurement

The `run()` method executes CMSSW with the current parameter set and measures performance:

```python
def run(self, desired_result, input, limit):
    cfg = desired_result.configuration.data
    self.output_cmssw_config_file(cfg)
    
    # Execute benchmark command
    cmd = [base_path + "patatrack-scripts/benchmark",
           self.args.cmssw_config,
           # ... command line arguments with current parameters
          ]
    subprocess.run(cmd, encoding='UTF-8', capture_output=True)
    
    # Parse results
    result = open(base_path + "benchmark_results", 'r').readlines()[-1].split(',')
    throughput = float(result[-2].strip())
    time = (int(self.args.events) - 300) / throughput
    
    return opentuner.resultsdb.models.Result(time=time)
```

The autotuner inverts throughput to create a "time" metric, as OpenTuner by default minimizes this value.

### Results Database

OpenTuner automatically stores all tuning results in an SQLite database (default filename: `opentuner.db`). This database contains information about:

- All tested configurations
- Measured performance for each configuration
- Search technique decisions
- Timing information

The main tables in the database include:

- `configuration`: Stores parameter values for each tested configuration
- `desired_result`: Contains requests for evaluations
- `result`: Stores performance measurements
- `technique`: Records which search techniques were used

#### Accessing the Results

The timing results can be accessed using direct SQL queries, but the configuration are stored as binary blobs ([Pickle](https://github.com/jansel/opentuner/blob/ed92a56197a2cb4c7a0203150f6976d7f3506507/opentuner/resultsdb/models.py#L19)). To access them it is easier to use the OpenTuner API.

1. **Direct SQL Queries**: Query the database directly using SQLite tools:

   ```bash
   sqlite3 opentuner.db "SELECT * FROM result ORDER BY time LIMIT 10;"
   ```

3. **OpenTuner API**: Use OpenTuner's built-in results interface:

   ```python
   from opentuner.resultsdb.models import *
   from opentuner.resultsdb import connect
   
   # Connect to the database
   session = connect("sqlite:///opentuner.db")
   
   # Query the best configuration
   best = session.query(Result).order_by(Result.time).first()
   best_config = best.configuration.data
   
   print("Best configuration:")
   for param, value in best_config.items():
       print(f"{param}: {value}")
       
   print(f"Throughput: {1/best.time} events/s")
   ```

## Results

These are results from an autotuning experiment on different GPUs:

| GPU | Baseline | Tuned |
| :----------- | ------: | -----: |
| T4 | 241.740 | 247.160 |
| A10 | 430.030 | 463.478 |
| L4 | 526.100 | 553.986 |
| L40S | 903.050 | 924.129 |
