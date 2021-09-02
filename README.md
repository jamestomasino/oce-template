# OCE Template

The following make tasks are available:

    build    - Build all files to output folder
    package  - Prepare zip package for OCE upload
    serve    - Watch project for file changes and rebuild with local server
    clean    - Clean project

## Dependencies

* GNU Make
* m4
* yarn
* zip (for `package` task)
* entr (for `serve` task)
* python3 (for `serve` task)
* ag (for `serve` task)

## OCE Notes

* Slide thumbnails must be 311x233 in size.
* PDF Assets must begin with `oceasset_`

## Template Notes

* m4 include paths are from repository root
* m4 is available to slide HTML, slide JS, and global JS
