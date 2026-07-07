package main

import "core:fmt"
import "core:os"
import "core:strings"
import "eld"

main :: proc() {
	if len(os.args) < 2 {
		fmt.eprintln("usage: eld <file> [arg...]")
		fmt.eprintln("         eld eval <string>")
		fmt.eprintln("         eld dis <file>")
		os.exit(1)
	}

	if os.args[1] == "eval" {
		if len(os.args) != 3 {
			fmt.eprintln("usage: eld eval <string>")
			os.exit(1)
		}

		vm := eld.make_vm()
		eld.set_argv(&vm, os.args, 3)
		result := eld.run_string(&vm, os.args[2])

		if vm.error_string != "" {
			fmt.eprintln(vm.error_string)
			os.exit(1)
		}

		eld.print_value(result)
		fmt.println()
		return
	}

	if os.args[1] == "dis" {
		if len(os.args) != 3 {
			fmt.eprintln("usage: eld dis <file>")
			os.exit(1)
		}

		path_arg := os.args[2]
		source_path := path_arg

		if !os.exists(source_path) && !strings.has_suffix(path_arg, ".eld") {
			source_path = fmt.tprintf("%s.eld", path_arg)
		}

		vm := eld.make_vm()
		eld.set_argv(&vm, os.args, 3)

		disassembly := eld.disassemble_file(&vm, source_path)
		if vm.error_string != "" {
			fmt.eprintln(vm.error_string)
			os.exit(1)
		}
		defer delete(disassembly)

		fmt.print(disassembly)
		return
	}

	path_arg := os.args[1]
	source_path := path_arg

	if !os.exists(source_path) && !strings.has_suffix(path_arg, ".eld") {
		source_path = fmt.tprintf("%s.eld", path_arg)
	}

	vm := eld.make_vm()
	eld.set_argv(&vm, os.args, 2)
	_ = eld.run_file(&vm, source_path)

	if vm.error_string != "" {
		fmt.eprintln(vm.error_string)
		os.exit(1)
	}
}
