N=1000
ports="2010 2011"

for port in $ports; do
  ruby counter.rb $port & #> /dev/null 2> /dev/null &
done
sleep 5 
for port in $ports; do
  fetch -o - http://localhost:$port/counter > /dev/null
done

date
for port in $ports; do
  ab -n ${N} http://localhost:$port/counter/s:1/p:0 > result.render.$port &
  ab -n ${N} http://localhost:$port/counter/s:1/p:0/h:1 > result.action.$port &
done
date

for port in $ports; do
  kill -9 `cat counter.$port.pid`
  rm -f counter.$port.pid
done
wait
date
