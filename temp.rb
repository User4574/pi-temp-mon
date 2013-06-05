require 'rubygems'
require 'mqtt'
require 'yaml'

CONFIG = open("config.yml") do |fd| YAML.load fd end

def start

	pid = Process.fork

	if pid.nil? then

		cli = MQTT::Client.new(
			:remote_host	=> CONFIG[:broker][:remote],
			:client_id		=> CONFIG[:broker][:clientid],
			:will_topic		=> CONFIG[:topics][:lwt],
			:will_payload	=> "Last Will and Testament: #{CONFIG[:broker][:clientid]} has died!"
		)

		cli.connect do |c|

			Signal.trap("TERM") do
				c.publish "#{CONFIG[:topics][:status]}/#{CONFIG[:broker][:clientid]}", "Stopped"
				c.disconnect
				Process.exit! true
			end

			c.publish "#{CONFIG[:topics][:status]}/#{CONFIG[:broker][:clientid]}", "Started"

			while true do

				bulk = ""

				IO.readlines("/sys/devices/w1_bus_master1/w1_master_slaves").each do |idn|
					id = idn.chomp

					lines = IO.readlines "/sys/devices/w1_bus_master1/#{id}/w1_slave"

					spl = lines[1].split "="
					temp = spl[1]

					c.publish "#{CONFIG[:topics][:report]}/#{CONFIG[:broker][:clientid]}/#{id}", "#{temp}"
					bulk += "#{id} : #{temp}"
				end

				c.publish "#{CONFIG[:topics][:report]}/#{CONFIG[:broker][:clientid]}/bulk", bulk

				sleep CONFIG[:reports][:period]

			end

		end

	else

		File.open("tempworker.pid", "w") do |file|
			file.write "#{CONFIG[:broker][:clientid]} : #{pid}"
		end

		puts "Worker #{CONFIG[:broker][:clientid]} started on PID #{pid}."

		Process.detach(pid)

	end

end

def stop

	IO.readlines("tempworker.pid").each do |line|

		linearr = line.split ":"
		Process.kill "TERM", linearr[1].to_i

		puts "Worker #{CONFIG[:broker][:clientid]}, PID #{linearr[1].to_i} killed."

	end

	File.unlink "tempworker.pid"

end

def restart
	stop
	start
end

case ARGV.first
	when "start"
		start
	when "stop"
		stop
	when "restart"
		restart
	else
		puts "Usage: ruby temp.rb { start | stop | restart }"
end
