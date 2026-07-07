; gloc - grouped lines of code.
;
; Counts non-blank, non-comment lines grouped by file extension.
; Comment lines are lines whose trimmed text starts with ;, //, --, or #.
;
; Usage:
;
;   eld examples/gloc.eld [path]

(import "fs")
(import "os")
(import "path")
(import "str")


(def stats {})
(def total-files 0)
(def total-lines 0)

(def args (os/args))
(def arg-root
  (if (> (len args) 0)
    (idx args 0)
    nil))

(def root
  (path/clean (?? arg-root (os/env "GLOC_PATH") ".")))


(def (ignored-dir? name)
  (or (= name ".git")
      (= name "_work")
      (= name "_bench")))

(def (ignored-file? file)
  (def name (path/base file))
  (def ext (path/ext file))

  (or (= name ".gitignore")
      (= name ".gitattributes")
      (= ext ".zip")
      (= ext ".md")
      (= ext ".exe")))

(def (comment-line? line)
  (def trimmed (str/trim line))

  (or (= trimmed "")
      (str/prefix? trimmed ";")
      (str/prefix? trimmed "//")
      (str/prefix? trimmed "--")
      (str/prefix? trimmed "#")))

(def (file-ext file)
  (def ext (path/ext file))

  (if (= ext "")
    "(none)"
    ext))

(def (count-text text)
  (def lines (str/split text "\n"))
  (def i 0)
  (def count 0)

  (while (< i (len lines))
    (if (not (comment-line? (idx lines i)))
      (set count (+ count 1)))

    (set i (+ i 1)))

  count)

(def (record-file file line-count)
  (def ext (file-ext file))
  (def entry
    (?? (key stats ext)
        (do
          (set (key stats ext) {:files 0 :lines 0})
          (key stats ext))))

  (set (key entry :files)
    (+ (key entry :files) 1))

  (set (key entry :lines)
    (+ (key entry :lines) line-count))

  (set total-files (+ total-files 1))
  (set total-lines (+ total-lines line-count)))

(def (count-file file)
  (def [text err] (fs/read-file file))

  (if (or err (ignored-file? file))
    nil
    (record-file file (count-text text))))

(def (pad-left value width)
  (def text (str value))

  (while (< (len text) width)
    (set text (str " " text)))

  text)

(def (pad-right value width)
  (def text (str value))

  (while (< (len text) width)
    (set text (str text " ")))

  text)

(def (walk dir)
  (def [names err] (fs/list-dir dir))

  (if err
    (print "skip:" dir err)
    (do
      (def i 0)

      (while (< i (len names))
        (def name (idx names i))
        (def full (path/join dir name))

        (if (fs/dir? full)
          (if (not (ignored-dir? name))
            (walk full))
          (if (fs/file? full)
            (count-file full)))

        (set i (+ i 1))))))

(def (print-stats)
  (print "gloc:" root)

  (def exts (keys stats))
  (def files-width (len "files"))
  (def ext-width (len "ext"))
  (def lines-width (len "loc"))
  (def i 0)

  (while (< i (len exts))
    (def ext (idx exts i))
    (def entry (key stats ext))
    (def files-text (str (key entry :files)))
    (def lines-text (str (key entry :lines)))

    (if (> (len files-text) files-width)
      (set files-width (len files-text)))

    (if (> (len ext) ext-width)
      (set ext-width (len ext)))

    (if (> (len lines-text) lines-width)
      (set lines-width (len lines-text)))

    (set i (+ i 1)))

  (write (pad-left "files" files-width) "  "
         (pad-right "ext" ext-width) "  "
         (pad-left "lines" lines-width) "\n")

  (set i 0)

  (while (< i (len exts))
    (def ext (idx exts i))
    (def entry (key stats ext))

    (write (pad-left (key entry :files) files-width) "  "
           (pad-right ext ext-width) "  "
           (pad-left (key entry :lines) lines-width) "\n")

    (set i (+ i 1)))

  (print)(print "total" total-files "files" total-lines "lines"))


(if (fs/dir? root)
  (walk root)

  (if (fs/file? root)
    (count-file root)

    (do
      (print "path not found:" root)
      (os/exit 1))))

(print-stats)
