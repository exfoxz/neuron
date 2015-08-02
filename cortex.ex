defmodule Cortex do
	
	def gen(exoSelf_pid, node) do
		spawn(node, Cortex, :loop, [exoSelf_pid])
	end

	# Cortex loop
	def loop(exoSelf_pid) do
		receive do
			# tot_steps: total of cycles the Cortex should execute
			# before terminating the NN system
			{exoSelf_pid, {id, s_pids, a_pids, n_pids}, tot_steps} ->
				Enum.each s_pids, fn s_pids -> send s_pids, {:sync, self()} end
				loop(id, exoSelf_pid, s_pids, {a_pids, a_pids}, n_pids, tot_steps)
		end	
	end

	# Cortex loop
	# Last cycle
	def loop(id, exoSelf_pid, s_pids, {_a_pids, ma_pids}, n_pids, 0) do
		:io.format("Cortex:~p is backing up and terminating.~n", [id])		
		neuron_ids_nweights = get_backup(n_pids, [])
		send exoSelf_pid, {self(), backup, neuron_ids_nweights}

		for pid <- s_pids, do: send pid, {:terminate, self()}
		for pid <- ma_pids, do: send pid, {:terminate, self()}
		for pid <- n_pids, do: send pid, {:terminate, self()}
	end

	# Cortex loop
	# ma_pids: Memory actuator pids
	def loop(id, exoSelf_pid, s_pids, {[a_pid|a_pids], ma_pids}, n_pids, step) do
		receive do
			{:sync, a_pid} ->
				loop(id, exoSelf_pid, s_pids, {a_pids, ma_pids}, n_pids, step)
			:terminate ->
				:io.format("Cortex:~p is terminating. ~n", [id])

				for pid <- s_pids, do: send pid, {:terminate, self()}
				for pid <- ma_pids, do: send pid, {:terminate, self()}
				for pid <- n_pids, do: send pid, {:terminate, self()}
		end
	end

	# Cortex loop
	def loop(id, exoSelf_pid, s_pids, {[], ma_pids}, n_pids, step) do

		for pid <- s_pids, do: send pid, {:sync, self()}

		# all the a_pids are exhausted
		# start a new cycle with the ma_pids
		loop(id, exoSelf_pid, s_pids, {ma_pids, ma_pids}, n_pids, step - 1)
	end


	@doc """
	Contact all neurons in its NN and requests for the neuron'id,
	and their input)idps. Once the updated input_idps from all the neurons
	have been accumulated,
	the list is sent to exoself for the actual backup and storage
	"""
	def get_backup([n_pid|n_pids], acc) do
		send n_pid, {:get_backup, self()}
		receive
			{n_pid, n_id, weight_tuples} ->
				get_backup(n_pids, [{n_pid, n_id, weight_tuples} | acc])
		end
	end

	def get_backup([], acc) do
		acc
	end
	
end