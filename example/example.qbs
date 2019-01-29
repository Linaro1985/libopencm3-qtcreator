import qbs
import qbs.FileInfo
import qbs.ModUtils

import "../Stm32App.qbs" as Stm32App

Stm32App {
    name: "example"

    // stm32Chip: "stm32f103c8t6"
    // romOffset: "0x08000000"
    // romSize: "64K"
    // ramOffset: "0x20000000"
    // ramSize: "20K"
    // stringList stm32flags: []

    Group {
        name: "sources"
        prefix: "./"
        files: [
            "main.c"
        ]
    }

    Group {
        name: "headers"
        prefix: "./"
        files: [
        ]
    }

    Group {
        fileTagsFilter: "application"
        qbs.install: true
    }
}
