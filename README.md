# `nni`

`nni` is an RTL implementation of the nearest neighbor interpolation algorithm
used in demosaicing.

## Testing

Python dependencies are managed via `uv`. They can be installed using the
following command.

```
uv sync
```

`iverilog` and `verilator` are also required. Install them using hte following
command.

```
sudo apt install iverilog verilator gtkwave
```

`uv` automatically manages a virtual environment (`.venv`), but it must be
manually activated before running tests with `cocotb`.

```
source .venv/bin/activate
```

Finally, navigate to the `test/` directory and run testbench with `make`.

```
cd test && make -B
```
