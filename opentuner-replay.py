import opentuner
from opentuner.resultsdb.models import *
from sqlalchemy import select

def output_config_file(params):
    from mako.template import Template
    template = Template(filename="step3_RAW2DIGI_RECO.py.mako")
    with open("step3_RAW2DIGI_RECO.py", "w") as f:
        f.write(template.render(**params))

engine, Session = opentuner.resultsdb.connect("sqlite:///cn01.db")

session = Session()

cursor = session.execute(select(Result).where(Result.was_new_best==True))
fastest = Result()
fastest.time = float('inf')
for result in cursor.scalars():
    if result.time < fastest.time:
        fastest = result

print(fastest.time)
print(fastest.configuration_id)
print(fastest.configuration.data)
for k, v in fastest.configuration.data.items():
    print(k, v)

fastest.configuration.data["kernel_BLFastFit"] = fastest.configuration.data["kernelFastFit3_threads"]
fastest.configuration.data["kernel_BLFit"] = fastest.configuration.data["kernelLineFit3_threads"]
fastest.configuration.data["events"] = 10000
fastest.configuration.data["kernel_fillNLayers"] = 0
fastest.configuration.data["getDoubletsFromHisto_stride"] = 0

print(fastest.configuration.data)
output_config_file(fastest.configuration.data)

