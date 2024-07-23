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

pub fn actions(path: String, msg: fn(String) -> String) -> Nil {
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
      |> gu.add_extra_button("Cancel")
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
                  "build" -> do_action.alert(1, msg("Not supported yet"))
                  "check" -> do_action.alert(1, msg("Not supported yet"))
                  "clean" -> do_action.alert(1, msg("Not supported yet"))
                  "deps" -> do_action.alert(1, msg("Not supported yet"))
                  "docs" -> do_action.alert(1, msg("Not supported yet"))
                  "export" -> do_action.alert(1, msg("Not supported yet"))
                  "fix" -> do_action.alert(1, msg("Not supported yet"))
                  "format" -> do_action.alert(1, msg("Not supported yet"))
                  "hex" -> do_action.alert(1, msg("Not supported yet"))
                  "new" -> do_action.alert(1, msg("Not supported yet"))
                  "publish" -> do_action.alert(1, msg("Not supported yet"))
                  "remove" -> do_action.alert(1, msg("Not supported yet"))
                  "run" -> action_run(path, msg)
                  "test" -> action_test(path, msg)
                  "update" -> do_action.do_action(["update", "gleam"], path)
                  "help" -> do_action.do_action(["help", "gleam"], path)
                  "Cancel" -> Nil
                  _ -> do_action.alert(1, out)
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
         msg(msg("Add the packages as dev-only dependencies")),
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
                     |> gu.add_value(packages),
                  path,
               )
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
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
