import argparse

import opentuner
from opentuner.measurement import MeasurementInterface
from opentuner.search.manipulator import (ConfigurationManipulator,
                                          IntegerParameter)
import BasinHopping
import BayesianOptimization

parser = argparse.ArgumentParser(parents=opentuner.argparsers())

parser.add_argument('--cmssw-config', type=str, 
                    help='location of cmssw config file')
parser.add_argument('--config-template', type=str, 
                    help='location of cmssw config template file')
parser.add_argument('--base-dir', type=str, 
                    help='base directory')
parser.add_argument('--events', type=str, default="10300",
                    help='number of events per cmsRun job')
parser.add_argument('--repeats', type=str, default="3",
                    help='repeat each measurement N times')

class CMSSWTuner(MeasurementInterface):
    def run(self, desired_result, input, limit):
        """
            run the given desired_result on input and produce a Result(),
            abort early if limit (in seconds) is reached
        """
        # print(desired_result.configuration.data)
        # TODO use subprocess to run CMSSW benchmark
        # val = self.get_time_from_hpl_output()
        cfg = desired_result.configuration.data
        self.output_cmssw_config_file(cfg)

        import subprocess
        cmd = [self.args.base_dir + "/patatrack-scripts/benchmark",
               self.args.cmssw_config,
               "--repeats", self.args.repeats,
               "--events", self.args.events,
               "--jobs", "1",
               "--threads", "32",
               "--streams", "24",
               "--no-warmup",
               "--no-run-io-benchmark",
               "--logdir", self.args.base_dir + "/benchmark_logs",
               "--benchmark-results", self.args.base_dir + "/benchmark_results"]

        result = subprocess.run(cmd, encoding='UTF-8', capture_output=True)
        print(result.stdout)
        print(result.stderr)

        result = open(self.args.base_dir + "/benchmark_results", 'r').readlines()[-1].split(',')
        print(result)
        print(cfg)
        
        overlapped = 0
        throughput = 0
        error = 0
        time = float('inf')
        try:
            overlapped = float(result[1].strip())
            throughput = float(result[-2].strip())
            error = float(result[-1].strip())
            time = (int(self.args.events) - 300) / throughput
        except Exception as e:
            print(f'invalid config: {e}')

        print(throughput, time)
        cfg["throughput"] = throughput

        return opentuner.resultsdb.models.Result(time=time)

    def manipulator(self):
        manipulator = ConfigurationManipulator()
        # manipulator.add_parameter(IntegerParameter("number_of_jobs", 1, 4))
        # manipulator.add_parameter(IntegerParameter("number_of_cpu_threads", 2, 16))
        # manipulator.add_parameter(IntegerParameter("number_of_streams", 2, 12))
        manipulator.add_parameter(IntegerParameter("RawToDigi_kernel", 1, 16))
        manipulator.add_parameter(IntegerParameter("CalibDigis", 1, 16))
        manipulator.add_parameter(IntegerParameter("CountModules", 1, 16))
        manipulator.add_parameter(IntegerParameter("FindClus", 1, 16))
        manipulator.add_parameter(IntegerParameter("ClusterChargeCut", 1, 16))
        manipulator.add_parameter(IntegerParameter("GetHits", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_BLFastFit_3", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_BLFit_3", 1, 10))
        manipulator.add_parameter(IntegerParameter("Kernel_BLFastFit_4", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_BLFit_4", 1, 10))
        manipulator.add_parameter(IntegerParameter("Kernel_connect", 1, 16))
        manipulator.add_parameter(IntegerParameter("CAFishbone", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_find_ntuplets", 1, 16))
        manipulator.add_parameter(IntegerParameter("finalizeBulk", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_fillHitDetIndices", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_fillNLayers", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_earlyDuplicateRemover", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_countMultiplicity", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_fillMultiplicity", 1, 16))
        manipulator.add_parameter(IntegerParameter("InitDoublets", 1, 16))
        manipulator.add_parameter(IntegerParameter("GetDoubletsFromHisto", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_classifyTracks", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_fastDuplicateRemover", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_countHitInTracks", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_fillHitInTracks", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_rejectDuplicate", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_sharedHitCleaner", 1, 16))
        manipulator.add_parameter(IntegerParameter("Kernel_simpleTripletCleaner", 1, 16))
        manipulator.add_parameter(IntegerParameter("LoadTracks", 1, 16))

        return manipulator

    def output_cmssw_config_file(self, params):
        params["events"] = self.args.events
        from mako.template import Template
        template = Template(filename=self.args.config_template)
        with open(self.args.cmssw_config, "w") as f:
            f.write(template.render(**params))


if __name__ == '__main__':
    args = parser.parse_args()
    CMSSWTuner.main(args)
