;;; dap-rust.el --- Debug Adapter Protocol mode for Rust powered by CodeLLDB -*- lexical-binding: t; -*-

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; URL: https://github.com/yyoncho/dap-mode
;; Package-Requires: ((emacs "25.1") (dash "2.14.1") (lsp-mode "4.0"))
;; Version: 0.2

;;; Commentary:
;; Adapter for https://github.com/vadimcn/vscode-lldb version 1.5
;; User manual can be found here
;; https://github.com/vadimcn/vscode-lldb/blob/874ac867ac413865af4fe07817ea537d253ad42f/MANUAL.md

;;; Code:


(require 'dap-mode)
(require 'rust-mode)
(require 'cargo-process)
(require 'lsp-mode)

;; Use cases:
;; 1. Debug this test
;; 2. Debug the binary
;; 3. Debug this example
;; 4. Debug this benchmark (compile in release mode and debug)


(defun dap-rust--populate-start-file-args (conf)
  "Populate CONF with the required arguments."
  (let* ((host "localhost")
         ;; TODO find a way to pass a function to populate-start-args
         ;; the function will stay a symbol until start the debugger and need to find a port
         ;; (debug-port (dap--find-available-port))
         (debug-port 23333)
         )
  ;; dap-python uses this - let's see if it works
  ;; Program that we will use to start the DAP server 
    (plist-put conf :program-to-start "RUST_BACKTRACE=full RUST_LOG=error,codelldb=debug ~/.vscode/extensions/vadimcn.vscode-lldb-1.5.0/adapter2/codelldb --libpython /usr/lib/x86_64-linux-gnu/libpython3.6m.so --port 23333")
  ;; ASK: what is better debugServer or port?
  (plist-put conf :debugServer debug-port)
  (plist-put conf :port debug-port)
  ;; ASK: what is the difference between hostName and host?
  (plist-put conf :hostName host)
  (plist-put conf :host host)
  
  ;; TODO find a way to find lsp-workspace root for the project
  (plist-put conf :cwd nil)
  ;; For visualising data structures
  ;; https://github.com/vadimcn/vscode-lldb/blob/874ac867ac413865af4fe07817ea537d253ad42f/MANUAL.md#rust-language-support
  (plist-put conf :sourceLanguages: "rust")
  conf))

(dap-register-debug-provider "lldb" 'dap-rust--populate-start-file-args)

;; TODO install and use an lldb-server in the emacs-directory
(defvar dap-server-path "../.vscode/extensions/vadimcn.vscode-lldb-1.5.0/lldb/bin/lldb-server" "Path to the executable for lldb-server")
(setq dap-server-path "~/.vscode/extensions/vadimcn.vscode-lldb-1.5.0/adapter2/codelldb")

;; (defcustom dap-rust-server-path `(,(expand-file-name dap-server-path))
;;   "The path to codelldb debug server"
;;   :group 'dap-rust
;;   :type '(repeat string))

(defun lldb-server-command (port)
  "Create a COMMAND to start the vscode lldb DAP server to listen on a given port"
  (list
   dap-server-path
   "platform"
   "--server"
   "--listen"
   (concat "*:" (number-to-string port))
   "--log-channels"
   "\"lldb all\"")
  )

;; Debug one specific unit test as found by rust-mode
;; Relies on text
;; TODO: check if lsp-rust can locate and return name of the method marked by #[test]
;; given a Location in a file
(dap-register-debug-template "Rust Debug #tests in library"
                             (list
                              :type "lldb"
                              :request "launch"
                              ;; TODO vscode-lldb can do this on the server, but dap-mode requires a value
                              :program "~/Coding/rust/dap-rust-example/target/debug/dap-rust-example"
                              ;; TODO make names that reflect the 4 usecases outlined above
                              :name "Debug unit tests in library"
                              :cargo (list :args '("test" "--no-run" "--lib"))
                              :cwd (cargo-process--workspace-root)
))

(provide 'dap-rust)
