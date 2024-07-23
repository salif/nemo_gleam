import action_new
import do_action
import gleam/list
import gleam/option.{Some}
import gleam/string
import gu

pub fn run(args: List(String), msg: fn(String) -> String) -> Nil {
   case list.first(args) {
      Ok(path) -> actions(path, msg)
      Error(Nil) ->
         do_action.alert(0, msg("Usage:") <> " gleam-action actions <PATH>")
   }
}

fn actions(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
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
      |> gu.set_timeout(30)
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) | Error(#(_, out)) -> {
         case string.is_empty(out) {
            True -> Nil
            False -> {
               case gu.parse(out) {
                  "add" -> action_add(path, msg)
                  "build" -> action_build(path, msg)
                  "check" -> action_check(path, msg)
                  "clean" -> action_clean(path)
                  "deps" -> action_deps(path, msg)
                  "docs" -> action_docs(path, msg)
                  "export" -> action_export(path, msg)
                  "fix" -> do_action.do_action(["fix", "gleam"], path)
                  "format" -> action_format(path, msg)
                  "hex" -> action_hex(path, msg)
                  "new" -> action_new.action_new(path, msg)
                  "publish" -> action_publish(path, msg)
                  "remove" -> action_remove(path, msg)
                  "run" -> action_run(path, msg)
                  "test" -> action_test(path, msg)
                  "update" -> do_action.do_action(["update", "gleam"], path)
                  "help" -> do_action.do_action(["help", "gleam"], path)
                  d ->
                     case d == msg("Close") {
                        True -> Nil
                        False -> do_action.alert(1, d)
                     }
               }
            }
         }
      }
   }
}

fn action_add(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Add new project dependencies"))
      |> gu.add_entry(msg("The names of Hex packages to add"))
      |> gu.add_combo_and_values(
         msg("Add the packages as dev-only dependencies"),
         values: [msg("no"), msg("yes")],
      )
      |> gu.set_separator("|")
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) ->
         case gu.parse_list(out, "|") {
            [packages, dev] ->
               do_action.do_action(
                  ["add", "gleam"]
                     |> gu.add_bool(dev == msg("yes"), "dev")
                     |> gu.add_value_if(!string.is_empty(packages), packages),
                  path,
               )
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
         }
      Error(_) -> Nil
   }
}

fn action_build(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Build the project"))
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
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) ->
         case gu.parse_list(out, "|") {
            [warnings_as_errors, target] ->
               do_action.do_action(
                  ["build", "gleam"]
                     |> gu.add_bool(
                        warnings_as_errors == msg("yes"),
                        "warnings-as-errors",
                     )
                     |> gu.add_opt_if(target != msg("unset"), target, "target"),
                  path,
               )
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
         }
      Error(_) -> Nil
   }
}

fn action_check(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Type check the project"))
      |> gu.add_combo_and_values(msg("The platform to target"), values: [
         msg("unset"),
         "erlang",
         "javascript",
      ])
      |> gu.set_separator("|")
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) -> {
         let target: String = gu.parse(out)
         do_action.do_action(
            ["check", "gleam"]
               |> gu.add_opt_if(target != msg("unset"), target, "target"),
            path,
         )
      }
      Error(_) -> Nil
   }
}

fn action_clean(path: String) -> Nil {
   case
      ["clean", "gleam"]
      |> gu.show_in(path, err: True)
   {
      Ok(_) -> Nil
      Error(err) -> do_action.alert(err.0, err.1)
   }
}

fn action_deps(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Work with dependency packages"))
      |> gu.add_combo_and_values(msg("Command"), values: [
         "list", "download", "update",
      ])
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) -> {
         do_action.do_action([gu.parse(out), "deps", "gleam"], path)
      }
      Error(_) -> Nil
   }
}

fn action_docs(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Render HTML documentation"))
      |> gu.add_combo_and_values(msg("Command"), values: [
         "build", "build --open", "publish", "remove",
      ])
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) ->
         case gu.parse(out) {
            "build" -> do_action.do_action(["build", "docs", "gleam"], path)
            "build --open" ->
               do_action.do_action(["--open", "build", "docs", "gleam"], path)
            "publish" -> do_action.do_action(["publish", "docs", "gleam"], path)
            "remove" -> action_docs_remove(path, msg)
            _ -> do_action.alert(1, msg("Not supported yet"))
         }
      Error(_) -> Nil
   }
}

fn action_docs_remove(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Remove HTML docs from HexDocs"))
      |> gu.add_entry(msg("The name of the package"))
      |> gu.add_entry(msg("The version of the docs to remove"))
      |> gu.set_separator("|")
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) -> {
         case gu.parse_list(out, "|") {
            [package, version] ->
               do_action.do_action(
                  ["remove", "docs", "gleam"]
                     |> gu.add_opt(Some(package), "package")
                     |> gu.add_opt(Some(version), "version"),
                  path,
               )
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
         }
      }
      Error(_) -> Nil
   }
}

fn action_export(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Export something useful from the Gleam project"))
      |> gu.add_combo_and_values(msg("Command"), values: [
         "erlang-shipment", "hex-tarball", "javascript-prelude",
         "typescript-prelude", "package-interface",
      ])
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) ->
         case gu.parse(out) {
            "erlang-shipment" ->
               do_action.do_action(["erlang-shipment", "export", "gleam"], path)
            "hex-tarball" ->
               do_action.do_action(["hex-tarball", "export", "gleam"], path)
            "javascript-prelude" -> {
               do_action.alert(1, msg("Not supported yet"))
            }
            "typescript-prelude" -> {
               do_action.alert(1, msg("Not supported yet"))
            }
            "package-interface" -> action_export_package_interface(path, msg)
            _ -> do_action.alert(1, msg("Not supported yet"))
         }
      Error(_) -> Nil
   }
}

fn action_export_package_interface(
   path: String,
   msg: fn(String) -> String,
) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg(
         "Information on the modules, functions, and types in the project in JSON format",
      ))
      |> gu.add_entry(msg("The path to write the JSON file to"))
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) -> {
         let output: String = gu.parse(out)
         do_action.do_action(
            ["package-interface", "export", "gleam"]
               |> gu.add_opt_if(!string.is_empty(output), output, "out"),
            path,
         )
      }
      Error(_) -> Nil
   }
}

fn action_format(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Format source code"))
      |> gu.add_entry(msg("Files to format"))
      |> gu.add_combo_and_values(msg("Read source from STDIN"), values: [
         msg("no"),
         msg("yes"),
      ])
      |> gu.add_combo_and_values(
         msg("Check if inputs are formatted without changing them"),
         values: [msg("no"), msg("yes")],
      )
      |> gu.set_separator("|")
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) ->
         case gu.parse_list(out, "|") {
            [files, stdin, check] -> {
               case
                  ["format", "gleam"]
                  |> gu.add_bool(stdin == msg("yes"), "stdin")
                  |> gu.add_bool(check == msg("yes"), "check")
                  |> gu.add_value_if(!string.is_empty(files), files)
                  |> gu.show_in(path, err: True)
               {
                  Ok(_) -> Nil
                  Error(err) -> do_action.alert(err.0, err.1)
               }
            }
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
         }
      Error(_) -> Nil
   }
}

fn action_hex(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Work with the Hex package manager"))
      |> gu.add_combo_and_values(msg("Command"), values: [
         "retire", "unretire", "revert",
      ])
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) ->
         case gu.parse(out) {
            "retire" -> action_hex_retire(path, msg)
            "unretire" -> action_hex_unretire(path, msg)
            "revert" -> action_hex_revert(path, msg)
            _ -> do_action.alert(1, msg("Not supported yet"))
         }
      Error(_) -> Nil
   }
}

fn action_hex_retire(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Retire a release from Hex"))
      |> gu.add_entry("<PACKAGE>")
      |> gu.add_entry("<VERSION>")
      |> gu.add_combo_and_values("<REASON>", values: [
         "other", "invalid", "security", "deprecated", "renamed",
      ])
      |> gu.add_entry("[MESSAGE]")
      |> gu.set_separator("|")
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) -> {
         case gu.parse_list(out, "|") {
            [package, version, reason, message] ->
               do_action.do_action(
                  ["retire", "hex", "gleam"]
                     |> gu.add_value(package)
                     |> gu.add_value(version)
                     |> gu.add_value(reason)
                     |> gu.add_value_if(!string.is_empty(message), message),
                  path,
               )
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
         }
      }
      Error(_) -> Nil
   }
}

fn action_hex_unretire(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Un-retire a release from Hex"))
      |> gu.add_entry("<PACKAGE>")
      |> gu.add_entry("<VERSION>")
      |> gu.set_separator("|")
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) -> {
         case gu.parse_list(out, "|") {
            [package, version] ->
               do_action.do_action(
                  ["unretire", "hex", "gleam"]
                     |> gu.add_value(package)
                     |> gu.add_value(version),
                  path,
               )
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
         }
      }
      Error(_) -> Nil
   }
}

fn action_hex_revert(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Revert a release from Hex"))
      |> gu.add_entry("--package")
      |> gu.add_entry("--version")
      |> gu.set_separator("|")
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) -> {
         case gu.parse_list(out, "|") {
            [package, version] ->
               do_action.do_action(
                  ["revert", "hex", "gleam"]
                     |> gu.add_opt(Some(package), "package")
                     |> gu.add_opt(Some(version), "version"),
                  path,
               )
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
         }
      }
      Error(_) -> Nil
   }
}

fn action_publish(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Publish the project to the Hex package manager"))
      |> gu.add_combo_and_values("--replace", values: [msg("no"), msg("yes")])
      |> gu.add_combo_and_values("--yes", values: [msg("yes"), msg("no")])
      |> gu.set_separator("|")
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) ->
         case gu.parse_list(out, "|") {
            [replace, yes] ->
               do_action.do_action(
                  ["publish", "gleam"]
                     |> gu.add_bool(replace == msg("yes"), "replace")
                     |> gu.add_bool(yes == msg("yes"), "yes"),
                  path,
               )
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
         }
      Error(_) -> Nil
   }
}

fn action_remove(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Remove project dependencies"))
      |> gu.add_entry(msg("The names of packages to remove"))
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) -> {
         let packages: String = gu.parse(out)
         do_action.do_action(
            ["remove", "gleam"]
               |> gu.add_value_if(!string.is_empty(packages), packages),
            path,
         )
      }
      Error(_) -> Nil
   }
}

fn action_run(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Run the project"))
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
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) ->
         case gu.parse_list(out, "|") {
            [args, target, runtime, module] ->
               do_action.do_action(
                  ["run", "gleam"]
                     |> gu.add_opt_if(target != msg("unset"), target, "target")
                     |> gu.add_opt_if(
                        runtime != msg("unset"),
                        runtime,
                        "runtime",
                     )
                     |> gu.add_opt_if(
                        !string.is_empty(module),
                        module,
                        "module",
                     )
                     |> gu.add_value_if(!string.is_empty(args), args),
                  path,
               )
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
         }
      Error(_) -> Nil
   }
}

fn action_test(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Run the project tests"))
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
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) ->
         case gu.parse_list(out, "|") {
            [target, runtime] ->
               do_action.do_action(
                  ["test", "gleam"]
                     |> gu.add_opt_if(target != msg("unset"), target, "target")
                     |> gu.add_opt_if(
                        runtime != msg("unset"),
                        runtime,
                        "runtime",
                     ),
                  path,
               )
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
         }
      Error(_) -> Nil
   }
}
