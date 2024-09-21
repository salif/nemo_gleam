import envoy
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gu

pub type Cx {
   Cx(msg: fn(String) -> String, path: String, gleam_cmd: String, do_log: Bool)
}

pub fn run(cx: Cx, args: List(String)) -> Bool {
   case list.first(args) {
      Ok(path) -> actions(Cx(..cx, path: path))
      Error(Nil) ->
         path_prompt(Cx(..cx, path: "."))
         |> result.map(actions(_))
         |> result.unwrap_both()
   }
}

pub fn run_actions_list(cx: Cx, args: List(String)) -> Bool {
   case list.first(args) {
      Ok(path) -> actions_list(Cx(..cx, path: path))
      Error(Nil) ->
         path_prompt(Cx(..cx, path: "."))
         |> result.map(actions_list(_))
         |> result.unwrap_both()
   }
}

pub fn run_action(cx: Cx, action: String, args: List(String)) -> Bool {
   case list.first(args) {
      Ok(path) -> actions_action(Cx(..cx, path: path), action)
      Error(Nil) ->
         path_prompt(Cx(..cx, path: "."))
         |> result.map(actions_action(_, action))
         |> result.unwrap_both()
   }
}

pub fn alert(
   alert_type: Int,
   text: String,
   title: option.Option(String),
) -> Bool {
   case
      gu.zenity
      |> gu.add_option_bool(alert_type == 0, "info")
      |> gu.add_option_bool(alert_type != 0, "error")
      |> gu.add_option(title, "title")
      |> gu.new_message_opts(
         text: Some(text),
         icon: None,
         no_wrap: True,
         no_markup: True,
         ellipsize: False,
      )
      |> gu.show(False)
   {
      Error(err) ->
         case err.0 == 1 && err.1 == "" {
            True -> Nil
            False -> io.println_error(int.to_string(alert_type) <> ": " <> text)
         }
      Ok(_) -> Nil
   }
   alert_type == 0
}

pub fn alert_usage(title: String, text: String) -> Bool {
   gu.zenity
   |> gu.new_info()
   |> gu.set_title(title)
   |> gu.new_message_opts(
      text: Some(text),
      icon: None,
      no_wrap: True,
      no_markup: True,
      ellipsize: False,
   )
   |> gu.show(False)
   |> result.replace(True)
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn alert_gu_error(gu_error: #(Int, String)) -> Bool {
   case gu_error.0 == 1 && gu_error.1 == "" {
      True -> False
      False ->
         alert(
            gu_error.0,
            int.to_string(gu_error.0) <> ": " <> gu_error.1,
            None,
         )
   }
}

fn alert_invalid(cx: Cx, value: List(String)) -> Bool {
   alert(
      1,
      cx.msg("Invalid input") <> ": [" <> string.join(value, "] [") <> "]",
      None,
   )
}

fn alert_not_supported(cx: Cx, value: String) -> Bool {
   alert(1, cx.msg("Not supported yet") <> ": " <> value, None)
}

fn alert_missing_env(cx: Cx) -> Bool {
   alert(1, cx.msg("Missing HEXPM_USER, HEXPM_PASS or HEXPM_API_KEY"), None)
}

fn do_action(cmd: List(String), cx: Cx) -> Bool {
   do_action_and_ignore(cmd, cx, False)
}

fn do_action_and_ignore(cmd: List(String), cx: Cx, ignore: Bool) -> Bool {
   let cmd_rev: List(String) = list.reverse(cmd)
   let cmd_line: String = "> " <> string.join(cmd_rev, " ") <> "\n\n"
   case cx.do_log {
      True -> io.println_error(cmd_line)
      False -> Nil
   }
   case gu.show_in(cmd, cx.path, err: True) {
      Ok(val) ->
         case ignore {
            True -> True
            False -> {
               let title: String =
                  string.join(
                     list.split_while(cmd_rev, fn(c: String) -> Bool {
                        !string.starts_with(c, "-")
                     }).0,
                     " ",
                  )
               alert(0, cmd_line <> val, Some(title))
            }
         }
      Error(err) -> alert(err.0, cmd_line <> err.1, None)
   }
}

fn check_env() -> Bool {
   let api_key: Result(String, Nil) = envoy.get("HEXPM_API_KEY")
   let user: Result(String, Nil) = envoy.get("HEXPM_USER")
   let pass: Result(String, Nil) = envoy.get("HEXPM_PASS")
   case result.is_ok(api_key), { result.is_ok(user) && result.is_ok(pass) } {
      False, False -> False
      _, _ -> True
   }
}

fn path_prompt(cx: Cx) -> Result(Cx, Bool) {
   gu.zenity
   |> gu.new_file_selection(
      filename: None,
      multiple: False,
      directory: True,
      save: False,
      separator: None,
      file_filter: None,
   )
   |> gu.set_title(cx.msg("Select a Gleam project"))
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> fn(gu_result: gu.GuResult) -> Result(Cx, Bool) {
      case gu_result {
         Ok(answer) ->
            case string.split(answer, "|") {
               [path] -> Ok(Cx(..cx, path: path))
               value -> Error(alert_invalid(cx, value))
            }
         Error(err) -> Error(alert_gu_error(err))
      }
   }
}

fn actions(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_question()
   |> gu.set_title(cx.msg("Gleam Actions"))
   |> gu.new_message_opts(
      text: Some(cx.msg("Commands:")),
      icon: Some("view-compact"),
      no_wrap: False,
      no_markup: True,
      ellipsize: False,
   )
   |> gu.new_question_opts(default_cancel: False, switch: True)
   |> gu.add_extra_button(cx.msg("Close"))
   |> gu.add_extra_button("help")
   |> gu.add_extra_button("update")
   |> gu.add_extra_button("test")
   |> gu.add_extra_button("run")
   |> gu.add_extra_button("remove")
   |> gu.add_extra_button("publish")
   |> gu.add_extra_button("new")
   |> gu.add_extra_button("hex")
   |> gu.add_extra_button("format")
   |> gu.add_extra_button("fix")
   |> gu.add_extra_button("export")
   |> gu.add_extra_button("docs")
   |> gu.add_extra_button("deps")
   |> gu.add_extra_button("clean")
   |> gu.add_extra_button("check")
   |> gu.add_extra_button("build")
   |> gu.add_extra_button("add")
   |> gu.set_timeout(120)
   |> gu.prompt_in(cx.path)
   |> result.map_error(fn(err: #(Int, String)) { err.1 })
   |> result.unwrap_both()
   |> fn(answer: String) -> Bool {
      case string.is_empty(answer) {
         True -> False
         False ->
            case answer == cx.msg("Close") {
               True -> False
               False -> actions_action(cx, answer)
            }
      }
   }
}

fn actions_list(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_list()
   |> gu.set_title(cx.msg("Gleam Actions"))
   |> gu.set_text(cx.msg("Select a command"))
   |> gu.set_height(700)
   |> gu.set_separator("|")
   |> gu.add_option_bool(True, "hide-header")
   |> gu.add_column("Command")
   |> gu.add_column("Description")
   |> gu.add_row(["add", cx.msg("Add new project dependencies")])
   |> gu.add_row(["build", cx.msg("Build the project")])
   |> gu.add_row(["check", cx.msg("Type check the project")])
   |> gu.add_row(["clean", cx.msg("Clean build artifacts")])
   |> gu.add_row(["deps", cx.msg("Work with dependency packages")])
   |> gu.add_row(["docs", cx.msg("Render HTML documentation")])
   |> gu.add_row([
      "export",
      cx.msg("Export something useful from the Gleam project"),
   ])
   |> gu.add_row(["fix", cx.msg("Rewrite deprecated Gleam code")])
   |> gu.add_row(["format", cx.msg("Format source code")])
   |> gu.add_row(["hex", cx.msg("Work with the Hex package manager")])
   |> gu.add_row(["new", cx.msg("Create a new project")])
   |> gu.add_row([
      "publish",
      cx.msg("Publish the project to the Hex package manager"),
   ])
   |> gu.add_row(["remove", cx.msg("Remove project dependencies")])
   |> gu.add_row(["run", cx.msg("Run the project")])
   |> gu.add_row(["test", cx.msg("Run the project tests")])
   |> gu.add_row([
      "update",
      cx.msg("Update dependency packages to their latest versions"),
   ])
   |> gu.add_row(["help", cx.msg("Print help")])
   |> gu.prompt_in(cx.path)
   |> result.map(actions_action(cx, _))
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn actions_action(cx: Cx, action: String) -> Bool {
   case action {
      "add" -> action_add(cx)
      "build" -> action_build(cx)
      "check" -> action_check(cx)
      "clean" -> do_action_and_ignore(gu.cmd([cx.gleam_cmd, action]), cx, True)
      "deps" -> action_deps(cx)
      "docs" -> action_docs(cx)
      "export" -> action_export(cx)
      "fix" -> do_action(gu.cmd([cx.gleam_cmd, action]), cx)
      "format" -> action_format(cx)
      "hex" -> action_hex(cx)
      "new" -> action_new(cx)
      "publish" -> action_publish(cx)
      "remove" -> action_remove(cx)
      "run" -> action_run(cx)
      "test" -> action_test(cx)
      "update" -> do_action(gu.cmd([cx.gleam_cmd, action]), cx)
      "help" -> do_action(gu.cmd([cx.gleam_cmd, action]), cx)
      _ -> alert_not_supported(cx, action)
   }
}

fn action_add(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Add new project dependencies"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_entry(cx.msg("The names of Hex packages to add"))
   |> gu.add_combo_and_values(
      cx.msg("Add the packages as dev-only dependencies"),
      values: [cx.msg("no"), cx.msg("yes")],
   )
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      case string.split(answer, "|") {
         [packages, dev] ->
            do_action(
               gu.cmd([cx.gleam_cmd, "add"])
                  |> gu.add_option_bool(dev == cx.msg("yes"), "dev")
                  |> gu.add_row(string.split(string.trim(packages), " ")),
               cx,
            )
         value -> alert_invalid(cx, value)
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_build(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Build the project"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_combo_and_values(
      cx.msg("Emit compile time warnings as errors"),
      values: [cx.msg("no"), cx.msg("yes")],
   )
   |> gu.add_combo_and_values(cx.msg("The platform to target"), values: [
      cx.msg("unset"),
      "erlang",
      "javascript",
   ])
   |> gu.add_combo_and_values(
      cx.msg("Don't print progress information"),
      values: [cx.msg("no"), cx.msg("yes")],
   )
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      case string.split(answer, "|") {
         [warnings_as_errors, target, no_print_progress] ->
            do_action(
               gu.cmd([cx.gleam_cmd, "build"])
                  |> gu.add_option_bool(
                     warnings_as_errors == cx.msg("yes"),
                     "warnings-as-errors",
                  )
                  |> gu.add_option_if(
                     target != cx.msg("unset"),
                     target,
                     "target",
                  )
                  |> gu.add_option_bool(
                     no_print_progress == cx.msg("yes"),
                     "no-print-progress",
                  ),
               cx,
            )
         value -> alert_invalid(cx, value)
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_check(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Type check the project"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_combo_and_values(cx.msg("The platform to target"), values: [
      cx.msg("unset"),
      "erlang",
      "javascript",
   ])
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      let target: String = answer
      do_action(
         gu.cmd([cx.gleam_cmd, "check"])
            |> gu.add_option_if(target != cx.msg("unset"), target, "target"),
         cx,
      )
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_deps(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_list()
   |> gu.set_title(cx.msg("Work with dependency packages"))
   |> gu.set_text(cx.msg("Select a command"))
   |> gu.set_separator("|")
   |> gu.add_option_bool(True, "hide-header")
   |> gu.add_column("Command")
   |> gu.add_column("Description")
   |> gu.add_row(["list", cx.msg("List all dependency packages")])
   |> gu.add_row(["download", cx.msg("Download all dependency packages")])
   |> gu.add_row([
      "update",
      cx.msg("Update dependency packages to their latest versions"),
   ])
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      let command: String = answer
      do_action(gu.cmd([cx.gleam_cmd, "deps", command]), cx)
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_docs(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_list()
   |> gu.set_title(cx.msg("Render HTML documentation"))
   |> gu.set_text(cx.msg("Select a command"))
   |> gu.set_separator("|")
   |> gu.add_option_bool(True, "hide-header")
   |> gu.add_column("Command")
   |> gu.add_column("Description")
   |> gu.add_row(["build", cx.msg("Render HTML docs locally")])
   |> gu.add_row(["publish", cx.msg("Publish HTML docs to HexDocs")])
   |> gu.add_row(["remove", cx.msg("Remove HTML docs from HexDocs")])
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      let command: String = answer
      case command {
         "build" -> action_docs_build(cx)
         "publish" ->
            case check_env() {
               False -> alert_missing_env(cx)
               True -> do_action(gu.cmd([cx.gleam_cmd, "docs", command]), cx)
            }
         "remove" -> action_docs_remove(cx)
         _ -> alert_not_supported(cx, command)
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_docs_build(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Render HTML docs locally"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.set_separator("|")
   |> gu.add_combo_and_values(
      cx.msg("Opens the docs in a browser after rendering"),
      values: [cx.msg("no"), cx.msg("yes")],
   )
   |> gu.add_combo_and_values(cx.msg("The platform to target"), values: [
      cx.msg("unset"),
      "erlang",
      "javascript",
   ])
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      case string.split(answer, "|") {
         [open, target] ->
            do_action(
               gu.cmd([cx.gleam_cmd, "docs", "build"])
                  |> gu.add_option_bool(open == cx.msg("yes"), "open")
                  |> gu.add_option_if(
                     target != cx.msg("unset"),
                     target,
                     "target",
                  ),
               cx,
            )
         value -> alert_invalid(cx, value)
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_docs_remove(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Remove HTML docs from HexDocs"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_entry(cx.msg("The name of the package"))
   |> gu.add_entry(cx.msg("The version of the docs to remove"))
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      case check_env() {
         False -> alert_missing_env(cx)
         True -> {
            case string.split(answer, "|") {
               [package, version] ->
                  do_action(
                     gu.cmd([cx.gleam_cmd, "docs", "remove"])
                        |> gu.add_option(Some(package), "package")
                        |> gu.add_option(Some(version), "version"),
                     cx,
                  )
               value -> alert_invalid(cx, value)
            }
         }
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_export(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_list()
   |> gu.set_title(cx.msg("Export something useful from the Gleam project"))
   |> gu.set_text(cx.msg("Select a command"))
   |> gu.set_separator("|")
   |> gu.add_option_bool(True, "hide-header")
   |> gu.add_column("Command")
   |> gu.add_column("Description")
   |> gu.add_row([
      "erlang-shipment",
      cx.msg("Precompiled Erlang, suitable for deployment"),
   ])
   |> gu.add_row([
      "hex-tarball",
      cx.msg(
         "The package bundled into a tarball, suitable for publishing to Hex",
      ),
   ])
   |> gu.add_row(["javascript-prelude", cx.msg("The JavaScript prelude module")])
   |> gu.add_row(["typescript-prelude", cx.msg("The TypeScript prelude module")])
   |> gu.add_row([
      "package-interface",
      cx.msg(
         "Information on the modules, functions, and types in the project in JSON format",
      ),
   ])
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      let command: String = answer
      case command {
         "erlang-shipment" ->
            do_action(gu.cmd([cx.gleam_cmd, "export", command]), cx)
         "hex-tarball" ->
            do_action(gu.cmd([cx.gleam_cmd, "export", command]), cx)
         "javascript-prelude" -> action_export_prelude(cx, command)
         "typescript-prelude" -> action_export_prelude(cx, command)
         "package-interface" -> action_export_package_interface(cx)
         _ -> alert_not_supported(cx, command)
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_export_prelude(cx: Cx, prelude: String) -> Bool {
   do_action_and_ignore(
      gu.cmd([
         "sh",
         "-euc",
         cx.gleam_cmd
            <> " export "
            <> prelude
            <> " | "
            <> string.join(
            gu.zenity
               |> gu.new_text_info(
                  filename: None,
                  editable: True,
                  font: None,
                  checkbox: None,
                  auto_scroll: True,
               )
               |> gu.set_title(prelude)
               |> list.reverse(),
            " ",
         )
            <> " | exit 0",
      ]),
      cx,
      True,
   )
}

fn action_export_package_interface(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg(
      "Information on the modules, functions, and types in the project in JSON format",
   ))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_entry(cx.msg("The path to write the JSON file to"))
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      let path: String = answer
      do_action(
         gu.cmd([cx.gleam_cmd, "export", "package-interface"])
            |> gu.add_option_if(!string.is_empty(path), path, "out"),
         cx,
      )
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_format(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Format source code"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_combo_and_values(cx.msg("Read source from STDIN"), values: [
      cx.msg("no"),
   ])
   |> gu.add_combo_and_values(
      cx.msg("Check if inputs are formatted without changing them"),
      values: [cx.msg("no"), cx.msg("yes")],
   )
   |> gu.set_separator("\n")
   |> gu.prompt_in(cx.path)
   |> result.try(fn(answer: String) -> gu.GuResult {
      gu.zenity
      |> gu.new_file_selection(
         filename: None,
         multiple: True,
         directory: False,
         save: False,
         separator: Some("|"),
         file_filter: None,
      )
      |> gu.prompt_in(cx.path)
      |> result.map(string.split(_, "|"))
      |> result.map(fn(files: List(String)) -> String {
         string.join(files, " ") <> "\n" <> answer
      })
   })
   |> result.map(fn(answer: String) -> Bool {
      case string.split(answer, "\n") {
         [files, stdin, check] ->
            do_action_and_ignore(
               gu.cmd([cx.gleam_cmd, "format"])
                  |> gu.add_option_bool(stdin == cx.msg("yes"), "stdin")
                  |> gu.add_option_bool(check == cx.msg("yes"), "check")
                  |> gu.add_row(string.split(files, " ")),
               cx,
               True,
            )
         value -> alert_invalid(cx, value)
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_hex(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_list()
   |> gu.set_title(cx.msg("Work with the Hex package manager"))
   |> gu.set_text(cx.msg("Select a command"))
   |> gu.set_separator("|")
   |> gu.add_option_bool(True, "hide-header")
   |> gu.add_column("Command")
   |> gu.add_column("Description")
   |> gu.add_row(["retire", cx.msg("Retire a release from Hex")])
   |> gu.add_row(["unretire", cx.msg("Un-retire a release from Hex")])
   |> gu.add_row(["revert", cx.msg("Revert a release from Hex")])
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      let command: String = answer
      case command {
         "retire" -> action_hex_retire(cx)
         "unretire" -> action_hex_unretire(cx)
         "revert" -> action_hex_revert(cx)
         _ -> alert_not_supported(cx, command)
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_hex_retire(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Retire a release from Hex"))
   |> gu.set_text(cx.msg("Arguments"))
   |> gu.add_entry("<PACKAGE>")
   |> gu.add_entry("<VERSION>")
   |> gu.add_combo_and_values("<REASON>", values: [
      "other", "invalid", "security", "deprecated", "renamed",
   ])
   |> gu.add_entry("[MESSAGE]")
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      case check_env() {
         False -> alert_missing_env(cx)
         True -> {
            case string.split(answer, "|") {
               [package, version, reason, message] ->
                  do_action(
                     gu.cmd([cx.gleam_cmd, "hex", "retire"])
                        |> gu.add_value(package)
                        |> gu.add_value(version)
                        |> gu.add_value(reason)
                        |> gu.add_value_if(!string.is_empty(message), message),
                     cx,
                  )
               value -> alert_invalid(cx, value)
            }
         }
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_hex_unretire(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Un-retire a release from Hex"))
   |> gu.set_text(cx.msg("Arguments"))
   |> gu.add_entry("<PACKAGE>")
   |> gu.add_entry("<VERSION>")
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      case check_env() {
         False -> alert_missing_env(cx)
         True -> {
            case string.split(answer, "|") {
               [package, version] ->
                  do_action(
                     gu.cmd([cx.gleam_cmd, "hex", "unretire", package, version]),
                     cx,
                  )
               value -> alert_invalid(cx, value)
            }
         }
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_hex_revert(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Revert a release from Hex"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_entry("<PACKAGE>")
   |> gu.add_entry("<VERSION>")
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      case check_env() {
         False -> alert_missing_env(cx)
         True -> {
            case string.split(answer, "|") {
               [package, version] ->
                  do_action(
                     gu.cmd([cx.gleam_cmd, "hex", "revert"])
                        |> gu.add_option(Some(package), "package")
                        |> gu.add_option(Some(version), "version"),
                     cx,
                  )
               value -> alert_invalid(cx, value)
            }
         }
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_new(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Create a new project"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_entry(cx.msg("Name of the project"))
   |> gu.add_combo_and_values(cx.msg("Skip git"), values: [
      cx.msg("no"),
      cx.msg("yes"),
   ])
   |> gu.add_combo_and_values(cx.msg("Skip github"), values: [
      cx.msg("no"),
      cx.msg("yes"),
   ])
   |> gu.add_combo_and_values(cx.msg("Template"), values: [
      cx.msg("unset"),
      "lib",
   ])
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      case string.split(answer, "|") {
         [name, skip_git, skip_github, template] ->
            do_action(
               gu.cmd([cx.gleam_cmd, "new"])
                  |> gu.add_option(Some(name), "name")
                  |> gu.add_option_bool(skip_git == cx.msg("yes"), "skip-git")
                  |> gu.add_option_bool(
                     skip_github == cx.msg("yes"),
                     "skip-github",
                  )
                  |> gu.add_option_if(
                     template != cx.msg("unset"),
                     template,
                     "template",
                  )
                  |> gu.add_value(cx.path <> "/" <> name),
               cx,
            )
         value -> alert_invalid(cx, value)
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_publish(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Publish the project to the Hex package manager"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_combo_and_values("--replace", values: [cx.msg("no"), cx.msg("yes")])
   |> gu.add_combo_and_values("--yes", values: [cx.msg("yes"), cx.msg("no")])
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      case check_env() {
         False -> alert_missing_env(cx)
         True -> {
            case string.split(answer, "|") {
               [replace, yes] ->
                  do_action(
                     gu.cmd([cx.gleam_cmd, "publish"])
                        |> gu.add_option_bool(
                           replace == cx.msg("yes"),
                           "replace",
                        )
                        |> gu.add_option_bool(yes == cx.msg("yes"), "yes"),
                     cx,
                  )
               value -> alert_invalid(cx, value)
            }
         }
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_remove(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Remove project dependencies"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_entry(cx.msg("The names of packages to remove"))
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      let packages: String = answer
      do_action(
         gu.cmd([cx.gleam_cmd, "remove"])
            |> gu.add_row(string.split(string.trim(packages), " ")),
         cx,
      )
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_run(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Run the project"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_entry(cx.msg("Arguments"))
   |> gu.add_combo_and_values(cx.msg("The platform to target"), values: [
      cx.msg("unset"),
      "erlang",
      "javascript",
   ])
   |> gu.add_combo_and_values(cx.msg("The runtime to target"), values: [
      cx.msg("unset"),
      "nodejs",
      "deno",
      "bun",
   ])
   |> gu.add_combo_and_values(
      cx.msg("Don't print progress information"),
      values: [cx.msg("no"), cx.msg("yes")],
   )
   |> gu.add_entry(cx.msg("The module to run"))
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      case string.split(answer, "|") {
         [args, target, runtime, no_print_progress, module] ->
            do_action(
               gu.cmd([cx.gleam_cmd, "run"])
                  |> gu.add_option_if(
                     target != cx.msg("unset"),
                     target,
                     "target",
                  )
                  |> gu.add_option_if(
                     runtime != cx.msg("unset"),
                     runtime,
                     "runtime",
                  )
                  |> gu.add_option_bool(
                     no_print_progress == cx.msg("yes"),
                     "no-print-progress",
                  )
                  |> gu.add_option_if(
                     !string.is_empty(module),
                     module,
                     "module",
                  )
                  |> fn(g) -> List(String) {
                     case string.is_empty(args) {
                        True -> g
                        False -> gu.add_row(g, string.split("-- " <> args, " "))
                     }
                  },
               cx,
            )
         value -> alert_invalid(cx, value)
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}

fn action_test(cx: Cx) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(cx.msg("Run the project tests"))
   |> gu.set_text(cx.msg("Options"))
   |> gu.add_combo_and_values(cx.msg("The platform to target"), values: [
      cx.msg("unset"),
      "erlang",
      "javascript",
   ])
   |> gu.add_combo_and_values(cx.msg("The runtime to target"), values: [
      cx.msg("unset"),
      "nodejs",
      "deno",
      "bun",
   ])
   |> gu.set_separator("|")
   |> gu.prompt_in(cx.path)
   |> result.map(fn(answer: String) -> Bool {
      case string.split(answer, "|") {
         [target, runtime] ->
            do_action(
               gu.cmd([cx.gleam_cmd, "test"])
                  |> gu.add_option_if(
                     target != cx.msg("unset"),
                     target,
                     "target",
                  )
                  |> gu.add_option_if(
                     runtime != cx.msg("unset"),
                     runtime,
                     "runtime",
                  ),
               cx,
            )
         value -> alert_invalid(cx, value)
      }
   })
   |> result.map_error(alert_gu_error)
   |> result.unwrap_both()
}
