defmodule SimplestNN do

	def create do
		weights = [:random.uniform()-0.5, :random.uniform()-0.5, :random.uniform()-0.5]
		n_pid = spawn(SimplestNN, :neuron, [weights, nil, nil])
		s_pid = spawn(SimplestNN, :sensor, [n_pid])
		a_pid = spawn(SimplestNN, :actuator, [n_pid])

		send(n_pid, {:init, s_pid, a_pid})

		Process.register(spawn(SimplestNN, :cortex, [s_pid, n_pid, a_pid]), :cortex)
	end
	
	def neuron(weights, s_pid, a_pid)  do
		receive do
			{:forward, s_pid, input} ->
				:io.format("***Thinking***~n Input: ~p~n with weights: ~p~n", [input, weights])

				dot_product = dot(input, weights, 0)
				output = [:math.tanh(dot_product)]

				# send actuator the output, together with neuron's pid
				send(a_pid, {:forward, self(), output}) 	
				neuron(weights, s_pid, a_pid)

			{:init, new_spid, new_apid} ->
				neuron(weights, new_spid, new_apid)

			:terminate ->
				:ok
		end	
	end


	def dot([i|input], [w|weights], acc) do
		dot(input, weights, i*w + acc)
	end
	def dot([], [bias], acc) do 
		acc + bias
	end
	def dot([],[], acc) do 
		acc
	end
	
	def sensor(n_pid) do
		receive do 
			:sync ->
				sensory_signal = [:random.uniform(), :random.uniform()]
				:io.format("***Sensing****:~n Signal from the environment ~p~n", [sensory_signal])
				send(n_pid, {:forward, self(), sensory_signal})	
				sensor(n_pid)
			:terminate ->
				:ok
		end	
	end

	def actuator(n_pid) do
		receive do	
			{:forward, n_pid, control_signal} ->
				pts(control_signal)				
				actuator(n_pid)

			:terminate ->
				:ok
		end
	end

	def pts(control_signal) do
		:io.format("***Acting***:~n Using: ~p to act on environment.~n", [control_signal])	
	end
	
	def cortex(sensor_pid, neuron_pid, actuator_pid) do
		receive do
			:sense_think_act ->
				send(sensor_pid, :sync)
				cortex(sensor_pid, neuron_pid, actuator_pid)

			:terminate ->
				send(sensor_pid, :terminate) 
				# send neuron_pid, :terminate
				# send actuator_pid, :terminate
				:ok
		end		
	end
end




















