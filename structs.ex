defmodule Sensor do
	defstruct id: nil, cx_id: nil, name: nil, vl: nil, fanout_ids: nil
	:ok
end

defmodule Actuator do
	defstruct id: nil, cx_id: nil, name: nil, vl: nil, fanid_ids: nil
end

defmodule Neuron do
	defstruct id: nil, cx_id: nil, af: nil, input_idps: nil, output_ids: nil
end

defmodule Cortex do
	defstruct id: nil, sensor_ids: nil, actuator_ids: nil, nids: nil 
end