import argparse

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

class CMSSWTuner(MeasurementInterface):
    def run(self, desired_result, input, limit):
        """
            run the given desired_result on input and produce a Result(),
            abort early if limit (in seconds) is reached
        """
        cfg = desired_result.configuration.data
        # self.output_cmssw_config_file(cfg)
        
        base_path = "/data/user/abmohame/CMSSW_13_0_0/run/"

        import subprocess
        cmd = [base_path + "patatrack-scripts/benchmark",
               self.args.cmssw_config,
               "--repeats", self.args.repeats,
               "--events", self.args.events,
               "--jobs", str(cfg["number_of_jobs"] * 2),
               "--threads", str(cfg["number_of_cpu_threads"] * 2),
               "--streams", str(cfg["number_of_streams"] * 2),
               "--no-warmup",
               "--no-io-benchmark",
               "--logdir", base_path + "benchmark_logs",
               "--benchmark-results", base_path + "benchmark_results"]

        subprocess.run(cmd, encoding='UTF-8', capture_output=True)

        result = open(base_path + "benchmark_results", 'r').readlines()
        result = result[-1].split(',')

        time = float('inf')
        try:
            cfg["overlapped"] = float(result[1].strip())
            cfg["throughput"] = float(result[-2].strip())
            cfg["error"] = float(result[-1].strip())
            time = (1.0 / cfg["throughput"]) * int(self.args.events)
        except:
            print('invalid config')

        return opentuner.resultsdb.models.Result(time=time)

    def manipulator(self):
        manipulator = ConfigurationManipulator()
        manipulator.add_parameter(IntegerParameter("number_of_jobs", 1, 8))
        manipulator.add_parameter(IntegerParameter("number_of_cpu_threads", 1, 20))
        manipulator.add_parameter(IntegerParameter("number_of_streams", 1, 20))
        # manipulator.add_parameter(IntegerParameter("kernel_connect_threads", 1, 32))
        # manipulator.add_parameter(IntegerParameter("kernel_connect_stride", 1, 8))
        # manipulator.add_parameter(IntegerParameter("fishbone_threads", 1, 32))
        # manipulator.add_parameter(IntegerParameter("fishbone_stride", 1, 8))
        # manipulator.add_parameter(IntegerParameter("kernel_find_ntuplets", 1, 32))
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
        # manipulator.add_parameter(IntegerParameter("kernel_BLFit", 1, 32))
        # manipulator.add_parameter(IntegerParameter("RawToDigi_kernel", 1, 32))
        # manipulator.add_parameter(IntegerParameter("calibDigis", 1, 32))
        # manipulator.add_parameter(IntegerParameter("countModules", 1, 32))
        # manipulator.add_parameter(IntegerParameter("findClus", 1, 32))
        # manipulator.add_parameter(IntegerParameter("clusterChargeCut", 1, 32))
        # manipulator.add_parameter(IntegerParameter("getHits", 1, 32))

        return manipulator

    def output_cmssw_config_file(self, params):
        params["events"] = self.args.events
        from mako.template import Template
        template = Template(filename="step3_RAW2DIGI_RECO.py.mako")
        with open("step3_RAW2DIGI_RECO.py", "w") as f:
            f.write(template.render(**params))



if __name__ == '__main__':
    args = parser.parse_args()
    CMSSWTuner.main(args)
