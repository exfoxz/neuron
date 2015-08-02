defmodule Sensor do
	defstruct id: nil, cx_id: nil, name: nil, vl: nil, fanout_ids: nil
end

defmodule Actuator do
	defstruct id: nil, cx_id: nil, name: nil, vl: nil, fanin_ids: nil
end

defmodule Neuron do
	defstruct id: nil, cx_id: nil, af: nil, input_idps: nil, output_ids: nil
end

defmodule Cortex do
	defstruct id: nil, sensor_ids: nil, actuator_ids: nil, nids: nil 
end

defmodule ID do
	def generate_ids(0, acc), do: acc  

	def generate_ids(index, acc) do 
		id = generate_id()
		generate_ids(index - 1, [id | acc])	
	end

	def generate_id() do 
		{mega_seconds, seconds, micro_seconds} = :erlang.now()
		1/(mega_seconds*100000 + seconds + micro_seconds/1000000)
	end
end

defmodule Constructor do
	require Sensor 
	require Actuator 
	require Neuron
	require Cortex 
	require ID

	def construct_genotype(sensor_name, actuator_name, hidden_layer_densities) do
		construct_genotype(:ffnn, sensor_name, actuator_name, hidden_layer_densities)
	end

	def construct_genotype(file_name, sensor_name, actuator_name, hidden_layer_densities) do
		s = create_sensor(sensor_name)
		a = create_actuator(actuator_name)

		output_VL = a.vl
		layer_densities = hidden_layer_densities ++ [output_VL]
		cx_id = {:cortex, ID.generate_id()}

		neurons = create_neuro_layers(cx_id, s, a, layer_densities)

		[input_layer|_] = neurons
		[output_layer|_] = :lists.reverse(neurons)

		fl_nids = Enum.map input_layer, fn n -> n.id end
		ll_nids = Enum.map output_layer, fn n -> n.id end
		n_ids = Enum.map :lists.flatten(neurons), fn n -> n.id	end

		sensor = %Sensor{cx_id: cx_id, fanout_ids: fl_nids}
		actuator = %Actuator{cx_id: cx_id, fanin_ids: ll_nids}
		cortex = create_cortex(cx_id, [sensor.id], [actuator.id], n_ids) 
		genotype = :lists.flatten([cortex, sensor, actuator | neurons])
		# Open a new file
		{:ok, file} = :file.open(file_name, :write)

		# For each typle in the genotype, write one line to the file
		Enum.each genotype, fn x -> :io.format(file, "~p.~n", [x]) end 

		# Close file	
		:file.close(file)
	end

	def create_sensor(sensor_name) do 
		case sensor_name do
			:rng ->
				# Create a new rng sensor
				%Sensor{id: {:sensor, ID.generate_id()}, name: :rng, vl: 2}
			_ ->
				Process.exit("System does not support a sensor by the name:~p", [sensor_name])
		end
	end

	def create_actuator(actuator_name) do 
		case actuator_name do
			:pts ->
				# Create a new rng sensor
				%Actuator{id: {:actuator, ID.generate_id()}, name: :pts, vl: 1}
			_ ->
				Process.exit("System does not support a actuator by the name:~p", [actuator_name])
		end
	end	

	@doc """
	Prepares the initial step before starting the recursive create_neuron_layers/7
	which will create all the neuron structs.
	We first generate the place holder input ids 'plus' (input_idps), which
	are tuples composed of ids and the vector lengths of the incoming signals associated with them.
	The proper input_idps will have a weight list in the tuple instead of the vector length.
	Because we are only building NNs each with only a single Sensor and Actuator, the idp to the
	first layer is composed of the single Sensor Id with the vector length of its sensory signal,
	likewise, in the case of the Actuator.
	We then generate the unique ids for the neurons in the first layer and drop into the
	recursive create_neuro_layers/7 function	
	"""	
	def create_neuro_layers(cx_id, sensor, actuator, layer_densities) do
		input_idps = [{sensor.id, sensor.vl}]
		tot_layers = length(layer_densities)
		[fl_neurons|next_lds] = layer_densities
		# go over the list by generate_ids to create a list of neurons with their ids
		n_ids = Enum.map ID.generate_ids(fl_neurons,[]), fn idx -> {:neuron, {1, idx}} end
		create_neuro_layers(cx_id, actuator.id, 1, tot_layers, input_idps, n_ids, next_lds, [])
	end

	# recursive version
	def create_neuro_layers(cx_id, actuator_id, layer_index, tot_layers, input_idps, n_ids, [next_ld|lds], acc) do
		output_nids = Enum.map ID.generate_ids(next_ld,[]), fn idx -> {:neuron, {layer_index + 1, idx}} end
		layer_neurons = create_neuro_layer(cx_id, input_idps, n_ids, output_nids, [])			
		next_input_idps = Enum.map n_ids, fn n_id -> {n_id, 1} end 

		create_neuro_layers(cx_id, actuator_id, layer_index + 1, tot_layers, next_input_idps, output_nids, lds, [layer_neurons | acc])
	end

	def create_neuro_layers(cx_id, actuator_id, layer_index, tot_layers, input_idps, n_ids, [], acc) do
		output_ids = [actuator_id]
		layer_neurons = create_neuro_layer(cx_id, input_idps, n_ids, output_ids, [])	
		:lists.reverse([layer_neurons|acc])
	end
			


	@doc """
	To create neurons from the same layer,
	all that is needed are the ids for those neurons
	a list of input_idps for every neuron so that we can create
	the proper number of weights and a list of output_ids
	"""
	def create_neuro_layer(cx_id, input_idps, [id|nids], output_ids, acc) do
		neuron = create_neuron(input_idps, id, cx_id, output_ids)	
		create_neuro_layer(cx_id, input_idps, nids, output_ids, [neuron|acc])
	end

	# base case	
	def create_neuro_layer(_cx_ids, _input_idps, [], _output_ids, acc) do
		acc	
	end
	
	@doc """
	Creates the input list from the tuples [{id, weights}...]
	using the vector lengths specified in the placeholder input_idps
	"""
	def create_neuron(input_idps, id, cx_id, output_ids) do
		proper_input_idps = create_neural_input(input_idps, [])	
		%Neuron{id: id, cx_id: cx_id, af: fn x -> :math.tanh(x) end, input_idps: proper_input_idps, output_ids: output_ids}
	end

	@doc """
	Generates random weights in the range of -0.5 to 0.5 together with the input_id, adding the bias
	to the end of the list
	"""
	def create_neural_input([{input_id, input_vl}|input_idps], acc) do
		weights = create_neural_weights(input_vl, [])
		create_neural_input(input_idps, [{input_id, weights}|acc])
	end

	def create_neural_input([], acc) do
		:lists.reverse([{:bias, :random.uniform()-0.5} | acc])
	end

	@doc """
	Generates random weights
	"""
	def create_neural_weights(0, acc) do
		acc;
	end

	def create_neural_weights(index, acc) do
		w = :random.uniform()-0.5
		create_neural_weights(index-1, [w | acc])
	end
	
	@doc """
	Generates the struct encoded genotypical representation of the cortex
	The Cortex elements needs to know the ids of every Neuron, Sensor
	and Actuator in the NN
	"""
	def create_cortex(cx_id, s_ids, a_ids, n_ids) do
		%Cortex{id: cx_id, sensor_ids: s_ids, actuator_ids: a_ids, nids: n_ids}
	end
end