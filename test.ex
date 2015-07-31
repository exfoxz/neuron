# defmodule User do
# 	require Record
# 	Record.defrecord :sensor, [name: nil, meg: nil, age: nil]
# end
# 	

defmodule NN do
	require Cortex

	def new do
		random = %Cortex{}
		random
	end
end