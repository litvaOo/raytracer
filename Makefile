run:
	mkdir -p target && odin run . -out:target/raytracer

run-optimized:
	mkdir -p target/release && odin run . -out:target/release/raytracer -o:aggressive -microarch:native
