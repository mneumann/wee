N=2000
PORT=2000
COUNTERS=10

RUBY=ruby

all: bench1 bench2
	echo "DONE"

start_counter:
	# start the counter app
	$(RUBY) counter.rb $(PORT) $(COUNTERS) > /dev/null 2> /dev/null &
	sleep 3

stop_counter:
	kill -9 `cat counter.$(PORT).pid`
	rm -f counter.$(PORT).pid
	rm -f dump

bench_counter:
	# generate initial session and first page
	fetch -o counter.html http://localhost:$(PORT)/counter

	# perform benchmark
	ab -n ${N} http://localhost:$(PORT)/counter/@1/1 > result.${N}.counter.render
	ab -n ${N} http://localhost:$(PORT)/counter/@1/1?4 > result.${N}.counter.action

report_counter:
	$(RUBY) report_req.rb result.$(N).counter.render result.$(N).counter.action

start_filehandler:
	# start the filehandler app
	$(RUBY) filehandler.rb > /dev/null 2> /dev/null &
	sleep 3

stop_filehandler:
	kill -9 `cat filehandler.pid`
	rm -f filehandler.pid

bench_filehandler:
	ab -n ${N} http://localhost:$(PORT)/counter.html > result.${N}.filehandler

clean:
	rm -f counter.$(PORT).pid
	rm -f filehandler.pid
	rm -f dump
	rm -f result.${N}.*
	rm -f counter.html

bench1: start_counter bench_counter stop_counter report_counter
bench2: start_filehandler bench_filehandler stop_filehandler


