defmodule SimpleNeuron do

	def create do
		weights = [:random.uniform()-0.5, :random.uniform()-0.5, :random.uniform()-0.5]
		# register to associate the pid with a name, atom, :neuron
		Process.register(spawn(SimpleNeuron, :loop, [weights]), :neuron)
	end

	def loop(weights) do
		receive do
			{from, input} ->
				:io.format("***Processing***~n Input: ~p~n Using Weights: ~p~n", [input, weights])
				dot_product = dot(input, weights, 0)
				output = [:math.tanh(dot_product)]
				# send back result to from pid
				send(from, {:result, output}) 	
				loop(weights)
		end
	end

	def dot([i|input], [w|weights], acc) do
		dot(input, weights, i*w + acc)
	end

	def dot([], [bias], acc) do 
		acc + bias
	end

	def sense(signal) do
		case is_list(signal) and (length(signal) == 2) do
			true ->
				send(:neuron, {self(), signal})
				receive do
					{:result, output} ->
						:io.format(" Output: ~p~n", [output])
				end
			false ->
				:io.format("The signal must be alist of length 2~n")
		end
	end
end