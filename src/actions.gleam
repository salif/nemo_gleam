import envoy
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gu

pub const gleam_cmd: String = "gleam"

pub fn run(args: List(String), msg: fn(String) -> String) -> Bool {
   case list.first(args) {
      Ok(path) -> actions(path, msg)
      Error(Nil) -> alert(0, msg("Usage:") <> " gleam-action actions <PATH>")
   }
}

pub fn run_new(args: List(String), msg: fn(String) -> String) -> Bool {
   case list.first(args) {
      Ok(path) -> action_new(path, msg)
      Error(Nil) -> alert(0, msg("Usage:") <> " gleam-action new <PATH>")
   }
}

pub fn alert(alert_type: Int, text: String) -> Bool {
   gu.zenity
   |> gu.add_value(case alert_type {
      0 -> gu.type_info
      _ -> gu.type_error
   })
   |> gu.new_message_opts(
      text: Some(text),
      icon: None,
      no_wrap: False,
      no_markup: True,
      ellipsize: False,
   )
   |> gu.show(True)
   |> result.is_ok
}

pub fn do_action(cmd: List(String), path: String) -> Bool {
   case gu.show_in(cmd, path, err: True) {
      Ok(val) -> alert(0, val)
      Error(err) -> alert(err.0, err.1)
   }
}

pub fn do_action_alert(value, msg) -> Bool {
   alert(1, msg("Invalid input: ") <> string.inspect(value))
}

fn check_env(msg: fn(String) -> String) -> Result(Nil, String) {
   let api_key = envoy.get("HEXPM_API_KEY")
   let user = envoy.get("HEXPM_USER")
   let pass = envoy.get("HEXPM_PASS")
   case result.is_ok(api_key), { result.is_ok(user) && result.is_ok(pass) } {
      False, False ->
         Error(msg("Missing HEXPM_USER, HEXPM_PASS or HEXPM_API_KEY"))
      _, _ -> Ok(Nil)
   }
}

fn actions(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_question()
   |> gu.set_title(msg("Gleam Actions"))
   |> gu.new_message_opts(
      text: Some(msg("Commands:")),
      icon: Some("view-compact"),
      no_wrap: False,
      no_markup: True,
      ellipsize: False,
   )
   |> gu.new_question_opts(default_cancel: False, switch: True)
   |> gu.add_extra_button(msg("Close"))
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
   |> gu.prompt_in(path)
   |> result.map_error(fn(err) { err.1 })
   |> result.unwrap_both()
   |> fn(answer: String) -> Bool {
      case string.is_empty(answer) {
         True -> False
         False -> {
            case answer {
               "add" -> action_add(path, msg)
               "build" -> action_build(path, msg)
               "check" -> action_check(path, msg)
               "clean" -> action_clean(path)
               "deps" -> action_deps(path, msg)
               "docs" -> action_docs(path, msg)
               "export" -> action_export(path, msg)
               "fix" -> do_action(gu.cmd([gleam_cmd, "fix"]), path)
               "format" -> action_format(path, msg)
               "hex" -> action_hex(path, msg)
               "new" -> action_new(path, msg)
               "publish" -> action_publish(path, msg)
               "remove" -> action_remove(path, msg)
               "run" -> action_run(path, msg)
               "test" -> action_test(path, msg)
               "update" -> do_action(gu.cmd([gleam_cmd, "update"]), path)
               "help" -> do_action(gu.cmd([gleam_cmd, "help"]), path)
               d ->
                  case d == msg("Close") {
                     True -> False
                     False -> alert(1, d)
                  }
            }
         }
      }
   }
}

fn action_add(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Add new project dependencies"))
   |> gu.set_text(msg("Options"))
   |> gu.add_entry(msg("The names of Hex packages to add"))
   |> gu.add_combo_and_values(
      msg("Add the packages as dev-only dependencies"),
      values: [msg("no"), msg("yes")],
   )
   |> gu.set_separator("|")
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) {
      case string.split(answer, "|") {
         [packages, dev] ->
            do_action(
               gu.cmd([gleam_cmd, "add"])
                  |> gu.add_option_bool(dev == msg("yes"), "dev")
                  |> gu.add_row(string.split(string.trim(packages), " ")),
               path,
            )
         value -> do_action_alert(value, msg)
      }
   })
   |> result.is_ok()
}

fn action_build(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Build the project"))
   |> gu.set_text(msg("Options"))
   |> gu.add_combo_and_values(
      msg("Emit compile time warnings as errors"),
      values: [msg("no"), msg("yes")],
   )
   |> gu.add_combo_and_values(msg("The platform to target"), values: [
      msg("unset"),
      "erlang",
      "javascript",
   ])
   |> gu.set_separator("|")
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) {
      case string.split(answer, "|") {
         [warnings_as_errors, target] ->
            do_action(
               gu.cmd([gleam_cmd, "build"])
                  |> gu.add_option_bool(
                     warnings_as_errors == msg("yes"),
                     "warnings-as-errors",
                  )
                  |> gu.add_option_if(target != msg("unset"), target, "target"),
               path,
            )
         value -> do_action_alert(value, msg)
      }
   })
   |> result.is_ok()
}

fn action_check(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Type check the project"))
   |> gu.set_text(msg("Options"))
   |> gu.add_combo_and_values(msg("The platform to target"), values: [
      msg("unset"),
      "erlang",
      "javascript",
   ])
   |> gu.set_separator("|")
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      let target: String = answer
      do_action(
         gu.cmd([gleam_cmd, "check"])
            |> gu.add_option_if(target != msg("unset"), target, "target"),
         path,
      )
   })
   |> result.is_ok()
}

fn action_clean(path: String) -> Bool {
   case
      gu.cmd([gleam_cmd, "clean"])
      |> gu.show_in(path, err: True)
   {
      // No output
      Ok(_) -> True
      Error(err) -> alert(err.0, err.1)
   }
}

fn action_deps(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_list()
   |> gu.set_title(msg("Work with dependency packages"))
   |> gu.set_text(msg("Select a command"))
   |> gu.set_separator("|")
   |> gu.add_option_bool(True, "hide-header")
   |> gu.add_column("Command")
   |> gu.add_column("Description")
   |> gu.add_row(["list", msg("List all dependency packages")])
   |> gu.add_row(["download", msg("Download all dependency packages")])
   |> gu.add_row([
      "update",
      msg("Update dependency packages to their latest versions"),
   ])
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      let command: String = answer
      do_action(gu.cmd([gleam_cmd, "deps", command]), path)
   })
   |> result.is_ok()
}

fn action_docs(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_list()
   |> gu.set_title(msg("Render HTML documentation"))
   |> gu.set_text(msg("Select a command"))
   |> gu.set_separator("|")
   |> gu.add_option_bool(True, "hide-header")
   |> gu.add_column("Command")
   |> gu.add_column("Description")
   |> gu.add_row(["build", msg("Render HTML docs locally")])
   |> gu.add_row([
      "build --open",
      msg("Opens the docs in a browser after rendering"),
   ])
   |> gu.add_row(["publish", msg("Publish HTML docs to HexDocs")])
   |> gu.add_row(["remove", msg("Remove HTML docs from HexDocs")])
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      let command: String = answer
      case command {
         "build" -> do_action(gu.cmd([gleam_cmd, "docs", "build"]), path)
         "build --open" ->
            do_action(gu.cmd([gleam_cmd, "docs", "build", "--open"]), path)
         "publish" ->
            case check_env(msg) {
               Error(err) -> alert(1, err)
               Ok(_) -> do_action(gu.cmd([gleam_cmd, "docs", "publish"]), path)
            }
         "remove" -> action_docs_remove(path, msg)
         _ -> alert(1, msg("Not supported yet"))
      }
   })
   |> result.is_ok()
}

fn action_docs_remove(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Remove HTML docs from HexDocs"))
   |> gu.set_text(msg("Options"))
   |> gu.add_entry(msg("The name of the package"))
   |> gu.add_entry(msg("The version of the docs to remove"))
   |> gu.set_separator("|")
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      case check_env(msg) {
         Error(err) -> alert(1, err)
         Ok(_) -> {
            case string.split(answer, "|") {
               [package, version] ->
                  do_action(
                     gu.cmd([gleam_cmd, "docs", "remove"])
                        |> gu.add_option(Some(package), "package")
                        |> gu.add_option(Some(version), "version"),
                     path,
                  )
               value -> do_action_alert(value, msg)
            }
         }
      }
   })
   |> result.is_ok()
}

fn action_export(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_list()
   |> gu.set_title(msg("Export something useful from the Gleam project"))
   |> gu.set_text(msg("Select a command"))
   |> gu.set_separator("|")
   |> gu.add_option_bool(True, "hide-header")
   |> gu.add_column("Command")
   |> gu.add_column("Description")
   |> gu.add_row([
      "erlang-shipment",
      msg("Precompiled Erlang, suitable for deployment"),
   ])
   |> gu.add_row([
      "hex-tarball",
      msg("The package bundled into a tarball, suitable for publishing to Hex"),
   ])
   |> gu.add_row(["javascript-prelude", msg("The JavaScript prelude module")])
   |> gu.add_row(["typescript-prelude", msg("The TypeScript prelude module")])
   |> gu.add_row([
      "package-interface",
      msg(
         "Information on the modules, functions, and types in the project in JSON format",
      ),
   ])
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      let command: String = answer
      case command {
         "erlang-shipment" ->
            do_action(gu.cmd([gleam_cmd, "export", "erlang-shipment"]), path)
         "hex-tarball" ->
            do_action(gu.cmd([gleam_cmd, "export", "hex-tarball"]), path)
         "javascript-prelude" -> {
            alert(1, msg("Not supported yet"))
         }
         "typescript-prelude" -> {
            alert(1, msg("Not supported yet"))
         }
         "package-interface" -> action_export_package_interface(path, msg)
         _ -> alert(1, msg("Not supported yet"))
      }
   })
   |> result.is_ok()
}

fn action_export_package_interface(
   path: String,
   msg: fn(String) -> String,
) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg(
      "Information on the modules, functions, and types in the project in JSON format",
   ))
   |> gu.set_text(msg("Options"))
   |> gu.add_entry(msg("The path to write the JSON file to"))
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      let path: String = answer
      do_action(
         gu.cmd([gleam_cmd, "export", "package-interface"])
            |> gu.add_option_if(!string.is_empty(path), path, "out"),
         path,
      )
   })
   |> result.is_ok()
}

fn action_format(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Format source code"))
   |> gu.set_text(msg("Options"))
   |> gu.add_combo_and_values(msg("Read source from STDIN"), values: [msg("no")])
   |> gu.add_combo_and_values(
      msg("Check if inputs are formatted without changing them"),
      values: [msg("no"), msg("yes")],
   )
   |> gu.set_separator("\n")
   |> gu.prompt_in(path)
   |> result.try(fn(answer: String) {
      gu.zenity
      |> gu.new_file_selection(
         filename: None,
         multiple: True,
         directory: False,
         save: False,
         separator: Some("|"),
         file_filter: None,
      )
      |> gu.prompt_in(path)
      |> result.map(string.split(_, "|"))
      |> result.map(fn(files: List(String)) {
         string.join(files, " ") <> "\n" <> answer
      })
   })
   |> result.map(fn(answer: String) -> Bool {
      case string.split(answer, "\n") {
         [files, stdin, check] -> {
            case
               gu.cmd([gleam_cmd, "format"])
               |> gu.add_option_bool(stdin == msg("yes"), "stdin")
               |> gu.add_option_bool(check == msg("yes"), "check")
               |> gu.add_row(string.split(files, " "))
               |> gu.show_in(path, err: True)
            {
               // No output
               Ok(_) -> True
               Error(err) -> alert(err.0, err.1)
            }
         }
         value -> do_action_alert(value, msg)
      }
   })
   |> result.is_ok()
}

fn action_hex(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_list()
   |> gu.set_title(msg("Work with the Hex package manager"))
   |> gu.set_text(msg("Select a command"))
   |> gu.set_separator("|")
   |> gu.add_option_bool(True, "hide-header")
   |> gu.add_column("Command")
   |> gu.add_column("Description")
   |> gu.add_row(["retire", msg("Retire a release from Hex")])
   |> gu.add_row(["unretire", msg("Un-retire a release from Hex")])
   |> gu.add_row(["revert", msg("Revert a release from Hex")])
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      let command: String = answer
      case command {
         "retire" -> action_hex_retire(path, msg)
         "unretire" -> action_hex_unretire(path, msg)
         "revert" -> action_hex_revert(path, msg)
         _ -> alert(1, msg("Not supported yet"))
      }
   })
   |> result.is_ok()
}

fn action_hex_retire(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Retire a release from Hex"))
   |> gu.set_text(msg("Arguments"))
   |> gu.add_entry("<PACKAGE>")
   |> gu.add_entry("<VERSION>")
   |> gu.add_combo_and_values("<REASON>", values: [
      "other", "invalid", "security", "deprecated", "renamed",
   ])
   |> gu.add_entry("[MESSAGE]")
   |> gu.set_separator("|")
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      case check_env(msg) {
         Error(err) -> alert(1, err)
         Ok(_) -> {
            case string.split(answer, "|") {
               [package, version, reason, message] ->
                  do_action(
                     gu.cmd([gleam_cmd, "hex", "retire"])
                        |> gu.add_value(package)
                        |> gu.add_value(version)
                        |> gu.add_value(reason)
                        |> gu.add_value_if(!string.is_empty(message), message),
                     path,
                  )
               value -> do_action_alert(value, msg)
            }
         }
      }
   })
   |> result.is_ok()
}

fn action_hex_unretire(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Un-retire a release from Hex"))
   |> gu.set_text(msg("Arguments"))
   |> gu.add_entry("<PACKAGE>")
   |> gu.add_entry("<VERSION>")
   |> gu.set_separator("|")
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      case check_env(msg) {
         Error(err) -> alert(1, err)
         Ok(_) -> {
            case string.split(answer, "|") {
               [package, version] ->
                  do_action(
                     gu.cmd([gleam_cmd, "hex", "unretire", package, version]),
                     path,
                  )
               value -> do_action_alert(value, msg)
            }
         }
      }
   })
   |> result.is_ok()
}

fn action_hex_revert(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Revert a release from Hex"))
   |> gu.set_text(msg("Options"))
   |> gu.add_entry("<PACKAGE>")
   |> gu.add_entry("<VERSION>")
   |> gu.set_separator("|")
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      case check_env(msg) {
         Error(err) -> alert(1, err)
         Ok(_) -> {
            case string.split(answer, "|") {
               [package, version] ->
                  do_action(
                     gu.cmd([gleam_cmd, "hex", "revert"])
                        |> gu.add_option(Some(package), "package")
                        |> gu.add_option(Some(version), "version"),
                     path,
                  )
               value -> do_action_alert(value, msg)
            }
         }
      }
   })
   |> result.is_ok()
}

pub fn action_new(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Create a new project"))
   |> gu.set_text(msg("Options"))
   |> gu.add_entry(msg("Name of the project"))
   |> gu.add_combo_and_values(msg("Skip git"), values: [msg("no"), msg("yes")])
   |> gu.add_combo_and_values(msg("Skip github"), values: [
      msg("no"),
      msg("yes"),
   ])
   |> gu.add_combo_and_values(msg("Template"), values: [msg("unset"), "lib"])
   |> gu.set_separator("|")
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) {
      case string.split(answer, "|") {
         [name, skip_git, skip_github, template] ->
            do_action(
               gu.cmd([gleam_cmd, "new"])
                  |> gu.add_option(Some(name), "name")
                  |> gu.add_option_bool(skip_git == msg("yes"), "skip-git")
                  |> gu.add_option_bool(
                     skip_github == msg("yes"),
                     "skip-github",
                  )
                  |> gu.add_option_if(
                     template != msg("unset"),
                     template,
                     "template",
                  )
                  |> gu.add_value(path <> "/" <> name),
               path,
            )
         value -> do_action_alert(value, msg)
      }
   })
   |> result.is_ok()
}

fn action_publish(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Publish the project to the Hex package manager"))
   |> gu.set_text(msg("Options"))
   |> gu.add_combo_and_values("--replace", values: [msg("no"), msg("yes")])
   |> gu.add_combo_and_values("--yes", values: [msg("yes"), msg("no")])
   |> gu.set_separator("|")
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      case check_env(msg) {
         Error(err) -> alert(1, err)
         Ok(_) -> {
            case string.split(answer, "|") {
               [replace, yes] ->
                  do_action(
                     gu.cmd([gleam_cmd, "publish"])
                        |> gu.add_option_bool(replace == msg("yes"), "replace")
                        |> gu.add_option_bool(yes == msg("yes"), "yes"),
                     path,
                  )
               value -> do_action_alert(value, msg)
            }
         }
      }
   })
   |> result.is_ok()
}

fn action_remove(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Remove project dependencies"))
   |> gu.set_text(msg("Options"))
   |> gu.add_entry(msg("The names of packages to remove"))
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      let packages: String = answer
      do_action(
         gu.cmd([gleam_cmd, "remove"])
            |> gu.add_row(string.split(string.trim(packages), " ")),
         path,
      )
   })
   |> result.is_ok()
}

fn action_run(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Run the project"))
   |> gu.set_text(msg("Options"))
   |> gu.add_entry(msg("Arguments"))
   |> gu.add_combo_and_values(msg("The platform to target"), values: [
      msg("unset"),
      "erlang",
      "javascript",
   ])
   |> gu.add_combo_and_values(msg("The runtime to target"), values: [
      msg("unset"),
      "nodejs",
      "deno",
      "bun",
   ])
   |> gu.add_entry(msg("The module to run"))
   |> gu.set_separator("|")
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) -> Bool {
      case string.split(answer, "|") {
         [args, target, runtime, module] ->
            do_action(
               gu.cmd([gleam_cmd, "run"])
                  |> gu.add_option_if(target != msg("unset"), target, "target")
                  |> gu.add_option_if(
                     runtime != msg("unset"),
                     runtime,
                     "runtime",
                  )
                  |> gu.add_option_if(
                     !string.is_empty(module),
                     module,
                     "module",
                  )
                  |> fn(g) -> List(String) {
                     case string.is_empty(args) {
                        True -> g
                        False -> gu.add_row(g, string.split(args, " "))
                     }
                  },
               path,
            )
         value -> do_action_alert(value, msg)
      }
   })
   |> result.is_ok()
}

fn action_test(path: String, msg: fn(String) -> String) -> Bool {
   gu.zenity
   |> gu.new_forms()
   |> gu.set_title(msg("Run the project tests"))
   |> gu.set_text(msg("Options"))
   |> gu.add_combo_and_values(msg("The platform to target"), values: [
      msg("unset"),
      "erlang",
      "javascript",
   ])
   |> gu.add_combo_and_values(msg("The runtime to target"), values: [
      msg("unset"),
      "nodejs",
      "deno",
      "bun",
   ])
   |> gu.set_separator("|")
   |> gu.prompt_in(path)
   |> result.map(fn(answer: String) {
      case string.split(answer, "|") {
         [target, runtime] ->
            do_action(
               gu.cmd([gleam_cmd, "test"])
                  |> gu.add_option_if(target != msg("unset"), target, "target")
                  |> gu.add_option_if(
                     runtime != msg("unset"),
                     runtime,
                     "runtime",
                  ),
               path,
            )
         value -> do_action_alert(value, msg)
      }
   })
   |> result.is_ok()
}
