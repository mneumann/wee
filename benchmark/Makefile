N=2000

RUBY=ruby

all: bench1 bench2
	echo "DONE"

start_counter:
	# start the counter app
	$(RUBY) counter.rb 2000 > /dev/null 2> /dev/null &
	sleep 3

stop_counter:
	kill -9 `cat counter.2000.pid`
	rm -f counter.2000.pid
	rm -f dump

bench_counter:
	# generate initial session and first page
	fetch -o counter.html http://localhost:2000/counter

	# perform benchmark
	ab -n ${N} http://localhost:2000/counter/s:1/p:1 > result.${N}.counter.render
	ab -n ${N} http://localhost:2000/counter/s:1/p:1/h:1 > result.${N}.counter.action

start_filehandler:
	# start the filehandler app
	$(RUBY) filehandler.rb > /dev/null 2> /dev/null &
	sleep 3

stop_filehandler:
	kill -9 `cat filehandler.pid`
	rm -f filehandler.pid

bench_filehandler:
	ab -n ${N} http://localhost:2000/counter.html > result.${N}.filehandler

clean:
	rm -f counter.2000.pid
	rm -f filehandler.pid
	rm -f dump
	rm -f result.${N}.*
	rm -f counter.html

bench1: start_counter bench_counter stop_counter
bench2: start_filehandler bench_filehandler stop_filehandler


