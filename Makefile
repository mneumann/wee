rdoc: clean
	rdoc --main README --all --inline-source --op rdoc lib README

clean:
	rm -rf rdoc
