import argparse
import subprocess

import opentuner
from opentuner.measurement import MeasurementInterface
from opentuner.search.manipulator import (ConfigurationManipulator,
                                          IntegerParameter)

parser = argparse.ArgumentParser(parents=opentuner.argparsers())

parser.add_argument('--cmssw-config', type=str, 
                    help='location of cmssw config file')
parser.add_argument('--events', type=str, default="10300",
                    help='number of events per cmsRun job')
parser.add_argument('--repeats', type=str, default="3",
                    help='repeat each measurement N times')

base_path = "/data/user/abmohame/CMSSW_13_0_0/run/"
class CMSSWTuner(MeasurementInterface):
    def run(self, desired_result, input, limit):
        """
            run the given desired_result on input and produce a Result(),
            abort early if limit (in seconds) is reached
        """
        cfg = desired_result.configuration.data
        self.output_cmssw_config_file(cfg)
        
        cmd = [base_path + "patatrack-scripts/benchmark",
                base_path + "cmssw-autotuning/" + self.args.cmssw_config,
                "--repeats", self.args.repeats,
                "--events", self.args.events,
                "--jobs", "4",
                "--threads", "32",
                "--streams", "24",
                "--no-warmup",
                "--no-io-benchmark",
                "--logdir", base_path + "cmssw-autotuning/benchmark_logs",
                "--benchmark-results", base_path + "cmssw-autotuning/benchmark_results"]

        subprocess.run(cmd, encoding='UTF-8', capture_output=True)

        result = open(base_path + "cmssw-autotuning/benchmark_results", 'r').readlines()
        result = result[-1].split(',')

        cfg["overlapped"] = 0.0 
        cfg["throughput"] = 0.0
        cfg["error"] = 0.0
        time = float('inf')
        try:
            cfg["overlapped"] = float(result[1].strip())
            cfg["throughput"] = float(result[-2].strip())
            cfg["error"] = float(result[-1].strip())
            time = (1.0 / cfg["throughput"]) * (int(self.args.events) - 300)
        except:
            pass

        return opentuner.resultsdb.models.Result(time=time)

    def manipulator(self):
        manipulator = ConfigurationManipulator()
        # manipulator.add_parameter(IntegerParameter("number_of_jobs", 1, 8))
        # manipulator.add_parameter(IntegerParameter("number_of_cpu_threads", 1, 20))
        # manipulator.add_parameter(IntegerParameter("number_of_streams", 1, 20))
        # manipulator.add_parameter(IntegerParameter("kernel_connect_threads", 1, 32))
        # manipulator.add_parameter(IntegerParameter("kernel_connect_stride", 1, 8))
        manipulator.add_parameter(IntegerParameter("fishbone_threads", 1, 16))
        manipulator.add_parameter(IntegerParameter("fishbone_stride", 1, 8))
        manipulator.add_parameter(IntegerParameter("kernel_find_ntuplets", 1, 32))
        # manipulator.add_parameter(IntegerParameter("finalizeBulk", 1, 32))
        # manipulator.add_parameter(IntegerParameter("kernel_fillHitDetIndices", 1, 32))
        # manipulator.add_parameter(IntegerParameter("kernel_fillNLayers", 1, 32))
        # manipulator.add_parameter(IntegerParameter("kernel_earlyDuplicateRemover", 1, 32))
        # manipulator.add_parameter(IntegerParameter("kernel_countMultiplicity", 1, 32))
        # manipulator.add_parameter(IntegerParameter("kernel_fillMultiplicity", 1, 32))
        # manipulator.add_parameter(IntegerParameter("initDoublets", 1, 32))
        # manipulator.add_parameter(IntegerParameter("getDoubletsFromHisto_stride", 1, 8))
        # manipulator.add_parameter(IntegerParameter("kernel_classifyTracks", 1, 32))
        # manipulator.add_parameter(IntegerParameter("kernel_fishboneCleaner", 1, 32))
        # manipulator.add_parameter(IntegerParameter("kernel_fastDuplicateRemover", 1, 32))
        # manipulator.add_parameter(IntegerParameter("kernel_BLFastFit", 1, 32))
        manipulator.add_parameter(IntegerParameter("kernel_BLFit", 1, 32))
        # manipulator.add_parameter(IntegerParameter("RawToDigi_kernel", 1, 32))
        # manipulator.add_parameter(IntegerParameter("calibDigis", 1, 32))
        # manipulator.add_parameter(IntegerParameter("countModules", 1, 32))
        manipulator.add_parameter(IntegerParameter("findClus", 12, 32))
        manipulator.add_parameter(IntegerParameter("clusterChargeCut", 1, 32))
        manipulator.add_parameter(IntegerParameter("getHits", 1, 32))

        return manipulator

    def output_cmssw_config_file(self, params):
        params["events"] = self.args.events
        from mako.template import Template
        template = Template(filename=base_path + "cmssw-autotuning/step3_RAW2DIGI_RECO.py.mako")
        with open(base_path+"cmssw-autotuning/step3_RAW2DIGI_RECO.py", "w") as f:
            f.write(template.render(**params))



if __name__ == '__main__':
    args = parser.parse_args()
    cmd = [base_path + "patatrack-scripts/benchmark",
           base_path + "cmssw-autotuning/" + args.cmssw_config,
           "--repeats", "3",
           "--events", "10300",
           "--jobs", "24",
           "--threads", "32",
           "--streams", "24",
           "--logdir", base_path + "benchmark_logs",
           "--benchmark-results", base_path + "benchmark_results"]
    
    subprocess.run(cmd, encoding='UTF-8', capture_output=True)

    CMSSWTuner.main(args)
