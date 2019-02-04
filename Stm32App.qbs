import qbs
import qbs.FileInfo
import qbs.ModUtils

Product {
    Depends { name: "cpp" }

    property string stm32Chip: "stm32f103c8t6"
    property string romOffset: "0x08000000"
    property string romSize: "64K"
    property string ramOffset: "0x20000000"
    property string ramSize: "20K"
    property stringList stm32flags: [
        "-mcpu=cortex-m3",
        "-mthumb",
        "-msoft-float",
    ]

    property string stm32ChipUpper: stm32Chip.toUpperCase()
    
    type: [
        "ldscript",
        "application",
        "bin",
        "hex"
    ]
    
    consoleApplication: true

    cpp.defines: [
        stm32ChipUpper.substr(0, 7),
        stm32ChipUpper
    ]

    Properties {
        condition: cpp.debugInformation
        cpp.defines: outer.concat(["DEBUG=1"])
        cpp.optimization: "none"
    }

    cpp.optimization: "small"

    cpp.includePaths: [
        "../libopencm3/include"
    ]

    cpp.libraryPaths: [
        "../libopencm3/lib"
    ]

    cpp.staticLibraries: [
        "opencm3_" + stm32Chip.substr(0, 7),
        "c", "gcc", "nosys"
    ]

    cpp.positionIndependentCode: false
    cpp.cFlags: ["-std=c99"]
    cpp.cxxFlags: ["-std=c++11"]
    cpp.enableExceptions: false
    cpp.executableSuffix: ".elf"

    cpp.commonCompilerFlags: stm32flags.concat([
        "-ggdb3",
        "-fno-common",
        "-ffunction-sections",
        "-fdata-sections",
	"-fno-merge-all-constants",
	"-fmerge-constants",
        "-Wshadow",
        "-Wno-unused-variable",
        "-Wimplicit-function-declaration",
        "-Wredundant-decls",
        "-Wstrict-prototypes",
        "-Wmissing-prototypes",
        "-MD",
        "-Wundef"
    ])

    cpp.linkerFlags: [
        "--gc-sections"
    ]

    cpp.driverLinkerFlags: stm32flags.concat([
         "-T" + buildDirectory + "/" +product.name + ".ld",
         "-nostartfiles",
         "-specs=nano.specs"
    ])

    Group {
        name: "Linker Script Template"
        files: [ "libopencm3/ld/linker.ld.S" ]
        fileTags: [ "linker.gen" ]
    }

    Rule {
        inputs: [ "linker.gen" ]
        
        Artifact {
            fileTags: ["ldscript"]
            filePath: product.buildDirectory + "/" + product.name + ".ld"
        }
        
        prepare: {
            var args = [
                "-E", 
                "-P"
            ].concat(product.stm32flags);
            var defines = [
                "_ROM=" + product.romSize,
                "_RAM=" + product.ramSize,
                "_ROM_OFF=" + product.romOffset,
                "_RAM_OFF=" + product.ramOffset
            ].concat(product.moduleProperty("cpp", "defines"))
            for (i in defines)
                args.push("-D" + defines[i]);
            args.push(input.filePath);
            var cmd = new Command(product.moduleProperty("cpp", "compilerPath"), args);
            cmd.description = "generate ld script: " + output.filePath;
            cmd.stdoutFilePath = output.filePath;
            return cmd;
        }
    }

    Rule {
        condition: qbs.buildVariant == "release"
        inputs: ["application"]

        Artifact {
            fileTags: ["bin"]
            filePath: input.baseDir + "/" + input.baseName + ".bin"
        }

        prepare: {
            var cmd = new Command(product.moduleProperty("cpp", "objcopyPath"), ["-O", "binary", input.filePath, output.filePath]);
            cmd.description = "converting to BIN: " + FileInfo.fileName(input.filePath) + " -> " + input.baseName + ".bin";
            return cmd;
        }
    }
    
    Rule {
        condition: qbs.buildVariant == "release"
        inputs: ["application"]
        
        Artifact {
            fileTags: ["hex"]
            filePath: input.baseDir + "/" + input.baseName + ".hex"
        }
        
        prepare: {
            var cmd = new Command(product.moduleProperty("cpp", "objcopyPath"), ["-O", "ihex", input.filePath, output.filePath]);
            cmd.description = "converting to HEX: " + FileInfo.fileName(input.filePath) + " -> " + input.baseName + ".hex";
            return cmd;
        }
    }
}
