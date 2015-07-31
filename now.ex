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
	