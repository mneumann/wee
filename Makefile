rdoc: clean
	rdoc --main README --all --inline-source --op doc/rdoc lib README

clean:
	rm -rf rdoc
