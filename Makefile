# Add every provided goal...
.PHONY: $(MAKECMDGOALS)


# firmware configuration
export FIRMWARE=esp32spiram-idf3-20210202-v1.14.bin
export FIRMWARE_URL=https://micropython.org/resources/firmware/${FIRMWARE}
export FIRMWARE_ADDRESS=0x1000

# port and baud configuration
export PORT=/dev/ttyUSB0
export BAUD=115200
export BAUD_BIN=460800

# map config to ampy
export AMPY_PORT=${PORT}
export AMPY_BAUD=${BAUD}
export AMPY_DELAY=0.5 # Fix for macOS users' "Could not enter raw repl"; try 2.0 and lower from there

# pipenv configuration
export PIPENV_VENV_IN_PROJECT=1


# Install dpendencies from Pipenv.lock
pipenv-init:
	pipenv sync

# Install dpendencies including dev from Pipenv.lock
pipenv-init-dev:
	pipenv sync --dev

# Install package and add it to Pipfile or install all packages specified in Pipfile if no package as ARG is given
pipenv-install:
	pipenv install ${ARG}

# Same as install but include dev dependencies
pipenv-install-dev:
	pipenv install --dev ${ARG}

# Uninstall package and remove it as dependency from Pipfile; ARG is mandatory
pipenv-uninstall:
	pipenv uninstall ${ARG}

# Uninstall package and remove it as dev dependency from Pipfile; ARG is mandatory
pipenv-uninstall-dev:
	pipenv uninstall --dev ${ARG}

# Start pipenv shell
pipenv:
	@echo "Spawning pipenv shell... Use 'exit' to leave."
	@pipenv shell

# Copy and run file on device; ARG is mandatory
run:
	pipenv run ampy run ${ARG}

# Run locally
run-local:
	micropython $(or ${ARG}, ${ARG}, src/main.py)

# ls remote files
ls:
	pipenv run ampy ls ${ARG}

# Start repl on remote device using screen
repl:
	screen ${PORT} ${BAUD}

# Deploy all src files to remote device
deploy-all:
	@echo "Uploading files from src..."
	@ls src | xargs -n1 -I {} pipenv run ampy put "src/{}" "{}"
	@pipenv run ampy ls -lr

# Deploy file to remote device; ARG is mandatory
deploy:
	@echo "Uploading file ${ARG}..."
	@pipenv run ampy put "${ARG}"
	@pipenv run ampy ls -lr

# Download esp firmware, erase flash and write new firmware to flash using esptool.py
firmware-esp:
	mkdir -p build
	wget --no-clobber ${FIRMWARE_URL} -P build

	@echo Warning: Erase flash, continue? [Y/n]
	@read line; if [ "$$line" != "y" ] && [ "$$line" != "Y" ]; then echo ...aborted; exit 1; fi
	pipenv run esptool.py --chip auto --port ${PORT} --baud ${BAUD} erase_flash

	@echo Warning: Flash firmware/${FIRMWARE}, continue? [Y/n]
	@read line; if [ "$$line" != "y" ] && [ "$$line" != "Y" ]; then echo ...aborted; exit 1; fi
	pipenv run esptool.py --chip auto --port ${PORT} --baud ${BAUD_BIN} write_flash --compress ${FIRMWARE_ADDRESS} build/${FIRMWARE}
	# TODO burn a key and encrypt data, see https://github.com/espressif/esptool/wiki/espefuse#burning-a-key

# Run unit tests
test:
ifdef name
	python -m unittest -v tests.$(name)
else
	python -m unittest discover -v
endif